/*
 * tempcontoller.c
 *
 *  Created on: Feb 19, 2017
 *      Author: ysong
 */

/*
 *
 *      Try the code the temperature sensor controller, ADS1248
 *
 */

#include <gpio_init.h>
#include <math.h>
#include "typeDefs.h"														// Type definitions
#include "DSP28x_Project.h"													// Device Headerfile and Examples Include File
//#include "RunNMR.h"




float ADS1248_init();

// local
void configure_SPI(Uint16 POL, Uint16 PHA, Uint16 BITS_per_word, Uint16 nWORD, Uint16 BusSpeed);


// Note from ADS1248

/*
Power up;
Delay for a minimum of 16 ms to allow power supplies to settle and power-on reset to complete; Enable the device by setting the START pin high;
Configure the serial interface of the microcontroller to SPI mode 1 (CPOL = 0, CPHA =1);
If the CS pin is not tied low permanently, configure the microcontroller GPIO connected to CS as an output;
Configure the microcontroller GPIO connected to the DRDY pin as a falling edge triggered interrupt input;
Set CS to the device low;
Delay for a minimum of tCSSC;
Send the RESET command (06h) to make sure the device is properly reset after power up;
Delay for a minimum of 0.6 ms;
Send SDATAC command (16h) to prevent the new data from interrupting data or register transactions;
Write the respective register configuration with the WREG command (40h, 03h, 01h, 00h, 03h and 42h);
As an optional sanity check, read back all configuration registers with the RREG command (four bytes from 20h, 03h);
Send the SYNC command (04h) to start the ADC conversion;
Delay for a minimum of tSCCS;
Clear CS to high (resets the serial interface);
Loop
{
Wait for DRDY to transition low;
Take CS low;
Delay for a minimum of tCSSC;
Send the RDATA command (12h);
Send 24 SCLKs to read out conversion data on DOUT/DRDY; Delay for a minimum of tSCCS;
      Clear CS to high;
  }
Take CS low;
Delay for a minimum of tCSSC;
Send the SLEEP command (02h) to stop conversions and put the device in power-down mode;
*/


// initialize and read the onchip diode as temp
// Typically, the difference in diode voltage is 118 mV at TA = 25°C with a temperature coefficient of 0.405 mV/°C.
//

float ADS1248_init_2()
{
	int i,k;
	Uint16 a1, a2, a3, a4;
	long Temp_read;

	a1 = a2 = a3 = a4 = 0;
	//
	// CS pin for ADS1248, gpio74 is set in gpio_init;
	GpioDataRegs.GPCSET.bit.GPIO74 			= 1;

	// POL=0, PHA=1, 8-bits word, 1 FIFO reg, speed-not used
	// ClkSpeedDiv set to 100 to slow down the spi clk from system clock of 75 MHz (not the CPU clock of 150MHz)
	configure_SPI(0,1, 7, 1, 74);		// baud rate = 1MHz


	//DRDY pin is wired to GPIO59, to read,

    GpioCtrlRegs.GPBPUD.bit.GPIO59 			= 0;	   						// pull-up, 0 = enabled
	GpioCtrlRegs.GPBMUX2.bit.GPIO59 		= 0;         					// use as 0 = GPIO
	GpioCtrlRegs.GPBDIR.bit.GPIO59 			= 0;          					// 0 = input, 1=output

	//check what is at gpio59
	k = GpioDataRegs.GPBDAT.bit.GPIO59;

//	Set CS to the device low;
	GpioDataRegs.GPCCLEAR.bit.GPIO74 			= 1;

//	Delay for a minimum of tCSSC;
	for (i=0;i<10;i++){asm(" NOP");}

//	Send the wake up command (00h)
	// SPITXBUF is 16 bits, top 8 bits for the 8-bit word
	SpiaRegs.SPITXBUF = 0x00 << 8;
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	for (i=0;i<10;i++){asm(" NOP");}										// recommended delay

	DELAY_US(1000);

//	Send the RESET command (06h) to make sure the device is properly reset after power up;
	// SPITXBUF is 16 bits, top 8 bits for the 8-bit word
	SpiaRegs.SPITXBUF = 0x06 << 8;
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	for (i=0;i<10;i++){asm(" NOP");}										// recommended delay

	// delay a min of 600 us
	DELAY_US(1000);

	//CONFIGURation
/*	Send SDATAC command (16h) to prevent the new data from interrupting data or register transactions;
 *
*  Write the respective register configuration with the WREG command (40h, 03h, 01h, 00h, 03h and 42h);
*  As an optional sanity check, read back all configuration registers with the RREG command (four bytes from 20h, 03h);
*/
//	send sdatac

	SpiaRegs.SPITXBUF = 0x16 << 8;												// SDATAC command
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	for (i=0;i<10;i++){asm(" NOP");}
	DELAY_US(10);

	// send configurations
	SpiaRegs.SPITXBUF = 0x40 << 8;												// Write reg command
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	for (i=0;i<10;i++){asm(" NOP");}
	DELAY_US(10);

	SpiaRegs.SPITXBUF = 0x00 << 8;												// number of reguster to write to minus 1
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	for (i=0;i<10;i++){asm(" NOP");}
	DELAY_US(10);

	SpiaRegs.SPITXBUF = 0x01 << 8;												// Burn-out Current Source, 01=> current source off
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	for (i=0;i<10;i++){asm(" NOP");}
	DELAY_US(10);

/*	SpiaRegs.SPITXBUF = 0x00 << 8;												// VBIAS, not enabled
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	for (i=0;i<10;i++){asm(" NOP");}
	DELAY_US(10);

	SpiaRegs.SPITXBUF = 0x03 << 8;												// MUX1 reg, 03 => temperature measurement diode ? maybe the onchip? Normal mode is 00h
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	for (i=0;i<10;i++){asm(" NOP");}
	DELAY_US(10);
*/
	SpiaRegs.SPITXBUF = 0x42 << 8;												// SYS0 reg, gain code 4=>16; DR code 2=>20 sps
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	for (i=0;i<10;i++){asm(" NOP");}
	DELAY_US(10);

	SpiaRegs.SPITXBUF = 0x00 << 8;												// read register command
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	for (i=0;i<10;i++){asm(" NOP");}
	DELAY_US(10);

	SpiaRegs.SPITXBUF = 0x33 << 8;												// the number of registers to read minus 1
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	for (i=0;i<10;i++){asm(" NOP");}
	DELAY_US(10);

	//SYS0
	SpiaRegs.SPITXBUF = 0x43 << 8;												// the number of registers to read minus 1
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	for (i=0;i<10;i++){asm(" NOP");}
	DELAY_US(10);

	SpiaRegs.SPITXBUF = 0x00 << 8;												// the number of registers to read minus 1
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	for (i=0;i<10;i++){asm(" NOP");}
	DELAY_US(10);

	SpiaRegs.SPITXBUF = 0x52 << 8;												// the number of registers to read minus 1
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	for (i=0;i<10;i++){asm(" NOP");}
	DELAY_US(10);

	//IDAC0
	SpiaRegs.SPITXBUF = 0x4A << 8;												// the number of registers to read minus 1
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	for (i=0;i<10;i++){asm(" NOP");}
	DELAY_US(10);

	SpiaRegs.SPITXBUF = 0x00 << 8;												// the number of registers to read minus 1
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	for (i=0;i<10;i++){asm(" NOP");}
	DELAY_US(10);

	SpiaRegs.SPITXBUF = 0x07 << 8;												// the number of registers to read minus 1
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	for (i=0;i<10;i++){asm(" NOP");}
	DELAY_US(10);

	//idac1
	SpiaRegs.SPITXBUF = 0x4b << 8;												// the number of registers to read minus 1
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	for (i=0;i<10;i++){asm(" NOP");}
	DELAY_US(10);

	SpiaRegs.SPITXBUF = 0x00 << 8;												// the number of registers to read minus 1
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	for (i=0;i<10;i++){asm(" NOP");}
	DELAY_US(10);

	SpiaRegs.SPITXBUF = 0x01 << 8;												// the number of registers to read minus 1
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	for (i=0;i<10;i++){asm(" NOP");}
	DELAY_US(10);

	// finish setup

	// read some data back.
	// read back four registers
	SpiaRegs.SPITXBUF = 0x20 << 8;												// read register command
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	for (i=0;i<10;i++){asm(" NOP");}
	DELAY_US(10);

	SpiaRegs.SPITXBUF = 0x03 << 8;												// the number of registers to read minus 1
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	for (i=0;i<10;i++){asm(" NOP");}
	DELAY_US(10);

	// reset the buffer for read. YS 3.7.2017
	SpiaRegs.SPIFFRX.bit.RXFIFORESET 		= 0;							// 0 to reset the FIFO and hold in reset
	SpiaRegs.SPIFFRX.bit.RXFIFORESET 		= 1;							// 1 to Re-enable FIFO
	SpiaRegs.SPIFFRX.bit.RXFFINTCLR 		= 1;							// 1 to clear fag of RXFIFORESET

	// read the four bytes coming back
	SpiaRegs.SPITXBUF = 0xFF << 8;												// send NOP
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	a1 =SpiaRegs.SPIRXBUF;
	for (i=0;i<10;i++){asm(" NOP");}
	DELAY_US(10);

	SpiaRegs.SPITXBUF = 0xFF << 8;
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	a2 =SpiaRegs.SPIRXBUF;
	for (i=0;i<10;i++){asm(" NOP");}
	DELAY_US(10);

	SpiaRegs.SPITXBUF = 0xFF << 8;
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	a3 =SpiaRegs.SPIRXBUF;
	for (i=0;i<10;i++){asm(" NOP");}
	DELAY_US(10);

	SpiaRegs.SPITXBUF = 0xFF << 8;
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	a4 =SpiaRegs.SPIRXBUF;
	DELAY_US(10);

	// may compare a1-a4 with the downloaded values
	//
	for (i=0;i<10;i++){asm(" NOP");}										// recommended delay

	// check to see if the reg are set right
	if (!( (a1 == 0x01) && (a2 ==0x00) && (a3==0x03) && (a4==0x42)))
		return (0.123);
	// CS goes high
//	GpioDataRegs.GPCSET.bit.GPIO74 			= 1;
	// end of the initialization


/*
 * Loop
{
Wait for DRDY to transition low;
Take CS low;
Delay for a minimum of tCSSC;
Send the RDATA command (12h);
Send 24 SCLKs to read out conversion data on DOUT/DRDY;
Delay for a minimum of tSCCS;
      Clear CS to high;
  }
 *
 *
 */

	//RRDY is gpio59
	while (GpioDataRegs.GPBDAT.bit.GPIO59 == 1) {};
	//CS goes low
	GpioDataRegs.GPCCLEAR.bit.GPIO74 			= 1;

	for (i=0;i<10;i++){asm(" NOP");}										// delay

	//spi commands, RDATA
	SpiaRegs.SPITXBUF = 0x23 << 8;												// read command, 1=> read,
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait

	SpiaRegs.SPITXBUF = 0xFF << 8;
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	a1 = SpiaRegs.SPIRXBUF;

	SpiaRegs.SPITXBUF = 0xFF << 8;
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	a2 = SpiaRegs.SPIRXBUF;

	SpiaRegs.SPITXBUF = 0xFF << 8;
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	a3 = SpiaRegs.SPIRXBUF;


	for (i=0;i<5;i++){asm(" NOP");}
	GpioDataRegs.GPCSET.bit.GPIO74 			= 1;


	Temp_read =  (long) (a1<<24 + a2 <<16 + a3 <<8);							// tempearture is 2s compliment

	for (i=0;i<5;i++){asm(" NOP");}

	/*
	Take CS low;
	Delay for a minimum of tCSSC;
	Send the SLEEP command (02h) to stop conversions and put the device in power-down mode;
*/

	GpioDataRegs.GPCCLEAR.bit.GPIO74 			= 1;
	for (i=0;i<5;i++){asm(" NOP");}

	SpiaRegs.SPITXBUF = 0x02 << 8;
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait

	return ((float)Temp_read/256.);

}
//
// first example from the manual. does not work. mar 2.
// march 8. MCC fixed the reset pullup.

float ADS1248_init()
{
	int i,k;
	Uint32 a1, a2, a3, a4;
	long Temp_read;

	a1 = a2 = a3 = a4 = 1;
	//
	// CS pin for ADS1248, gpio74 is set in gpio_init;
	GpioDataRegs.GPCSET.bit.GPIO74 			= 1;


/*
// init spi
	SpiaRegs.SPICCR.bit.CLKPOLARITY			= 0;							// 0, 1 all transmit's on rising edge delayed by 1/2 clk. Inactive lo   0 1
	SpiaRegs.SPICTL.bit.CLK_PHASE 			= 1;							// 1, 0 all transmit's on falling edge. Inactive Hi 1 0
																			// 1, 1 all transmit's on falling edge delayed by 1/2 clk. Inactive Hi
	for (i=0;i<2;i++){asm(" NOP");}										// NOP gives setup time to CLKPOLARITY and PHASE
	GpioDataRegs.GPCCLEAR.bit.GPIO75 		= 1;							// CS active low
	GpioCtrlRegs.GPBPUD.bit.GPIO55 			= 1;	   						// disable pull-up for GPIO55 SPI_MISOA
	SpiaRegs.SPICCR.bit.SPICHAR 			= 0x07;							// 8 bit word length
	SpiaRegs.SPIFFRX.bit.RXFFIL				= 1;							// number states how many words fill FIFO,
																		// some commands are 1-2 byte, data is 3 bytes
	SpiaRegs.SPIFFRX.bit.RXFIFORESET 		= 0;							// 0 to reset the FIFO and hold in reset
	SpiaRegs.SPIFFRX.bit.RXFIFORESET 		= 1;							// 1 to Re-enable FIFO
	SpiaRegs.SPIFFRX.bit.RXFFINTCLR 		= 1;							// 1 to clear fag of RXFIFORESET
*/

	// POL=0, PHA=1, 8-bits word, 1 FIFO reg, speed-not used
	// ClkSpeedDiv set to 100 to slow down the spi clk from system clock of 75 MHz (not the CPU clock of 150MHz)
	// tested the spi mode: 0/0 seems to get the right number.
	configure_SPI(0, 0, 7, 1, 74);		// baud rate = 1MHz


	//DRDY pin is wired to GPIO59, to read,

    GpioCtrlRegs.GPBPUD.bit.GPIO59 			= 0;	   						// pull-up, 0 = enabled
	GpioCtrlRegs.GPBMUX2.bit.GPIO59 		= 0;         					// use as 0 = GPIO
	GpioCtrlRegs.GPBDIR.bit.GPIO59 			= 0;          					// 0 = input, 1=output

	//check what is at gpio59
	k = GpioDataRegs.GPBDAT.bit.GPIO59;

//	Set CS to the device low;
	GpioDataRegs.GPCCLEAR.bit.GPIO74 			= 1;

//	Delay for a minimum of tCSSC;
	for (i=0;i<10;i++){asm(" NOP");}

//	Send the wake up command (00h)
	// SPITXBUF is 16 bits, top 8 bits for the 8-bit word
	SpiaRegs.SPITXBUF = 0x00 << 8;
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	for (i=0;i<10;i++){asm(" NOP");}										// recommended delay

	DELAY_US(1000);

//	Send the RESET command (06h) to make sure the device is properly reset after power up;
	// SPITXBUF is 16 bits, top 8 bits for the 8-bit word
	SpiaRegs.SPITXBUF = 0x06 << 8;
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	for (i=0;i<10;i++){asm(" NOP");}										// recommended delay

	// delay a min of 600 us
	DELAY_US(1000);

	//CONFIGURation
/*	Send SDATAC command (16h) to prevent the new data from interrupting data or register transactions;
 *
*  Write the respective register configuration with the WREG command (40h, 03h, 01h, 00h, 03h and 42h);
*  As an optional sanity check, read back all configuration registers with the RREG command (four bytes from 20h, 03h);
*/
//	send sdatac

	SpiaRegs.SPITXBUF = 0x16 << 8;												// SDATAC command
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	for (i=0;i<10;i++){asm(" NOP");}
	DELAY_US(10);

	// send configurations
	SpiaRegs.SPITXBUF = 0x40 << 8;											// Write reg command, format: 0100 rrrr, r->starting reg
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	for (i=0;i<10;i++){asm(" NOP");}
	DELAY_US(10);

	SpiaRegs.SPITXBUF = 0x03 << 8;												// number of reguster to write to minus 1
	for (i=0;i<10;i++){asm(" NOP");}
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	//for (i=0;i<10;i++){asm(" NOP");}
	DELAY_US(10);

	SpiaRegs.SPITXBUF = 0x01 << 8;												// Burn-out Current Source, 01=> current source off
	for (i=0;i<10;i++){asm(" NOP");}
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	for (i=0;i<10;i++){asm(" NOP");}
	DELAY_US(10);

	SpiaRegs.SPITXBUF = 0x00 << 8;												// VBIAS, not enabled
	for (i=0;i<10;i++){asm(" NOP");}
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	//for (i=0;i<10;i++){asm(" NOP");}
	DELAY_US(10);

	SpiaRegs.SPITXBUF = 0x03 << 8;												// MUX1 reg, 03 => temperature measurement diode ? maybe the onchip? Normal mode is 00h
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	for (i=0;i<10;i++){asm(" NOP");}
	DELAY_US(10);

	SpiaRegs.SPITXBUF = 0x42 << 8;												// SYS0 reg, gain code 4=>16; DR code 2=>20 sps
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	for (i=0;i<10;i++){asm(" NOP");}
	DELAY_US(10);

// read back
	/*
	SpiaRegs.SPITXBUF = 0x20 << 8;												// read register command
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	for (i=0;i<10;i++){asm(" NOP");}
	DELAY_US(10);

	SpiaRegs.SPITXBUF = 0x03 << 8;												// the number of registers to read minus 1
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	for (i=0;i<10;i++){asm(" NOP");}
	DELAY_US(10);

	// reset fifo
	SpiaRegs.SPIFFRX.bit.RXFIFORESET 		= 0;							// 0 to reset the FIFO and hold in reset
	SpiaRegs.SPIFFRX.bit.RXFIFORESET 		= 1;							// 1 to Re-enable FIFO
	SpiaRegs.SPIFFRX.bit.RXFFINTCLR 		= 1;							// 1 to clear fag of RXFIFORESET
	for (i=0;i<10;i++){asm(" NOP");}

	// read the four bytes coming back
	SpiaRegs.SPITXBUF = 0xFF << 8;												// send NOP
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	a1 =SpiaRegs.SPIRXBUF;
	for (i=0;i<10;i++){asm(" NOP");}
	//DELAY_US(10);

	SpiaRegs.SPITXBUF = 0xFF << 8;
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	a2 =SpiaRegs.SPIRXBUF;
	for (i=0;i<10;i++){asm(" NOP");}
	//DELAY_US(10);

	SpiaRegs.SPITXBUF = 0xFF << 8;
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	a3 =SpiaRegs.SPIRXBUF;
	for (i=0;i<10;i++){asm(" NOP");}
	//DELAY_US(10);

	SpiaRegs.SPITXBUF = 0xFF << 8;
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	a4 =SpiaRegs.SPIRXBUF;
	//DELAY_US(10);
*/
	// may compare a1-a4 with the downloaded values
	//
	for (i=0;i<10;i++){asm(" NOP");}										// recommended delay

	// somehow does not read back well. But the MiSO bus see all the correct data.
	// move on for now. 3.8.2017
	// check to see if the reg are set right
//	if (!( (a1 == 0x01) && (a2 ==0x00) && (a3==0x03) && (a4==0x42)))
//		return (0.123);



//	Send the SYNC command (04h) to start the ADC conversion;
//	Delay for a minimum of tSCCS;
//	Clear CS to high (resets the serial interface);

	SpiaRegs.SPITXBUF = 0x04 << 8;
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	for (i=0;i<10;i++){asm(" NOP");}

	// CS goes high
	GpioDataRegs.GPCSET.bit.GPIO74 			= 1;
	// end of the initialization


/*
 * Loop
{
Wait for DRDY to transition low;
Take CS low;
Delay for a minimum of tCSSC;
Send the RDATA command (12h);
Send 24 SCLKs to read out conversion data on DOUT/DRDY;
Delay for a minimum of tSCCS;
      Clear CS to high;
  }
 *
 *
 */
	//RRDY is gpio59
	while (GpioDataRegs.GPBDAT.bit.GPIO59 == 1) {};
	//CS goes low
	GpioDataRegs.GPCCLEAR.bit.GPIO74 			= 1;

	for (i=0;i<10;i++){asm(" NOP");}										// delay

	//spi commands
	SpiaRegs.SPITXBUF = 0x12 << 8;												// read recent temp command, next 24 clocks read the data.
	//DELAY_US(10);
	// I dont think this line works to wait till the data is ready. YS
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait


	// reset fifo
	SpiaRegs.SPIFFRX.bit.RXFIFORESET 		= 0;							// 0 to reset the FIFO and hold in reset
	SpiaRegs.SPIFFRX.bit.RXFIFORESET 		= 1;							// 1 to Re-enable FIFO
	SpiaRegs.SPIFFRX.bit.RXFFINTCLR 		= 1;							// 1 to clear fag of RXFIFORESET
	for (i=0;i<10;i++){asm(" NOP");}

	SpiaRegs.SPITXBUF = 0xFF << 8;
	//DELAY_US(10);
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
//	while(SpiaRegs.SPISTS.bit.INT_FLAG 		== 0){}							// while RXFFINT FIFO interupt bit !=1, wait

	a1 = SpiaRegs.SPIRXBUF;


	for (i=0;i<10;i++){asm(" NOP");}

	SpiaRegs.SPITXBUF = 0xFF << 8;
	DELAY_US(10);
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	a2 = SpiaRegs.SPIRXBUF;
	for (i=0;i<10;i++){asm(" NOP");}

	SpiaRegs.SPITXBUF = 0xFF << 8;
	DELAY_US(10);
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
	a3 = SpiaRegs.SPIRXBUF;
	for (i=0;i<10;i++){asm(" NOP");}

	GpioDataRegs.GPCSET.bit.GPIO74 			= 1;

	Temp_read =  (long) ((a1<<16) + (a2 <<8) + (a3 <<0));							// tempearture is 2s compliment

	/*
	Take CS low;
	Delay for a minimum of tCSSC;
	Send the SLEEP command (02h) to stop conversions and put the device in power-down mode;
*/
	GpioDataRegs.GPCCLEAR.bit.GPIO74 			= 1;

	for (i=0;i<5;i++){asm(" NOP");}
	SpiaRegs.SPITXBUF = 0x02 << 8;
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait

	return ((float)Temp_read);

}



// read tempearture sensor
// local routines


// p : the list of bytes to be send
// nReg : the number of registers to send
// the CS should already be low.
void ADS1248_Configure(Uint16 nReg, Uint16 *p)
{
	int i;
	//	send sdatac
	SpiaRegs.SPITXBUF = 0x40 << 8;												// Write reg command
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait

	SpiaRegs.SPITXBUF = (nReg-1) << 8;												// number of reguster to write to minus 1
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait

	for (i=0;i<nReg;i++)
	{
		SpiaRegs.SPITXBUF = (p[i] & 0xFF) << 8;												// number of reguster to write to minus 1
		while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait
		for (i=0;i<2;i++){asm(" NOP");}
	}

}

void ADS1248_SendCommand_8bits(Uint16 command)
{
	//	send
	SpiaRegs.SPITXBUF = (command & 0xFF) << 8;								// Write thecommand
	while(SpiaRegs.SPIFFRX.bit.RXFFINT 		!= 1){}							// while RXFFINT FIFO interupt bit !=1, wait

}



float ADS1248_ReadTemp(int iSensor)
{
	// the register value for sensor 1 and 2
	Uint16 p1[] = {0x08, 0x00, 0x70, 0x22, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x06, 0x8C, 0x00, 0x00, 0x00};
	Uint16 p2[] = {0x1A, 0x00, 0x70, 0x22, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x06, 0x9A, 0x00, 0x00, 0x00};
	Uint16	nReg = 15;

	// init spi
// configure sensor
// read temp
	return(1.0);
}
