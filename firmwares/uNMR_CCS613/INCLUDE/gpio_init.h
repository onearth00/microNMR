/*
 * setup.h
 *
 *  Created on: Jul 28, 2016
 *      Author: mccowan1
 */
//###########################################################################
// Revision History:
//
//
//
//
//
//###########################################################################

#ifndef INCLUDE_GPIO_INIT_H_
#define INCLUDE_GPIO_INIT_H_


#include "typeDefs.h"

void setup_gpio(void);
void spi_init(void);
void configure_SPI(Uint16 POL, Uint16 PHA, Uint16 BITS, Uint16 nFIFO, Uint16 ClkSpeedDiv);



void InitEPwm2();
void setup_McbspbSpi();
void led_blink_40(void);
void led_blink_42(void);
Uint16 spi_temp_board();

void magnet_temp_init();
void magnet_temp_write(Uint8 reg, Uint8 data);
Uint32 magnet_temp_read(Uint8 reg);
void magnet_temp_reset();
void magnet_temp_sync();
void magnet_temp_sdatac();
void magnet_temp_mosi(Uint8 nBytes, Uint8 *data);

//SPI DAC LTC2630, set the varicap bias
void spi_dac(Uint16 a);
void spi_dac_MCC(Uint16 a);



void PLL_init()	;
Uint32 PLL_freq_set(Uint32 inFreq);
Uint32 PLL_freq_set3(Uint32 inFreq);
Uint32 PLL_freq_set2(long Nint,long Nfrac) ;

#endif /* INCLUDE_GPIO_INIT_H_ */
