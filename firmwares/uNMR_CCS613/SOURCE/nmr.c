/*
 * nmr.c
 *
 *  Created on: Aug 1, 2016
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

#include "nmr.h"
#include "nmr_plsq.h"
#include "asic.h"
#include "typeDefs.h"
#include "DSP28x_Project.h"											// Device Headerfile and Examples Include File

//int a;

void ResetNMR( void )												// default config of NMR ASIC
{

EALLOW;
// configure I/O

// ASIC pin25. Goes Hi enabling invoking ASIC sequence (default Lo)
	GpioCtrlRegs.GPCPUD.bit.GPIO65 		= 1;						// 1 = disable pull-up  for GPIO65 uC_EN_ASIC_3V3
	GpioCtrlRegs.GPCMUX1.bit.GPIO65 	= 0;   						// 1 = Configure GPIO65 for GPIO use
	GpioCtrlRegs.GPCDIR.bit.GPIO65 		= 1;						// 1 = enables output   for GPIO65 uC_EN_ASIC_3V3
	GpioDataRegs.GPCCLEAR.bit.GPIO65 	= 1;						// 1 = sets output Lo   for GPIO65 uC_EN_ASIC_3V3
	//GpioDataRegs.GPCSET.bit.GPIO65 		= 1;						// 1 = sets output Hi for GPIO65 uC_EN_ASIC_3V3

// ASIC pin24. Hi is enabled, goes Lo during RF pulse (default Lo)
	GpioCtrlRegs.GPBPUD.bit.GPIO61 		= 1;						// 1 = disable pull-up  for GPIO61 uC_EN_SNS_3V3
	GpioCtrlRegs.GPBMUX2.bit.GPIO61 	= 0;   						// 1 = Configure GPIO61 for GPIO use
	GpioCtrlRegs.GPBDIR.bit.GPIO61 		= 1;						// 1 = enables output   for GPIO61 uC_EN_SNS_3V3
	GpioDataRegs.GPBCLEAR.bit.GPIO61 	= 1;						// 1 = sets output Lo   for GPIO61 uC_EN_SNS_3V3
	//GpioDataRegs.GPCSET.bit.GPIO61 		= 1;						// 1 = sets output Hi for GPIO61 uC_EN_SNS_3V3

// Default gain is 9db
// ASIC pin12. Hi is enabled (default Lo)
	GpioCtrlRegs.GPCPUD.bit.GPIO64 		= 1;						// 1 = disable pull-up  for GPIO64 uC_VGA_GAIN3V3<0>
	GpioCtrlRegs.GPCMUX1.bit.GPIO64 	= 0;   						// 1 = Configure GPIO64 for GPIO use
	GpioCtrlRegs.GPCDIR.bit.GPIO64 		= 1;						// 1 = enables output   for GPIO64 uC_VGA_GAIN3V3<0>
	GpioDataRegs.GPCCLEAR.bit.GPIO64 	= 1;						// 1 = sets output Lo   for GPIO64 uC_VGA_GAIN3V3<0>
	GpioDataRegs.GPCSET.bit.GPIO64 		= 1;						// 1 = sets output Hi for GPIO64 uC_VGA_GAIN3V3<0>

// ASIC pin13. Hi is enabled (default Lo)
	GpioCtrlRegs.GPCPUD.bit.GPIO67 		= 1;						// 1 = disable pull-up  for GPIO67 uC_VGA_GAIN3V3<1>
	GpioCtrlRegs.GPCMUX1.bit.GPIO67 	= 0;   						// 1 = Configure GPIO67 for GPIO use
	GpioCtrlRegs.GPCDIR.bit.GPIO67 		= 1;						// 1 = enables output   for GPIO67 uC_VGA_GAIN3V3<1>
	GpioDataRegs.GPCCLEAR.bit.GPIO67 	= 1;						// 1 = sets output Lo   for GPIO67 uC_VGA_GAIN3V3<1>
	//GpioDataRegs.GPCSET.bit.GPIO67 		= 1;						// 1 = sets output Hi for GPIO67 uC_VGA_GAIN3V3<1>

// ASIC pin14. Hi is enabled (default Lo)
	GpioCtrlRegs.GPCPUD.bit.GPIO69 		= 1;						// 1 = disable pull-up  for GPIO69 uC_VGA_GAIN3V3<2>
	GpioCtrlRegs.GPCMUX1.bit.GPIO69 	= 0;   						// 1 = Configure GPIO69 for GPIO use
	GpioCtrlRegs.GPCDIR.bit.GPIO69 		= 1;						// 1 = enables output   for GPIO69 uC_VGA_GAIN3V3<2>
	GpioDataRegs.GPCCLEAR.bit.GPIO69 	= 1;						// 1 = sets output Lo   for GPIO69 uC_VGA_GAIN3V3<2>
	//GpioDataRegs.GPCSET.bit.GPIO69 		= 1;						// 1 = sets output Hi for GPIO69 uC_VGA_GAIN3V3<2>

// ASIC pin15. Hi is enabled (default Lo)
	GpioCtrlRegs.GPBPUD.bit.GPIO62 		= 1;						// 1 = disable pull-up  for GPIO62 uC_VGA_GAIN3V3<3>
	GpioCtrlRegs.GPBMUX2.bit.GPIO62 	= 0;   						// 1 = Configure GPIO62 for GPIO use
	GpioCtrlRegs.GPBDIR.bit.GPIO62 		= 1;						// 1 = enables output   for GPIO62 uC_VGA_GAIN3V3<3>
	GpioDataRegs.GPBCLEAR.bit.GPIO62 	= 1;						// 1 = sets output Lo   for GPIO62 uC_VGA_GAIN3V3<3>
	GpioDataRegs.GPBSET.bit.GPIO62 		= 1;						// 1 = sets output Hi for GPIO62 uC_VGA_GAIN3V3<3>

// U12 pin1. Hi enables Rx mode (default Lo)
	GpioCtrlRegs.GPCPUD.bit.GPIO68 		= 1;						// 1 = disable pull-up  for GPIO68 uC_EN_PIN_DRV_RX
	GpioCtrlRegs.GPCMUX1.bit.GPIO68 	= 0;   						// 1 = Configure GPIO68 for GPIO use
	GpioCtrlRegs.GPCDIR.bit.GPIO68 		= 1;						// 1 = enables output   for GPIO68 uC_EN_PIN_DRV_RX
	GpioDataRegs.GPCCLEAR.bit.GPIO68 	= 1;						// 1 = sets output Lo   for GPIO68 uC_EN_PIN_DRV_RX
	//GpioDataRegs.GPCSET.bit.GPIO68 		= 1;						// 1 = sets output Hi for GPIO68 uC_EN_PIN_DRV_RX

// U12 pin1. Hi enables Tx mode (default Lo)
	GpioCtrlRegs.GPBPUD.bit.GPIO60 		= 1;						// 1 = disable pull-up  for GPIO68 uC_EN_PIN_DRV_TX
	GpioCtrlRegs.GPBMUX2.bit.GPIO60 	= 0;   						// 1 = Configure GPIO60 for GPIO use
	GpioCtrlRegs.GPBDIR.bit.GPIO60 		= 1;						// 1 = enables output   for GPIO68 uC_EN_PIN_DRV_TX
	GpioDataRegs.GPBCLEAR.bit.GPIO60 	= 1;						// 1 = sets output Lo   for GPIO68 uC_EN_PIN_DRV_TX
	//GpioDataRegs.GPBSET.bit.GPIO60 		= 1;						// 1 = sets output Hi for GPIO68 uC_EN_PIN_DRV_TX

// ADC pin10. Hi is sample (default Lo)
	GpioCtrlRegs.GPAPUD.bit.GPIO0 		= 1;						// 1 = disable pull-up  for GPIO0 uC_CLK_ADC_3V3
	GpioCtrlRegs.GPAMUX1.bit.GPIO0 		= 0;   						// 1 = Configure GPIO0 for GPIO use
	GpioCtrlRegs.GPADIR.bit.GPIO0 		= 1;						// 1 = enables output   for GPIO0 uC_CLK_ADC_3V3
	GpioDataRegs.GPACLEAR.bit.GPIO0 	= 1;						// 1 = sets output Lo   for GPIO0 uC_CLK_ADC_3V3
	//GpioDataRegs.GPASET.bit.GPIO0 		= 1;						// 1 = sets output Hi for GPIO0 uC_CLK_ADC_3V3

// DAC 																// set up not yet implimented
// TEMP																// set up not yet implimented

EDIS;
}


void InitNMR( void )												// to convert for F28335
{

EALLOW;
// configure I/O

// ASIC pin25. Goes Hi enabling invoking ASIC sequence (default Lo)
	GpioCtrlRegs.GPCPUD.bit.GPIO65 		= 1;						// 1 = disable pull-up  for GPIO65 uC_EN_ASIC_3V3
	GpioCtrlRegs.GPCMUX1.bit.GPIO65 	= 0;   						// 1 = Configure GPIO65 for GPIO use
	GpioCtrlRegs.GPCDIR.bit.GPIO65 		= 1;						// 1 = enables output   for GPIO65 uC_EN_ASIC_3V3
	GpioDataRegs.GPCCLEAR.bit.GPIO65 	= 1;						// 1 = sets output Lo   for GPIO65 uC_EN_ASIC_3V3
	//GpioDataRegs.GPCSET.bit.GPIO65 		= 1;						// 1 = sets output Hi for GPIO65 uC_EN_ASIC_3V3

// ASIC pin24. Hi is enabled, goes Lo during RF pulse (default Lo)
	GpioCtrlRegs.GPBPUD.bit.GPIO61 		= 1;						// 1 = disable pull-up  for GPIO61 uC_EN_SNS_3V3
	GpioCtrlRegs.GPBMUX2.bit.GPIO61 	= 0;   						// 1 = Configure GPIO61 for GPIO use
	GpioCtrlRegs.GPBDIR.bit.GPIO61 		= 1;						// 1 = enables output   for GPIO61 uC_EN_SNS_3V3
	GpioDataRegs.GPBCLEAR.bit.GPIO61 	= 1;						// 1 = sets output Lo   for GPIO61 uC_EN_SNS_3V3
	//GpioDataRegs.GPCSET.bit.GPIO61 		= 1;						// 1 = sets output Hi for GPIO61 uC_EN_SNS_3V3

// Default gain is 9db
// ASIC pin12. Hi is enabled (default Lo)
	GpioCtrlRegs.GPCPUD.bit.GPIO64 		= 1;						// 1 = disable pull-up  for GPIO64 uC_VGA_GAIN3V3<0>
	GpioCtrlRegs.GPCMUX1.bit.GPIO64 	= 0;   						// 1 = Configure GPIO64 for GPIO use
	GpioCtrlRegs.GPCDIR.bit.GPIO64 		= 1;						// 1 = enables output   for GPIO64 uC_VGA_GAIN3V3<0>
	GpioDataRegs.GPCCLEAR.bit.GPIO64 	= 1;						// 1 = sets output Lo   for GPIO64 uC_VGA_GAIN3V3<0>
	GpioDataRegs.GPCSET.bit.GPIO64 		= 1;						// 1 = sets output Hi for GPIO64 uC_VGA_GAIN3V3<0>

// ASIC pin13. Hi is enabled (default Lo)
	GpioCtrlRegs.GPCPUD.bit.GPIO67 		= 1;						// 1 = disable pull-up  for GPIO67 uC_VGA_GAIN3V3<1>
	GpioCtrlRegs.GPCMUX1.bit.GPIO67 	= 0;   						// 1 = Configure GPIO67 for GPIO use
	GpioCtrlRegs.GPCDIR.bit.GPIO67 		= 1;						// 1 = enables output   for GPIO67 uC_VGA_GAIN3V3<1>
	GpioDataRegs.GPCCLEAR.bit.GPIO67 	= 1;						// 1 = sets output Lo   for GPIO67 uC_VGA_GAIN3V3<1>
	//GpioDataRegs.GPCSET.bit.GPIO67 		= 1;						// 1 = sets output Hi for GPIO67 uC_VGA_GAIN3V3<1>

// ASIC pin14. Hi is enabled (default Lo)
	GpioCtrlRegs.GPCPUD.bit.GPIO69 		= 1;						// 1 = disable pull-up  for GPIO69 uC_VGA_GAIN3V3<2>
	GpioCtrlRegs.GPCMUX1.bit.GPIO69 	= 0;   						// 1 = Configure GPIO69 for GPIO use
	GpioCtrlRegs.GPCDIR.bit.GPIO69 		= 1;						// 1 = enables output   for GPIO69 uC_VGA_GAIN3V3<2>
	GpioDataRegs.GPCCLEAR.bit.GPIO69 	= 1;						// 1 = sets output Lo   for GPIO69 uC_VGA_GAIN3V3<2>
	//GpioDataRegs.GPCSET.bit.GPIO69 		= 1;						// 1 = sets output Hi for GPIO69 uC_VGA_GAIN3V3<2>

// ASIC pin15. Hi is enabled (default Lo)
	GpioCtrlRegs.GPBPUD.bit.GPIO62 		= 1;						// 1 = disable pull-up  for GPIO62 uC_VGA_GAIN3V3<3>
	GpioCtrlRegs.GPBMUX2.bit.GPIO62 	= 0;   						// 1 = Configure GPIO62 for GPIO use
	GpioCtrlRegs.GPBDIR.bit.GPIO62 		= 1;						// 1 = enables output   for GPIO62 uC_VGA_GAIN3V3<3>
	GpioDataRegs.GPBCLEAR.bit.GPIO62 	= 1;						// 1 = sets output Lo   for GPIO62 uC_VGA_GAIN3V3<3>
	GpioDataRegs.GPBSET.bit.GPIO62 		= 1;						// 1 = sets output Hi for GPIO62 uC_VGA_GAIN3V3<3>

// U12 pin1. Hi enables Rx mode (default Lo)
	GpioCtrlRegs.GPCPUD.bit.GPIO68 		= 1;						// 1 = disable pull-up  for GPIO68 uC_EN_PIN_DRV_RX
	GpioCtrlRegs.GPCMUX1.bit.GPIO68 	= 0;   						// 1 = Configure GPIO68 for GPIO use
	GpioCtrlRegs.GPCDIR.bit.GPIO68 		= 1;						// 1 = enables output   for GPIO68 uC_EN_PIN_DRV_RX
	GpioDataRegs.GPCCLEAR.bit.GPIO68 	= 1;						// 1 = sets output Lo   for GPIO68 uC_EN_PIN_DRV_RX
	//GpioDataRegs.GPCSET.bit.GPIO68 		= 1;						// 1 = sets output Hi for GPIO68 uC_EN_PIN_DRV_RX

// U16 pin2. Hi enables Tx mode (default Lo)
	GpioCtrlRegs.GPBPUD.bit.GPIO60 		= 1;						// 1 = disable pull-up  for GPIO68 uC_EN_PIN_DRV_TX
	GpioCtrlRegs.GPBMUX2.bit.GPIO60 	= 0;   						// 1 = Configure GPIO60 for GPIO use
	GpioCtrlRegs.GPBDIR.bit.GPIO60 		= 1;						// 1 = enables output   for GPIO68 uC_EN_PIN_DRV_TX
	GpioDataRegs.GPBCLEAR.bit.GPIO60 	= 1;						// 1 = sets output Lo   for GPIO68 uC_EN_PIN_DRV_TX
	//GpioDataRegs.GPBSET.bit.GPIO60 		= 1;						// 1 = sets output Hi for GPIO68 uC_EN_PIN_DRV_TX

// ADC pin10. Hi is sample (default Lo)
	GpioCtrlRegs.GPAPUD.bit.GPIO0 		= 1;						// 1 = disable pull-up  for GPIO0 uC_CLK_ADC_3V3
	GpioCtrlRegs.GPAMUX1.bit.GPIO0 		= 0;   						// 1 = Configure GPIO0 for GPIO use
	GpioCtrlRegs.GPADIR.bit.GPIO0 		= 1;						// 1 = enables output   for GPIO0 uC_CLK_ADC_3V3
	GpioDataRegs.GPACLEAR.bit.GPIO0 	= 1;						// 1 = sets output Lo   for GPIO0 uC_CLK_ADC_3V3
	//GpioDataRegs.GPASET.bit.GPIO0 		= 1;						// 1 = sets output Hi for GPIO0 uC_CLK_ADC_3V3

// initialize I/O for ASIC
	GpioDataRegs.GPCCLEAR.bit.GPIO65 	= 1;						// 1 sets output Lo - uC_EN_ASIC_3V3
	GpioDataRegs.GPBCLEAR.bit.GPIO61 	= 1;						// 1 sets output Lo - uC_EN_SNS_3V3
	GpioDataRegs.GPCSET.bit.GPIO68 		= 1;						// 1 sets output Hi - uC_EN_PIN_DRV_RX
	GpioDataRegs.GPBSET.bit.GPIO60 		= 1;						// 1 sets output Hi - uC_EN_PIN_DRV_TX



// I think this pin is not being used by the current pcb.
// Instead, it is tied to the the SS2 pin.
	/*
	PORTClearBits(NMR_CLK_CONV_PORT, NMR_CLK_CONV_BIT);
	*/

	// MAy be a problem. YS jan 2017.
	//GpioDataRegs.GPASET.bit.GPIO0 		= 1;						// 1 sets output Hi for GPIO0 uC_CLK_ADC_3V3

// CS_NMR active high for 2013 chip
// CS_NMR active low, new NMR chip (made in 2014) Feb 2015.
// Thus when it's not downloading pulse sequence, keep it high.

	GpioDataRegs.GPCSET.bit.GPIO71 		= 1;   						// Configure GPIO71 for uC CS NMR SPI 3V3

// DAC 																// set up not yet implimented
// TEMP																// set up not yet implimented

EDIS;
}

void DlPlSeq(PlsSeq* plsq)											// downloads nmr sequence to asic
{

//Downloads the full nmr pulse sequence to the asic via 16-bit word
    ASIC_mosi_download(plsq);

}

/*
 * Set the uC_EN_PIN_DRV_RX and uC_EN_PIN_DRV_TX (GPIO68, 60) to low for
 * normal NMR mode. The duplexer will be controlled by ASIC EN_PA and acq flags.
 *
 * ASIC SNS low.
 *
 */
void EN_NMR_mode()
{
	GpioDataRegs.GPCSET.bit.GPIO68 		= 1;						// 1 = sets output Hi for GPIO68 uC_EN_PIN_DRV_RX
	GpioDataRegs.GPBSET.bit.GPIO60 		= 1;						// 1 = sets output Hi for GPIO68 uC_EN_PIN_DRV_TX

	GpioDataRegs.GPBCLEAR.bit.GPIO61 	= 1;						// 1 sets output Lo - uC_EN_SNS_3V3
}


/*
 * Set the uC_EN_PIN_DRV_RX and uC_EN_PIN_DRV_TX (GPIO68, 60) to high for
 * tuning mode. The duplexer will be controlled by ASIC EN_PA and acq flags.
 *
 * ASIC SNS high.
 *
 */
void EN_Tuning_mode()
{
	GpioDataRegs.GPCCLEAR.bit.GPIO68 		= 1;						// 1 = sets output Hi for GPIO68 uC_EN_PIN_DRV_RX
	GpioDataRegs.GPBCLEAR.bit.GPIO60 		= 1;						// 1 = sets output Hi for GPIO68 uC_EN_PIN_DRV_TX

	GpioDataRegs.GPBSET.bit.GPIO61 	= 1;						// 1 sets output Lo - uC_EN_SNS_3V3

}


