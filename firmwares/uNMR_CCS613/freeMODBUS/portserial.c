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
 * File: $Id: portserial.c,v 1.1 2006/08/22 21:35:13 wolti Exp $
 */

#include "port.h"
#include "DSP28x_Project.h"     // Device Headerfile and Examples Include File

/* ----------------------- Modbus includes ----------------------------------*/
#include "mb.h"
#include "mbport.h"

/* ----------------------- Scheduler includes ----------------------------------*/


interrupt void sciaRxIsr(void);
interrupt void sciaTxIsr(void);
inline BOOL SCI_isTxEmpty(void);

/* Macros to  Enable/Disable interrupts */
#define EnableIntU1RX                    SciaRegs.SCICTL2.bit.RXBKINTENA = 1
#define EnableIntU1TX                    SciaRegs.SCICTL2.bit.TXINTENA = 1

#define DisableIntU1RX                   SciaRegs.SCICTL2.bit.RXBKINTENA = 0
#define DisableIntU1TX                   SciaRegs.SCICTL2.bit.TXINTENA = 0

inline BOOL SCI_isTxEmpty(void)
{
    BOOL status;

    status = SciaRegs.SCICTL2.bit.TXEMPTY;

    return((BOOL)status);
} // end of SCI_isTxReady() function


/* ----------------------- Start implementation -----------------------------*/
void vMBPortSerialEnable( BOOL xRxEnable, BOOL xTxEnable )
{
    /* If xRXEnable enable serial receive interrupts. If xTxENable enable
     * transmitter empty interrupts.
     */
	if(xRxEnable == TRUE && xTxEnable == TRUE){
            // this should not be reached
            RECEIVE_ON_485( );
            EnableIntU1RX;
            EnableIntU1TX;
	}
	else if(xRxEnable == TRUE && xTxEnable == FALSE){
            RECEIVE_ON_485( );
            EnableIntU1RX;
            DisableIntU1TX;
	}
	else if(xRxEnable == FALSE && xTxEnable == TRUE){
            TRANSMIT_ON_485( );
            DisableIntU1RX;
            EnableIntU1TX;
            PieCtrlRegs.PIEIFR9.bit.INTx2 = 1; //manually trigger interrupt
	}
	else if(xRxEnable == FALSE && xTxEnable == FALSE){
            RECEIVE_ON_485( );
            DisableIntU1RX;
            DisableIntU1TX;
	}
}

void vMBPortSerialWaitForTXEnd()
{
	while (!SCI_isTxEmpty())
	{
		asm(" NOP");
	}
    // interrupt on emptying transmit buffer
}

BOOL xMBPortSerialInit( UCHAR ucPORT, ULONG ulBaudRate, UCHAR ucDataBits, eMBParity eParity )
{
    unsigned short BRG;
    ENTER_CRITICAL_SECTION( );
    SciaRegs.SCICCR.bit.STOPBITS = 0;
//    SCI_setNumStopBits(mySci, SCI_NumStopBits_One);
    SciaRegs.SCICCR.bit.SCICHAR = 7;
//    SCI_setCharLength(mySci, (SCI_CharLength_e)(ucDataBits-1));
    RECEIVE_ON_485( );
    switch (eParity)
    {
        case MB_PAR_NONE:
        	SciaRegs.SCICCR.bit.PARITYENA = 0;
//        	SCI_disableParity(mySci);
            break;
        case MB_PAR_EVEN:
        	SciaRegs.SCICCR.bit.PARITY = 1;
//            SCI_setParity(mySci,SCI_Parity_Even);
            SciaRegs.SCICCR.bit.PARITYENA = 1;
//            SCI_enableParity(mySci);
            break;
        case MB_PAR_ODD:
        	SciaRegs.SCICCR.bit.PARITY = 0;
//            SCI_setParity(mySci,SCI_Parity_Odd);
            SciaRegs.SCICCR.bit.PARITYENA = 1;
//            SCI_enableParity(mySci);
            break;
    }
    // interrupt on emptying transmit buffer

    //SciaRegs.SCIHBAUD    =0x0000;  // 19200 baud @LSPCLK = 37.5MHz.
    //SciaRegs.SCILBAUD    =0x00F3;

    BRG = configCPU_CLOCK_HZ/(8*ulBaudRate) - 1;			// configCPU_CLOCK_HZ = LSPCLK = LOSPCP = 75MHz see DSP2833x_SysCtrl.c
    SciaRegs.SCIHBAUD = ((Uint16)BRG >> 8);
    SciaRegs.SCILBAUD = BRG & 0xFF;
    //SCI_setBaudRate(mySci, (SCI_BaudRate_e)BRG);
    // enable TX, RX, internal SCICLK,
    // Disable RX ERR, SLEEP, TXWAKE
    SciaRegs.SCICTL1.bit.TXENA = 1;
//    SCI_enableTx(mySci);
    SciaRegs.SCICTL1.bit.RXENA = 1;
//    SCI_enableRx(mySci);
    EnableIntU1TX;
    EnableIntU1RX;
    SciaRegs.SCICTL1.bit.RXERRINTENA = 1;
//    SCI_enableRxErrorInt(mySci);

    //SCI_enableFifoEnh(mySci);
    //SCI_resetTxFifo(mySci);
    //SCI_clearTxFifoInt(mySci);
    //SCI_resetChannels(mySci);
    //SCI_setTxFifoIntLevel(mySci, SCI_FifoLevel_Empty);
    //SCI_enableTxFifoInt(mySci);


    //SCI_resetRxFifo(mySci);
    //SCI_clearRxFifoInt(mySci);
    //SCI_setRxFifoIntLevel(mySci, SCI_FifoLevel_1_Word);
    //SCI_enableRxFifoInt(mySci);
    // Interrupts that are used in this example are re-mapped to
    // ISR functions found within this file.
       EALLOW;	// This is needed to write to EALLOW protected registers
       PieVectTable.SCIRXINTA = &sciaRxIsr;
       PieVectTable.SCITXINTA = &sciaTxIsr;
       EDIS;   // This is needed to disable write to EALLOW protected registers
    //PIE_registerPieIntHandler(myPie, PIE_GroupNumber_9, PIE_SubGroupNumber_1, (intVec_t)&sciaRxIsr);
    //PIE_registerPieIntHandler(myPie, PIE_GroupNumber_9, PIE_SubGroupNumber_2, (intVec_t)&sciaTxIsr);
       // Enable interrupts required for this example
	  PieCtrlRegs.PIECTRL.bit.ENPIE = 1;   // Enable the PIE block
	  PieCtrlRegs.PIEIER9.bit.INTx1=1;     // PIE Group 9, int1
	  PieCtrlRegs.PIEIER9.bit.INTx2=1;     // PIE Group 9, INT2
	  IER|= M_INT9;	// Enable CPU INT
    //PIE_enableInt(myPie, PIE_GroupNumber_9, PIE_InterruptSource_SCIARX);
    //PIE_enableInt(myPie, PIE_GroupNumber_9, PIE_InterruptSource_SCIATX);
    //CPU_enableInt(myCpu, CPU_IntNumber_9);
    SciaRegs.SCICTL1.bit.SWRESET = 1;
    //SCI_enable(mySci);
    EXIT_CRITICAL_SECTION( );
    return TRUE;
}

BOOL
xMBPortSerialPutByte( CHAR ucByte )
{
    /* Put a byte in the UARTs transmit buffer. This function is called
     * by the protocol stack if pxMBFrameCBTransmitterEmpty( ) has been
     * called. */
	SciaRegs.SCITXBUF = ucByte;
    return TRUE;
}

BOOL
xMBPortSerialGetByte( CHAR * pucByte )
{
    /* Return the byte in the UARTs receive buffer. This function is called
     * by the protocol stack after pxMBFrameCBByteReceived( ) has been called.
     */
    *pucByte = SciaRegs.SCIRXBUF.all;
    return TRUE;
}

/* Create an interrupt handler for the transmit buffer empty interrupt
 * (or an equivalent) for your target processor. This function should then
 * call pxMBFrameCBTransmitterEmpty( ) which tells the protocol stack that
 * a new character can be sent. The protocol stack will then call
 * xMBPortSerialPutByte( ) to send the character.
 */


interrupt void sciaRxIsr(void)
{
	if (SciaRegs.SCIRXST.bit.RXERROR == 1)
	{
		SciaRegs.SCICTL1.bit.SWRESET = 0;
		SciaRegs.SCICTL1.bit.SWRESET = 1;
	}
	else
	{
	    pxMBFrameCBByteReceived(  );
	}
    // Issue PIE ack
	PieCtrlRegs.PIEACK.all|=0x100;       // Issue PIE ack

    return;
}

interrupt void sciaTxIsr(void)
{

    pxMBFrameCBTransmitterEmpty(  );
    // Issue PIE ack
    PieCtrlRegs.PIEACK.all|=0x100;       // Issue PIE ack
    return;
}

