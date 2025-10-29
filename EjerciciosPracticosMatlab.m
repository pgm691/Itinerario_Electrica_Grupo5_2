%% PRÁCTICA: ANÁLISIS DE CALIDAD DE POTENCIA
% Ejercicios 1.1, 1.2, 1.3, 2.1, 2.2, 2.3
% Autor: Pablo Godoy Moreno y Fran Moreno Manzano
% Fecha: 2025

clear all; close all; clc;

%% ========== EJERCICIO 1.1: CÁLCULO DEL VALOR RMS ==========
clear; close all; clc;
fprintf('\n========== EJERCICIO 1.1: CÁLCULO DEL VALOR RMS ==========\n');

% Parámetros de la señal
f_fund = 50;           % Frecuencia fundamental (Hz)
fs = 1000;             % Frecuencia de muestreo (Hz)
duracion = 0.1;        % Duración (segundos)
V_pico = 325;          % Voltaje pico (V)
RMS_teorico = 230;     % Valor RMS teórico (V)

% Vector de tiempo
t1 = 0:1/fs:duracion-1/fs;

% Señal sinusoidal
v1 = V_pico * sin(2*pi*f_fund*t1);

% Calcular el valor RMS
RMS_calculado = sqrt(mean(v1.^2));

% Calcular el error
error = abs(RMS_calculado - RMS_teorico) / RMS_teorico * 100;

fprintf('Valor RMS calculado: %.4f V\n', RMS_calculado);
fprintf('Valor RMS teórico: %.4f V\n', RMS_teorico);
fprintf('Error: %.4f %%\n\n', error);

figure('Position', [100 100 1000 500]);

% Gráfica de la señal
plot(t1*1000, v1, 'b-', 'LineWidth', 2);
hold on;

% Líneas de referencia
yline(V_pico, '--r', 'Pico positivo', 'LineWidth', 1.5, 'LabelHorizontalAlignment', 'right');
yline(-V_pico, '--r', 'Pico negativo', 'LineWidth', 1.5, 'LabelHorizontalAlignment', 'right');
yline(RMS_calculado, '--g', sprintf('RMS calculado: %.2f V', RMS_calculado), 'LineWidth', 1.5, 'LabelHorizontalAlignment', 'right');
yline(-RMS_calculado, '--g', LineWidth=1.5);
yline(0, '-k', 'LineWidth', 0.5);

% Etiquetas y formato
xlabel('Tiempo (ms)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Voltaje (V)', 'FontSize', 12, 'FontWeight', 'bold');
title(sprintf('Ejercicio 1.1: Señal Sinusoidal 50 Hz - RMS = %.2f V (Error: %.2f %%)', ...
    RMS_calculado, error), 'FontSize', 13, 'FontWeight', 'bold');
grid on;
grid minor;

legend('Señal', 'Pico (+)', 'Pico (-)', 'RMS', 'Location', 'southeast', 'FontSize', 10);
hold off;
%% ========== EJERCICIO 1.2: DETECCIÓN DE CRUCES POR CERO ==========
clear; close all; clc;
fprintf('========== EJERCICIO 1.2: DETECCIÓN DE CRUCES POR CERO ==========\n');

% Parámetros de la señal
f_fund = 50;           % Frecuencia fundamental (Hz)
fs = 1000;             % Frecuencia de muestreo (Hz)
V_pico = 325;          % Voltaje pico (V)

% Generar nueva señal para este ejercicio
t2 = 0:1/fs:0.5-1/fs;
v2 = V_pico * sin(2*pi*f_fund*t2);

% Detectar cruces por cero - Método mejorado
% Un cruce ocurre cuando la señal cambia de signo entre dos muestras consecutivas
cruces_indices = [];
tiempos_cruces_exactos = [];

for i = 1:length(v2)-1
    % Si el producto es negativo, hay un cruce por cero entre i e i+1
    if v2(i) * v2(i+1) < 0
        % Encontrar el cruce más preciso usando interpolación lineal
        t_cruce = t2(i) - v2(i) * (t2(i+1) - t2(i)) / (v2(i+1) - v2(i));
        idx_cruce = round(t_cruce * fs);
        
        % Evitar duplicados muy cercanos
        if isempty(cruces_indices) || (idx_cruce - cruces_indices(end) > 5)
            cruces_indices = [cruces_indices, idx_cruce];
            tiempos_cruces_exactos = [tiempos_cruces_exactos, t_cruce];
        end
    end
end

% Calcular frecuencia desde los cruces
if length(cruces_indices) > 2
    periodos = diff(tiempos_cruces_exactos);
    periodo_promedio = mean(periodos) * 2;  % 2 cruces = 1 período
    frecuencia_detectada = 1 / periodo_promedio;
else
    frecuencia_detectada = 0;
end

fprintf('Número de cruces por cero detectados: %d\n', length(cruces_indices));
fprintf('Frecuencia detectada: %.2f Hz\n', frecuencia_detectada);
fprintf('Frecuencia teórica: %.2f Hz\n\n', f_fund);

% Visualización - Ejercicio 1.2
figure('Position', [100 400 1100 450]);
plot(t2*1000, v2, 'b-', 'LineWidth', 1.8); hold on;
% Plotear los cruces en sus tiempos exactos (interpolados) con voltaje = 0
plot(tiempos_cruces_exactos*1000, zeros(size(tiempos_cruces_exactos)), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
yline(0, '--k', 'LineWidth', 1);  % Línea de referencia en cero

xlabel('Tiempo (ms)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Voltaje (V)', 'FontSize', 12, 'FontWeight', 'bold');
title(sprintf('Detección de Cruces por Cero - Frecuencia Detectada: %.2f Hz', frecuencia_detectada), ...
    'FontSize', 13, 'FontWeight', 'bold');
legend('Señal', 'Cruces por cero', 'Cero', 'FontSize', 11);
grid on;
grid minor;


hold off;

%% ========== EJERCICIO 1.3: DETECCIÓN DE VARIACIONES DE TENSIÓN ==========
clear; close all; clc;
fprintf('========== EJERCICIO 1.3: DETECCIÓN DE VARIACIONES DE TENSIÓN ==========\n');

% Parámetros
f_fund = 50;           % Frecuencia fundamental (Hz)
fs_13 = 1000;          % Frecuencia de muestreo (Hz)
V_pico = 325;          % Voltaje pico (V)
RMS_nominal = 230;     % Valor RMS nominal (V)

% Generar señal sinusoidal pura
t3 = 0:1/fs_13:0.3-1/fs_13;
v3 = V_pico * sin(2*pi*f_fund*t3);

% ========== FUNCIÓN: Calcular RMS en ventanas deslizantes ==========
% Parámetros de entrada: señal, frecuencia de muestreo, tamaño de ventana en ms
% Devuelve: vector de valores RMS y vector de tiempos correspondientes

ventana_ms = 20;  % Ventana de 20 ms (un ciclo completo para 50 Hz)
ventana_muestras = round(ventana_ms * fs_13 / 1000);

rms_desli = [];
t_rms = [];

for i = 1:length(v3)-ventana_muestras+1
    % Extrae la ventana
    ventana = v3(i:i+ventana_muestras-1);
    % Calcula el RMS de la ventana
    rms_desli = [rms_desli, sqrt(mean(ventana.^2))];
    % Tiempo al centro de la ventana
    t_rms = [t_rms, (i + ventana_muestras/2 - 1) / fs_13];
end

% ========== ANÁLISIS DE RESULTADOS ==========
fprintf('RMS deslizante calculado con ventana de %d ms\n', ventana_ms);
fprintf('Número de valores RMS: %d\n', length(rms_desli));
fprintf('RMS promedio: %.2f V\n', mean(rms_desli));
fprintf('RMS mínimo: %.2f V\n', min(rms_desli));
fprintf('RMS máximo: %.2f V\n\n', max(rms_desli));

% ========== VISUALIZACIÓN ==========
figure('Position', [100 50 1200 700]);

% Subplot 1: Señal temporal completa
subplot(2,1,1);
plot(t3*1000, v3, 'b-', 'LineWidth', 1.5); hold on;
yline(V_pico, '--r', 'LineWidth', 1, 'Alpha', 0.5);
yline(-V_pico, '--r', 'LineWidth', 1, 'Alpha', 0.5);
yline(0, '-k', 'LineWidth', 0.5);
xlabel('Tiempo (ms)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Voltaje (V)', 'FontSize', 12, 'FontWeight', 'bold');
title('Ejercicio 1.3: Señal Sinusoidal (Dominio del Tiempo)', 'FontSize', 13, 'FontWeight', 'bold');
grid on;
grid minor;
legend('Señal', 'Pico +', 'Pico -', 'FontSize', 10);
hold off;

% Subplot 2: RMS deslizante
subplot(2,1,2);
plot(t_rms*1000, rms_desli, 'r-', 'LineWidth', 2.5); hold on;
yline(RMS_nominal, '--k', 'Nominal (230V)', 'LineWidth', 1.5, 'LabelHorizontalAlignment', 'right');
yline(RMS_nominal*0.9, '--g', 'Límite -10% (207V)', 'LineWidth', 1.5, 'LabelHorizontalAlignment', 'right');
yline(RMS_nominal*1.1, '--b', 'Límite +10% (253V)', 'LineWidth', 1.5, 'LabelHorizontalAlignment', 'right');

xlabel('Tiempo (ms)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('RMS (V)', 'FontSize', 12, 'FontWeight', 'bold');
title(sprintf('RMS Deslizante - Ventana: %d ms (Estable)', ventana_ms), 'FontSize', 13, 'FontWeight', 'bold');
grid on;
grid minor;

legend('RMS deslizante', 'Nominal', 'Límite -10%', 'Límite +10%', 'FontSize', 10, 'Location', 'best');
hold off;

% ========== INFORMACIÓN ADICIONAL ==========
fprintf('\n--- CONCLUSIONES ---\n');
fprintf('Para una señal sinusoidal pura sin variaciones:\n');
fprintf('- El RMS debe mantenerse constante en torno a %.2f V\n', RMS_nominal);
fprintf('- No hay desviaciones respecto a los límites ±10%%\n');
fprintf('- Esta función permite detectar variaciones rápidas de tensión\n');
fprintf('- La ventana de 20 ms es adecuada para detectar huecos y sobretensiones\n');
%% ========== EJERCICIO 2.1: ANÁLISIS ESPECTRAL BÁSICO ==========
clear; close all; clc;
fprintf('========== EJERCICIO 2.1: ANÁLISIS ESPECTRAL BÁSICO ==========\n');

% Parámetros
f_fund = 50;           % Frecuencia fundamental (Hz)
fs_esp = 2000;         % Frecuencia de muestreo (Hz)
V_pico = 325;          % Voltaje pico (V)

% Generar señal pura de 50 Hz
t_esp = 0:1/fs_esp:1-1/fs_esp;
v_pura = V_pico * sin(2*pi*f_fund*t_esp);

% ========== FUNCIÓN: Calcular espectro de frecuencias ==========
% Entrada: señal temporal y frecuencia de muestreo
% Salida: vector de frecuencias y magnitudes correspondientes

N_esp = length(v_pura);

% Calcular FFT
FFT_pura = fft(v_pura);

% Considerar solo frecuencias positivas (primera mitad del espectro)
FFT_pura = FFT_pura(1:N_esp/2+1);

% Normalizar magnitudes dividiendo por el número de muestras
mag_esp = abs(FFT_pura) / N_esp;

% Multiplicar por 2 las componentes intermedias (excepto DC y Nyquist)
mag_esp(2:end-1) = 2 * mag_esp(2:end-1);

% Vector de frecuencias
freqs_esp = (0:length(FFT_pura)-1) * (fs_esp/N_esp);

% ========== ANÁLISIS DE RESULTADOS ==========
% Encontrar componente fundamental (50 Hz)
[~, idx_50] = min(abs(freqs_esp - 50));
mag_50 = mag_esp(idx_50);
freq_real_50 = freqs_esp(idx_50);

fprintf('Espectro calculado para señal pura de 50 Hz\n');
fprintf('Resolución de frecuencia: %.4f Hz\n', fs_esp/N_esp);
fprintf('Frecuencia fundamental encontrada: %.2f Hz\n', freq_real_50);
fprintf('Magnitud en 50 Hz: %.2f V\n', mag_50);
fprintf('Magnitud teórica esperada: %.2f V\n\n', V_pico/2);

% Verificar que hay un solo pico en 50 Hz
% Buscar picos significativos (mayores a 10 V)
umbral = 10;
picos_indices = find(mag_esp > umbral);

fprintf('Análisis de picos significativos (> %d V):\n', umbral);
fprintf('Número de picos encontrados: %d\n', length(picos_indices));

if length(picos_indices) == 1
    fprintf('✓ VERIFICADO: Solo hay un pico, en la frecuencia fundamental\n\n');
else
    fprintf('Picos encontrados en:\n');
    for i = 1:length(picos_indices)
        fprintf('  Frecuencia: %7.2f Hz | Magnitud: %7.2f V\n', ...
            freqs_esp(picos_indices(i)), mag_esp(picos_indices(i)));
    end
    fprintf('\n');
end

% ========== VISUALIZACIÓN ==========
figure('Position', [100 50 1200 500]);

% Gráfica con stem (tallo) - Espectro hasta 500 Hz
% Encontrar índice correspondiente a 500 Hz
idx_500 = floor(500 * N_esp / fs_esp) + 1;

stem(freqs_esp(1:idx_500), mag_esp(1:idx_500), 'b', 'filled', 'LineWidth', 1.5);
hold on;

% Marcar el pico en 50 Hz
plot(freq_real_50, mag_50, 'r*', 'MarkerSize', 20, 'LineWidth', 2);
text(freq_real_50, mag_50 + 5, sprintf('Fundamental\n%.2f Hz\n%.2f V', freq_real_50, mag_50), ...
    'HorizontalAlignment', 'center', 'FontSize', 11, 'FontWeight', 'bold', ...
    'BackgroundColor', 'white', 'EdgeColor', 'red');

xlabel('Frecuencia (Hz)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Magnitud (V)', 'FontSize', 12, 'FontWeight', 'bold');
title('Ejercicio 2.1: Espectro de Frecuencias - Señal Pura 50 Hz', 'FontSize', 13, 'FontWeight', 'bold');
grid on;
grid minor;
xlim([0 500]);

% Información en la gráfica
text(0.98, 0.97, sprintf(['Parámetros:\n' ...
    'Frecuencia fundamental: %d Hz\n' ...
    'Frecuencia de muestreo: %d Hz\n' ...
    'Duración: 1 segundo\n' ...
    'Voltaje pico: %d V\n' ...
    'Muestras: %d'], ...
    f_fund, fs_esp, V_pico, N_esp), ...
    'Units', 'normalized', 'FontSize', 10, 'BackgroundColor', 'white', ...
    'EdgeColor', 'black', 'VerticalAlignment', 'top', ...
    'HorizontalAlignment', 'right');

hold off;

%% ========== EJERCICIO 2.2: ANÁLISIS DE ARMÓNICOS ==========
clear; close all; clc;
fprintf('========== EJERCICIO 2.2: ANÁLISIS DE ARMÓNICOS ==========\n');

% Parámetros
f_fund = 50;           % Frecuencia fundamental (Hz)
fs_esp = 2000;         % Frecuencia de muestreo (Hz)
V_pico = 325;          % Voltaje pico (V)

% Generar señal pura de 50 Hz (igual que Ejercicio 2.1)
t_esp = 0:1/fs_esp:1-1/fs_esp;
v_pura = V_pico * sin(2*pi*f_fund*t_esp);

% Calcular FFT
N_esp = length(v_pura);
FFT_pura = fft(v_pura);
FFT_pura = FFT_pura(1:N_esp/2+1);
mag_esp = abs(FFT_pura) / N_esp;
mag_esp(2:end-1) = 2 * mag_esp(2:end-1);
freqs_esp = (0:length(FFT_pura)-1) * (fs_esp/N_esp);

% ========== FUNCIÓN: Analizar armónicos ==========
% Entrada: señal, frecuencia de muestreo, frecuencia fundamental, número de armónicos
% Salida: tabla con n, frecuencia exacta, magnitud; y THD calculado

% Número de armónicos a analizar
n_armonicos = 15;

% Crear tabla de armónicos
tabla_arm_pura = [];

% Encontrar fundamental
[~, idx_50] = min(abs(freqs_esp - f_fund));
V_fundamental = mag_esp(idx_50);

fprintf('Búsqueda de armónicos:\n');
fprintf('Resolución de frecuencia: %.4f Hz\n\n', fs_esp/N_esp);

% Buscar cada armónico
for n = 1:n_armonicos
    freq_target = n * f_fund;  % Frecuencia teórica del armónico n
    [~, idx_arm] = min(abs(freqs_esp - freq_target));  % Índice más cercano
    mag_arm = mag_esp(idx_arm);  % Magnitud en ese índice
    freq_real = freqs_esp(idx_arm);  % Frecuencia real encontrada
    
    tabla_arm_pura = [tabla_arm_pura; n, freq_real, mag_arm];
end

% ========== CALCULAR THD ==========
% THD = 100 * sqrt(suma de V_n^2 desde n=2 hasta infinito) / V_1
suma_cuadrados_pura = sum(tabla_arm_pura(2:end,3).^2);
THD_puro = 100 * sqrt(suma_cuadrados_pura) / V_fundamental;

% ========== RESULTADOS EN CONSOLA ==========
fprintf('Análisis de armónicos para señal pura de 50 Hz:\n');
fprintf('='*50 + "\n");
fprintf('Fundamental (1er armónico): %.4f V\n\n', V_fundamental);

fprintf('Tabla de armónicos:\n');
fprintf('  n  | Frecuencia (Hz) | Magnitud (V) | %% Fundamental\n');
fprintf('-----|-----------------|--------------|---------------\n');

for i = 1:n_armonicos
    pct = 100 * tabla_arm_pura(i,3) / V_fundamental;
    fprintf(' %2d  | %14.2f | %12.4f | %13.2f\n', ...
        tabla_arm_pura(i,1), tabla_arm_pura(i,2), tabla_arm_pura(i,3), pct);
end

fprintf('\n');
fprintf('THD calculado: %.4f %%\n', THD_puro);
fprintf('Interpretación: Señal pura sin distorsión\n\n');

% ========== VISUALIZACIÓN: Gráfica de barras de armónicos ==========
figure('Position', [100 50 1100 500]);

bar(tabla_arm_pura(1:10,1), tabla_arm_pura(1:10,3), 'b', 'EdgeColor', 'black', 'LineWidth', 1.5);
hold on;

% Marcar el fundamental
bar(1, V_fundamental, 'r', 'EdgeColor', 'black', 'LineWidth', 1.5);

xlabel('Número de Armónico', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Magnitud (V)', 'FontSize', 12, 'FontWeight', 'bold');
title(sprintf('Ejercicio 2.2: Análisis de Armónicos - THD: %.4f %%', THD_puro), ...
    'FontSize', 13, 'FontWeight', 'bold');
grid on;
grid minor;

% Etiquetas en barras principales
for i = 1:10
    if tabla_arm_pura(i,3) > 5
        text(i, tabla_arm_pura(i,3) + 5, sprintf('%.1f V', tabla_arm_pura(i,3)), ...
            'HorizontalAlignment', 'center', 'FontSize', 9);
    end
end

% Información en la gráfica
text(0.98, 0.97, sprintf(['Parámetros:\n' ...
    'Tipo: Señal pura\n' ...
    'Fundamental: %.2f V\n' ...
    'THD: %.4f %%\n' ...
    'Armónicos analizados: %d'], ...
    V_fundamental, THD_puro, n_armonicos), ...
    'Units', 'normalized', 'FontSize', 10, 'BackgroundColor', 'white', ...
    'EdgeColor', 'black', 'VerticalAlignment', 'top', ...
    'HorizontalAlignment', 'right');

legend('Armónicos', 'Fundamental', 'FontSize', 11);
hold off;

fprintf('Gráfica generada con éxito.\n');
%% ========== EJERCICIO 2.3: GENERAR Y ANALIZAR SEÑAL CON ARMÓNICOS ==========
clear; close all; clc;
fprintf('========== EJERCICIO 2.3: GENERAR Y ANALIZAR SEÑAL CON ARMÓNICOS ==========\n');

% Parámetros
f_fund = 50;           % Frecuencia fundamental (Hz)
fs_arm = 2000;         % Frecuencia de muestreo (Hz)
V_pico = 325;          % Voltaje pico (V)
duracion = 0.5;        % Duración (segundos)

% Generar vector de tiempo
t_arm = 0:1/fs_arm:duracion-1/fs_arm;

% Parámetros de la señal compuesta
V_fund = V_pico;                    % Fundamental: 325 V
V_3 = 0.15 * V_pico;                % 3er armónico: 15% = 48.75 V
V_5 = 0.10 * V_pico;                % 5to armónico: 10% = 32.5 V

fprintf('Parámetros de la señal:\n');
fprintf('  Fundamental (50 Hz):    %.2f V\n', V_fund);
fprintf('  3er armónico (150 Hz):  %.2f V (15%% del fundamental)\n', V_3);
fprintf('  5to armónico (250 Hz):  %.2f V (10%% del fundamental)\n\n', V_5);

% Generar señal con armónicos (superposición)
v_arm = V_fund * sin(2*pi*f_fund*t_arm) + ...
        V_3 * sin(2*pi*3*f_fund*t_arm) + ...
        V_5 * sin(2*pi*5*f_fund*t_arm);

% Calcular FFT de señal con armónicos
N_arm = length(v_arm);
FFT_arm = fft(v_arm);
FFT_arm = FFT_arm(1:N_arm/2+1);
mag_arm = abs(FFT_arm) / N_arm;
mag_arm(2:end-1) = 2 * mag_arm(2:end-1);
freqs_arm = (0:length(FFT_arm)-1) * (fs_arm/N_arm);

% Encontrar componente fundamental
[~, idx_50_arm] = min(abs(freqs_arm - 50));
V_fundamental_arm = mag_arm(idx_50_arm);

% Calcular armónicos
tabla_arm = [];
for n = 1:15
    freq_target = n * f_fund;
    [~, idx_arm] = min(abs(freqs_arm - freq_target));
    mag_armonico = mag_arm(idx_arm);
    tabla_arm = [tabla_arm; n, freqs_arm(idx_arm), mag_armonico];
end

% Calcular THD
suma_cuadrados = sum(tabla_arm(2:end,3).^2);
THD_arm = 100 * sqrt(suma_cuadrados) / V_fundamental_arm;

% THD teórico esperado
THD_teorico = 100 * sqrt(0.15^2 + 0.10^2);

% ========== RESULTADOS EN CONSOLA ==========
fprintf('Análisis de armónicos con distorsión:\n');
fprintf('='*50 + "\n");
fprintf('Fundamental (1er armónico):  %.4f V\n\n', V_fundamental_arm);

fprintf('Tabla de armónicos:\n');
fprintf('  n  | Frecuencia (Hz) | Magnitud (V) | %% Fundamental\n');
fprintf('-----|-----------------|--------------|---------------\n');

for i = 1:10
    pct = 100 * tabla_arm(i,3) / V_fundamental_arm;
    fprintf(' %2d  | %14.2f | %12.4f | %13.2f\n', ...
        tabla_arm(i,1), tabla_arm(i,2), tabla_arm(i,3), pct);
end

fprintf('\n');
fprintf('THD calculado:     %.4f %%\n', THD_arm);
fprintf('THD teórico esperado: %.4f %%\n', THD_teorico);
fprintf('Diferencia:        %.4f %%\n\n', abs(THD_arm - THD_teorico));

if THD_arm > 8
    fprintf('⚠ ADVERTENCIA: THD supera el límite normativo de 8%%\n\n');
else
    fprintf('✓ Cumple con el límite normativo de 8%%\n\n');
end

% ========== VISUALIZACIÓN ==========
figure('Position', [100 50 1300 700]);

% ========== Subplot 1: Señal temporal (primeros 4 ciclos) ==========
subplot(2,1,1);

% Calcular número de muestras para 4 ciclos (4/50 = 0.08 segundos)
num_ciclos = 4;
tiempo_ciclos = num_ciclos / f_fund;
idx_ciclos = find(t_arm <= tiempo_ciclos);

plot(t_arm(idx_ciclos)*1000, v_arm(idx_ciclos), 'b-', 'LineWidth', 2);
hold on;
yline(0, '-k', 'LineWidth', 0.5);
yline(V_pico, '--r', 'LineWidth', 1, 'Alpha', 0.5);
yline(-V_pico, '--r', 'LineWidth', 1, 'Alpha', 0.5);

xlabel('Tiempo (ms)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Voltaje (V)', 'FontSize', 12, 'FontWeight', 'bold');
title('Ejercicio 2.3: Señal Compuesta con Armónicos (primeros 4 ciclos)', ...
    'FontSize', 13, 'FontWeight', 'bold');
grid on;
grid minor;
legend('Señal distorsionada', 'Referencia', 'FontSize', 10);
hold off;

% ========== Subplot 2: Espectro de armónicos (barras) ==========
subplot(2,1,2);

% Crear gráfica de barras para los primeros 10 armónicos
bar(tabla_arm(1:10,1), tabla_arm(1:10,3), 'FaceColor', [0.3 0.5 0.9], ...
    'EdgeColor', 'black', 'LineWidth', 1.5);
hold on;

% Destacar los armónicos principales (1, 3, 5)
bar(1, tabla_arm(1,3), 'FaceColor', 'red', 'EdgeColor', 'black', 'LineWidth', 1.5);
bar(3, tabla_arm(3,3), 'FaceColor', 'green', 'EdgeColor', 'black', 'LineWidth', 1.5);
bar(5, tabla_arm(5,3), 'FaceColor', [1 0.5 0], 'EdgeColor', 'black', 'LineWidth', 1.5);

xlabel('Número de Armónico', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Magnitud (V)', 'FontSize', 12, 'FontWeight', 'bold');
title(sprintf('Espectro de Armónicos - THD Calculado: %.2f %% (Teórico: %.2f %%)', ...
    THD_arm, THD_teorico), 'FontSize', 13, 'FontWeight', 'bold');
grid on;
grid minor;

% Etiquetas en barras principales
for i = [1, 3, 5]
    if tabla_arm(i,3) > 5
        text(i, tabla_arm(i,3) + 5, sprintf('%.1f V', tabla_arm(i,3)), ...
            'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold');
    end
end

% Información en la gráfica
text(0.98, 0.97, sprintf(['Parámetros:\n' ...
    'Fundamental: %.2f V\n' ...
    'THD calculado: %.2f %%\n' ...
    'THD teórico: %.2f %%\n' ...
    'Diferencia: %.2f %%'], ...
    V_fundamental_arm, THD_arm, THD_teorico, abs(THD_arm - THD_teorico)), ...
    'Units', 'normalized', 'FontSize', 10, 'BackgroundColor', 'white', ...
    'EdgeColor', 'black', 'VerticalAlignment', 'top', ...
    'HorizontalAlignment', 'right');

legend('Otros armónicos', 'Fundamental (1)', '3er armónico', '5to armónico', ...
    'FontSize', 10, 'Location', 'northeast');

hold off;

fprintf('Gráficas generadas con éxito.\n');

%% ACTIVIDAD GUIADA 2.3: ANALIZAR UN HUECO DE TENSIÓN
clear; clc; close all;
fprintf('========== ACTIVIDAD GUIADA 2.3: ANALIZAR UN HUECO DE TENSIÓN ==========\n\n');

% PARÁMETROS DE LA SEÑAL
fs = 2000;
duracion = 0.2;
f = 50;
V_pico = 325;
V_rms_nominal = 230;

fprintf('PASO 1: Generando señal base...\n');
fprintf('  Frecuencia de muestreo: %d Hz\n', fs);
fprintf('  Duración total: %.0f ms\n', duracion*1000);
fprintf('  Frecuencia fundamental: %d Hz\n', f);
fprintf('  Amplitud pico: %.0f V\n', V_pico);
fprintf('  Valor RMS nominal: %.0f V\n\n', V_rms_nominal);

t = 0:1/fs:duracion-1/fs;
v_base = V_pico * sin(2*pi*f*t);

fprintf('PASO 2: Introduciendo hueco de tensión...\n');
t_inicio_hueco = 0.050;
t_duracion_hueco = 0.050;
profundidad = 0.50;

idx_inicio = round(t_inicio_hueco * fs) + 1;
idx_fin = round((t_inicio_hueco + t_duracion_hueco) * fs);

v_hueco = v_base;
v_hueco(idx_inicio:idx_fin) = v_base(idx_inicio:idx_fin) * profundidad;

fprintf('  Inicio del hueco: %.0f ms\n', t_inicio_hueco*1000);
fprintf('  Duración del hueco: %.0f ms (%.1f ciclos)\n', t_duracion_hueco*1000, t_duracion_hueco*f);
fprintf('  Profundidad: %.0f%% (amplitud reducida a %.0f%%)\n', (1-profundidad)*100, profundidad*100);
fprintf('  Índices afectados: %d a %d\n\n', idx_inicio, idx_fin);

fprintf('PASO 3: Calculando RMS deslizante...\n');
ventana_ms = 20;
ventana_muestras = round(ventana_ms * fs / 1000);
fprintf('  Tamaño de ventana: %d ms (%d muestras)\n', ventana_ms, ventana_muestras);

N = length(v_hueco);
rms_deslizante = zeros(1, N - ventana_muestras + 1);

for i = ventana_muestras:N
    ventana_datos = v_hueco(i-ventana_muestras+1:i);
    rms_deslizante(i-ventana_muestras+1) = sqrt(mean(ventana_datos.^2));
end

t_rms = t(ventana_muestras:end);
fprintf('  RMS deslizante calculado: %d valores\n\n', length(rms_deslizante));

fprintf('========== ANÁLISIS DE RESULTADOS ==========\n\n');
limite_menos_10 = V_rms_nominal * 0.90;

umbral_deteccion = V_rms_nominal * 0.95;
idx_deteccion = find(rms_deslizante < umbral_deteccion, 1);
if ~isempty(idx_deteccion)
    t_deteccion = t_rms(idx_deteccion) * 1000;
    fprintf('1. DETECCIÓN DEL INICIO DEL HUECO:\n');
    fprintf('   El hueco se detecta en t = %.2f ms\n', t_deteccion);
    fprintf('   (Hueco real comienza en t = %.0f ms)\n', t_inicio_hueco*1000);
    fprintf('   Retardo de detección: %.2f ms\n\n', t_deteccion - t_inicio_hueco*1000);
end

[rms_minimo, idx_min] = min(rms_deslizante);
t_minimo = t_rms(idx_min) * 1000;
porcentaje_caida = ((V_rms_nominal - rms_minimo) / V_rms_nominal) * 100;

fprintf('2. VALOR RMS MÍNIMO:\n');
fprintf('   RMS mínimo alcanzado: %.2f V\n', rms_minimo);
fprintf('   Momento del mínimo: %.2f ms\n', t_minimo);
fprintf('   Caída respecto al nominal: %.2f V (%.1f%%)\n', V_rms_nominal - rms_minimo, porcentaje_caida);
fprintf('   RMS teórico esperado: %.2f V\n\n', V_rms_nominal * profundidad);

umbral_recuperacion = V_rms_nominal * 0.98;
idx_recuperacion = find(rms_deslizante(idx_min:end) > umbral_recuperacion, 1);
if ~isempty(idx_recuperacion)
    idx_recuperacion = idx_recuperacion + idx_min - 1;
    t_recuperacion = t_rms(idx_recuperacion) * 1000;
    tiempo_recuperacion = t_recuperacion - t_minimo;
    fprintf('3. TIEMPO DE RECUPERACIÓN:\n');
    fprintf('   La señal recupera el 98%% del nominal en t = %.2f ms\n', t_recuperacion);
    fprintf('   Tiempo de recuperación desde el mínimo: %.2f ms\n', tiempo_recuperacion);
    fprintf('   Tiempo total del evento: %.2f ms\n\n', t_recuperacion - t_deteccion);
end

idx_bajo_limite = rms_deslizante < limite_menos_10;
duracion_violacion = 0;
t_inicio_violacion = 0;
t_fin_violacion = 0;

if any(idx_bajo_limite)
    t_inicio_violacion = t_rms(find(idx_bajo_limite, 1)) * 1000;
    t_fin_violacion = t_rms(find(idx_bajo_limite, 1, 'last')) * 1000;
    duracion_violacion = t_fin_violacion - t_inicio_violacion;
    fprintf('4. CUMPLIMIENTO NORMATIVO (Límite -10%% = %.0f V):\n', limite_menos_10);
    fprintf('   ⚠ SÍ supera el límite del -10%%\n');
    fprintf('   Inicio de la violación: %.2f ms\n', t_inicio_violacion);
    fprintf('   Fin de la violación: %.2f ms\n', t_fin_violacion);
    fprintf('   Duración de la violación: %.2f ms\n', duracion_violacion);
    fprintf('   RMS mínimo vs límite: %.2f V < %.0f V\n\n', rms_minimo, limite_menos_10);
else
    fprintf('4. CUMPLIMIENTO NORMATIVO:\n');
    fprintf('   ✓ NO supera el límite del -10%%\n');
    fprintf('   RMS mínimo: %.2f V > Límite: %.0f V\n\n', rms_minimo, limite_menos_10);
end

fprintf('PASO 4: Generando visualizaciones...\n\n');

figure('Position', [100 50 1400 800]);

subplot(2,1,1);
plot(t*1000, v_hueco, 'b-', 'LineWidth', 1.5);
hold on;
zona_x = [t_inicio_hueco*1000, (t_inicio_hueco+t_duracion_hueco)*1000, (t_inicio_hueco+t_duracion_hueco)*1000, t_inicio_hueco*1000];
zona_y = [-400, -400, 400, 400];
fill(zona_x, zona_y, 'r', 'FaceAlpha', 0.1, 'EdgeColor', 'none');
plot([0 duracion*1000], [0 0], '--k', 'LineWidth', 0.5);
plot([0 duracion*1000], [V_pico V_pico], ':r', 'LineWidth', 1);
plot([0 duracion*1000], [-V_pico -V_pico], ':r', 'LineWidth', 1);
xlabel('Tiempo (ms)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Voltaje (V)', 'FontSize', 12, 'FontWeight', 'bold');
title('Señal Temporal con Hueco de Tensión', 'FontSize', 14, 'FontWeight', 'bold');
grid on;
grid minor;
legend('Señal con hueco', 'Zona del hueco', 'Location', 'best', 'FontSize', 10);
xlim([0 duracion*1000]);
ylim([-400 400]);
hold off;

subplot(2,1,2);
plot(t_rms*1000, rms_deslizante, 'b-', 'LineWidth', 2);
hold on;
plot([0 duracion*1000], [V_rms_nominal V_rms_nominal], '-g', 'LineWidth', 2);
plot([0 duracion*1000], [limite_menos_10 limite_menos_10], '--r', 'LineWidth', 2);
text(5, V_rms_nominal+5, 'Nominal (230 V)', 'FontSize', 10, 'Color', 'g', 'FontWeight', 'bold');
text(5, limite_menos_10-5, 'Límite -10% (207 V)', 'FontSize', 10, 'Color', 'r', 'FontWeight', 'bold');
plot(t_minimo, rms_minimo, 'ro', 'MarkerSize', 10, 'LineWidth', 2, 'MarkerFaceColor', 'r');
text(t_minimo + 5, rms_minimo - 10, sprintf('Mínimo: %.1f V\n(t=%.1f ms)', rms_minimo, t_minimo), 'FontSize', 10, 'BackgroundColor', 'white', 'EdgeColor', 'black');
if any(idx_bajo_limite)
    zona_viol_x = [t_inicio_violacion, t_fin_violacion, t_fin_violacion, t_inicio_violacion];
    zona_viol_y = [150, 150, 250, 250];
    fill(zona_viol_x, zona_viol_y, 'r', 'FaceAlpha', 0.15, 'EdgeColor', 'none');
end
xlabel('Tiempo (ms)', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Valor RMS (V)', 'FontSize', 12, 'FontWeight', 'bold');
title(sprintf('Valor RMS Deslizante (Ventana: %d ms = 1 ciclo)', ventana_ms), 'FontSize', 14, 'FontWeight', 'bold');
grid on;
grid minor;
xlim([0 duracion*1000]);
ylim([150 250]);
info_text = sprintf('PARAMETROS DEL HUECO:\n  Inicio: %.0f ms\n  Duracion: %.0f ms\n  Profundidad: %.0f%%\n  RMS minimo: %.1f V\n  Caida: %.1f%%\n  Violacion -10%%: %.1f ms', t_inicio_hueco*1000, t_duracion_hueco*1000, (1-profundidad)*100, rms_minimo, porcentaje_caida, duracion_violacion);
annotation('textbox', [0.72, 0.15, 0.25, 0.18], 'String', info_text, 'FontSize', 9, 'BackgroundColor', 'white', 'EdgeColor', 'black', 'FontName', 'Courier New', 'FitBoxToText', 'on');
hold off;

fprintf('========== ANÁLISIS COMPLETADO ==========\n');
fprintf('Gráficas generadas exitosamente.\n');

%% ========== ACTIVIDAD GUIADA 3.4: COMPARAR DIFERENTES CARGAS ==========
clear; close all; clc;
fprintf('\n========== ACTIVIDAD GUIADA 3.4: COMPARAR DIFERENTES CARGAS ==========\n');

% Parámetros generales
fs = 2000;             % Frecuencia de muestreo (Hz)
f0 = 50;               % Frecuencia fundamental (Hz)
duracion = 1;          % Duración total (s)
t = 0:1/fs:duracion-1/fs;
Vpico = 325;           % Amplitud pico (V)

% ==========================================================
% 1. Generación de señales para tres tipos de carga
% ==========================================================

% Carga 1: Lineal (solo fundamental)
v1 = Vpico * sin(2*pi*f0*t);

% Carga 2: Distorsión moderada (3er y 5to armónico)
v2 = Vpico*sin(2*pi*f0*t) + ...
     0.10*Vpico*sin(2*pi*3*f0*t) + ...
     0.05*Vpico*sin(2*pi*5*f0*t);

% Carga 3: Altamente distorsionada (3er, 5to y 7mo)
v3 = Vpico*sin(2*pi*f0*t) + ...
     0.25*Vpico*sin(2*pi*3*f0*t) + ...
     0.15*Vpico*sin(2*pi*5*f0*t) + ...
     0.10*Vpico*sin(2*pi*7*f0*t);

% ==========================================================
% 2. Cálculo del espectro y THD
% ==========================================================

N = length(t);
f = (0:N/2-1)*(fs/N);  % Vector de frecuencias (positivas)

% Función anónima para obtener magnitud espectral
calcMag = @(v) abs(fft(v)/N)*2;

% Magnitudes
V1 = calcMag(v1);
V2 = calcMag(v2);
V3 = calcMag(v3);

% Armónicos (fundamental hasta 10º)
harmonics = 1:10;
freq_h = harmonics * f0;

% Función para extraer magnitudes de armónicos
getHarmonics = @(V) arrayfun(@(fh) ...
    V(find(abs(f - fh) == min(abs(f - fh)), 1)), freq_h);

mag1 = getHarmonics(V1);
mag2 = getHarmonics(V2);
mag3 = getHarmonics(V3);

% Cálculo del THD
THD = @(mags) 100*sqrt(sum(mags(2:end).^2))/mags(1);

THD1 = THD(mag1);
THD2 = THD(mag2);
THD3 = THD(mag3);

% ==========================================================
% 3. Resultados y tabla comparativa
% ==========================================================

fprintf('Carga Lineal (solo fundamental): THD = %.2f %%\n', THD1);
fprintf('Carga Moderadamente Distorsionada: THD = %.2f %%\n', THD2);
fprintf('Carga Altamente Distorsionada: THD = %.2f %%\n', THD3);

T = table(["Lineal"; "Moderada"; "Alta"], [THD1; THD2; THD3], ...
    'VariableNames', {'Tipo_Carga', 'THD_porcentaje'});

disp(' ');
disp('Tabla comparativa de THD:');
disp(T);

% ==========================================================
% 4. Visualización de los espectros
% ==========================================================

figure('Position', [100 100 1000 700]);

subplot(3,1,1);
stem(freq_h, mag1(1:10), 'b', 'LineWidth', 1.5);
title(sprintf('Carga Lineal - THD = %.2f %%', THD1), 'FontWeight','bold');
xlabel('Frecuencia (Hz)');
ylabel('Magnitud (V)');
grid on; xlim([0 600]);

subplot(3,1,2);
stem(freq_h, mag2(1:10), 'm', 'LineWidth', 1.5);
title(sprintf('Carga Moderada - THD = %.2f %%', THD2), 'FontWeight','bold');
xlabel('Frecuencia (Hz)');
ylabel('Magnitud (V)');
grid on; xlim([0 600]);

subplot(3,1,3);
stem(freq_h, mag3(1:10), 'r', 'LineWidth', 1.5);
title(sprintf('Carga Alta - THD = %.2f %%', THD3), 'FontWeight','bold');
xlabel('Frecuencia (Hz)');
ylabel('Magnitud (V)');
grid on; xlim([0 600]);

sgtitle('Actividad Guiada 3.4: Comparación de Espectros Armónicos', 'FontWeight','bold');

% ==========================================================
% 5. Análisis final
% ==========================================================
fprintf('\nAnálisis:\n');
fprintf('• La carga lineal tiene una señal puramente sinusoidal (THD ≈ 0%%).\n');
fprintf('• La carga moderadamente distorsionada tiene THD ≈ %.1f%% (menor que el 8%% normativo: %s).\n', ...
        THD2, ternary(THD2<8,'CUMPLE','NO CUMPLE'));
fprintf('• La carga altamente distorsionada tiene THD ≈ %.1f%% (mayor que el 8%% normativo: NO CUMPLE).\n\n', THD3);

% Función auxiliar tipo operador ternario
function out = ternary(cond, valTrue, valFalse)
    if cond
        out = valTrue;
    else
        out = valFalse;
    end
end
