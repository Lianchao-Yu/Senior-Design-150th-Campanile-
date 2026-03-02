%%%%%%% read the audio %%
[audio_sequence,sampleRate]=audioread('bell.m4a');
audio_sequence=audio_sequence(:,1); %get only one channel to analyze

%%%%%%%prepare for fft parameter %%%%%%%%%
L=length(audio_sequence);
N = 2^nextpow2(L);  %optimize the speed

%%%%%%%%%%%%%%%%%% fft %%%%%%%%%%%%%%%%
FFT_result=fft(audio_sequence,N);
Amp_doubleband=abs(FFT_result/L);
Amp_singleband=Amp_doubleband(1:N/2+1); %%GET THE HALF
Amp_singleband(2:end-1)=2*Amp_singleband(2:end-1);
frequency_x = (sampleRate * (0:(N/2)) / N)';

%%%%%%%%%%%%% visualization for fft%%%%%
%figure;
%plot(frequency_x,Amp_singleband,'LineWidth', 1.5);
%%%%%%%%%%%%%%%%%%%%% find the primary frequency  %%%%%%%%%%%%%%


%%%%%%%% damping factor calculation %%%%%%%

%%% extract main frequency
[peak,main_frequency]=findpeaks(Amp_singleband, frequency_x, ...
    "MinPeakHeight",max(Amp_singleband)*0.01, ...
    "MinPeakDistance",100, ...
    "NPeaks",8,"SortStr","descend");
for n=1:length(peak)
    fprintf('find the %d peak amplitude= %.4f,frequency=%.2f\n',n,peak(n),main_frequency(n));
end
plot(0:length(Amp_singleband)-1,Amp_singleband);

%%%%calculate alpha base on hlibert convert%%%
analytic_signal = hilbert(audio_sequence); %calculate the envelope
envelope = abs(analytic_signal);

envelope_smooth = smoothdata(envelope, 'gaussian', round(sampleRate/10));%filter
t=(0:L-1)'/sampleRate;

% select an effective area
start_idx = round(0.1 * sampleRate); % avoid first 0.1 second
end_idx = round(0.8 * L);            % ending at 80% of the signal
t_analyze=t(start_idx:end_idx);
env_fit = envelope_smooth(start_idx:end_idx); %catch the decay period
alpha_array = zeros(length(main_frequency), 1); %saving alpha value
% linear fitting%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure('Name', '各频率衰减拟合分析');

for k = 1:length(main_frequency)
    f_target = main_frequency(k);
    
    % 1. 设计带通滤波器范围 (提取目标频率上下 15 Hz 的能量)
    bw = 15; 
    freq_range = [f_target - bw, f_target + bw];
    
    % 边界保护：防止滤波器频率超出奈奎斯特频率或小于 0
    if freq_range(1) <= 0
        freq_range(1) = 1;
    end
    if freq_range(2) >= sampleRate/2
        freq_range(2) = sampleRate/2 - 1;
    end
    
    % 2. 核心步骤：对原始音频进行带通滤波，剥离出当前的单频信号
    filtered_audio = bandpass(audio_sequence, freq_range, sampleRate);
    
    % 3. 对剥离后的纯净单频信号做希尔伯特变换
    analytic_signal = hilbert(filtered_audio); 
    envelope = abs(analytic_signal);
    
    % 根据该频率的波长动态调整平滑窗口 (低频需要更大的平滑窗口)
    smooth_window = round(sampleRate / f_target * 5); 
    envelope_smooth = smoothdata(envelope, 'gaussian', smooth_window);
    
    % 4. 提取有效衰减区间进行拟合
    env_fit = envelope_smooth(start_idx:end_idx); 
    
    % 5. 线性拟合求 Alpha
    p = polyfit(t_analyze, log(env_fit + 1e-6), 1);
    alpha_array(k) = -p(1); 
    
    % 打印该频率的计算结果
    fprintf('频率 %d (%.2f Hz) 的衰减因子 alpha = %.4f\n', k, f_target, alpha_array(k));
    
    % 6. 可视化包络与拟合曲线，方便排错
    subplot(4, 2, k);
    plot(t_analyze, env_fit, 'b', 'LineWidth', 1); hold on;
    % 绘制拟合出的理想指数衰减曲线
    plot(t_analyze, exp(polyval(p, t_analyze)), 'r--', 'LineWidth', 1.5);
    title(sprintf('Freq: %.1f Hz | \\alpha: %.4f', f_target, alpha_array(k)));
    grid on;
end

% fprintf('检测到的衰减因子 alpha = %.4f\n', alpha);
% fprintf('信号减弱到一半所需时间 (Half-life) = %.4f s\n', log(2)/alpha);







