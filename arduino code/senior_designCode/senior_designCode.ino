/*
  MKR1010 DAC 优化版音阶测试
  输出引脚: A0 (DAC0)
*/

#include <Arduino.h>

// 预计算一个周期的正弦波表 (256个点)，提高执行效率
uint16_t sineTable[256];

// C4 组音阶频率
float tones[] = {261.6, 293.7, 329.6, 349.2, 392.0, 440.0, 493.9};
int currentTone = 0;
unsigned long lastSwitch = 0;

void setup() {
  analogWriteResolution(10); // 10位 DAC (0-1023)
  
  // 初始化正弦波查找表
  for (int i = 0; i < 256; i++) {
    sineTable[i] = (uint16_t)(511 * sin(i * 2.0 * PI / 256.0) + 512);
  }
}

void loop() {
  // 每 500ms 换一个音符
  if (millis() - lastSwitch > 500) {
    currentTone = (currentTone + 1) % 7;
    lastSwitch = millis();
  }

  // 根据频率计算采样间隔 (微秒)
  // 周期 T = 1/f, 每个点间隔 = T / 256
  float targetFreq = tones[currentTone];
  uint32_t stepDelay = (uint32_t)(1000000.0 / (targetFreq * 256.0));

  // 播放一个周期的波形
  for (int i = 0; i < 256; i++) {
    analogWrite(A0, sineTable[i]);
    delayMicroseconds(stepDelay); 
  }
}