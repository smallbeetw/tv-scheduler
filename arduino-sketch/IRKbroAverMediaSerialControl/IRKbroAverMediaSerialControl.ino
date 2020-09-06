/*
 * Sketch of sync recorder between AverMedia with Tivo
 *
 * Copyright (C) 2020 Smallbee.TW <smallbee.tw@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, see <http://www.gnu.org/licenses/>.
 */
#include <avr/pgmspace.h>
#include <IRremote.h>

#define KBRO 123

static unsigned int kbro_one[71] PROGMEM = {232, 888, 232, 2244, 220, 756, 228, 2788, 232, 1292, 224, 1300, 224, 1432, 232, 1836, 224, 14268, 228, 888, 284, 2596, 224, 756, 228, 748, 232, 748, 224, 888, 232, 748, 224, 752, 232, 15412, 228, 888, 232, 2244, 224, 752, 232, 2788, 232, 1288, 228, 1296, 228, 1428, 232, 1836, 224, 14268, 232, 884, 220, 1572, 228, 1840, 228, 752, 220, 756, 228, 884, 224, 756, 228, 748, 232};    //KBRO_ONE
static unsigned int kbro_two[71] PROGMEM = {232, 888, 232, 2240, 228, 752, 228, 2788, 224, 1300, 228, 1292, 232, 1428, 224, 1840, 232, 14264, 224, 892, 224, 2520, 232, 748, 224, 752, 232, 748, 224, 1024, 228, 752, 220, 756, 228, 15452, 224, 892, 228, 2248, 228, 748, 228, 2792, 228, 1292, 224, 1300, 224, 1432, 232, 1836, 224, 14268, 232, 884, 224, 1436, 224, 1840, 232, 744, 228, 752, 228, 1020, 224, 756, 228, 748, 224};
static unsigned int kbro_three[71] PROGMEM = {232, 888, 232, 2240, 224, 756, 228, 2788, 232, 1292, 224, 1296, 232, 1428, 224, 1844, 224, 14268, 232, 884, 224, 2384, 232, 748, 224, 752, 228, 752, 304, 1080, 228, 752, 232, 744, 228, 15444, 224, 896, 224, 2248, 232, 748, 224, 2792, 228, 1296, 232, 1288, 224, 1436, 228, 1836, 224, 14272, 228, 884, 224, 1300, 224, 1840, 232, 748, 224, 752, 232, 1156, 224, 752, 312, 664, 224};
static unsigned int kbro_four[71] PROGMEM = {224, 896, 224, 2248, 228, 752, 316, 2700, 224, 1300, 228, 1292, 224, 1436, 228, 1840, 228, 14264, 308, 808, 228, 2244, 224, 756, 228, 748, 232, 744, 228, 1296, 232, 748, 224, 752, 316, 15356, 228, 888, 232, 2244, 224, 752, 312, 2708, 232, 1288, 228, 1296, 228, 1432, 224, 1840, 228, 14268, 232, 880, 228, 1160, 228, 1836, 224, 752, 316, 664, 308, 1212, 232, 748, 224, 752, 228};
static unsigned int kbro_five[71] PROGMEM = {224, 896, 220, 2252, 228, 752, 228, 2788, 224, 1300, 228, 1292, 224, 1436, 224, 1840, 232, 14264, 224, 892, 228, 2108, 224, 752, 232, 748, 224, 752, 312, 1348, 232, 748, 308, 668, 316, 15360, 228, 892, 228, 2244, 232, 748, 224, 2792, 228, 1296, 232, 1292, 224, 1432, 232, 1836, 224, 14268, 228, 888, 224, 1024, 228, 1840, 232, 744, 228, 752, 232, 1424, 224, 756, 228, 748, 224};
static unsigned int kbro_six[71] PROGMEM = {224, 892, 224, 2252, 228, 748, 232, 2788, 224, 1296, 232, 1292, 224, 1432, 228, 1840, 232, 14260, 228, 888, 232, 1972, 224, 752, 232, 748, 224, 752, 228, 1568, 220, 756, 228, 752, 220, 15420, 232, 888, 232, 2240, 228, 752, 228, 2788, 224, 1300, 228, 1292, 232, 1428, 224, 1840, 232, 14264, 224, 888, 232, 884, 224, 1844, 228, 748, 232, 744, 228, 1568, 232, 748, 224, 752, 232};  //KBRO_SIX, limit
static unsigned int kbro_seven[71] PROGMEM = {224, 892, 224, 2252, 228, 748, 224, 2796, 224, 1296, 232, 1292, 228, 1428, 228, 1840, 232, 14264, 224, 888, 232, 1836, 224, 752, 312, 668, 304, 672, 312, 1616, 236, 744, 312, 664, 316, 15344, 224, 892, 224, 2252, 228, 748, 236, 2784, 224, 1296, 232, 1292, 224, 1432, 228, 1840, 220, 14272, 232, 884, 232, 748, 224, 1840, 232, 748, 224, 752, 312, 1616, 224, 756, 228, 752, 220};
static unsigned int kbro_eight[71] PROGMEM = {232, 884, 224, 2252, 228, 752, 228, 2788, 224, 1296, 232, 1292, 224, 1432, 228, 1840, 232, 14264, 224, 888, 232, 1700, 224, 752, 228, 752, 304, 672, 312, 1756, 228, 748, 228, 752, 228, 15428, 224, 896, 220, 2252, 228, 752, 228, 2788, 224, 1300, 228, 1292, 224, 1436, 224, 1840, 232, 14264, 224, 888, 232, 2788, 232, 1832, 228, 752, 232, 744, 228, 1840, 228, 748, 308, 620, 344};
static unsigned int kbro_nine[71] PROGMEM = {232, 888, 232, 2240, 224, 756, 228, 2788, 224, 1300, 224, 1296, 232, 1428, 224, 1840, 228, 14268, 224, 888, 228, 1568, 232, 744, 312, 668, 312, 664, 312, 1892, 228, 748, 224, 756, 312, 15384, 232, 888, 228, 2248, 220, 756, 228, 2788, 232, 1292, 224, 1300, 228, 1428, 224, 1844, 224, 14268, 232, 884, 224, 2660, 228, 1836, 232, 744, 228, 752, 316, 1884, 228, 752, 228, 748, 224};
static unsigned int kbro_zero[71] PROGMEM = {224, 896, 224, 2248, 228, 752, 232, 2784, 228, 1296, 228, 1292, 224, 1436, 228, 1836, 232, 14264, 224, 892, 228, 2788, 236, 744, 228, 748, 232, 748, 224, 752, 232, 748, 224, 752, 232, 15424, 232, 888, 224, 2252, 224, 752, 232, 2784, 228, 1296, 228, 1292, 232, 1428, 224, 1840, 232, 14264, 224, 892, 228, 1700, 224, 1844, 224, 752, 316, 664, 224, 752, 232, 744, 228, 752, 228};    //KBRO_ZERO
static unsigned int kbro_back[71] PROGMEM = {232, 888, 224, 2248, 224, 780, 200, 2792, 232, 1292, 232, 1288, 232, 1428, 232, 1832, 232, 14264, 228, 888, 224, 1568, 228, 776, 204, 776, 204, 1020, 228, 1700, 232, 772, 196, 780, 200, 15520, 228, 892, 224, 2252, 228, 748, 224, 2796, 228, 1292, 228, 1292, 232, 1428, 228, 1840, 224, 14268, 224, 892, 224, 2656, 232, 1836, 228, 748, 232, 1020, 220, 1708, 232, 744, 224, 780, 200};  //KBRO_BACK
static unsigned int ram_buf[71];

struct ir_entry {
  char input_byte;
  long decode_type;
  long ir_code;
  unsigned int *raw_code;
  unsigned int delay_ms;
};

static struct ir_entry ir_map[] = {
  {'0', KBRO, -1, kbro_zero, 200},
  {'1', KBRO, -1, kbro_one, 200},
  {'2', KBRO, -1, kbro_two, 200},
  {'3', KBRO, -1, kbro_three, 200},
  {'4', KBRO, -1, kbro_four, 200},
  {'5', KBRO, -1, kbro_five, 200},
  {'6', KBRO, -1, kbro_six, 200},
  {'7', KBRO, -1, kbro_seven, 200},
  {'8', KBRO, -1, kbro_eight, 200},
  {'9', KBRO, -1, kbro_nine, 200},
  {'b', KBRO, -1, kbro_back, 200},
  {'R', NEC, 0xBFC0C03F, 0, 200},  // Record 
  {'E', NEC, 0xBFC0B04F, 0, 200},  // ESC
  {'S', NEC, 0xBFC050AF, 0, 200},  // Stop
  {'-', -1, -1, 0, 0},            // MAP_END
};

const int led_pin=13;
IRsend irsend;
char input_byte;

void setup() {
  pinMode(led_pin, OUTPUT);
  Serial.begin(115200);
}

void loop() { 
  while (Serial.available()) {
    int i=0;
    input_byte = Serial.read();
    while (ir_map[i].input_byte != '-') {
      if (input_byte == ir_map[i].input_byte) {
        digitalWrite(led_pin, HIGH);
       // Serial.println("HIGH");
        if (ir_map[i].decode_type == NEC) {
          irsend.sendNEC(ir_map[i].ir_code, 32);
          delay(ir_map[i].delay_ms);
        }
        if (ir_map[i].decode_type == KBRO) {
          memcpy_P (ram_buf, ir_map[i].raw_code, 71);
          irsend.sendRaw(ram_buf, 71, 38);
          delay(ir_map[i].delay_ms);
        }
     //   Serial.println("LOW");
        digitalWrite(led_pin, LOW);
        break;
      }
      i++;
    }
    // Serial.println("break out");
  }
}
