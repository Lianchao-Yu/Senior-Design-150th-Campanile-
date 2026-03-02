% =========================================================================
% UNI Campanile 钟声参数化重构 (Additive Synthesis)
% 剔除 133.30 Hz 环境噪声频段
% =========================================================================

% 1. 基本设置
fs = 44100;             % 采样率 (44.1kHz 标准高保真)
duration = 8.0;         % 合成音频的总时长 (秒) - 低音 alpha 约 0.06，余韵很长
t = (0 : 1/fs : duration - 1/fs)'; % 时间向量

% 2. 输入提取的参数 (已剔除 133.30 Hz)
% 频率 (Hz)
freqs  = [308.17, 512.15, 662.66, 765.38, 1053.22, 1372.38, 1716.61];

% 对应的衰减因子 Alpha
alphas = [0.0601, 0.8750, 1.0223, 0.5526, 0.7362,  0.5875,  0.8673];

% 相对初始振幅 (Amplitude)
% 注：根据你上一张图的包络线峰值估算。308Hz 能量最高，高频能量依次递减。
% 你可以根据听感微调这里的数值，以改变钟声的“亮”或“暗”。
amps   = [1.00,   0.45,   0.50,   0.40,   0.35,    0.15,    0.20];

% 3. 初始化合成信号
synth_audio = zeros(length(t), 1);

% 4. 加法合成核心循环
fprintf('开始合成钟声...\n');
for i = 1:length(freqs)
    % 生成纯正弦波：sin(2*pi*f*t)
    oscillator = sin(2 * pi * freqs(i) * t);
    
    % 生成对应的指数衰减包络：e^(-alpha * t)
    envelope = exp(-alphas(i) * t);
    
    % 将振幅、振荡器和包络相乘，加入总信号
    component = amps(i) * oscillator .* envelope;
    synth_audio = synth_audio + component;
    
    fprintf('已叠加频率: %7.2f Hz | Alpha: %.4f | 权重: %.2f\n', freqs(i), alphas(i), amps(i));
end

% 5. 音频标准化 (Normalization)
% 防止由于叠加导致的振幅超载 (Clipping)
synth_audio = synth_audio / max(abs(synth_audio)) * 0.95; 

% 6. 播放重构的钟声
fprintf('\n合成完毕！正在播放...\n');
sound(synth_audio, fs);

% 8. 可视化合成结果
figure('Name', '钟声合成结果');
subplot(2,1,1);
plot(t, synth_audio, 'k');
title('合成钟声波形 (Time Domain)');
xlabel('Time (s)'); ylabel('Amplitude');
xlim([0 duration]);
grid on;

