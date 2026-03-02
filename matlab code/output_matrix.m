% =========================================================================
% 生成 16kHz 10-bit 钟声并导出为 Arduino (SAMD21) 可用的 C++ 数组
% =========================================================================

fs = 16000;             
duration = 2.5;         
t = (0 : 1/fs : duration - 1/fs)'; 

% 剔除风噪后的 7 个核心频率与参数
freqs  = [308.17, 512.15, 662.66, 765.38, 1053.22, 1372.38, 1716.61];
alphas = [0.0601, 0.8750, 1.0223, 0.5526, 0.7362,  0.5875,  0.8673];
amps   = [1.00,   0.45,   0.50,   0.40,   0.35,    0.15,    0.20];

synth_audio = zeros(length(t), 1);

% 1. 加法合成
for i = 1:length(freqs)
    synth_audio = synth_audio + amps(i) * sin(2 * pi * freqs(i) * t) .* exp(-alphas(i) * t);
end

% 2. 10-bit 标准化与量化 (转换为 16-bit 容器内的 0-1023)
% 1.65V 直流偏置中心点变为 511.5
synth_audio = synth_audio / max(abs(synth_audio)); 
audio_10bit = round((synth_audio + 1) * 511.5);     

% 确保数据不越界
audio_10bit(audio_10bit > 1023) = 1023;
audio_10bit(audio_10bit < 0) = 0;

% 3. 导出为 C++ 头文件
filename = 'bell_audio_10bit.h';
fid = fopen(filename, 'w');

fprintf(fid, '// UNI Campanile Synthesized Bell (10-bit Hi-Fi)\n');
fprintf(fid, '// Sample Rate: %d Hz\n', fs);
fprintf(fid, '// Length: %d samples\n\n', length(audio_10bit));

fprintf(fid, 'const unsigned int bell_sample_rate = %d;\n', fs);
fprintf(fid, 'const unsigned int bell_sample_length = %d;\n', length(audio_10bit));
% 注意：这里改成了 uint16_t，以容纳大于 255 的数值
fprintf(fid, 'const uint16_t bell_samples[] = {\n');

% 每行打印 12 个十六进制数据点 (0x0000 到 0x03FF 之间)
for i = 1:length(audio_10bit)
    fprintf(fid, '0x%04X', audio_10bit(i)); 
    if i < length(audio_10bit)
        fprintf(fid, ', ');
    end
    if mod(i, 12) == 0
        fprintf(fid, '\n');
    end
end

fprintf(fid, '\n};\n');
fclose(fid);

fprintf('成功生成 %s！包含 %d 个 10-bit 数据点 (占用约 %d KB Flash)。\n', ...
    filename, length(audio_10bit), round(length(audio_10bit)*2/1024));