
clear; clc; close all;

%% Parameters
fs = 5000;              % 取樣頻率 (Hz)
f = 100;                % 參考頻率 (Hz)
w = 2 * pi * f;         % 角頻率
noise_amp = 5.0;        % 雜訊強度
R = 2.5;                % 真實振幅
phi = pi / 4;           % 真實相位

% LPF 參數
fc = 10; 
[b, a] = butter(2, fc / (fs / 2)); 


T = 1 / f;
t_single = 0 : 1/fs : 10*T;

% S(t)
N_t = noise_amp * randn(size(t_single)); 
S_t = R * sin(w * t_single + phi) + N_t;

% Mixing
ref_x = sin(w * t_single);
ref_y = cos(w * t_single); % 即 sin(w*t + pi/2)
M_x = S_t .* ref_x;
M_y = S_t .* ref_y;

% LPF 濾波
X_t_filt = filtfilt(b, a, M_x);
Y_t_filt = filtfilt(b, a, M_y);

% 計算 Avg DC 值, R, phi
X_dc_final = 2 * mean(X_t_filt); 
Y_dc_final = 2 * mean(Y_t_filt);
R_exp_single = sqrt(X_dc_final^2 + Y_dc_final^2);
phi_exp_single = atan2(Y_dc_final, X_dc_final);

%% Plotting
figure('Name', '鎖相放大器', 'Position', [50, 100, 900, 700]);

% S(t)
subplot(3, 2, 1);
plot(t_single, S_t, 'Color', [0.7 0.7 0.7]); hold on;
plot(t_single, R * sin(w * t_single + phi), 'r', 'LineWidth', 1.5);
title('S(t) Input Signal'); xlabel('Time (s)'); ylabel('Amp');

% FFT (S(t))
subplot(3, 2, 2);
L = length(t_single);
f_axis = fs * (0 : floor(L/2)) / L;
fft_S = fft(S_t);
P1_S = abs(fft_S/L); P1_S = P1_S(1:floor(L/2)+1); P1_S(2:end-1) = 2*P1_S(2:end-1);
plot(f_axis, P1_S, 'c'); xlim([0 250]);
title('S(t) FFT'); xlabel('Freq (Hz)');

% Mixing
subplot(3, 2, 3);
plot(t_single, M_x, t_single, M_y);
title('Mixed Signals (M_x, M_y)'); legend('M_x','M_y');

% FFT (Mixing)
subplot(3, 2, 4);
fft_Mx = fft(M_x);
P1_Mx = abs(fft_Mx/L); P1_Mx = P1_Mx(1:floor(L/2)+1); P1_Mx(2:end-1) = 2*P1_Mx(2:end-1);
plot(f_axis, P1_Mx, 'b'); xlim([0 250]);
title('Mixed Signal FFT (Note 2f component)');

% LPF, Avg DC
subplot(3, 2, 5.5);
plot(t_single, X_t_filt, 'r', t_single, Y_t_filt, 'b'); hold on;
yline(X_dc_final/2, 'r--', 'X DC'); yline(Y_dc_final/2, 'b--', 'Y DC');
title('Filtered DC Components (X, Y)'); xlabel('Time (s)');

fprintf('==================================\n');
fprintf('真實振幅 R: %.4f \n', R);
fprintf('真實相位 phi: %.2f deg\n', phi * 180 / pi);
fprintf('實驗振幅 R: %.4f (誤差: %.2f%%)\n', R_exp_single, abs(R_exp_single-R)/R*100);
fprintf('實驗相位 phi: %.2f deg\n', phi_exp_single*180/pi);
fprintf('==================================\n');

%% R(t), phi(t)
dt = 0.1;          
total_time = 3.0;   
t_now = 0;
t_array = []; R_array = []; phi_array = [];

figure('Name', 'R(t) and phi(t)', 'Position', [1000, 150, 700, 500]);
ax1 = subplot(2, 1, 1); title('Real-time Amplitude R'); grid on; hold on;
yline(R, 'k--', 'LineWidth', 1.5); 

ax2 = subplot(2, 1, 2); title('Real-time Phase \phi'); grid on; hold on;
yline(phi * 180 / pi, 'k--', 'LineWidth', 1.5); 

while t_now < total_time
    t_win = t_now : 1/fs : (t_now + dt - 1/fs);
    
    S_win = R * sin(w * t_win + phi) + noise_amp * randn(size(t_win));
    
    Mx_win = S_win .* sin(w * t_win);
    My_win = S_win .* cos(w * t_win);
    Xt_win = filtfilt(b, a, Mx_win);
    Yt_win = filtfilt(b, a, My_win);
    
    X_dc_win = 2 * mean(Xt_win);
    Y_dc_win = 2 * mean(Yt_win);
    
    R_now = sqrt(X_dc_win^2 + Y_dc_win^2);
    phi_now = atan2(Y_dc_win, X_dc_win) * 180 / pi;
    
    t_array = [t_array, t_now];
    R_array = [R_array, R_now];
    phi_array = [phi_array, phi_now];
    
    plot(ax1, t_array, R_array, '-oc', 'MarkerFaceColor', 'c');
    plot(ax2, t_array, phi_array, '-or', 'MarkerFaceColor', 'r');
    drawnow;
    pause(0.05);
    
    t_now = t_now + dt;
end