/*
 * setup.c
 *
 *  Created on: Jul 28, 2016
 *      Author: mccowan1
 *
 * This file's primary function is to configure the gpio ports of F28335.
 *
 *
 */
//###########################################################################
// Revision History:
//
//
//
//
//
//###########################################################################

#include <gpio_init.h>
#include <math.h>
#include "typeDefs.h"														// Type definitions
#include "DSP28x_Project.h"													// Device Headerfile and Examples Include File
#include "RunNMR.h"


void InitEPwm2();															// Default configuration of asic CLK_CTRL @ 15MHz
void spi_init(void);														// Default configuration of SPI module
void gpio_init(void);														// Default configuration of F28335 gpio
void spi_dac(Uint16 a);														// Default configuration of LTC2630 SPI
Uint16 spi_temp_board();													// default configuration of SPI Temp LM95071
void led_blink_D40(void);													// Default call of test led D40
void led_blink_D42(void);													// Default call of test led D42
void PLL_write(Uint8 reg, Uint32 data);										// Single write to the PLL
void PLL_mosi(Uint16 msb, Uint16 lsb);										// mosi spi function config
Uint32 spi_PLL_read(Uint8 reg);                                                                                                         // read PLL registers

//#define EPWM1_TIMER_TBPRD  				1499  							// Period register, ADC, 1500 x 6.6667e-9 = period in seconds
//#define EPWM1_MIN_CMPA     				30 								// compare count
#define EPWM2_TIMER_TBPRD  				9  									// Period register, ASIC CLK, 10 x 6.6667e-9 = period in seconds
#define EPWM2_MIN_CMPA     				5  									// compare count

// Variables:
Uint32 t1, t2;																// Time variables
Uint16 sdata1 		= 0x001;    											// Sent Data
Uint16 sdata2 		= 0x002;    											// Sent Data
Uint16 rdata1 		= 0;   													// Received Data RXO_Q
Uint16 rdata2 		= 0;  													// Received Data RXO_I
Uint16 data1[3] 	= {0};													// Received Data RXO_Q
Uint16 data2[3] 	= {0}; 													// Received Data RXO_I

#define freqxtal 32000000;			// current crystal clock freq. YS

volatile Uint32 Timer_Count;												// Timer count variable

// Timer Operations:
#define StartCpuTimer0()   		CpuTimer0Regs.TCR.bit.TSS 	= 0				// Start Timer
#define StopCpuTimer0()   		CpuTimer0Regs.TCR.bit.TSS 	= 1				// Stop Timer
#define ReloadCpuTimer0() 		CpuTimer0Regs.TCR.bit.TRB 	= 1				// Reload Timer With period Value
#define ReadCpuTimer0Counter() 	CpuTimer0Regs.TIM.all						// Read 32-Bit Timer Value
#define ReadCpuTimer0Period() 	CpuTimer0Regs.PRD.all						// Read 32-Bit Period Value

void led_blink_D42(void)													// blink led D40/ D42 1 time
{
	StartCpuTimer0();														// start timer
	t1=CpuTimer0Regs.TIM.all;												// t1, 1st time stamp
	GpioDataRegs.GPASET.bit.GPIO31 			= 1;   							// Configure GPIO31 for LED D42
	DELAY_US(10000);														// 10ms delay
	GpioDataRegs.GPACLEAR.bit.GPIO31 		= 1;   							// Configure GPIO31 for LED D42
	t2=CpuTimer0Regs.TIM.all;												// t2, 2nd time stamp
	Timer_Count 							= t1-t2;						// Timer_Count x SYSCLKOUT = event time
	StopCpuTimer0();														// stop timer
}

void led_blink_D40(void)													// blink led D40/ D42 1 time
{
	StartCpuTimer0();														// start timer
	t1=CpuTimer0Regs.TIM.all;												// t1, 1st time stamp
	GpioDataRegs.GPCSET.bit.GPIO76 			= 1;   							// Configure GPIO31 for LED D42
	DELAY_US(10000);														// 10ms delay
	GpioDataRegs.GPCCLEAR.bit.GPIO76 		= 1;   							// Configure GPIO31 for LED D42
	t2=CpuTimer0Regs.TIM.all;												// t2, 2nd time stamp
	Timer_Count 							= t1-t2;						// Timer_Count x SYSCLKOUT = event time
	StopCpuTimer0();														// stop timer
}

void gpio_init(void)
{
	/* Enable internal pull-up for the selected pins */
	// Pull-ups can be enabled or disabled 0 = Enabled, 1 = disabled
	EALLOW;
	// F28335 int of serial comms ports
	GpioCtrlRegs.GPBQSEL1.bit.GPIO36 		= 3; 							// Asynch input GPIO36 SCIRXDA
	GpioCtrlRegs.GPBQSEL2.bit.GPIO54 		= 3; 							// Asynch input GPIO54 SPI_MOSIA
	GpioCtrlRegs.GPBQSEL2.bit.GPIO55 		= 3; 							// Asynch input GPIO55 SPI_MISOA
	GpioCtrlRegs.GPBQSEL2.bit.GPIO56 		= 3; 							// Asynch input GPIO56 SPI_CLKA
	//GpioCtrlRegs.GPBQSEL2.bit.GPIO57 = 3; 								// Asynch input GPIO57 SPI_CSDAC, only used if one SPI device

	// HMC832 Open Mode Comms. On start-up PLL CLK Hi Before CS
	GpioDataRegs.GPBCLEAR.bit.GPIO56		= 1;							// Configure GPIO57 for SPI CS DAC
	GpioCtrlRegs.GPBDIR.bit.GPIO56 			= 1;							// Configure GPIO57 for SPI CS DAC
	GpioDataRegs.GPCCLEAR.bit.GPIO72 		= 1;   							// Configure GPIO72 for uC CS PLL SPI 3V3
	GpioCtrlRegs.GPCDIR.bit.GPIO72			= 1;							// Configure output for uC CS PLL SPI 3V3
	DELAY_US(1000);															// 100ms delay
	GpioDataRegs.GPBSET.bit.GPIO56 			= 1;							// setting GPIO56 CLK SPI high
	DELAY_US(1000);															// 1ms delay
	GpioDataRegs.GPCSET.bit.GPIO72 			= 1;							// setting GPIO56 CLK SPI high
	DELAY_US(1000);															// 1ms delay

//  Configure GPIO pin functionality using GPIO regs

    GpioCtrlRegs.GPAPUD.bit.GPIO0 			= 1;	   						// Disable pull-up for GPIO0 uC CLK ADC 3V3
	GpioDataRegs.GPACLEAR.bit.GPIO0 		= 1;   							// Configure GPIO0 for cs clk_adc_3v3
	GpioCtrlRegs.GPAMUX1.bit.GPIO0 			= 1;   							// Configure GPIO0 for cs clk_adc_3v3
	GpioCtrlRegs.GPADIR.bit.GPIO0			= 0;							// Configure GPIO0 for cs clk_adc_3v3
	//GpioDataRegs.GPASET.bit.GPIO0 			= 1;   							// Configure GPIO0 for cs clk_adc_3v3
	GpioDataRegs.GPACLEAR.bit.GPIO0 			= 1;							// set to lo

    GpioCtrlRegs.GPAPUD.bit.GPIO2 			= 1;	   						// Disable pull-up for GPIO2 uC CLK CTRL

    GpioCtrlRegs.GPAPUD.bit.GPIO31 			= 1;	   						// Disable pull-up for GPIO31 LED D42 FLASH
	GpioDataRegs.GPACLEAR.bit.GPIO31 		= 1;   							// Configure GPIO31 for LED D42
	GpioCtrlRegs.GPADIR.bit.GPIO31			= 1;							// Configure GPIO31 for LED D42
	GpioCtrlRegs.GPAMUX2.bit.GPIO31 		= 0;   							// Configure GPIO31 for LED D42
	GpioDataRegs.GPASET.bit.GPIO31 			= 0;   							// Configure GPIO31 for LED D42

    GpioCtrlRegs.GPBPUD.bit.GPIO35 			= 0;    						// Enable  pull-up for GPIO35 SERIAL SCITXDA
	GpioCtrlRegs.GPBMUX1.bit.GPIO35 		= 1;   							// Configure GPIO35 for SCI TXDA
	GpioCtrlRegs.GPBPUD.bit.GPIO36 			= 0;	   						// Enable  pull-up for GPIO36 SERIAL SCIRXDA
	GpioCtrlRegs.GPBMUX1.bit.GPIO36 		= 1;   							// Configure GPIO36 for SCI RXDA
	GpioCtrlRegs.GPBDIR.bit.GPIO37 			= 1;							// Configure GPIO37 for SCI nRE

	GpioCtrlRegs.GPBPUD.bit.GPIO54 			= 1;	   						// Disable pull-up for GPIO54 SPI MOSIA
	GpioCtrlRegs.GPBMUX2.bit.GPIO54 		= 1;   							// Configure GPIO54 for SPI MOSIA
	GpioCtrlRegs.GPBPUD.bit.GPIO55 			= 1;	   						// Disable pull-up for GPIO55 SPI MISOA
	GpioCtrlRegs.GPBMUX2.bit.GPIO55 		= 1;   							// Configure GPIO55 for SPI MISOA

	GpioCtrlRegs.GPBPUD.bit.GPIO56 			= 1;	   						// Disable pull-up for GPIO56 SPI CLKA
	GpioDataRegs.GPBCLEAR.bit.GPIO56		= 1;							// Configure GPIO56 for SPI CLKA
	GpioCtrlRegs.GPBDIR.bit.GPIO56 			= 1;							// Configure GPIO56 for SPI CLKA
	GpioCtrlRegs.GPBMUX2.bit.GPIO56 		= 1;   							// Configure GPIO56 for SPI CLKA

	GpioCtrlRegs.GPBPUD.bit.GPIO57 			= 0;	   						// Enable  pull-up for GPIO57 SPI CSDAC
	GpioDataRegs.GPBCLEAR.bit.GPIO57 		= 0;   							// Configure GPIO57 for SPI CS DAC
	GpioCtrlRegs.GPBMUX2.bit.GPIO57 		= 0;   							// Configure GPIO57 for SPI CS DAC
	GpioCtrlRegs.GPBDIR.bit.GPIO57 			= 1;							// Configure GPIO57 for SPI CS DAC
	GpioDataRegs.GPBSET.bit.GPIO57 			= 1;							// Configure GPIO57 for SPI CS DAC

	GpioCtrlRegs.GPBPUD.bit.GPIO63 			= 0;	   						// Enable pull-up for GPIO63 EN_18V
	GpioDataRegs.GPBCLEAR.bit.GPIO63 		= 1;   							// Configure GPIO63 EN_18V
	GpioCtrlRegs.GPBMUX2.bit.GPIO63 		= 0;   							// Configure GPIO63 EN_18V
	GpioCtrlRegs.GPBDIR.bit.GPIO63			= 1;							// Configure GPIO63 EN_18V

	GpioCtrlRegs.GPCPUD.bit.GPIO71 			= 0;	   						// Enable  pull-up for GPIO75 uC CS NMR 3V3
	GpioDataRegs.GPCCLEAR.bit.GPIO71 		= 1;   							// Configure GPIO71 for uC CS NMR SPI 3V3
	GpioCtrlRegs.GPCMUX1.bit.GPIO71 		= 0;   							// Configure GPIO71 for uC CS NMR SPI 3V3
	GpioCtrlRegs.GPCDIR.bit.GPIO71			= 1;							// Configure GPIO71 for uC CS NMR SPI 3V3
	GpioDataRegs.GPCSET.bit.GPIO71 			= 1;   							// Configure GPIO71 for uC CS NMR SPI 3V3

	GpioCtrlRegs.GPCPUD.bit.GPIO72 			= 1;	   						// Disable pull-up for GPIO75 uC CS PLL 3V3
	GpioDataRegs.GPCCLEAR.bit.GPIO72 		= 1;   							// Configure GPIO72 for uC CS PLL SPI 3V3
	GpioCtrlRegs.GPCMUX1.bit.GPIO72 		= 0;   							// Configure GPIO72 for uC CS PLL SPI 3V3
	GpioCtrlRegs.GPCDIR.bit.GPIO72			= 1;							// Configure GPIO72 for uC CS PLL SPI 3V3
	GpioDataRegs.GPCSET.bit.GPIO72 			= 1;   							// Configure GPIO72 for uC CS PLL SPI 3V3

	GpioCtrlRegs.GPCPUD.bit.GPIO74 			= 0;	   						// Enable  pull-up for GPIO75 SPI CS TEMP2
	GpioDataRegs.GPCCLEAR.bit.GPIO74 		= 0;   							// Configure GPIO74 for SPI CS TEMP2
	GpioCtrlRegs.GPCMUX1.bit.GPIO74 		= 0;   							// Configure GPIO74 for SPI CS TEMP2
	GpioCtrlRegs.GPCDIR.bit.GPIO74			= 1;							// Configure GPIO74 for SPI CS TEMP2
	GpioDataRegs.GPCSET.bit.GPIO74 			= 1;   							// Configure GPIO74 for SPI CS TEMP2

	GpioCtrlRegs.GPCPUD.bit.GPIO75 			= 0;	   						// Enable  pull-up for GPIO75 SPI CS TEMP1
	GpioDataRegs.GPCCLEAR.bit.GPIO75 		= 0;   							// Configure GPIO75 for SPI CS TEMP1
	GpioCtrlRegs.GPCMUX1.bit.GPIO75 		= 0;   							// Configure GPIO75 for SPI CS TEMP1
	GpioCtrlRegs.GPCDIR.bit.GPIO75			= 1;							// Configure GPIO75 for SPI CS TEMP1
	GpioDataRegs.GPCSET.bit.GPIO75 			= 1;   							// Configure GPIO75 for SPI CS TEMP1

	GpioCtrlRegs.GPCPUD.bit.GPIO76 			= 1;	   						// Disable pull-up for GPIO76 LED D40 FLASH
	GpioDataRegs.GPCCLEAR.bit.GPIO76 		= 1;   							// Configure GPIO76 for LED D40
	GpioCtrlRegs.GPCMUX1.bit.GPIO76 		= 0;   							// Configure GPIO76 for LED D40
	GpioCtrlRegs.GPCDIR.bit.GPIO76			= 1;							// Configure GPIO76 for LED D40
	GpioDataRegs.GPCSET.bit.GPIO76 			= 0;   							// Configure GPIO76 for LED D40

	GpioCtrlRegs.GPCPUD.bit.GPIO64 			= 1;	   						// Disable pull-up for GPIO64
	GpioDataRegs.GPCCLEAR.bit.GPIO64 		= 1;   							// Configure GPIO64 for GAIN 0
	GpioCtrlRegs.GPCMUX1.bit.GPIO64 		= 0;   							// Configure GPIO64 for GAIN 0
	GpioCtrlRegs.GPCDIR.bit.GPIO64			= 1;							// Configure GPIO64 for GAIN 0
	GpioDataRegs.GPCSET.bit.GPIO64 			= 1;   							// Configure GPIO64 for GAIN 0

	GpioCtrlRegs.GPBPUD.bit.GPIO63 			= 0;	   						// Enable pull-up for EN_15V
	GpioDataRegs.GPBCLEAR.bit.GPIO63 		= 1;   							// Configure GPIO64 for  EN_15V
	GpioCtrlRegs.GPBMUX2.bit.GPIO63 		= 0;   							// Configure GPIO64 for  EN_15V
	GpioCtrlRegs.GPBDIR.bit.GPIO63			= 1;							// Configure GPIO64 for  EN_15V
	GpioDataRegs.GPBSET.bit.GPIO63 			= 1;   							// Configure GPIO64 for  EN_15V

	GpioCtrlRegs.GPCPUD.bit.GPIO67 			= 1;	   						// Disable pull-up for GPIO67
	GpioDataRegs.GPCCLEAR.bit.GPIO67 		= 1;   							// Configure GPIO67 for GAIN 1
	GpioCtrlRegs.GPCMUX1.bit.GPIO67 		= 0;   							// Configure GPIO67 for GAIN 1
	GpioCtrlRegs.GPCDIR.bit.GPIO67			= 1;							// Configure GPIO67 for GAIN 1
	GpioDataRegs.GPCSET.bit.GPIO67 			= 0;   							// Configure GPIO67 for GAIN 1

	GpioCtrlRegs.GPCPUD.bit.GPIO69 			= 1;	   						// Disable pull-up for GPIO69
	GpioDataRegs.GPCCLEAR.bit.GPIO69 		= 1;   							// Configure GPIO69 for GAIN 2
	GpioCtrlRegs.GPCMUX1.bit.GPIO69 		= 0;   							// Configure GPIO69 for GAIN 2
	GpioCtrlRegs.GPCDIR.bit.GPIO69			= 1;							// Configure GPIO69 for GAIN 2
	GpioDataRegs.GPCSET.bit.GPIO69 			= 0;   							// Configure GPIO69 for GAIN 2

	GpioCtrlRegs.GPBPUD.bit.GPIO62 			= 1;	   						// Disable pull-up for GPIO62
	GpioDataRegs.GPBCLEAR.bit.GPIO62 		= 1;   							// Configure GPIO62 for GAIN 3
	GpioCtrlRegs.GPBMUX2.bit.GPIO62 		= 0;   							// Configure GPIO62 for GAIN 3
	GpioCtrlRegs.GPBDIR.bit.GPIO62			= 1;							// Configure GPIO62 for GAIN 3
	GpioDataRegs.GPBSET.bit.GPIO62 			= 1;   							// Configure GPIO62 for GAIN 3

// configure GPIO24 for xint1
    GpioCtrlRegs.GPAPUD.bit.GPIO24 			= 0;	   						// GPIO24 XINT pull-up, 0 = enabled
	GpioCtrlRegs.GPAMUX2.bit.GPIO24 		= 0;         					// GPIO24 as ext interrupt, 0 = GPIO
	GpioCtrlRegs.GPADIR.bit.GPIO24 			= 0;          					// GPIO24 as ext interrupt, 0 = input
	GpioCtrlRegs.GPAQSEL2.bit.GPIO24 		= 3;        					// GPIO24 Synch to SYSCLKOUT, 0 = synched
	GpioIntRegs.GPIOXINT1SEL.bit.GPIOSEL 	= 0x18;   						// GPIO24 is Xint1
	XIntruptRegs.XINT1CR.bit.POLARITY 		= 0;      						// GPIO24 falling edge interrupt
	XIntruptRegs.XINT1CR.bit.ENABLE 		= 1;        					// GPIO24 Enable Xint1

// GPIO70 for ASIC output during ACQ, RLY_RX_DRV_BUF
    GpioCtrlRegs.GPCPUD.bit.GPIO70 			= 0;	   						// pull-up, 0 = enabled
	GpioCtrlRegs.GPCMUX1.bit.GPIO70 		= 0;         					// use as 0 = GPIO
	GpioCtrlRegs.GPCDIR.bit.GPIO70 			= 0;          					// 0 = input, 1=output
//	GpioCtrlRegs.GPAQSEL2.bit.GPIO24 		= 3;        					// GPIO24 Synch to SYSCLKOUT, 0 = synched

	EDIS;


}


// YS feb 2017. check for slower baud
void spi_init()																// Default configuration of SPI module
{
	EALLOW;
	// SPI TX
	SpiaRegs.SPICCR.all 					= 0x0000;						// Reset on, rising edge, 16-bit char bits
	SpiaRegs.SPICTL.all 					= 0x0000;   					// Enable master mode, normal phase, enable talk, and SPI int disabled

	//SpiaRegs.SPIBRR 						= 0x000A;						// Baud Rate Register, 75/(10+1) ~ 7.5 MHz
	SpiaRegs.SPIBRR 						= 0x0005;						// baud rate = 75Mhz/(spi spibrr + 1). YS feb 2017
																		// spibrr=5 => 12.5 MHz


	SpiaRegs.SPICCR.bit.CLKPOLARITY			= 0;							// 0 = Data is output on rising edge and input on falling edge
	SpiaRegs.SPICCR.bit.SPICHAR 			= 0x0007;						// Character length conrol bits

	SpiaRegs.SPICCR.bit.SPISWRESET 			= 1;							// 1 = SPI is ready to transmit or receive the next character

    SpiaRegs.SPICTL.bit.MASTER_SLAVE		= 1;							// 1 = SPI configured as a master
	SpiaRegs.SPICTL.bit.CLK_PHASE 			= 1;							// 1 = SPICLK signal delayed by one half-cycle;
	SpiaRegs.SPICTL.bit.TALK 				= 1;							// 1 = Enables transmission For the 4-pin option
	SpiaRegs.SPICTL.bit.SPIINTENA 			= 0;							// 0 = Disables interupt, 1 - enable
    SpiaRegs.SPIPRI.bit.FREE 				= 1;							// 1 = Free run, continue SPI operation regardless of suspend or when the suspend occurred
    SpiaRegs.SPIFFTX.bit.SPIFFENA 			= 1;							// 1 = SPI FIFO enhancements are enable
    SpiaRegs.SPIFFTX.bit.SPIRST 			= 1;							// 1 = SPI FIFO can resume transmit or receive. No effect to the SPI registers bits
    SpiaRegs.SPIFFTX.bit.TXFIFO 			= 1;							// 1 = Re-enable Transmit FIFO operation
    SpiaRegs.SPIFFRX.bit.RXFFIL				= 0;							// Receive FIFO interrupt level bits
	SpiaRegs.SPIFFRX.bit.RXFFOVF 			= 0;							// 0 = Write 0 does not affect RXFFOVF flag bit, Bit reads back a zer
	//SpiaRegs.SPIFFRX.bit.RXFFST			= 0;							// RX FIFO register
	SpiaRegs.SPIFFRX.bit.RXFFINT 			= 1;							// 1 = RXFIFO interrupt has occurred. This is a read-only bit
	SpiaRegs.SPIFFRX.bit.RXFFIENA			= 0;							// 0 = RXFIFO interrupt based on RXFFIL match (greater than or equal to) will be disabled.
	SpiaRegs.SPIFFRX.bit.RXFFOVFCLR			= 1;							// 1 = Write 1 to clear RXFFOVF flag in bit 15
	SpiaRegs.SPIFFRX.bit.RXFFOVF			= 1;							// 1 = More than 16 words have been received in to the FIFO, and the first received word is lost.
    EDIS;
}


/*
 *  Configure SPI and reset
* POL, PHA : polarity and clk_phase
* BITS, nFIFO : number of bits per word, number of words in the FIFO (1-4)
* ClkSpeedDiv : divider for baud rate control, 0-127. Fastest 75/4, others=75/(Div+1)
*
* Use this after running spi_init() in gpio_init.c
*
*/
void configure_SPI(Uint16 POL, Uint16 PHA, Uint16 BITS, Uint16 nFIFO, Uint16 ClkSpeedDiv)
{
	int i;
	// init spi
    SpiaRegs.SPICCR.bit.SPISWRESET 			= 0;							// 1 = SPI is ready to transmit or receive the next character

	SpiaRegs.SPICCR.bit.CLKPOLARITY			= POL;							// 0, 1 all transmit's on rising edge delayed by 1/2 clk. Inactive lo   0 1
	SpiaRegs.SPICTL.bit.CLK_PHASE 			= PHA;							// 1, 0 all transmit's on falling edge. Inactive Hi 1 0
																			// 1, 1 all transmit's on falling edge delayed by 1/2 clk. Inactive Hi
	for (i=0;i<20;i++){asm(" NOP");}										// NOP gives setup time to CLKPOLARITY and PHASE

	GpioCtrlRegs.GPBPUD.bit.GPIO55 			= 1;	   						// disable pull-up for GPIO55 SPI_MISOA
	SpiaRegs.SPICCR.bit.SPICHAR 			=  BITS;							// 8 bit word length
	SpiaRegs.SPIFFRX.bit.RXFFIL				= nFIFO;							// number states how many words fill FIFO,
																		// some commands are 1-2 byte, data is 3 bytes
	SpiaRegs.SPIFFRX.bit.RXFIFORESET 		= 0;							// 0 to reset the FIFO and hold in reset
	SpiaRegs.SPIFFRX.bit.RXFIFORESET 		= 1;							// 1 to Re-enable FIFO
	SpiaRegs.SPIFFRX.bit.RXFFINTCLR 		= 1;							// 1 to clear fag of RXFIFORESET

	// how to set the spi clock spped
	SpiaRegs.SPIBRR 						= (Uint16) (ClkSpeedDiv & 0x7F);		// 0-127

	// try to enable interrupt to see if how it works in rx
	SpiaRegs.SPICTL.bit.SPIINTENA 			= 1;							// 0 = Disables interupt, 1 - enable
	SpiaRegs.SPIFFRX.bit.RXFFIENA			= 1;							// 0 = RXFIFO interrupt based on RXFFIL match (greater than or equal to) will be disabled.

	SpiaRegs.SPICTL.bit.SPIINTENA 			= 1;							// 0 = Disables interupt, 1 - enable

    SpiaRegs.SPICCR.bit.SPISWRESET 			= 1;							// 1 = SPI is ready to transmit or receive the next character
}


void InitEPwm2()															// GPIO Pin02 asic CLK_CTRL 15MHz
{
   EPwm2Regs.TBCTL.bit.CTRMODE 				= TB_COUNT_UP; 					// Count up
   EPwm2Regs.TBCTL.bit.PRDLD 				= TB_SHADOW; 					// load the TBPRD immedeiately
   EPwm2Regs.TBCTL.bit.SYNCOSEL 			= TB_DISABLE; 					// EPWM2SYNC
   EPwm2Regs.TBPRD 							= EPWM2_TIMER_TBPRD;			// Set timer period
   EPwm2Regs.TBCTL.bit.PHSEN 				= TB_DISABLE;    				// Disable phase loading
   EPwm2Regs.TBPHS.half.TBPHS 				= 0x0000;       				// Phase is 0
   EPwm2Regs.TBCTR 							= 0x0000;           			// Clear counter
   EPwm2Regs.TBCTL.bit.HSPCLKDIV 			= TB_DIV1;   					// Clock ratio to SYSCLKOUT
   EPwm2Regs.TBCTL.bit.CLKDIV 				= TB_DIV1;						// TBCLK = SYSCLK
   EPwm2Regs.TBCTL.bit.HSPCLKDIV 			= 0;   							// Clock ratio to SYSCLKOUT
   EPwm2Regs.TBCTL.bit.CLKDIV 				= 0;							// TBCLK = SYSCLK
// Setup shadow register load on ZERO
   EPwm2Regs.CMPCTL.bit.SHDWAMODE 			= CC_SHADOW;					// CMPA register value = 0
   EPwm2Regs.CMPCTL.bit.SHDWBMODE 			= CC_SHADOW;					// CMPB register value = 0
   EPwm2Regs.CMPCTL.bit.LOADAMODE 			= CC_CTR_ZERO;					// Load on CTR = 0
   EPwm2Regs.CMPCTL.bit.LOADBMODE 			= CC_CTR_ZERO;					// Load on CTR = 0
// Set Compare values
   EPwm2Regs.CMPA.half.CMPA 				= EPWM2_MIN_CMPA;   			// Set compare A value
// Set actions
   EPwm2Regs.AQCTLA.bit.ZRO 				= AQ_SET;           			// Set PWM1A on Zero
   EPwm2Regs.AQCTLA.bit.CAU 				= AQ_CLEAR;         			// Clear PWM1A on event A, up count
   EPwm2Regs.AQCTLB.bit.ZRO 				= AQ_SET;           			// Set PWM1B on Zero
   EPwm2Regs.AQCTLB.bit.CBU 				= AQ_CLEAR;         			// Clear PWM1B on event B, up count
// Interrupt where we will change the Compare Values
   EPwm2Regs.ETSEL.bit.INTSEL 				= ET_CTR_ZERO;     				// Select INT on Zero event
   EPwm2Regs.ETSEL.bit.INTEN 				= 1;                			// Enable INT
   EPwm2Regs.ETPS.bit.INTPRD 				= ET_3RD;           			// Generate INT on 3rd event
}



// McBSP-B register config
void setup_McbspbSpi()
{
    McbspbRegs.SPCR2.all		= 0x0000;									// Reset FS generator, sample rate generator & transmitter
	McbspbRegs.SPCR1.all		= 0x0000;									// Reset Receiver, Right justify word, Digital loopback dis
	McbspbRegs.PCR.all			= 0x0000;       							// Reset Pin Control Register
    McbspbRegs.PCR.bit.FSXM 	= 1;										// When FSXM=1, the FSGM bit determines how the McBSP supplies frame-synchronization
    McbspbRegs.PCR.bit.FSRM 	= 1;										// Receive frame-synchronization mode 1 = output
    McbspbRegs.PCR.bit.CLKXM 	= 1;										// Transmit clock mode 1 = CLKX is driven by the sample rate generator
    McbspbRegs.PCR.bit.CLKRM 	= 1;										// Receive clock mode 1 = CLKX is driven by the sample rate generator
    McbspbRegs.PCR.bit.SCLKME 	= 0;										// CLKG freq. = (Input clock frequency) / (CLKGDV + 1)
    //McbspbRegs.PCR.bit.DXSTAT = 0;										// 0 = Drive the signal on the DX pin low.
    //McbspbRegs.PCR.bit.DRSTAT = 0;										// 0 = The signal on DR pin is low.
    //McbspbRegs.PCR.bit.FSXP 	= 1;										// 1 = Tx frame-synchronization pulses are active low
    McbspbRegs.PCR.bit.FSRP 	= 0;										// 0 = Receive frame-synchronization pulses are active hi
    McbspbRegs.PCR.bit.CLKXP 	= 0;
    McbspbRegs.PCR.bit.CLKRP 	= 0;										// Receive data is sampled on the falling edge of MCLKR.
	//McbspbRegs.PCR.all			=0x0F08;       							//(CLKXM=CLKRM=FSXM=FSRM= 1, FSXP = 1)
	McbspbRegs.SPCR1.bit.DLB 	= 0;										// 0 = Digital loopback mode bit disabled
    McbspbRegs.SPCR1.bit.RRDY	= 1;										// Receiver ready, new data can be read from DRR[1,2].
	McbspbRegs.SPCR1.bit.RJUST 	= 0;										// Right justify the data and zero fill the MSBs
    McbspbRegs.SPCR1.bit.CLKSTP = 0;     									// CLKSTP disabled LTC1407A does not use true SPI
    McbspbRegs.SPCR1.bit.RINTM  = 2;
	McbspbRegs.PCR.bit.CLKXP 	= 0;		 								// CLKRP = CLKXP when the same clock is used for Rx and Tx
	McbspbRegs.PCR.bit.CLKRP 	= 0;										// CLKRP = CLKXP when the same clock is used for Rx and Tx
    McbspbRegs.RCR2.bit.RDATDLY	= 1;      									// 1-bit delay is selected, because data follows 1-cycle frame-synch pulse
    McbspbRegs.XCR2.bit.XDATDLY	= 1;      									// 1-bit delay is selected, because data follows 1-cycle frame-synch pulse
	McbspbRegs.RCR1.bit.RWDLEN1	= 5;       									// 32-bit word
	McbspbRegs.RCR1.bit.RFRLEN1	= 0;       									// 1 words
    McbspbRegs.XCR1.bit.XWDLEN1	= 5;       									// 32-bit word
    McbspbRegs.XCR1.bit.XFRLEN1	= 0;       									// 1 words
    McbspbRegs.SRGR2.all		= 0x0000;
    McbspbRegs.SRGR2.bit.GSYNC	= 0; 	 									// clock synchronization
    McbspbRegs.SRGR2.bit.CLKSM	= 1;										// input clock for the sample rate generator is taken from the LSPCLK
    McbspbRegs.SRGR2.bit.FSGM	= 0;										//
    //McbspbRegs.SRGR2.bit.FPER	= 124;										// The period between FSG is FPER+1 = 32cycles FSG width is determined by FWID
    McbspbRegs.SRGR2.bit.FPER	= 49;										// The period between FSG is FPER+1 = 32cycles FSG width is determined by FWID
    McbspbRegs.SRGR1.all		= 0x0000;	    							// Frame Width = 1 CLKG period, CLKGDV=16
    McbspbRegs.SRGR1.bit.CLKGDV	= 14;	    								// CLKG freq = LSPCLK/(CLKGDV + 1) = 75MHz/(9 + 1) = 0.5MHz
    McbspbRegs.SRGR1.bit.FWID	= 0x02;										// Frame-synchronization pulse width for FSG = 2 x 13.3ns (LTC1407A min is 2ns)
    McbspbRegs.SPCR2.bit.GRST	= 0;         								// Sample rate generator enabled
    delay_loop();
    McbspbRegs.SPCR2.bit.FRST	= 0;         								// Frame Sync Generator enabled, this must be after GRST
    McbspbRegs.SPCR2.bit.XRDY   = 0;										// Transmitter ready to accept new data
	delay_loop();                        									// Wait at least 2 SRG clock cycles
	McbspbRegs.SPCR2.bit.XRST	= 0;         								// Transmitter enabled, not required for uNMR
	McbspbRegs.SPCR1.bit.RRST	= 0;         								// receiver enabled

}


Uint32 mcsb32bitWordFromADC()
{

	Uint16 i = 0;
    McbspbRegs.SPCR2.bit.GRST	= 1;          								// Sample rate generator enabled
    McbspbRegs.SPCR2.bit.FRST	= 1;         								// Frame Sync Generator enabled, this must be after GRST
    McbspbRegs.SPCR2.bit.XRDY   = 1;										// Transmitter ready to accept new data
	delay_loop();
	rdata1 = McbspbRegs.DRR1.all;											// Read DRR1 to complete receiving of data
    for( i = 0; i < 3; i++){
		while( McbspbRegs.SPCR1.bit.RRDY == 0 ) {}      					// Master waits until RX data is ready
		rdata2 = McbspbRegs.DRR2.all & 0x3fff;          					// Read DRR2 first.
		rdata1 = McbspbRegs.DRR1.all & 0x3fff;          					// Then read DRR1 to complete receiving of data
		//for( i = 0; i < 10; i++){
			data2[i] = rdata2;
			data1[i] = rdata1;
	}

    McbspbRegs.SPCR2.bit.GRST	= 0;         								// Sample rate generator disabled
    sdata1 ^= 0xFFFF;														// bitwise exclusive XOR
    sdata2 ^= 0xFFFF;														// bitwise exclusive XOR
    __asm("    nop");                                						// Good place for a breakpoint
    return 0;
}


// **********************************************************
// ************* SPI interfaces
//
//SPI Temp Sens LM95071
//

Uint16 spi_temp_board()
{
    Uint32 i;                                                               // variable declaration
    Uint16 TEMP_read;                                                       // variable declaration


    configure_SPI(0,1, 15, 1, 20); // Uint16 POL, Uint16 PHA, Uint16 BITS, Uint16 nFIFO, Uint16 ClkSpeedDiv);

/*
    SpiaRegs.SPICCR.bit.CLKPOLARITY         = 0;                            // 0, 1 all transmit's on rising edge delayed by 1/2 clk. Inactive lo   0 1
    SpiaRegs.SPICTL.bit.CLK_PHASE           = 1;                            // 1, 0 all transmit's on falling edge. Inactive Hi 1 0
                                                                            // 1, 1 all transmit's on falling edge delayed by 1/2 clk. Inactive Hi
    for (i=0;i<20;i++){asm(" NOP");}                                        // NOP gives setup time to CLKPOLARITY and PHASE
    GpioCtrlRegs.GPBPUD.bit.GPIO55          = 1;                            // disable pull-up for GPIO55 SPI_MISOA
    SpiaRegs.SPICCR.bit.SPICHAR             = 0x0F;                         // 16 bit word length
    SpiaRegs.SPIFFRX.bit.RXFFIL             = 1;                            // number states how many words fill FIFO


    SpiaRegs.SPIFFRX.bit.RXFIFORESET        = 0;                            // 0 to reset the FIFO and hold in reset
    SpiaRegs.SPIFFRX.bit.RXFIFORESET        = 1;                            // 1 to Re-enable FIFO
    SpiaRegs.SPIFFRX.bit.RXFFINTCLR         = 1;                            // 1 to clear fag of RXFIFORESET
*/

    GpioDataRegs.GPCCLEAR.bit.GPIO75        = 1;                            // CS active low

    for (i=0;i<10;i++){asm(" NOP");}                                        // recommended delay
    SpiaRegs.SPITXBUF = 0x0000;                                         // the tx data is not wired to yhe chip.

    for (i=0;i<20;i++){asm(" NOP");}
    while(SpiaRegs.SPIFFRX.bit.RXFFINT      != 1){}                         // while RXFFINT FIFO interupt bit !=1, wait

    for (i=0;i<5;i++){asm(" NOP");}
    GpioDataRegs.GPCSET.bit.GPIO75          = 1;                            // RX FIFO interupt bit =1, set GPIO75 =1 (Hi)

    TEMP_read = (Uint16)(SpiaRegs.SPIRXBUF) >> 2 ;                          // ROR by 2 gets rid of unwanted lsb's
    return TEMP_read;
}

// **************************************************
// *************** interfacing with DAC for tuning
// chip select is at GpioDataRegs.GPCSET.bit.GPIO57
//
// SPI DAC LTC2630
void spi_dac(Uint16 a)														// SPI dac function configuration
{
	configure_SPI(0,1, 7, 3, 9); // Uint16 POL, Uint16 PHA, Uint16 BITS, Uint16 nFIFO, Uint16 ClkSpeedDiv);
/*
	SpiaRegs.SPICCR.bit.CLKPOLARITY		= 0;								// MOSI on rise edge, MISO on fall edge
	SpiaRegs.SPICTL.bit.CLK_PHASE 		= 1;								// Normal SPI clocking scheme
	asm(" NOP");															// NOP gives setup time to CLKPOLARITY and PHASE
	asm(" NOP");															// NOP gives setup time to CLKPOLARITY and PHASE
	GpioDataRegs.GPBCLEAR.bit.GPIO57 	= 1;								// CS DAC. Writing a 1 forces the respective output data latch to low
	SpiaRegs.SPICCR.bit.SPICHAR 		= 0x007;							// SPI Char length 8 bits
	SpiaRegs.SPIFFRX.bit.RXFFIL			= 3;								// Receive FIFO Status, set for 3 words
*/
	SpiaRegs.SPIFFRX.bit.RXFIFORESET 	= 0;								// Write 0 to reset the FIFO pointer to zero, and hold in reset
	SpiaRegs.SPIFFRX.bit.RXFIFORESET 	= 1;								// Write 1 Re-enable receive FIFO operation
	SpiaRegs.SPIFFRX.bit.RXFFINTCLR 	= 1;								// Write 1 to clear RXFFINT flag in bit 7
	asm(" NOP");															// NOP gives time at the end of SPI setup before SPITX
	asm(" NOP");															// NOP gives time at the end of SPI setup before SPITX

	SpiaRegs.SPITXBUF = 0x30 <<8;											// Load SPITXBUF DAC control 0x30
	SpiaRegs.SPITXBUF = a<<4;													// Load SPITXBUF upper 8bits right shifted << 4
	SpiaRegs.SPITXBUF = a << 12;												// Load SPITXBUF lower 8bits right shifted << 4 + additional << 8
																			// 24bit word to DAC when only sending 2x8bits via ModBus

	asm(" NOP");															// NOP gives time at the end of SPI TX before enable goes Hi
	while(SpiaRegs.SPIFFRX.bit.RXFFINT !=1){}								// while RXFFINT FIFO interupt bit !=1, wait
	GpioDataRegs.GPBSET.bit.GPIO57 		=1;									// RX FIFO interupt bit =1, set GPIO57 =1 (Hi)
	led_blink_D42();
	DELAY_US(100);// Test led blink
	led_blink_D42();

}

// initialize the DAC to internal ref
void init_spi_dac(Uint16 a)														// SPI dac function configuration
{
	SpiaRegs.SPICCR.bit.CLKPOLARITY		= 0;								// MOSI on rise edge, MISO on fall edge
	SpiaRegs.SPICTL.bit.CLK_PHASE 		= 1;								// Normal SPI clocking scheme
	asm(" NOP");															// NOP gives setup time to CLKPOLARITY and PHASE
	asm(" NOP");															// NOP gives setup time to CLKPOLARITY and PHASE
	GpioDataRegs.GPBCLEAR.bit.GPIO57 	= 1;								// CS DAC. Writing a 1 forces the respective output data latch to low
	SpiaRegs.SPICCR.bit.SPICHAR 		= 0x007;							// SPI Char length 8 bits
	SpiaRegs.SPIFFRX.bit.RXFFIL			= 3;								// Receive FIFO Status, set for 3 words
	SpiaRegs.SPIFFRX.bit.RXFIFORESET 	= 0;								// Write 0 to reset the FIFO pointer to zero, and hold in reset
	SpiaRegs.SPIFFRX.bit.RXFIFORESET 	= 1;								// Write 1 Re-enable receive FIFO operation
	SpiaRegs.SPIFFRX.bit.RXFFINTCLR 	= 1;								// Write 1 to clear RXFFINT flag in bit 7
	asm(" NOP");															// NOP gives time at the end of SPI setup before SPITX
	asm(" NOP");															// NOP gives time at the end of SPI setup before SPITX

	// write the iniitialization command '0110'
	SpiaRegs.SPITXBUF = 0x60;											// Load SPITXBUF DAC control 0x30
	SpiaRegs.SPITXBUF = 0x00;													// Load SPITXBUF upper 8bits right shifted << 4
	SpiaRegs.SPITXBUF = 0x00;												// Load SPITXBUF lower 8bits right shifted << 4 + additional << 8
																			// 24bit word to DAC when only sending 2x8bits via ModBus
	asm(" NOP");															// NOP gives time at the end of SPI TX before enable goes Hi
	while(SpiaRegs.SPIFFRX.bit.RXFFINT !=1){}								// while RXFFINT FIFO interupt bit !=1, wait
	GpioDataRegs.GPBSET.bit.GPIO57 		=1;									// RX FIFO interupt bit =1, set GPIO57 =1 (Hi)
	led_blink_D42();                                        				// Test led blink

}



// davids, orignal code
void spi_dac_MCC(Uint16 a)														// SPI dac function configuration
{


	SpiaRegs.SPICCR.bit.CLKPOLARITY		= 0;								// MOSI on rise edge, MISO on fall edge
	SpiaRegs.SPICTL.bit.CLK_PHASE 		= 1;								// Normal SPI clocking scheme
	asm(" NOP");															// NOP gives setup time to CLKPOLARITY and PHASE
	asm(" NOP");															// NOP gives setup time to CLKPOLARITY and PHASE
	GpioDataRegs.GPBCLEAR.bit.GPIO57 	= 1;								// CS DAC. Writing a 1 forces the respective output data latch to low
	SpiaRegs.SPICCR.bit.SPICHAR 		= 0x007;							// SPI Char length 8 bits
	SpiaRegs.SPIFFRX.bit.RXFFIL			= 3;								// Receive FIFO Status, set for 3 words
	SpiaRegs.SPIFFRX.bit.RXFIFORESET 	= 0;								// Write 0 to reset the FIFO pointer to zero, and hold in reset
	SpiaRegs.SPIFFRX.bit.RXFIFORESET 	= 1;								// Write 1 Re-enable receive FIFO operation
	SpiaRegs.SPIFFRX.bit.RXFFINTCLR 	= 1;								// Write 1 to clear RXFFINT flag in bit 7
	asm(" NOP");															// NOP gives time at the end of SPI setup before SPITX
	asm(" NOP");															// NOP gives time at the end of SPI setup before SPITX
	SpiaRegs.SPITXBUF = 0x30 << 8;											// Load SPITXBUF DAC control 0x30
	SpiaRegs.SPITXBUF = a << 4;													// Load SPITXBUF upper 8bits right shifted << 4
	SpiaRegs.SPITXBUF = a << 12;												// Load SPITXBUF lower 8bits right shifted << 4 + additional << 8
																			// 24bit word to DAC when only sending 2x8bits via ModBus
	asm(" NOP");															// NOP gives time at the end of SPI TX before enable goes Hi
	while(SpiaRegs.SPIFFRX.bit.RXFFINT !=1){}								// while RXFFINT FIFO interupt bit !=1, wait
	GpioDataRegs.GPBSET.bit.GPIO57 		=1;									// RX FIFO interupt bit =1, set GPIO57 =1 (Hi)
	led_blink_D42();                                        				// Test led blink

}


// ********************************************************************
// *************** interfacing with PLL
// chip select is at GpioDataRegs.GPCSET.bit.GPIO72

// SPI PLL HMC832
void PLL_init()																// initial 100 MHz setting at start up
{
	DELAY_US(100);															// 	100us delay
	PLL_write(1, 0x000002);       											//	Reset register, 2 = PLL enable via SPI
	DELAY_US(100);															// 	100us delay
	PLL_write(2, 0x000001);       											//	REF divide register, range (1 to 16383)d
	DELAY_US(100);															// 	100us delay
//	PLL_write(3, 0x000059);         										//	VCO freq register, range 16 to 524284)d
	PLL_write(3, 0x3E);                                                     // RTang, change the value to 3E (62d), 8/22/17
	DELAY_US(100);															// 	100us delay

// Register 0x05 is a special register used for indirect addressing of the VCO subsystem
// Writes to Register 0x05 are automatically forwarded to the VCO subsystem by the VCO SPI statemachine controller
// Register 0x05 holds only the contents of the last transfer to the VCO subsystem
// 																VCO_DATA [15:7], 		VCO_REGADDR [6:3], VCO_ID [2:0]
	PLL_write(5, 0x00FF88);													//	VCO_DATA = 1111 1111 1, VCO_REGADDR= 0001, VCO ID=000
	DELAY_US(100);															// 	100us delay
	PLL_write(5, 0x004F98);													//	VCO_DATA = 0100 1111 1, VCO_REGADDR= 0011, VCO ID=000
	DELAY_US(100);															// 	100us delay
	PLL_write(5, 0x0064A0);													//	VCO_DATA = 0110 0100 1, VCO_REGADDR= 0100, VCO ID=000
	DELAY_US(100);															// 	100us delay
	PLL_write(5, 0x005528);													//	VCO_DATA = 0101 0101 0, VCO_REGADDR= 0101, VCO ID=000
	DELAY_US(100);															// 	100us delay
	PLL_write(5, 0x007FB0);													//	VCO_DATA = 0111 1111 1, VCO_REGADDR= 0110, VCO ID=000
	DELAY_US(100);															// 	100us delay
	PLL_write(5, 0x004DB8);													//	VCO_DATA = 0100 1101 1, VCO_REGADDR= 0111, VCO ID=000
	DELAY_US(100);															// 	100us delay
	PLL_write(5, 0x007F10);													//	VCO_DATA = 0111 1111 0, VCO_REGADDR= 0010, VCO ID=000
	DELAY_US(100);															// 	100us delay
	PLL_write(5, 0x00FF00);													//	VCO_DATA = 1111 1111 0, VCO_REGADDR= 0000, VCO ID=000
	DELAY_US(100);															// 	100us delay

	PLL_write(6, 0x000F4A);													// 	Delta sigma configuration register, for fractional mode.
	DELAY_US(100);															// 	100us delay
	PLL_write(7, 0x0025CD);													// 	Lock detect register
	DELAY_US(100);															// 	100us delay
	PLL_write(8, 0xC1BEFF);													// 	Analog enable register
	DELAY_US(100);															// 	100us delay
	PLL_write(9, 0x30ED5A);													// 	Charge pump register
	DELAY_US(100);															// 	100us delay
	PLL_write(10,0x002046);													// 	VCO autocalibration configuration register
	DELAY_US(100);															// 	100us delay
	PLL_write(11,0x0F8061);													// 	Phase Detect register
	DELAY_US(100);															// 	100us delay
	PLL_write(12,0x000023);													// 	Exact freq mode register
	DELAY_US(100);															// 	100us delay
	PLL_write(15,0x000001);													// 	GP_SPI_RDIV register
	DELAY_US(100);															// 	100us delay
	//PLL_write(4, 0x19601C);        										//	Freq register (fractional), range (0 to 16777215)d 45986644.00 Hz
	PLL_write(4, 0x256B4C);        											//	Freq register (fractional), range (0 to 16777215)d 45986644.00 Hz
	DELAY_US(100);
}


// SPI PLL HMC832 read
Uint32 spi_PLL_read(Uint8 reg)
{
    Uint32 read_val;
    PLL_mosi(0x0000, reg << 8);
    PLL_mosi(0x0000, reg << 8);
    read_val = (Uint32)(SpiaRegs.SPIRXBUF) << 16;
    read_val += SpiaRegs.SPIRXBUF;
    return read_val >> 8; //change from 7 to 8 Ray Tang 8/29/2017
}




// SPI PLL HMC832
// update freq
// Input freq in unit of Hertz
#define TWO_POW_24 16777216 // 2^24

// put  Nint and Nfrac calculation in software, rather than firmware
// R Tang 08/24/2017

Uint32 PLL_freq_set2(long Nint,long Nfrac)                                                              // initial 100 MHz setting at start up
{
//    Uint32 k = 62, R=1;                     // The current PLL_init sets vco_reg_0x02 to 49d and pll_0x02 to 1. 8/22/2017
//    Uint32 N1;
      Uint32 data_reg16, temp1, temp2, temp3;
//    Uint32 N2 ;
//    double x;

//    x = (double)inFreq*k*(R)/freqxtal; //R-1 in DM's python code??
//    N1 = floor(x);
//    x = x-N1;

//    N2=floor(x*TWO_POW_24);
    //N2 = TWO_POW_24*(k*R*inFreq/freqxtal-N1);


    DELAY_US(100);                                                          //  100us delay
    PLL_write(1, 0x000002);                                                 //  Reset register, 2 = PLL enable via SPI
    DELAY_US(100);                                                          //  100us delay
    PLL_write(2, 0x000001);                                                 //  REF divide register, range (1 to 16383)d
    DELAY_US(100);                                                          //  100us delay
                                                           //  100us delay

// Register 0x05 is a special register used for indirect addressing of the VCO subsystem
// Writes to Register 0x05 are automatically forwarded to the VCO subsystem by the VCO SPI statemachine controller
// Register 0x05 holds only the contents of the last transfer to the VCO subsystem
//                                                              VCO_DATA [15:7],        VCO_REGADDR [6:3], VCO_ID [2:0]
    PLL_write(5, 0x00FF88);                                                 //  VCO_DATA = 1111 1111 1, VCO_REGADDR= 0001, VCO ID=000
    DELAY_US(100);                                                          //  100us delay
    PLL_write(5, 0x004F98);                                                 //  VCO_DATA = 0100 1111 1, VCO_REGADDR= 0011, VCO ID=000
    DELAY_US(100);                                                          //  100us delay
    PLL_write(5, 0x0064A0);                                                 //  VCO_DATA = 0110 0100 1, VCO_REGADDR= 0100, VCO ID=000
    DELAY_US(100);                                                          //  100us delay
    PLL_write(5, 0x005528);                                                 //  VCO_DATA = 0101 0101 0, VCO_REGADDR= 0101, VCO ID=000
    DELAY_US(100);                                                          //  100us delay
    PLL_write(5, 0x007FB0);                                                 //  VCO_DATA = 0111 1111 1, VCO_REGADDR= 0110, VCO ID=000
    DELAY_US(100);                                                          //  100us delay
    PLL_write(5, 0x004DB8);                                                 //  VCO_DATA = 0100 1101 1, VCO_REGADDR= 0111, VCO ID=000
    DELAY_US(100);                                                          //  100us delay
    PLL_write(5, 0x007F10);                                                 //  VCO_DATA = 0111 1111 0, VCO_REGADDR= 0010, VCO ID=000
//  PLL_write(5, 0x007890);                                                 // change to 49 RTang 08/22/2017
    DELAY_US(100);                                                          //  100us delay
    PLL_write(5, 0x00FF00);                                                 //  VCO_DATA = 1111 1111 0, VCO_REGADDR= 0000, VCO ID=000
    DELAY_US(100);                                                          //  100us delay

    PLL_write(6, 0x000F4A);                                                 //  Delta sigma configuration register, for fractional mode.
    DELAY_US(100);                                                          //  100us delay
    PLL_write(7, 0x0025CD);                                                 //  Lock detect register
    DELAY_US(100);                                                          //  100us delay
    PLL_write(8, 0xC1BEFF);                                                 //  Analog enable register
    DELAY_US(100);                                                          //  100us delay
    PLL_write(9, 0x30ED5A);                                                 //  Charge pump register
    DELAY_US(100);                                                          //  100us delay
    PLL_write(10,0x002205);   //change from 2046 by R Tang, 8/30/17                                              //  VCO autocalibration configuration register
    DELAY_US(100);                                                          //  100us delay
    PLL_write(11,0x0F8061);                                                 //  Phase Detect register
    DELAY_US(100);                                                          //  100us delay
    PLL_write(12,0x000000);    //change from 12 by R Tang, 8/30/17                                             //  Exact freq mode register
    DELAY_US(100);                                                          //  100us delay
    PLL_write(15,0x000001);                                                 //  GP_SPI_RDIV register
    DELAY_US(100);                                                          //  100us delay


    PLL_write(5, 0x0);        //  VCO_DATA = 0_0000_0000, VCO_REGADDR= 0000, VCO ID=000
    DELAY_US(100);
    PLL_write(3, Nint);                                                    //  VCO freq register, range 16 to 524284)d
    DELAY_US(100);                                                         //  100us delay
    PLL_write(4, Nfrac);                                                   //  Freq register (fractional), range (0 to 16777215)d 45986644.00 Hz

    // here is to follow the procedure from manual page 16
//    data_reg16 = spi_PLL_read(16);
//
//    temp1 = data_reg16 << 8;
//    temp2 = temp1|0x2000; //raise [13] = 1
//    temp3 = temp2 & 0xFF00; //set [0 - 7 ] = 0
//
//    //data_reg16 >>=1;
//
//    PLL_write(5, temp3); // this is to follow procedure on manual page 16.
//    DELAY_US(100);

//    return data_reg16;
//    return temp1;
    return 0;
}

// use PLL_freq_set2, but input full freq as a 32-bit int
// return is not set yet.
// YS nov 2019
Uint32 PLL_freq_set3(Uint32 inFreq)
{
    Uint32 k = 62, R=1;                     // The current PLL_init sets vco_reg_0x02 to 49d and pll_0x02 to 1. 8/22/2017
    double x;
    Uint32 N1,N2;

    x = (double)inFreq*k*(R)/freqxtal; //R-1 in DM's python code??
    N1 = floor(x);
    x = x-N1;

    N2=floor(x*TWO_POW_24);

    return PLL_freq_set2(N1,N2);


}



Uint32 PLL_freq_set(Uint32 inFreq)																// initial 100 MHz setting at start up
{
	Uint32 k = 62, R=1;						// The current PLL_init sets vco_reg_0x02 to 49d and pll_0x02 to 1. 8/22/2017
	Uint32 N1;

	Uint32 N2 ;
	double x;

	x = (double)inFreq*k*(R)/freqxtal; //R-1 in DM's python code??
	N1 = floor(x);
	x = x-N1;

	N2=floor(x*TWO_POW_24);
	//N2 = TWO_POW_24*(k*R*inFreq/freqxtal-N1);


	DELAY_US(100);															// 	100us delay
	PLL_write(1, 0x000002);       											//	Reset register, 2 = PLL enable via SPI
	DELAY_US(100);															// 	100us delay
	PLL_write(2, 0x000001);       											//	REF divide register, range (1 to 16383)d
	DELAY_US(100);															// 	100us delay
	PLL_write(3, N1);         										//	VCO freq register, range 16 to 524284)d
	DELAY_US(100);															// 	100us delay

// Register 0x05 is a special register used for indirect addressing of the VCO subsystem
// Writes to Register 0x05 are automatically forwarded to the VCO subsystem by the VCO SPI statemachine controller
// Register 0x05 holds only the contents of the last transfer to the VCO subsystem
// 																VCO_DATA [15:7], 		VCO_REGADDR [6:3], VCO_ID [2:0]
	PLL_write(5, 0x00FF88);													//	VCO_DATA = 1111 1111 1, VCO_REGADDR= 0001, VCO ID=000
	DELAY_US(100);															// 	100us delay
	PLL_write(5, 0x004F98);													//	VCO_DATA = 0100 1111 1, VCO_REGADDR= 0011, VCO ID=000
	DELAY_US(100);															// 	100us delay
	PLL_write(5, 0x0064A0);													//	VCO_DATA = 0110 0100 1, VCO_REGADDR= 0100, VCO ID=000
	DELAY_US(100);															// 	100us delay
	PLL_write(5, 0x005528);													//	VCO_DATA = 0101 0101 0, VCO_REGADDR= 0101, VCO ID=000
	DELAY_US(100);															// 	100us delay
	PLL_write(5, 0x007FB0);													//	VCO_DATA = 0111 1111 1, VCO_REGADDR= 0110, VCO ID=000
	DELAY_US(100);															// 	100us delay
	PLL_write(5, 0x004DB8);													//	VCO_DATA = 0100 1101 1, VCO_REGADDR= 0111, VCO ID=000
	DELAY_US(100);															// 	100us delay
	PLL_write(5, 0x007F10);													//	VCO_DATA = 0111 1111 0, VCO_REGADDR= 0010, VCO ID=000
//	PLL_write(5, 0x007890);                                                 // change to 49 RTang 08/22/2017
	DELAY_US(100);															// 	100us delay
	PLL_write(5, 0x00FF00);													//	VCO_DATA = 1111 1111 0, VCO_REGADDR= 0000, VCO ID=000
	DELAY_US(100);															// 	100us delay

	PLL_write(6, 0x000F4A);													// 	Delta sigma configuration register, for fractional mode.
	DELAY_US(100);															// 	100us delay
	PLL_write(7, 0x0025CD);													// 	Lock detect register
	DELAY_US(100);															// 	100us delay
	PLL_write(8, 0xC1BEFF);													// 	Analog enable register
	DELAY_US(100);															// 	100us delay
	PLL_write(9, 0x30ED5A);													// 	Charge pump register
	DELAY_US(100);															// 	100us delay
	PLL_write(10,0x002046);													// 	VCO autocalibration configuration register
	DELAY_US(100);															// 	100us delay
	PLL_write(11,0x0F8061);													// 	Phase Detect register
	DELAY_US(100);															// 	100us delay
	PLL_write(12,0x000023);													// 	Exact freq mode register
	DELAY_US(100);															// 	100us delay
	PLL_write(15,0x000001);													// 	GP_SPI_RDIV register
	DELAY_US(100);															// 	100us delay


	// reset VCO (addr 0000) to zero and then set Nfrac will restart the autocal and relock.
	PLL_write(5, 0);													//	VCO_DATA = 0_0000_0000, VCO_REGADDR= 0000, VCO ID=000
	//DELAY_US(1);															// 	100us delay
	PLL_write(4, N2);
	//	Freq register (fractional), range (0 to 16777215)d 45986644.00 Hz
	DELAY_US(100);

	return N2;
}

// SPI PLL HMC832 write single
void PLL_write(Uint8 reg, Uint32 data)
{
	Uint16 msb, lsb;
	lsb = ((reg&0x1F)<<3) + ((data&0xFF)<<8);
	msb = ((data&0xFFFF00)>>8);
	PLL_mosi(msb, lsb);
}

// SPI PLL HMC832 write all
// set SPI to POL=1, PHA=0, bits_per_word=0x0F, number_of_word=2, speeddiv=9=>7.5 MHz
void PLL_mosi(Uint16 msb, Uint16 lsb)										// mosi spi function config
{
	Uint32 i;

	configure_SPI(1,0, 15, 2, 9); // Uint16 POL, Uint16 PHA, Uint16 BITS, Uint16 nFIFO, Uint16 ClkSpeedDiv);

	SpiaRegs.SPICCR.bit.CLKPOLARITY		= 1;								// MOSI on falling edge, MISO on fall edge
	SpiaRegs.SPICTL.bit.CLK_PHASE 		= 0;
	//GpioDataRegs.GPCSET.bit.GPIO72      = 1;
	for (i=0;i<100;i++){asm(" NOP");}
	GpioDataRegs.GPCCLEAR.bit.GPIO72 	= 1;                                // This must be the chip select (CS), set to low
	SpiaRegs.SPICCR.bit.SPICHAR 		= 0x00F;
	SpiaRegs.SPIFFRX.bit.RXFFIL			= 2;

	SpiaRegs.SPIFFRX.bit.RXFIFORESET 	= 0;
	SpiaRegs.SPIFFRX.bit.RXFIFORESET 	= 1;
	SpiaRegs.SPIFFRX.bit.RXFFINTCLR 	= 1;
	asm(" NOP");
	asm(" NOP");
	asm(" NOP");
	asm(" NOP");
	asm(" NOP");
	asm(" NOP");
	asm(" NOP");
	SpiaRegs.SPITXBUF = msb;
	SpiaRegs.SPITXBUF = lsb;
	while(SpiaRegs.SPIFFRX.bit.RXFFINT !=1){}
	GpioDataRegs.GPCSET.bit.GPIO72 		= 1;                            // CS set to high to stop

}


// set PLL freq, this routine can only be used after PLL_init()
// SPI PLL HMC832, only set the integer (03) and fractional (04) registers.
// Input freq in unit of Hertz
Uint32 PLL_freq_set_orig(Uint32 inFreq)
{
	Uint32 k = 62;						// The current PLL_init sets this value to 62.
	Uint32 N1;

	Uint32 N2 ;
	float x;


	N1 = inFreq*k/freqxtal;
	x = (float) N1*freqxtal;
	x = inFreq - x/(float) k;

	N2 = pow(2.0,24.0)*x*(float)k /freqxtal;
	PLL_write(3, N1);         					//	VCO freq register, integer, range 916 to 524284)d
	DELAY_US(100);									// 	100us delay

	PLL_write(4, N2);        					//	Freq register (fractional), range (0 to 16777215)d 45986644.00 Hz
	DELAY_US(100);
	SetNMRParameters(18,N2);
	return 1;
}

// ************************************************************************************
// below functions are for the 24-bit temp sensor ADS1248
// ADS1248, magnet temp sensor initialize
//
// chip select is connected to GpioDataRegs.GPCSET.bit.GPIO74.
//
void magnet_temp_init()
{
       DELAY_US(10);
       magnet_temp_reset();
       DELAY_US(1000);
       magnet_temp_sdatac();
       DELAY_US(10);
       magnet_temp_write(0x0, 0x08);                                                                          //  +ve input AN1, -ve input AN0
       DELAY_US(10);
       magnet_temp_write(0x1, 0x00);                                                                          //  Bias voltage of mid-supply (AVDD + AVSS) / 2, not enabled
       DELAY_US(10);
       magnet_temp_write(0x2, 0x20);                                                                          //  Internal reference selected
       DELAY_US(10);
       magnet_temp_write(0x3, 0x20);                                                                          //  PGA = 4
       DELAY_US(10);
       magnet_temp_write(0xA, 0x04);                                                                          //  Excitation Current Magnitude 500uA
       DELAY_US(10);
       magnet_temp_write(0xB, 0x8C);                                                                          //  IDAC Output 1 IEXC1 Output 2 disabled
       DELAY_US(10);
       magnet_temp_write(0xC, 0x03);                                                                          //  GPIO 0/1 set for REFP0 & REFN0
       DELAY_US(10);
       magnet_temp_write(0xD, 0x03);                                                                          //  REFP0 & REFN0 config as inputs
       DELAY_US(10);
       magnet_temp_write(0xE, 0x03);                                                                          //  REFP0 & REFN0 config as input
       DELAY_US(10);
       magnet_temp_sync();
       DELAY_US(10);
}

// ADS1248, magnet temp sensor reset command
void magnet_temp_reset()
{
       Uint8 cmds[1];
       cmds[0] = (0x6);
       magnet_temp_mosi(1, cmds);
}

// ADS1248, magnet temp sensor sync command
void magnet_temp_sync()
{
       Uint8 cmds[1];
       cmds[0] = (0x4);
       magnet_temp_mosi(1, cmds);
}

// ADS1248, magnet temp sensor serial read
void magnet_temp_sdatac()
{
       Uint8 cmds[1];
       cmds[0] = (0x16);
       magnet_temp_mosi(1, cmds);
}


// ADS1248, magnet temp write (data valid on leadig edge)
void magnet_temp_write(Uint8 reg, Uint8 data)
{
       Uint8 cmds[3];
       cmds[0] = (0b01000000 + reg);
       cmds[1] = 0;
       cmds[2] = data;
       magnet_temp_mosi(3, cmds);
}

// ADS1248, magnet register read ADS1248
Uint8 magnet_reg_read(Uint8 reg)
{
       Uint8 cmds[3];
       cmds[0] = (0b00100000 + reg);
       cmds[1] = 0x0;
       cmds[2] = 0xFF;
       magnet_temp_mosi(3, cmds);
       return cmds[2];
}

// ADS1248, magnet temp read ADS1248
Uint32 magnet_temp_read(Uint8 ADC)
{
       Uint8 cmds[4];
       Uint32 data;
       cmds[0] = (0b00010010 + ADC);
       cmds[1] = 0xFF;
       cmds[2] = 0xFF;
       cmds[3] = 0xFF;
       magnet_temp_mosi(4, cmds);
       data=(((Uint32)cmds[1])<<16)+(((Uint32)cmds[2])<<8)+(((Uint32)cmds[3]));
       return data;

}

void magnet_temp_mosi(Uint8 nBytes, Uint8 *data)                                              // mosi spi function config
{
       Uint32 i;
       SpiaRegs.SPIBRR                                       = 0x0040;                                       // Baud Rate Register
       SpiaRegs.SPICCR.bit.CLKPOLARITY         = 0;                                                   // MOSI on falling edge, MISO on fall edge
       SpiaRegs.SPICTL.bit.CLK_PHASE           = 0;
       //GpioDataRegs.GPCSET.bit.GPIO72      = 1;
       for (i=0;i<100;i++){asm(" NOP");}
       GpioDataRegs.GPCCLEAR.bit.GPIO74        = 1;                         // Chip select, CS, goes low.
       SpiaRegs.SPICCR.bit.SPICHAR             = 0x007;
       SpiaRegs.SPIFFRX.bit.RXFFIL                    = nBytes;
       SpiaRegs.SPIFFRX.bit.RXFIFORESET        = 0;
       SpiaRegs.SPIFFRX.bit.RXFIFORESET        = 1;
       SpiaRegs.SPIFFRX.bit.RXFFINTCLR = 1;
       asm(" NOP");
       asm(" NOP");
       asm(" NOP");
       asm(" NOP");
       asm(" NOP");
       asm(" NOP");
       asm(" NOP");
       for (i=0;i<nBytes;i++)
              SpiaRegs.SPITXBUF = ((Uint16)(data[i]))<<8;
       while(SpiaRegs.SPIFFRX.bit.RXFFINT !=1){}
       for (i=0;i<20;i++) {asm(" NOP");}
       GpioDataRegs.GPCSET.bit.GPIO74          = 1;                     // CS goes high
       for (i=0;i<nBytes;i++)
       {
              data[i]=(SpiaRegs.SPIRXBUF);
       }

}


