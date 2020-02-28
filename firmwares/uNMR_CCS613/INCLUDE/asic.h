/*
 * asic.h
 *
 *  Created on: Jul 29, 2016
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

#ifndef INCLUDE_ASIC_H_
#define INCLUDE_ASIC_H_

#include "typeDefs.h"


#ifndef INCLUDE_NMR_PLSQ_H_
	#include "nmr_plsq.h"
#endif


//void ASIC_mosi(Uint16 msb, Uint16 lsb);						// Test funtion only
void ASIC_mosi_download(PlsSeq* plsq);						// downloads pulse sequence
void InitAsicGainCtrl (void);								// sets asic gain, default 9
void AsicGainCtrl (int gain);								// sets asic gain, default 9
void StartNMRASIC_SEQ(void);								// starts asic sequence sent
void StopNMRASIC_SEQ(void);									// stops asic sequence sent

// read the status of the SW_ACQ pin of ASIC
// High when the pulse sequence output data
// GPIO24 is defined as an input in gpio_init.c
// YS Jan 2017
Uint16 mReadNMR_ACQ(void);

// use this to speed up
#define mReadNMR_ACQ_ (GpioDataRegs.GPCDAT.bit.GPIO70 == 1)



Uint32 SPIRead32bitWordFromADC();
Uint32 SPIRead32bitWordFromADCFast();

Uint16 trigger_ADC_sample();




#endif /* INCLUDE_ASIC_H_ */
