%% Análisis de Microcortes en Centro de Datos
% Este script analiza microcortes que afectan equipos críticos
% y evalúa la protección de un UPS según la norma IEC 61000-4-11

clear all; close all; clc;

%% 1. PARÁMETROS DE LA SEÑAL
fprintf('=== ANÁLISIS DE MICROCORTES EN CENTRO DE DATOS ===\n\n');

% Parámetros generales
duracion_total = 0.3;           % 300 ms en segundos
V_pico = 325;                   % Tensión nominal pico (V)
V_rms_nominal = V_pico/sqrt(2); % Tensión RMS nominal
frecuencia = 50;                % Frecuencia de red (Hz)
fs = 10000;                     % Frecuencia de muestreo (Hz)
t = 0:1/fs:duracion_total;      % Vector de tiempo

% Microcorte 1
inicio_mc1 = 0.050;             % 50 ms
duracion_mc1 = 0.015;           % 15 ms
hueco_mc1 = 0.80;               % 80% de reducción
fin_mc1 = inicio_mc1 + duracion_mc1;

% Microcorte 2
inicio_mc2 = 0.150;             % 150 ms
duracion_mc2 = 0.020;           % 20 ms
hueco_mc2 = 0.70;               % 70% de reducción
fin_mc2 = inicio_mc2 + duracion_mc2;

% UPS
tiempo_conmutacion_ups = 0.004; % 4 ms

fprintf('Parámetros de la señal:\n');
fprintf('  - Tensión nominal pico: %.2f V\n', V_pico);
fprintf('  - Tensión RMS nominal: %.2f V\n', V_rms_nominal);
fprintf('  - Frecuencia: %.0f Hz\n', frecuencia);
fprintf('  - Duración total: %.0f ms\n', duracion_total*1000);
fprintf('\nMicrocorte 1:\n');
fprintf('  - Inicio: %.0f ms\n', inicio_mc1*1000);
fprintf('  - Duración: %.0f ms\n', duracion_mc1*1000);
fprintf('  - Reducción: %.0f%%\n', hueco_mc1*100);
fprintf('\nMicrocorte 2:\n');
fprintf('  - Inicio: %.0f ms\n', inicio_mc2*1000);
fprintf('  - Duración: %.0f ms\n', duracion_mc2*1000);
fprintf('  - Reducción: %.0f%%\n\n', hueco_mc2*100);

%% 2. GENERACIÓN DE LA SEÑAL CON MICROCORTES
fprintf('Generando señal con microcortes...\n');

% Señal base (senoidal)
v_base = V_pico * sin(2*pi*frecuencia*t);

% Inicializar señal con microcortes
v_microcortes = v_base;

% Aplicar microcorte 1
mask_mc1 = (t >= inicio_mc1) & (t < fin_mc1);
v_microcortes(mask_mc1) = v_base(mask_mc1) * (1 - hueco_mc1);

% Aplicar microcorte 2
mask_mc2 = (t >= inicio_mc2) & (t < fin_mc2);
v_microcortes(mask_mc2) = v_base(mask_mc2) * (1 - hueco_mc2);

%% 3. CÁLCULO DE RMS DESLIZANTE (Ventana: 10 ms)
fprintf('Calculando RMS deslizante (ventana: 10 ms)...\n');

ventana_rms = 0.010;                    % 10 ms
muestras_ventana = round(ventana_rms * fs);

% RMS deslizante
v_rms = zeros(size(t));
for i = 1:length(t)
    if i <= muestras_ventana
        % Para los primeros puntos, usar desde el inicio
        v_rms(i) = sqrt(mean(v_microcortes(1:i).^2));
    else
        % Ventana deslizante completa
        v_rms(i) = sqrt(mean(v_microcortes(i-muestras_ventana+1:i).^2));
    end
end

%% 4. IDENTIFICACIÓN Y CARACTERIZACIÓN DE EVENTOS
fprintf('\n=== CARACTERIZACIÓN DE EVENTOS ===\n\n');

% Umbral de detección (95% de la tensión nominal)
umbral_deteccion = 0.95 * V_rms_nominal;

% Detectar eventos (cuando RMS cae por debajo del umbral)
eventos_detectados = v_rms < umbral_deteccion;

% Encontrar inicio y fin de cada evento
diff_eventos = diff([0 eventos_detectados 0]);
inicios = find(diff_eventos == 1);
fines = find(diff_eventos == -1) - 1;

fprintf('Eventos detectados: %d\n\n', length(inicios));

% Caracterizar cada evento
for i = 1:length(inicios)
    idx_inicio = inicios(i);
    idx_fin = fines(i);
    
    tiempo_inicio = t(idx_inicio) * 1000;  % en ms
    tiempo_fin = t(idx_fin) * 1000;        % en ms
    duracion_evento = tiempo_fin - tiempo_inicio;
    
    % Tensión mínima durante el evento
    v_min = min(v_rms(idx_inicio:idx_fin));
    v_min_porcentaje = (v_min / V_rms_nominal) * 100;
    
    % Profundidad del hueco
    profundidad_hueco = ((V_rms_nominal - v_min) / V_rms_nominal) * 100;
    
    fprintf('EVENTO %d:\n', i);
    fprintf('  - Tiempo de inicio: %.2f ms\n', tiempo_inicio);
    fprintf('  - Tiempo de fin: %.2f ms\n', tiempo_fin);
    fprintf('  - Duración: %.2f ms\n', duracion_evento);
    fprintf('  - Tensión mínima: %.2f V (%.1f%% de nominal)\n', v_min, v_min_porcentaje);
    fprintf('  - Profundidad del hueco: %.1f%%\n', profundidad_hueco);
      %% 5. CLASIFICACIÓN SEGÚN IEC 61000-4-11
    % Clasificación según duración y magnitud conforme a las Tablas 1 y 2 de la norma
    fprintf('  - Clasificación IEC 61000-4-11:\n');
    
    % Determinar número de periodos (ciclos a 50 Hz)
    num_periodos = duracion_evento / 20;  % 20 ms = 1 periodo a 50 Hz
    
    % Clasificar tipo de evento según IEC 61000-4-11
    % Tabla 1: Huecos de tensión
    % Tabla 2: Interrupciones breves
    
    if v_min_porcentaje < 1
        % Interrupción breve (Tabla 2)
        tipo_evento = 'Interrupción breve';
        
        if num_periodos < 250/300
            nivel_clase = 'Clase X (especial, fuera de tablas estándar)';
            severidad = 'Crítica';
        elseif duracion_evento >= 5000
            nivel_clase = 'Fuera de rango normalizado (> 250/300 periodos)';
            severidad = 'Extrema';
        else
            nivel_clase = sprintf('Interrupción 0%% durante %.0f ms (%.1f periodos)', duracion_evento, num_periodos);
            severidad = 'Crítica';
        end
        
    else
        % Hueco de tensión (Tabla 1)
        tipo_evento = 'Hueco de tensión';
        
        % Determinar Clase según tensión residual y duración (Tabla 1 IEC 61000-4-11)
        if num_periodos <= 0.5
            % 0% durante 1/2 periodo (10 ms a 50 Hz)
            duracion_clase = '0% durante 1/2 periodo (Clase 2)';
            
            if v_min_porcentaje >= 70
                nivel_clase = sprintf('Clase 2: Hueco al %.0f%% durante 1/2 periodo (10 ms)', v_min_porcentaje);
                severidad = 'Media';
            elseif v_min_porcentaje >= 40
                nivel_clase = sprintf('Hueco al %.0f%% durante 1/2 periodo - MÁS SEVERO que Clase 2 estándar', v_min_porcentaje);
                severidad = 'Alta';
            else
                nivel_clase = sprintf('Hueco al %.0f%% durante 1/2 periodo - SEVERIDAD EXTREMA', v_min_porcentaje);
                severidad = 'Muy Alta';
            end
            
        elseif num_periodos <= 1
            % 0% durante 1 periodo (20 ms a 50 Hz)
            duracion_clase = '0% durante 1 periodo (Clase 2)';
            
            if v_min_porcentaje >= 70
                nivel_clase = sprintf('Clase 2: Hueco al %.0f%% durante 1 periodo (20 ms)', v_min_porcentaje);
                severidad = 'Media';
            elseif v_min_porcentaje >= 40
                nivel_clase = sprintf('Hueco al %.0f%% durante 1 periodo - MÁS SEVERO que Clase 2 estándar', v_min_porcentaje);
                severidad = 'Alta';
            else
                nivel_clase = sprintf('Hueco al %.0f%% durante 1 periodo - SEVERIDAD EXTREMA', v_min_porcentaje);
                severidad = 'Muy Alta';
            end
            
        elseif num_periodos <= 12.5
            % 10/12 periodos (200-250 ms a 50 Hz)
            duracion_clase = sprintf('%.1f periodos', num_periodos);
            
            if v_min_porcentaje >= 70
                nivel_clase = sprintf('Clase 3: Hueco al %.0f%% durante %.0f ms (%.1f periodos)', ...
                    v_min_porcentaje, duracion_evento, num_periodos);
                severidad = 'Media';
            elseif v_min_porcentaje >= 40
                nivel_clase = sprintf('Clase 3: Hueco al %.0f%% durante %.0f ms - PROFUNDO', ...
                    v_min_porcentaje, duracion_evento);
                severidad = 'Alta';
            else
                nivel_clase = sprintf('Hueco al %.0f%% durante %.0f ms - MUY PROFUNDO', ...
                    v_min_porcentaje, duracion_evento);
                severidad = 'Muy Alta';
            end
            
        elseif num_periodos <= 30
            % 25/30 periodos (500-600 ms a 50 Hz)
            duracion_clase = sprintf('%.1f periodos (25/30c)', num_periodos);
            
            if v_min_porcentaje >= 80
                nivel_clase = sprintf('Clase 3: Hueco al %.0f%% durante %.0f ms (%.1f periodos)', ...
                    v_min_porcentaje, duracion_evento, num_periodos);
                severidad = 'Media-Alta';
            elseif v_min_porcentaje >= 70
                nivel_clase = sprintf('Clase 2/3: Hueco al %.0f%% durante %.0f ms (%.1f periodos)', ...
                    v_min_porcentaje, duracion_evento, num_periodos);
                severidad = 'Alta';
            elseif v_min_porcentaje >= 40
                nivel_clase = sprintf('Hueco al %.0f%% durante %.0f ms - PROFUNDO', ...
                    v_min_porcentaje, duracion_evento);
                severidad = 'Muy Alta';
            else
                nivel_clase = sprintf('Hueco al %.0f%% durante %.0f ms - EXTREMO', ...
                    v_min_porcentaje, duracion_evento);
                severidad = 'Crítica';
            end
            
        elseif num_periodos <= 300
            % 250/300 periodos (5-6 s a 50 Hz)
            duracion_clase = sprintf('%.0f periodos (larga duración)', num_periodos);
            
            if v_min_porcentaje >= 80
                nivel_clase = sprintf('Clase 3: Hueco al %.0f%% durante %.2f s', ...
                    v_min_porcentaje, duracion_evento/1000);
                severidad = 'Alta';
            else
                nivel_clase = sprintf('Hueco al %.0f%% durante %.2f s - LARGA DURACIÓN', ...
                    v_min_porcentaje, duracion_evento/1000);
                severidad = 'Muy Alta';
            end
            
        else
            % Más de 300 periodos
            nivel_clase = 'Fuera de rango normalizado (> 250/300 periodos)';
            severidad = 'Extrema';
        end
    end
    
    fprintf('    · Tipo: %s\n', tipo_evento);
    fprintf('    · Duración: %.2f ms (%.2f periodos/ciclos a 50 Hz)\n', duracion_evento, num_periodos);
    fprintf('    · Tensión residual: %.1f%% (Reducción: %.1f%%)\n', v_min_porcentaje, profundidad_hueco);
    fprintf('    · Clasificación: %s\n', nivel_clase);
    fprintf('    · Severidad: %s\n', severidad);
    
    % Almacenar datos para análisis UPS
    eventos(i).inicio = tiempo_inicio;
    eventos(i).duracion = duracion_evento;
    eventos(i).v_min = v_min;
    eventos(i).profundidad = profundidad_hueco;
    eventos(i).severidad = severidad;
    
    fprintf('\n');
end

%% 6. EVALUACIÓN DE PROTECCIÓN UPS
fprintf('=== EVALUACIÓN DE PROTECCIÓN UPS ===\n\n');
fprintf('Tiempo de conmutación del UPS: %.1f ms\n\n', tiempo_conmutacion_ups*1000);

proteccion_adecuada = true;

for i = 1:length(eventos)
    fprintf('EVENTO %d:\n', i);
    
    % Verificar si el UPS puede proteger
    if eventos(i).duracion > tiempo_conmutacion_ups*1000
        % El evento dura más que el tiempo de conmutación
        % Calcular tiempo de exposición
        tiempo_exposicion = tiempo_conmutacion_ups * 1000;
        tiempo_protegido = eventos(i).duracion - tiempo_exposicion;
        
        fprintf('  - Duración del evento: %.2f ms\n', eventos(i).duracion);
        fprintf('  - Tiempo de exposición: %.2f ms\n', tiempo_exposicion);
        fprintf('  - Tiempo protegido por UPS: %.2f ms\n', tiempo_protegido);
        fprintf('  - Profundidad del hueco: %.1f%%\n', eventos(i).profundidad);
        
        % Evaluar si la exposición es crítica
        if eventos(i).profundidad > 50 && tiempo_exposicion > 2
            fprintf('  - RESULTADO: Protección PARCIAL\n');
            fprintf('    · El equipo estará expuesto %.2f ms al hueco de %.1f%%\n', ...
                    tiempo_exposicion, eventos(i).profundidad);
            fprintf('    · Riesgo: MEDIO - Posibles perturbaciones en equipos sensibles\n');
            proteccion_adecuada = false;
        else
            fprintf('  - RESULTADO: Protección ADECUADA\n');
            fprintf('    · El UPS conmutará antes del periodo crítico\n');
        end
    else
        % El evento es más corto que el tiempo de conmutación
        fprintf('  - Duración del evento: %.2f ms\n', eventos(i).duracion);
        fprintf('  - Profundidad del hueco: %.1f%%\n', eventos(i).profundidad);
        fprintf('  - RESULTADO: SIN PROTECCIÓN\n');
        fprintf('    · El evento es más corto que el tiempo de conmutación\n');
        fprintf('    · El UPS NO alcanza a activarse\n');
        fprintf('    · Riesgo: ALTO - Equipo completamente expuesto\n');
        proteccion_adecuada = false;
    end
    fprintf('\n');
end

%% CONCLUSIONES FINALES
fprintf('=== CONCLUSIONES FINALES ===\n\n');

if proteccion_adecuada
    fprintf('✓ El UPS con tiempo de conmutación de 4 ms protegería ADECUADAMENTE\n');
    fprintf('  los equipos críticos del centro de datos.\n\n');
else
    fprintf('✗ El UPS con tiempo de conmutación de 4 ms NO protegería ADECUADAMENTE\n');
    fprintf('  los equipos críticos del centro de datos.\n\n');
end

fprintf('JUSTIFICACIÓN:\n');
fprintf('1. Análisis de eventos detectados:\n');
for i = 1:length(eventos)
    fprintf('   - Evento %d: %.1f ms de duración, hueco del %.1f%%, severidad %s\n', ...
            i, eventos(i).duracion, eventos(i).profundidad, eventos(i).severidad);
end

fprintf('\n2. Capacidad de respuesta del UPS:\n');
fprintf('   - Tiempo de conmutación: %.1f ms\n', tiempo_conmutacion_ups*1000);
fprintf('   - Evento 1 (%.1f ms): ', eventos(1).duracion);
if eventos(1).duracion < tiempo_conmutacion_ups*1000
    fprintf('Más CORTO que tiempo de conmutación → SIN PROTECCIÓN\n');
else
    fprintf('Más LARGO que tiempo de conmutación → PROTECCIÓN PARCIAL\n');
end
fprintf('   - Evento 2 (%.1f ms): ', eventos(2).duracion);
if eventos(2).duracion < tiempo_conmutacion_ups*1000
    fprintf('Más CORTO que tiempo de conmutación → SIN PROTECCIÓN\n');
else
    fprintf('Más LARGO que tiempo de conmutación → PROTECCIÓN PARCIAL\n');
end

fprintf('\n3. Impacto en equipos críticos:\n');
fprintf('   - Los microcortes de 15-20 ms son típicamente tolerados por fuentes\n');
fprintf('     de alimentación modernas (hold-up time: 16-20 ms típico)\n');
fprintf('   - Sin embargo, huecos del 70-80%% pueden causar:\n');
fprintf('     · Reinicios de equipos sensibles\n');
fprintf('     · Pérdida de datos en memoria volátil\n');
fprintf('     · Degradación de vida útil de componentes\n');

fprintf('\n4. Recomendaciones:\n');
fprintf('   - Considerar UPS con tiempo de conmutación < 2 ms (UPS línea interactiva)\n');
fprintf('   - Alternativamente, usar UPS en línea (online/doble conversión) con\n');
fprintf('     tiempo de respuesta = 0 ms\n');
fprintf('   - Instalar acondicionadores de línea en equipos más críticos\n');
fprintf('   - Monitorizar calidad de energía para prevenir eventos futuros\n');

%% 7. VISUALIZACIÓN
fprintf('\n=== GENERANDO GRÁFICAS ===\n');

figure('Position', [100 100 1400 900], 'Name', 'Análisis de Microcortes en Centro de Datos');

% Subplot 1: Señal de tensión
subplot(3,1,1);
plot(t*1000, v_base, 'b--', 'LineWidth', 1, 'DisplayName', 'Señal nominal');
hold on;
plot(t*1000, v_microcortes, 'r', 'LineWidth', 1.5, 'DisplayName', 'Señal con microcortes');
% Marcar zonas de microcortes
fill([inicio_mc1 fin_mc1 fin_mc1 inicio_mc1]*1000, ...
     [min(v_microcortes) min(v_microcortes) max(v_microcortes) max(v_microcortes)], ...
     'y', 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'DisplayName', 'Microcorte 1');
fill([inicio_mc2 fin_mc2 fin_mc2 inicio_mc2]*1000, ...
     [min(v_microcortes) min(v_microcortes) max(v_microcortes) max(v_microcortes)], ...
     'm', 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'DisplayName', 'Microcorte 2');
grid on;
xlabel('Tiempo (ms)');
ylabel('Tensión (V)');
title('Señal de Tensión con Microcortes');
legend('Location', 'best');
xlim([0 duracion_total*1000]);

% Subplot 2: RMS deslizante
subplot(3,1,2);
plot(t*1000, v_rms, 'b', 'LineWidth', 2, 'DisplayName', 'RMS deslizante');
hold on;
yline(V_rms_nominal, 'g--', 'LineWidth', 1.5, 'DisplayName', 'RMS nominal');
yline(umbral_deteccion, 'r--', 'LineWidth', 1.5, 'DisplayName', 'Umbral detección (95%)');
% Marcar eventos detectados
for i = 1:length(inicios)
    t_inicio = t(inicios(i))*1000;
    t_fin = t(fines(i))*1000;
    fill([t_inicio t_fin t_fin t_inicio], ...
         [0 0 max(v_rms) max(v_rms)], ...
         'r', 'FaceAlpha', 0.15, 'EdgeColor', 'none');
end
grid on;
xlabel('Tiempo (ms)');
ylabel('Tensión RMS (V)');
title('Valor RMS Deslizante (Ventana: 10 ms)');
legend('Location', 'best');
xlim([0 duracion_total*1000]);
ylim([0 max(v_rms)*1.1]);

% Subplot 3: Análisis de eventos y protección UPS
subplot(3,1,3);
hold on;

% EXPLICACIÓN DE SOMBREADOS:
% - ROJO: Periodo en que el equipo está EXPUESTO al microcorte (sin protección UPS)
%         El UPS aún no ha conmutado a baterías
% - VERDE: Periodo en que el UPS ya conmutó y está PROTEGIENDO el equipo
%          El equipo recibe energía de las baterías del UPS

% Primero dibujar sombreados (para que queden detrás)
for i = 1:length(inicios)
    t_inicio = t(inicios(i))*1000;
    t_fin_evento = t(fines(i))*1000;
    t_conmutacion = t_inicio + tiempo_conmutacion_ups*1000;
    
    if i == 1
        % Solo en primer evento, añadir a leyenda
        % ZONA ROJA: Tiempo de exposición sin protección
        % Desde el inicio del evento hasta que el UPS conmuta (o hasta el fin si el evento es muy corto)
        t_fin_zona_roja = min(t_conmutacion, t_fin_evento);
        fill([t_inicio t_fin_zona_roja t_fin_zona_roja t_inicio], ...
             [0 0 110 110], ...
             'r', 'FaceAlpha', 0.25, 'EdgeColor', 'k', 'LineWidth', 0.5, ...
             'DisplayName', sprintf('EXPOSICIÓN (sin protección UPS): 0-%.0f ms del evento', tiempo_conmutacion_ups*1000));
        
        % ZONA VERDE: Tiempo con protección UPS
        % Desde que el UPS conmuta hasta el fin del evento
        if t_conmutacion < t_fin_evento
            fill([t_conmutacion t_fin_evento t_fin_evento t_conmutacion], ...
                 [0 0 110 110], ...
                 'g', 'FaceAlpha', 0.2, 'EdgeColor', 'k', 'LineWidth', 0.5, ...
                 'DisplayName', sprintf('PROTEGIDO (UPS activo): >%.0f ms del evento', tiempo_conmutacion_ups*1000));
        end
    else
        % Para eventos posteriores, sin añadir a leyenda
        t_fin_zona_roja = min(t_conmutacion, t_fin_evento);
        fill([t_inicio t_fin_zona_roja t_fin_zona_roja t_inicio], ...
             [0 0 110 110], ...
             'r', 'FaceAlpha', 0.25, 'EdgeColor', 'k', 'LineWidth', 0.5, ...
             'HandleVisibility', 'off');
        
        if t_conmutacion < t_fin_evento
            fill([t_conmutacion t_fin_evento t_fin_evento t_conmutacion], ...
                 [0 0 110 110], ...
                 'g', 'FaceAlpha', 0.2, 'EdgeColor', 'k', 'LineWidth', 0.5, ...
                 'HandleVisibility', 'off');
        end
    end
    
    % Marcar visualmente el tiempo de conmutación del UPS
    if t_conmutacion < t_fin_evento
        if i == 1
            plot([t_conmutacion t_conmutacion], [0 110], 'k:', 'LineWidth', 2, ...
                 'DisplayName', sprintf('Tiempo conmutación UPS (%.0f ms)', tiempo_conmutacion_ups*1000));
        else
            plot([t_conmutacion t_conmutacion], [0 110], 'k:', 'LineWidth', 2, ...
                 'HandleVisibility', 'off');
        end
    end
end

% Línea base y tensión relativa
plot(t*1000, ones(size(t))*100, 'g--', 'LineWidth', 1.5, 'DisplayName', '100% Nominal');
v_relativa = (v_rms / V_rms_nominal) * 100;
plot(t*1000, v_relativa, 'b', 'LineWidth', 2.5, 'DisplayName', 'Tensión RMS (% nominal)');

% Umbrales según norma IEC 61000-4-11 (Tabla 1)
% Líneas de referencia para tensión residual según las clases de prueba
yline(100, 'g--', 'LineWidth', 1.5, 'DisplayName', '100% Nominal');
yline(80, '--', 'Color', [0.85 0.33 0.1], 'LineWidth', 1.5, 'DisplayName', '80% - Clase 3 (80% durante 25/30c)');
yline(70, '--', 'Color', [0.9 0.7 0], 'LineWidth', 1.5, 'DisplayName', '70% - Clase 2/3 (70% durante 25/30c)');
yline(40, 'm--', 'LineWidth', 1.5, 'DisplayName', '40% - Nivel severo (40% durante 10/12c)');
yline(0, 'r--', 'LineWidth', 1.5, 'DisplayName', '0% - Interrupción');

grid on;
xlabel('Tiempo (ms)');
ylabel('Tensión (% nominal)');
title('Análisis de Protección UPS y Clasificación IEC 61000-4-11');
legend('Location', 'best');
xlim([0 duracion_total*1000]);
ylim([0 110]);

% Ajustar layout
sgtitle('Análisis de Microcortes en Centro de Datos - Evaluación de Protección UPS', ...
        'FontSize', 14, 'FontWeight', 'bold');

fprintf('\nAnálisis completado exitosamente.\n');
fprintf('Gráficas generadas.\n');
