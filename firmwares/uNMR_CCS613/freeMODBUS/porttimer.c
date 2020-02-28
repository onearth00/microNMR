/*
 * FreeModbus Libary: BARE Port
 * Copyright (C) 2006 Christian Walter <wolti@sil.at>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *
 * File: $Id: porttimer.c,v 1.1 2006/08/22 21:35:13 wolti Exp $
 */

#include "port.h"
#include "DSP28x_Project.h"     // Device Headerfile and Examples Include File

/* ----------------------- Modbus includes ----------------------------------*/
#include "mb.h"
#include "mbport.h"

const ULONG TimerTicksPer50us=7500;

interrupt void cpu_timer1_isr(void);

/* ----------------------- Scheduler includes ----------------------------------*/
//#include "FreeRTOS.h"
//#include "task.h"

/* ----------------------- static functions ---------------------------------*/

/* ----------------------- Start implementation -----------------------------*/
BOOL
xMBPortTimersInit( USHORT usTim1Timerout50us )
{
    ENTER_CRITICAL_SECTION( );
    // Setup Timer1 for modbus RTU timing
    StopCpuTimer1();
    //TIMER_stop(myTimer1);
    CpuTimer1Regs.TPR.bit.PSC=0;
    CpuTimer1Regs.TPR.bit.TDDR=0;
    //TIMER_setDecimationFactor(myTimer1, 0);
    CpuTimer1Regs.PRD.all=usTim1Timerout50us*TimerTicksPer50us;
    //TIMER_setPeriod(myTimer1, usTim1Timerout50us*TimerTicksPer50us);
    ReloadCpuTimer1();
    //TIMER_reload(myTimer1);
    CpuTimer1Regs.TCR.bit.FREE = 0;
    CpuTimer1Regs.TCR.bit.SOFT = 0;
    //TIMER_setEmulationMode(myTimer1, TIMER_EmulationMode_StopAfterNextDecrement);
    CpuTimer1Regs.TCR.bit.TIE = 1;
    //TIMER_enableInt(myTimer1);
    // Interrupts that are used in this example are re-mapped to
    // ISR functions found within this file.
       EALLOW;  // This is needed to write to EALLOW protected registers
       PieVectTable.XINT13 = &cpu_timer1_isr;
       EDIS;    // This is needed to disable write to EALLOW protected registers
    //PIE_registerSystemIntHandler(myPie, PIE_SystemInterrupts_TINT1, (intVec_t)&cpu_timer1_isr);
       IER |= M_INT13;
    //CPU_enableInt(myCpu, CPU_IntNumber_13); //timer 1
    EXIT_CRITICAL_SECTION( );
    return TRUE;
}


void vMBPortTimersEnable( void )
{
	StartCpuTimer1();
	//TIMER_start(myTimer1);
	ReloadCpuTimer1();
	//TIMER_reload(myTimer1);
}

void vMBPortTimersDisable( void )
{
	StopCpuTimer1();
	//TIMER_stop(myTimer1);
    /* Disable any pending timers. */
}

/* Create an ISR which is called whenever the timer has expired. This function
 * must then call pxMBPortCBTimerExpired( ) to notify the protocol stack that
 * the timer has expired.
 */
interrupt void cpu_timer1_isr(void)
{
    pxMBPortCBTimerExpired(  );
}

