/*
 * cpu_timer.c
 *
 *  Created on: Aug 25, 2016
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

#include "DSP28x_Project.h"									// Device Headerfile and Examples Include File

void delay_loop();


interrupt void cpu_timer0_isr(void)							// Used to test timer functionality on GPIO31
{
/*
	CpuTimer0.InterruptCount++;
	GpioDataRegs.GPADAT.bit.GPIO31 = 1; // Sets the GPIO31 to high once per interrupt for the time t provided by delay loop.
	delay_loop();
	GpioDataRegs.GPADAT.bit.GPIO31 = 0;// clears the GPIO31 to low once per interrupt after delay loop is over and stays there till interrupt is encountered again.

	PieCtrlRegs.PIEACK.all = PIEACK_GROUP1;// Acknowledge this interrupt to receive more interrupts from group 1
*/
}

