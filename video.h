#ifndef _VIDEO_H_
#define _VIDEO_H_

#include <stdbool.h>
#include <SDL.h>

bool video_init(uint8_t *chargen);
bool video_update(void);
void video_end(void);

uint8_t video_read(uint8_t reg);
void video_write(uint8_t reg, uint8_t value);

#endif
