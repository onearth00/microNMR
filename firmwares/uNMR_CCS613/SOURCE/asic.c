/*
 * asic.c
 *
 *  Created on: Jul 29, 2016
 *      Author: mccowan1
 */
//###########################################################################
// Revision History:
//
// Sept 26th:- GPCSET.bit.GPIO71 = 1; moved outside loop to prevent CS from toggling 64 times
//
//
//
//###########################################################################

#include "asic.h"
#include "nmr_plsq.h"




void ASIC_mosi_download(PlsSeq* plsq)										// ASIC spi mosi function configured for one word transfer
{
	Uint32 i,j;

	Uint16 m4, m3, m2, m1;

	configure_SPI(1, 0, 15, 4, 9); //, Uint16 PHA, Uint16 BITS, Uint16 nFIFO, Uint16 ClkSpeedDiv)
	for (i=0;i<10;i++){asm(" NOP");}

	GpioDataRegs.GPCCLEAR.bit.GPIO71 		= 1;						// 1 forces GPIO71 (CS_NMR) to Lo

	for (j=0;j<64;j++)
	{
		for (i=0;i<8;i++){asm(" NOP");}
		SpiaRegs.SPICCR.bit.CLKPOLARITY			= 1;						// 0, 1 all transmit's on rising edge delayed by 1/2 clk. Inactive lo
		SpiaRegs.SPICTL.bit.CLK_PHASE 			= 0;						// 1, 0 all transmit's on falling edge. Inactive Hi
																			// 1, 1 all transmit's on falling edge delayed by 1/2 clk. Inactive Hi
		for (i=0;i<10;i++){asm(" NOP");}

		SpiaRegs.SPICCR.bit.SPICHAR 			= 0x00F;					// Char length 16bit
		SpiaRegs.SPIFFRX.bit.RXFFIL				= 4;						// Rx FIFO register
		SpiaRegs.SPIFFRX.bit.RXFIFORESET 		= 0;						// Rx FIFO reset
		SpiaRegs.SPIFFRX.bit.RXFIFORESET 		= 1;						// Rx FIFO reset
		SpiaRegs.SPIFFRX.bit.RXFFINTCLR 		= 1;						// Rx FIFO clear


		for (i=0;i<8;i++){asm(" NOP");}
/*
		m4 = ( unsigned char )( plsq->pls[63-j].dword[1] >> 16 );				// top 16 bits
		m3 = ( unsigned char )( plsq->pls[63-j].dword[1] & 0x0000FFFF );		// bottom 16 bits
		m2 = ( unsigned char )( plsq->pls[63-j].dword[0] >> 16 );				// top 16 bits
		m1 = ( unsigned char )( plsq->pls[63-j].dword[0] & 0x0000FFFF );		// bottom 16 bits
*/
		m4 = ( Uint16)( plsq->pls[63-j].dword[1] >> 16 );				// top 16 bits
		m3 = ( Uint16 )( plsq->pls[63-j].dword[1] & 0x0000FFFF );		// bottom 16 bits
		m2 = ( Uint16 )( plsq->pls[63-j].dword[0] >> 16 );				// top 16 bits
		m1 = ( Uint16 )( plsq->pls[63-j].dword[0] & 0x0000FFFF );		// bottom 16 bits

		SpiaRegs.SPITXBUF = m4;													// Tx spi msb
		SpiaRegs.SPITXBUF = m3;													// Tx spi lsb
		SpiaRegs.SPITXBUF = m2;													// Tx spi msb
		SpiaRegs.SPITXBUF = m1;													// Tx spi lsb
		while(SpiaRegs.SPIFFRX.bit.RXFFINT !=1){}								// wait for Rx flag

		for (i=0;i<8;i++){asm(" NOP");}
	}

	GpioDataRegs.GPCSET.bit.GPIO71 			= 1;							// 1 forces GPIO71 (CS_NMR) to Hi
}



void StartNMRASIC_SEQ(void)
{
    // Enable NMR chip and the sequence will start running right away
     GpioDataRegs.GPCSET.bit.GPIO65 		= 1;							// 1 = sets output Hi for GPIO65 uC_EN_ASIC_3V3
}

void StopNMRASIC_SEQ(void)
{
    // Disable NMR chip to stop the seq
	GpioDataRegs.GPCCLEAR.bit.GPIO65 		= 1;							// 1 = sets output Lo for GPIO65 uC_EN_ASIC_3V3
}

/*ASIC Gain Setting */

/* ASIC Gain Struct, bit definitions */
struct ASICGAIN_BITS { 														// bits		description
	Uint16	gain0 : 1;														// 0		assigned to gpio64
	Uint16	gain1 : 1;														// 1		assigned to gpio67
	Uint16	gain2 : 1;														// 2		assigned to gpio69
	Uint16	gain3 : 1;														// 3		assigned to gpio62
	Uint16	rsvd  : 12;														// 4-15 	reserved
};

/* Union of ASICGAIN_REG and ASICGAIN_BITS  */
union ASICGAIN_REG {
	Uint16					all;											// union member
	struct ASICGAIN_BITS 	bit;											// union variable
};

void AsicGainCtrl (int gain)
{
	union ASICGAIN_REG gainFlags;											// gainFlags is union ASICGAIN_REG's variable
	gainFlags.all = gain;

	EALLOW;
	//GpioDataRegs.GPCDAT.bit.GPIO64 = gainFlags.bit.gain0;
	// if statements below are in a more robust format
	if (gainFlags.bit.gain0)
	{
		GpioDataRegs.GPCSET.bit.GPIO64 = 1;
	}
	else
	{
		GpioDataRegs.GPCCLEAR.bit.GPIO64 = 1;
	}

	if (gainFlags.bit.gain1)
	{
		GpioDataRegs.GPCSET.bit.GPIO67 = 1;
	}
	else
	{
		GpioDataRegs.GPCCLEAR.bit.GPIO67 = 1;
	}

	if (gainFlags.bit.gain2)
	{
		GpioDataRegs.GPCSET.bit.GPIO69 = 1;
	}
	else
	{
		GpioDataRegs.GPCCLEAR.bit.GPIO69 = 1;
	}

	if (gainFlags.bit.gain3)
	{
		GpioDataRegs.GPBSET.bit.GPIO62 = 1;
	}
	else
	{
		GpioDataRegs.GPBCLEAR.bit.GPIO62 = 1;
	}
	EDIS;
}

// read the status of the SW_ACQ pin of ASIC
// High when the pulse sequence output data
// GPIO70 is defined as an input in gpio_init.c

// YS Jan 2017
Uint16 mReadNMR_ACQ(void)
{
	return (GpioDataRegs.GPCDAT.bit.GPIO70 == 1);

}




/*
 * need the following functions (YS aug 18. 2016)
 *
 * 1. trigger ADC to acquire data, GPIO0 go high and then low
 * then read from ADC, 32 bit read, two 16-bit words for the two ADC. The ADC is 14 bits.		-- Good, feb 1, 2017
 *
 * 2. Read the status of the SW_ACQ pin from ASIC. move to asic.c								-- Good, feb 1, 2017, pin GPIO70
 */



// ADC YS 2017.1.23
// need to work on this. YS dec 18.
// put inside the data reading, SPIRead32bitWordFromADC
Uint16 trigger_ADC_sample()
{
	int i;

	// GPIO0, uC CLK ADC 3V3
	GpioDataRegs.GPACLEAR.bit.GPIO0 		= 1;				// uC CLK ADC 3V3, set to low
	for (i=0;i<2;i++){asm(" NOP");}

	GpioDataRegs.GPASET.bit.GPIO0 		= 1;				// set to high for a moment

	for (i=0;i<3;i++){asm(" NOP");}
	GpioDataRegs.GPACLEAR.bit.GPIO0 		= 1;				// uC CLK ADC 3V3, set to low

	return 1;
}



Uint32 SPIRead32bitWordFromADC()
{
	Uint32 i;												// 0, 0 all transmit's on rising edge. Inactive lo
	Uint32 data;
	Uint32 x1, x2;

	// GPIO0, uC CLK ADC 3V3. This is the conversion trigger for ADC.
	GpioDataRegs.GPACLEAR.bit.GPIO0 		= 1;				// uC CLK ADC 3V3, set to low
	GpioCtrlRegs.GPAPUD.bit.GPIO0 			= 0;			// pull-up enabled


	// read SPI bus to get a 32-bit word, or two 16-bits words
	//EALLOW;
	// David uses 0, 1. Try others
	// According to NMR4YD, 1407A expect falling edge
	SpiaRegs.SPICCR.bit.CLKPOLARITY		= 0;				// 0, 1 all transmit's on rising edge delayed by 1/2 clk. Inactive lo   0 1
	SpiaRegs.SPICTL.bit.CLK_PHASE 		= 1;				// 1, 0 all transmit's on falling edge. Inactive Hi 1 0
														// 1, 1 all transmit's on falling edge delayed by 1/2 clk. Inactive Hi
	// try to enable this pull-up.
	GpioCtrlRegs.GPBPUD.bit.GPIO55 		= 0;	   			// disable (1) pull-up for GPIO55 SPI_MISOA, enable (0)

	SpiaRegs.SPICCR.bit.SPICHAR 		= 0x0F;				// 16 bit word length
	SpiaRegs.SPIFFRX.bit.RXFFIL			= 2;				// number states how many words fill FIFO, YS. 2 should be good.
	SpiaRegs.SPIFFRX.bit.RXFIFORESET 	= 0;				// 0 to reset the FIFO and hold in reset
	SpiaRegs.SPIFFRX.bit.RXFIFORESET 	= 1;				// 1 to Re-enable FIFO
	SpiaRegs.SPIFFRX.bit.RXFFINTCLR 	= 1;				// 1 to clear fag of RXFIFORESET
	//EDIS;

	//trigger_ADC_sample();

	GpioDataRegs.GPASET.bit.GPIO0 		= 1;				// set to high for a moment to trigger ADC conversion.

	for (i=0;i<3;i++){asm(" NOP");}
	GpioDataRegs.GPACLEAR.bit.GPIO0 		= 1;				// uC CLK ADC 3V3, set to low
	for (i=0;i<2;i++){asm(" NOP");}

	// does not matter what the values are transmitted.
	SpiaRegs.SPITXBUF = 0x00F0;
	SpiaRegs.SPITXBUF = 0x0F00;

	while(SpiaRegs.SPIFFRX.bit.RXFFINT != 1){}				// while RXFFINT FIFO interupt bit !=1, wait

	//data = (Uint32)(SpiaRegs.SPIRXBUF) << 16;
	//data += SpiaRegs.SPIRXBUF;
	x1 = (Uint32)SpiaRegs.SPIRXBUF;
	x2 = (Uint32)SpiaRegs.SPIRXBUF;

	// somehow the read data is off by one bit.
	// The data seems to require 33 bits to read all.
	data = (Uint32)  ((x1 & 0x0000FFFF) << 16);
	data += (Uint32) ((x2 & 0x0000FFFF) );

	data = data <<1;

	GpioCtrlRegs.GPAPUD.bit.GPIO0 			= 1;			// disable pull-up
	return (data);
}

// Same function as SPIRead32bitWordFromADC(), but remove a few lines for SPI configuration
// to speed up the acquisition
// Need to run the below right before data reading:
// configure_SPI(0, 1, 15, 2, 3); //, Uint16 PHA, Uint16 BITS, Uint16 nFIFO, Uint16 ClkSpeedDiv)
// ClkSpeedDiv = 3 => 18.5 MHz spi clock.
// Fastest dwell is 4 us.
//
Uint32 SPIRead32bitWordFromADCFast()
{
	Uint32 i;												// 0, 0 all transmit's on rising edge. Inactive lo
	Uint32 data;
	Uint32 x1, x2;

	// GPIO0, uC CLK ADC 3V3. This is the conversion trigger for ADC.
//	GpioDataRegs.GPACLEAR.bit.GPIO0 		= 1;				// uC CLK ADC 3V3, set to low
//	GpioCtrlRegs.GPAPUD.bit.GPIO0 			= 0;			// pull-up enabled


	// read SPI bus to get a 32-bit word, or two 16-bits words
	//EALLOW;
	// David uses 0, 1. Try others
	// According to NMR4YD, 1407A expect falling edge


//	SpiaRegs.SPICCR.bit.CLKPOLARITY		= 0;				// 0, 1 all transmit's on rising edge delayed by 1/2 clk. Inactive lo   0 1
//	SpiaRegs.SPICTL.bit.CLK_PHASE 		= 1;				// 1, 0 all transmit's on falling edge. Inactive Hi 1 0
														// 1, 1 all transmit's on falling edge delayed by 1/2 clk. Inactive Hi
	// try to enable this pull-up.
//	GpioCtrlRegs.GPBPUD.bit.GPIO55 		= 0;	   			// disable (1) pull-up for GPIO55 SPI_MISOA, enable (0)

//	SpiaRegs.SPICCR.bit.SPICHAR 		= 0x0F;				// 16 bit word length

//	SpiaRegs.SPIFFRX.bit.RXFFIL			= 2;				// number states how many words fill FIFO, YS. 2 should be good.


	// These are needed to reset the FIFO
//	SpiaRegs.SPIFFRX.bit.RXFIFORESET 	= 0;				// 0 to reset the FIFO and hold in reset
//	SpiaRegs.SPIFFRX.bit.RXFIFORESET 	= 1;				// 1 to Re-enable FIFO
//	SpiaRegs.SPIFFRX.bit.RXFFINTCLR 	= 1;				// 1 to clear fag of RXFIFORESET
	//EDIS;

	//trigger_ADC_sample();

	GpioDataRegs.GPASET.bit.GPIO0 		= 1;				// set to high for a moment to trigger ADC conversion.

	for (i=0;i<1;i++){asm(" NOP");}
	GpioDataRegs.GPACLEAR.bit.GPIO0 		= 1;				// uC CLK ADC 3V3, set to low
//	for (i=0;i<1;i++){asm(" NOP");}

	// does not matter what the values are transmitted.
	SpiaRegs.SPITXBUF = 0x0055;
	SpiaRegs.SPITXBUF = 0x5500;

	while(SpiaRegs.SPIFFRX.bit.RXFFINT != 1){}				// while RXFFINT FIFO interupt bit !=1, wait

	data = (Uint32)(SpiaRegs.SPIRXBUF) << 17;
	data += (Uint32)(SpiaRegs.SPIRXBUF<<1);

	// somehow the read data is off by one bit.
	// The data seems to require 33 bits to read all.
	// data = data <<1;

//	GpioCtrlRegs.GPAPUD.bit.GPIO0 			= 1;			// disable pull-up
	return (data);
}


