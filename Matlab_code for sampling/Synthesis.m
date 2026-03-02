%read me: 该方案使用fft合成 再导出

% --- 1. 参数定义 ---
fs_target = 16000; % 适配你的 Arduino 项目采样率
duration = 3.0;    % 合成 3 秒钟声
t = 0:1/fs_target:duration;






% 
% % --- 2. 模拟 FFT 提取出的特征频率 (以 UNI 钟楼为例) ---
% % 假设这是你从 FFT 分析中提取的前 5 个最强谐波
% freqs = [440.0, 882.5, 1324.1, 1765.8, 2207.0]; 
% amps = [1.0, 0.6, 0.4, 0.2, 0.1]; 
% decays = [0.5, 1, 1.8, 2.5, 6]; % 高频谐波衰减通常更快
% --- 1. 频率设计：模拟大型铜钟的光谱 ---
% Hum (嗡鸣音): 基音的一半，提供浑厚感
% Prime (基音): 核心频率
% Tierce (小三度): 赋予钟声特有的色彩
% Quint (五度): 增加饱满度
% Nominal (高八度): 增加清脆度
% Superquint & Octave: 高频细节

freqs =  [220.0, 440.0, 523.2, 659.3, 880.0, 1320.0, 1760.0, 2640.0]; 
amps =   [3,   1.0,   0.7,   0.5,   0.4,   0.2,    0.15,   0.1]; % 加大低频权重
decays = [0.2,   0.6,   1.2,   1.5,   3,   6.0,    8.0,    8.0];  % 低频衰减极慢，高频极快

% --- 2. 引入“拍频” (Beating) 增加灵动感 ---
% 给核心频率增加微小的偏差（Detuning），模拟大钟物理结构的不对称
freqs = freqs .* [1.0, 1.001, 0.998, 1.002, 1.0, 1.0, 1.0, 1.0];

% --- 3. 混合叠加 ---
y_synth = zeros(size(t));
for i = 1:length(freqs)
    % 增加随机初相位，防止 t=0 时所有正弦波叠加导致削波
    phase = rand * 2 * pi; 
    y_synth = y_synth + amps(i) * exp(-decays(i) * t) .* sin(2 * pi * freqs(i) * t + phase);
end







% --- 3. 叠加合成逻辑 ---
y_synth = zeros(size(t));
for i = 1:length(freqs)
    y_synth = y_synth + amps(i) * exp(-decays(i) * t) .* sin(2 * pi * freqs(i) * t);
end

% --- 4. 模拟 10 位 DAC 量化 (针对 MKR 1010) ---
y_synth = y_synth / max(abs(y_synth)); % 归一化
y_dac = round((y_synth + 1) * 511.5);  % 映射到 0-1023 整数
y_sim = (double(y_dac) / 511.5) - 1;   % 还原为浮点数用于 MATLAB 播放

% --- 5. 播放对比 ---
fprintf('正在播放纯净合成音 (无底噪模式)...\n');
sound(y_sim, fs_target);

% --- 6. 可视化分析 ---
%figure('Name', 'UNI 钟声合成分析');
%subplot(2,1,1);
%plot(t, y_sim);
%title('合成钟声的时域波形 (包含指数衰减)');
%xlabel('时间 (s)'); ylabel('振幅');
% 
% subplot(2,1,2);
% spectrogram(y_sim, 256, [], [], fs_target, 'yaxis');
% title('合成钟声的语谱图 (可以看到清晰的谐波线条)');

% --- 导出为 Arduino 数组 ---
fileName = 'chime_data.h';
fid = fopen(fileName, 'w');

fprintf(fid, '// UNI Campanile Chime Data (10-bit PCM)\n');
fprintf(fid, '// Sample Rate: 16000 Hz\n\n');
fprintf(fid, '#include <avr/pgmspace.h>\n\n');

% 使用 const uint16_t 并加上 PROGMEM 关键字
fprintf(fid, 'const uint16_t chime_data[] PROGMEM = {\n    ');

for i = 1:length(y_dac)
    fprintf(fid, '%d', y_dac(i));
    
    % 每行打印 12 个数据，增加可读性
    if i < length(y_dac)
        fprintf(fid, ', ');
        if mod(i, 12) == 0
            fprintf(fid, '\n    ');
        end
    end
end

fprintf(fid, '\n};\n\n');
fprintf(fid, '#define CHIME_LEN %d\n', length(y_dac));
fclose(fid);

fprintf('导出完成！请将 %s 放入你的 Arduino 项目文件夹中。\n', fileName);
