%read me!这个方案采用录音-取样-压缩后导入arduino进行播放，在mrk1010上音质不及预期。使用R4再次尝试一次

%read the secquence of audio
[recording_point,fs]=audioread('sample.m4a');
recording_point=recording_point(:,1);  %extract the first channel
%recording_normalize=recording_point/max(abs(recording_point));

fs_arduino=16000; %setting arduino nano R4 sampleRate=16k
record_downSample=resample(recording_point,fs_arduino,fs); %reduce the sampleRate to 16K

%simulate 10bits DAC
% y_dac=round((record_downSample+1)*2047.5);   %quantized 16bits,for arduino R4
% y_play=(double(y_dac)/2047.5)-1;
%TEST for arduino MRK 1010
y_dacNormal=record_downSample/max(abs(record_downSample));
y_dac=round((y_dacNormal+1)*8);   %quantized 8bits, output for arduino mrx
y_play=(double(y_dac)/8)-1;  %play 8 bit audio in matlab


figure('Name','16Kbits');
%plot(0:length(y_play)-1,y_play);
sound(y_play,fs_arduino);

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



