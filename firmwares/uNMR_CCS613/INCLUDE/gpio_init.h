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

//SPI DAC LTC2630, set the varicap bias
void spi_dac(Uint16 a)	;


void PLL_init()	;
Uint32 PLL_freq_set(Uint32 inFreq);

#endif /* INCLUDE_GPIO_INIT_H_ */
