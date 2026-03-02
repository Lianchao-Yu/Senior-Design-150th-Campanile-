/*readme!
this code used for testing audio matrix playback for ARDUINO MRX 1010! If use Arduino R4, please change following configuration:
1. DAC->12bits
2. Don't use "delay" function! Timer or millis() will prevent program blocking
SampleRate=16k
DAC=10bits
*/

#include "chime_data.h"
uint16_t valume=0;
void setup() {
  analogWriteResolution(10); 
}
void loop(){
 playChime();

 //↓测试正弦波播放
// 让延时从 20us 变化到 200us，从而产生由高到低的变调效果
 /* for (int d = 20; d < 200; d++) {
    playOneCycle(d);
  }
  for (int d = 200; d > 20; d--) {
    playOneCycle(d);
  }
  */
 }

void playChime() {
  for (int i = 0; i < bell_sample_length; i++) {
    
    uint16_t val = pgm_read_word(&(bell_samples[i]));
    analogWrite(A0, val);

    // 16kHz delay=1/16000 = 62.5 ms
   delayMicroseconds(64);  //62
  }
}
// 辅助函数：播放一个完整的正弦波周期
void playOneCycle(int delayTime) {
  for (int i = 0; i < 360; i += 10) { // 
    float angle = i * (PI / 180.0);
    uint16_t val = (uint16_t)((sin(angle) + 1.0) * 511.5);
    analogWrite(A0, val);
    delayMicroseconds(delayTime); 
  }
}