//###########################################################################
//
// $TI Release: F2833x/F2823x Header Files and Peripheral Examples V141 $
// $Release Date: November  6, 2015 $
// $Copyright: Copyright (C) 2007-2015 Texas Instruments Incorporated -
//             http://www.ti.com/ ALL RIGHTS RESERVED $
//
//#############################################################################################
// Description:
//
//Note:- 	CPUTimer uses timer 1 for ModBus
//			FID working Sept 30th
//			file: svn://redwood.cambridge-us1089.slb.com/unmr
//			asic gain 0 through 15 via gain0,1,2,3
//			ADC now sending data. Next, tie it into Do_NMR_Experiment
//
// 12192106 Varying the number of sinusoid pulses on the signal generator is represented on python plots
//#############################################################################################
//
/*
 * Change Note: See also RunNMR.c
 * ******
 * Feb 3. YS. Use spi to get data from ADC. Add timer control. Set timer0 period=2,000,000,000 =>1sec.
 * Add Tuning seq, CPMG seq.
 * FID seq runs ok.
 * Add rs485 commands: 101 (nmr commands), 102, 103 (status, parameters), 104 (read data)
 * Add NMR parameter record,
 ********
 * Feb 4. Get cpmg work. then tuning
 * Feb 6. FID and CPMG working on simulated signals
 * feb 7. FID gets signal from magnet!
 */





//QMODbus RS486 Commands:
// Function code					Start Address		# of Coils 			Description
//	Read Holding 	Reg (0x03)			1					1					Firmware Version
//	Read Holding 	Reg (0x03)			2					1					Modbus comms test
//	Write Holding 	Reg (0x06)			3					1					SPI DAC LTC2630, write
//	Write Holding 	Reg (0x06)			4					1					SPI PLL HMC832, write single (not used)
//	Write Holding 	Reg (0x06)			5					1					SPI PLL default, write config & Fout
//	Read Holding 	Reg (0x03)			6					1					ADC[04] vtune, read
//	Read Holding 	Reg (0x03)			7					1					SPI Board Temp, read
//	Write Holding 	Reg (0x06)			8 					1					ASIC gain set, write
//										10-29				2					SPI PLL HMC832, read/write single


// #include header files
// #include "setup_adc.h															// ADC DMA Config
// #include "ttemp_board.h"															// Temp Sensor LM95071
// #include "ssetup_mcbsp.h"														// mcbsp setup
// #include <ddac.h>																// DAC LTC1407A
// #include <ssetup_adc.h>
// #include "blink.h"															// LED Blink

#include "mb.h"																	// Modbus
#include "port.h"																// Modbus
#include "asic.h"																// NMR ASIC
#include "main.h"																// Device specific header files
#include "gpio_init.h"															// gpio setup
#include "RunNMR.h"																// Run NMR measurements
#include "nmr.h"
#include "typeDefs.h"															// Type definitions
#include "DSP28x_Project.h"														// Device Headerfile and Examples Include File

// Timer prototype statements
__interrupt void cpu_timer0_isr(void);											// CPU timer 0 iterrupt service routine used for counter
__interrupt void cpu_timer2_isr(void);											// CPU timer 2 iterrupt service routine used for telemetry
__interrupt void epwm1_isr(void);												// EPWM1 iterrupt service routine for ePWM1A GPIO0, uC_CLK_CTRL
__interrupt void epwm2_isr(void);												// EPWM2 iterrupt service routine for ePWM2A GPIO2, uC_CLK_ADC
__interrupt void xint1_isr(void);												// external interrupt for ADC LTC1407A

// Prototype declarations
void led_blink_D42(void);															// Test function call to blink led
void spi_init(void);															// DAC SPI function call
void gpio_init(void);															// gpio config
void PLL_init(void);															// Default PLL configuration
void PLL_autocal(void);															// Not yet implimented
void spi_dac(Uint16 a);															// spi_mosi function with 1 byte prototype
//void ASIC_mosi(Uint16 msb, Uint16 lsb);											// spi_asic function with 2 byte prototype
void PLL_mosi(Uint16 msb, Uint16 lsb);											// spi_mosi function with 2 byte prototype
void PLL_write(Uint8 reg, Uint32 data);											// Single write to the PLL
void InitSysCtrl(void);															// Int system
void Do_NMR_experiments(int seqnum);											// takes NMR sequence number
void InitEPwm2 (void);															// Init GPIO2, uC_CLK_CTRL, 15MHz
void InitEPwm2Gpio(void);														// Init GPIO for EPwm
//void InitAsicGainCtrl (void);													// Init asic gain setting
void AsicGainCtrl (int gain);													// Init asic gain setting
void InitMcbspbGpio(void);														// init Mcbspb GPI0
void InitMcbspa16bit(void);														// init Mcbspb 16 bit

Uint32 spi_PLL_read(Uint8 reg);													// Single read of the PLL
Uint16 spi_temp_board();														// Single read of Temperature sensor

void magnet_temp_init(void);                                                                                                                                                                                                   // Default Magnet temp configuration
void magnet_temp_write(Uint8 reg, Uint8 data);                                                                                                                                                               // Write to configure magnet temp register
Uint8 magnet_reg_read(Uint8 reg);
Uint32 magnet_temp_read(Uint8 reg);                                                                                                                                                                               // Single write to the magnet temperature sensor
void magnet_temp_reset();
void magnet_temp_sync();
void magnet_temp_sdatac();

// Global variables
int asic_gain 							= 0x09;									// default asic gain
Uint16 j								= 0x00; 								// default value
Uint16 usAddress						= 0x00;									// default value

volatile Uint32 TSt1, TSt2, TSt3, On_Period, Off_Period, Period;				// for ePWM2A GPIO2
volatile Uint32 Xint1Count				= 0;									// counts number of ADC samples
const Uint16 FW_VERSION 				= 0x01;									// Revision identifier
const Uint8 MB_SLV_ID 					= 0x01;									// Slave ID
unsigned short usRegInputBuf 			= 0x00;									// Set usRegInputBuf = 0

// CPU Frequency setting
#if (CPU_FRQ_150MHZ)     														// Default 150 MHz SYSCLKOUT
#define ADC_MODCLK 0x3 															// HSPCLK = SYSCLKOUT/2*ADC_MODCLK2 = 150/(2*3)   = 25.0 MHz
#endif
#if (CPU_FRQ_100MHZ)     														// Default 100 MHz SYSCLKOUT
  #define ADC_MODCLK 0x2 														// HSPCLK = SYSCLKOUT/2*ADC_MODCLK2 = 100/(2*2)   = 25.0 MHz
#endif

// ADC init parameters
#define ADC_CKPS   0x1   														// ADC module clock = HSPCLK/2*ADC_CKPS   = 25.0MHz/(1*2) = 12.5MHz
#define ADC_SHCLK  0xf   														// S/H width in ADC module periods                        = 16 ADC clocks
#define AVG        1000  														// Average sample limit
#define ZOFFSET    0x00  														// Average Zero offset
#define BUF_SIZE   8    														// Sample buffer size

// DMA init parameters
#pragma DATA_SECTION(DMABuf1,"DMARAML4");										//
volatile Uint16 DMABuf1[40];													//
volatile Uint16 *DMADest;														//
volatile Uint16 *DMASource;														//
__interrupt void local_DINTCH1_ISR(void);										// PIE vector DMA CH1 (highest)

// These are defined by the linker (see F28335.cmd)
extern Uint16 RamfuncsLoadStart;     											// RAM memory location start
extern Uint16 RamfuncsLoadEnd;
extern Uint16 RamfuncsRunStart;
extern Uint16 RamfuncsLoadSize;

//extern Uint32 dataBuf_real [2600];
//extern Uint32 dataBuf_imag [2600];

// NMR related variables
typedef  struct
{short index,	// experiment index, used in Do_NMR_experiments(nextExpt.index);
	ndata,	// number of data points
	nscan,	// number of scans, not the same as NA in the pulse seq.
	done ,		// if the experiment is done
	ready2start ,	// experiment should start now
	read_index ;	// used during serial transfer.
} NMRvar;

NMRvar nextExpt;


// data buffers, defined in RunNMR.c
// defined in RunNMR.h
// #define dataBufferTD 1000

extern int16 	dataBuf_real[];
extern int16	dataBuf_imag[];
extern PlsSeq   gPulseSeq;

/*
 * Performing NMR experiments
 * Input:
 * Output: none. The status of the experiment should be recorded in nextExpt.
 */
void NMR_job();

void NMR_job()
{
	if ( (nextExpt.done == 0) && (nextExpt.ready2start == 1) )
		if ((nextExpt.index<255) && (nextExpt.nscan>0))
		{
			// CPU timer setting
			CpuTimer0Regs.PRD.all = 4000000000;	// This is the period to count down for timer0
			ReloadCpuTimer0() ;
			StartCpuTimer0();													// Start timer 0

			Do_NMR_experiments(nextExpt.index);

			StopCpuTimer0();
			//when the experiment is done
			nextExpt.done= 1;
			nextExpt.ready2start = 0;
			// nextExpt.ndata = GetAcqTD();         // error fixed nov 2019,
			nextExpt.ndata = GetNMRParameters(i_acquiredTD);
			nextExpt.nscan = 0;
			nextExpt.read_index = 0;
		}
}

void main(void)
{

   Uint16 i;

// Step 1. Initialize System Control:
// This is found in the DSP2833x_SysCtrl.c file.
   InitSysCtrl();

// Specific clock setting:
   EALLOW;
   SysCtrlRegs.HISPCP.all = ADC_MODCLK;											// HSPCLK = SYSCLKOUT/ADC_MODCLK
   EDIS;

#ifdef FLASH
// Copy time critical code and Flash setup code to RAM
// The  RamfuncsLoadStart, RamfuncsLoadEnd, and RamfuncsRunStart
// symbols are created by the linker. Refer to the linker files.
	memcpy(&RamfuncsRunStart, &RamfuncsLoadStart, (Uint32)&RamfuncsLoadSize);

// Call Flash Initialization to setup flash waitstates
// This function must reside in RAM
	InitFlash();	// Call the flash wrapper init function
#endif //(FLASH)

// Step 2. Initialize GPIO:
// This example function is found in the DSP2833x_Gpio.c file and
// illustrates how to set the GPIO to it's default state.
// These functions are found in the F2837xD_Gpio.c file.
	InitGpio();																	// initialize all gpio to default, inputs, SYSCLKOUT, Pullup
	gpio_init();																// initialize all gpio user defined
	InitEPwm2Gpio();															// initialize GPIO2 to ePWM2A, nmr asic CLK_CTRL

// Step 3. Clear all interrupts and initialize PIE vector table:

    DINT;																		// Disable CPU interrupts

// The default state is all PIE interrupts disabled and flags are cleared.
// This function is found in the DSP2833x_PieCtrl.c file.
    InitPieCtrl();																// Initialize the PIE control registers to default state.

// Disable CPU interrupts and clear all CPU interrupt flags:
    IER = 0x0000;																// Disables IER
    IFR = 0x0000; 																// Clears IFR


// This will populate the entire table, even if the interrupt
// is not used in this example.  This is useful for debug purposes.
// The shell ISR routines are found in DSP2833x_DefaultIsr.c.
// This function is found in DSP2833x_PieVect.c.
   InitPieVectTable();															// initialize the PIE vector table with pointers to the shell ISR

// Step 5. User specific code:

// Interrupts that are used in this example are re-mapped to
// ISR functions found within this file.
   EALLOW;																		// Allow access to EALLOW protected registers
   PieVectTable.DINTCH1					= &local_DINTCH1_ISR;					// DMA CH1 interrupt
   PieVectTable.EPWM1_INT 				= &epwm1_isr;							// group3 flag 1 interrupt for EPWM2A GPIO2, nmr asic CLK_CTRL
   PieVectTable.TINT0 					= &cpu_timer0_isr;						// interrupt for timer0, used for modbus 1sec delay
   PieVectTable.TINT2 					= &cpu_timer2_isr;						// interrupt for timer2, used for EPWM clocks

   EDIS;   																		// Disable access to EALLOW protected registers
   IER 									|= M_INT7 ;	            				// Enable IER INT7 (7.1 DMA Ch1)
   IER 									|= M_INT14; 							// Enable CPUINT2

   EALLOW;
   SysCtrlRegs.PCLKCR0.bit.TBCLKSYNC 	= 0;									// stops TBCLK within each ePWM module
   EDIS;

// Initialize Device Peripherals:
   InitAdc();  																	// init F28335 ADC
   InitEPwm2();																	// init nmr asic CLK_CTRL
   InitMcbspbGpio();															// init Mcbspb GPI0 port
   InitMcbspa16bit();															// init Mcbspb word size
   setup_McbspbSpi();															// init Mcbspb spi reg


   EALLOW;
   SysCtrlRegs.PCLKCR0.bit.TBCLKSYNC 	= 1;									// enables all ePWM module clocks
   EDIS;

   // Enable EPWM INTn in the PIE: Group 3 interrupt 1-3
   PieCtrlRegs.PIEIER3.bit.INTx1 		= 1;
   PieCtrlRegs.PIEIER3.bit.INTx2 		= 1;
   PieCtrlRegs.PIEIER3.bit.INTx3 		= 1;


   // Enable Xint1 in the PIE: Group 1 interrupt 4
   // Enable int1 which is connected to WAKEINT:
	PieCtrlRegs.PIECTRL.bit.ENPIE 		= 1;          							// Enable the PIE block
	IER |= M_INT1;                              								// Enable CPU int1

   CpuTimer0Regs.PRD.all 				= 0xFFFFFFFF;							// Counter period set to 32bits
   CpuTimer0Regs.TPR.all  				= 0x01;									// Set pre-scale counter to divide by 1 (SYSCLKOUT). Change it to 1 from 0 by Ray, 09/15/2017
   CpuTimer0Regs.TPRH.all  				= 0;

   // Initialize timer control register:
   CpuTimer0Regs.TCR.bit.TSS 			= 1;      								// 1 = Stop timer, 0 = Start/Restart Timer
   CpuTimer0Regs.TCR.bit.TRB			= 1;      								// 1 = reload timer
   CpuTimer0Regs.TCR.bit.SOFT 			= 1;									// Timer Free Run
   CpuTimer0Regs.TCR.bit.FREE 			= 1;     								// Timer Free Run
   CpuTimer0Regs.TCR.bit.TIE 			= 1;      								// 0 = Disable/ 1 = Enable Timer Interrupt
   StartCpuTimer0();															// Start Timer 0
   CpuTimer2Regs.PRD.all 				= 0xE4E1C0; 							// 100ms
   CpuTimer2Regs.TPR.all  				= 0;									// Set pre-scale counter to divide by 1 (SYSCLKOUT)
   CpuTimer2Regs.TPRH.all  				= 0;
   CpuTimer2Regs.TCR.bit.TSS 			= 1;      								// 1 = Stop timer, 0 = Start/Restart Timer
   CpuTimer2Regs.TCR.bit.TRB			= 1;      								// 1 = reload timer
   CpuTimer2Regs.TCR.bit.SOFT 			= 1;									// Timer Free Run
   CpuTimer2Regs.TCR.bit.FREE 			= 1;     								// Timer Free Run
   CpuTimer2Regs.TCR.bit.TIE 			= 0;      								// 0 = Disable/ 1 = Enable Timer Interrupt

// InitAdc();
// Specific ADC setup:
   AdcRegs.ADCTRL1.bit.ACQ_PS 			= ADC_SHCLK;							// This bit field controls the width of SOC pulse
   AdcRegs.ADCTRL3.bit.ADCCLKPS 		= ADC_CKPS;								// HSPCLK, is divided by 2*ADCCLKPS
   AdcRegs.ADCTRL1.bit.SEQ_CASC 		= 0;        							// 0 Non-Cascaded Mode
   AdcRegs.ADCTRL1.bit.CONT_RUN 		= 1;        							// Continuous run
   AdcRegs.ADCTRL1.bit.SEQ_OVRD 		= 1;        							// Wraparound occurs only at the end of the sequencer
   AdcRegs.ADCTRL2.bit.INT_ENA_SEQ1 	= 0x1;									// Interrupt request by INT_SEQ1 is enabled
   AdcRegs.ADCTRL2.bit.RST_SEQ1 		= 0x1;									// Immediately reset sequencer to state CONV00
   AdcRegs.ADCCHSELSEQ1.bit.CONV00 		= 0x0; 									// ADC Input Channel Select & Sequencing Control Registers A0
   AdcRegs.ADCCHSELSEQ1.bit.CONV01 		= 0x1;									// ADC Input Channel Select & Sequencing Control Registers A1
   AdcRegs.ADCCHSELSEQ1.bit.CONV02 		= 0x2;									// ADC Input Channel Select & Sequencing Control Registers A2
   AdcRegs.ADCCHSELSEQ1.bit.CONV03 		= 0x3;									// ADC Input Channel Select & Sequencing Control Registers A3
   AdcRegs.ADCCHSELSEQ2.bit.CONV04 		= 0x4;									// ADC Input Channel Select & Sequencing Control Registers A4
   AdcRegs.ADCCHSELSEQ2.bit.CONV05 		= 0x5;									// ADC Input Channel Select & Sequencing Control Registers A5
   AdcRegs.ADCCHSELSEQ2.bit.CONV06 		= 0x6;									// ADC Input Channel Select & Sequencing Control Registers A6
   AdcRegs.ADCCHSELSEQ2.bit.CONV07 		= 0x7;									// ADC Input Channel Select & Sequencing Control Registers B7
   AdcRegs.ADCMAXCONV.bit.MAX_CONV1 	= 7;   									// Set up ADC to perform 4 channels, X+1, conversions for every SOC

//Step 5. User specific code, enable interrupts:

   DMAInitialize();																// Initialize DMA

   for (i = 0; i < BUF_SIZE; i++)
   {
     DMABuf1[i] = 0;															// Clear DMA Table
   }

// Configure DMA Channels
   DMADest   = &DMABuf1[0];              										// Point DMA destination to the beginning of the array
   DMASource = &AdcMirror.ADCRESULT0;    										// Point DMA source to ADC result register base

   DMACH1AddrConfig(DMADest,DMASource);											// Point to beginning of destination buffer
																				// Point to beginning of source buffer

   DMACH1BurstConfig(7,1,1);													// 3- Number of words(X-1) x-ferred in a burst
																				// 1- Increment source addr between each word x-ferred
																				// 5- Increment dest addr between each word x-ferred

   DMACH1TransferConfig(0,0,0);													// 3- Number of bursts per transfer, X+1, DMA interrupt will occur after completed transfer
																				// 1- TRANSFER_STEP is ignored when WRAP occurs
																				// 0- TRANSFER_STEP is ignored when WRAP occurs

   DMACH1WrapConfig(0,0,0,0);													// 1- Wrap source address after N bursts
																				// 0- Step for source wrap
																				// 0- Wrap destination address after N bursts
																				// 1- Step for destination wrap

// Set up DMA MODE Register:
   EALLOW;
	DmaRegs.CH1.MODE.bit.PERINTSEL 		= 0x0001; 	    						// Passed DMA channel as peripheral interrupt source
	DmaRegs.CH1.MODE.bit.OVRINTE 		= 0x0000;       						// Enable/disable the overflow interrupt
	DmaRegs.CH1.MODE.bit.PERINTE 		= 0x0001;       						// Peripheral interrupt enable
	DmaRegs.CH1.MODE.bit.CHINTE 		= 0x0001;       						// Channel Interrupt to CPU enable
	DmaRegs.CH1.MODE.bit.ONESHOT 		= 0x0000;       						// Oneshot enable
	DmaRegs.CH1.MODE.bit.CONTINUOUS 	= 0x0001;     							// Continous enable
	DmaRegs.CH1.MODE.bit.SYNCE 			= 0x0000;       						// Peripheral sync enable/disable
	DmaRegs.CH1.MODE.bit.SYNCSEL 		= 0x0000;       						// Sync effects source or destination
	DmaRegs.CH1.MODE.bit.DATASIZE 		= 0x0000;       						// 16-bit/32-bit data size transfers
	DmaRegs.CH1.MODE.bit.CHINTMODE 		= 0x0001; 								// Generate interrupt to CPU at beginning/end of transfer

// Clear any spurious flags:
	DmaRegs.CH1.CONTROL.bit.PERINTCLR 	= 1;  									// clear any spurious interrupt flags
	DmaRegs.CH1.CONTROL.bit.SYNCCLR 	= 1;    								// clear any spurious sync flags
	DmaRegs.CH1.CONTROL.bit.ERRCLR 		= 1; 	    							// clear any spurious sync error flags

// Initialize PIE vector for CPU interrupt:
	PieCtrlRegs.PIEIER7.bit.INTx1 		= 1;        							// enable DMA CH1 interrupt in PIE
	EDIS;

	spi_init();																	// setup SPI module
	StartDMACH1();																// starts DMA Channel 1

// Start SEQ1
   AdcRegs.ADCTRL2.bit.SOC_SEQ1 		= 0x1;									// start ADC sequence

// speed up the modbus. YS. FEb 2017
//   eMBInit( MB_RTU, MB_SLV_ID, 0, 128000, MB_PAR_EVEN );							// Modbus init
   eMBInit( MB_RTU, MB_SLV_ID, 0, 57600, MB_PAR_EVEN );

   EnableInterrupts();															// enables interrupts

   eMBEnable();
   PLL_init();																	// initial 100 MHz setting at start up
   magnet_temp_init();                                                   //initialize ADS1248 temp sensor

   // set up NMR parameters
   initNMRParameters();
   ResetNMR();															// default config of NMR ASIC found in nmr.c
   InitNMR();															// found in nmr.c

   nextExpt.done = 0;
   nextExpt.ready2start = 0;
   nextExpt.nscan = 0;
   nextExpt.read_index=0;

// Polling Modbus
   i=0;
   long kk=0;
   for (;;)
   {

		( void )eMBPoll();
		NMR_job();

		if (kk>150000)
		{	//blink();
			led_blink_D42();
			DELAY_US(1000);
			kk=0;
		}
		else
			kk++;


		if (CpuTimer2Regs.TCR.bit.TIF)
		{
			CpuTimer2Regs.TCR.bit.TSS = 1;										// 1, Timer Stop Status bit is stopped
			CpuTimer2Regs.TCR.bit.TIF = 1;										// 1, Timer Interrupt Flag is cleared
			//CpuTimer2Regs.TCR.bit.TRB = 0;									// Loads TIMH:TIM with timer value
			ReloadCpuTimer0();													// Loads TIMH/TIM with contents of PRD
			StartCpuTimer0();													// Start timer 2
			//Do_NMR_experiments(usAddress - 100);
			StopCpuTimer0();
		}

   }

}

// Modbus error codes
eMBErrorCode eMBRegHoldingCB( UCHAR * pucRegBuffer, USHORT usAddress, USHORT usNRegs,
                eMBRegisterMode eMode )
{
	Uint16 tempVal,tempVal1, tempVal2;
	Uint32 tempval3;


	led_blink_D42();                                        					// Test led blink if used
/*
	GpioDataRegs.GPASET.bit.GPIO31 			= 1;   								// Configure GPIO31 for LED D42
	DELAY_US(5000);																// 5ms delay
	GpioDataRegs.GPACLEAR.bit.GPIO31 		= 1;   								// Configure GPIO31 for LED D42
	DELAY_US(5000);																// 5ms delay
*/

	eMBErrorCode eMBError = MB_ENOREG;
	switch (usAddress)
	{

		case 1:
			// firmware version read holding reg 0x03
			if ((usNRegs == 1) && (eMode == MB_REG_READ))
			{
				tempVal=(unsigned int)FW_VERSION;
				*pucRegBuffer++ = ( unsigned char )( tempVal >> 8 );
				*pucRegBuffer++ = ( unsigned char )( tempVal & 0xFF );
				usRegInputBuf++;
				eMBError = MB_ENOERR;
			}
			else
			{
				eMBError = MB_EINVAL;
			}
			break;

		case 2:
			// test modbus command read holding reg 0x02
			//led_blink_D42();                                        			// Test led blink if used
			tempVal=usRegInputBuf;
			if ((usNRegs == 1) && (eMode == MB_REG_READ))
			{
				*pucRegBuffer++ = ( unsigned char )( tempVal >> 8 );
				*pucRegBuffer++ = ( unsigned char )( tempVal & 0xFF );
				usRegInputBuf++;
				eMBError = MB_ENOERR;
			}
			else
			{
				eMBError = MB_EINVAL;
			}
			break;

		case 3:
			// Write SPI DAC LTC2630
			// Write single register (0x06), Start Addr 3, Data =    0 DAC = 0V U10 pin1 = -13V 0.54
			// Write single register (0x06), Start Addr 3, Data = 4095 DAC = 0V U10 pin1 = +14V 2.78
			// DAC = -13V, VTUNE_MON = 0.54V
			// DAC = +14V, VTUNE_MON = 2.78V

			if ((usNRegs == 1) && (eMode == MB_REG_WRITE))
			{
				tempVal= (((unsigned int)(*pucRegBuffer))<<8)+(*(pucRegBuffer+1));
				//spi_dac_MCC(tempVal<<4);
				spi_dac(tempVal);
				eMBError = MB_ENOERR;
			}
			else
			{
				eMBError = MB_EINVAL;
			}

			break;

		case 4:
			// SPI PLL HMC832 Write

			if ((usNRegs == 2) && (eMode == MB_REG_WRITE))
			{
				tempVal= (((unsigned int)(*pucRegBuffer))<<8)+(*(pucRegBuffer+1));
				pucRegBuffer+=2;

				tempVal2= (((unsigned int)(*pucRegBuffer))<<8)+(*(pucRegBuffer+1));
				PLL_mosi(tempVal, tempVal2);

				eMBError = MB_ENOERR;
			}
			else
			{
				eMBError = MB_EINVAL;
			}

			break;

		case 5:
			// RESET PLL to default output frequency
			PLL_init();															// function call to send all PLL set up words
			eMBError = MB_ENOERR;
			break;

		case 6:
			// Slow Channel ADC[04] DAC Read
			tempVal=usRegInputBuf;
			if ((usNRegs == 1) && (eMode == MB_REG_READ))
			{
				*pucRegBuffer++ = ( unsigned char )( DMABuf1[4] >> 8 );
				*pucRegBuffer++ = ( unsigned char )( DMABuf1[4] & 0xFF );
				usRegInputBuf++;
				eMBError = MB_ENOERR;
			}
			else
			{
				eMBError = MB_EINVAL;
			}
			break;

		case 7:
			// SPI Read Board Temperature

			if ((usNRegs == 1) && (eMode == MB_REG_READ))
			{
				tempVal = spi_temp_board(usAddress);							// tempval3 now contains addressed register data
				*pucRegBuffer++ = ( unsigned char )( tempVal >> 8 );			// modbus Tx of msb 16bits of A7975 8bits at a time via *pucRegBuffer
				*pucRegBuffer++ = ( unsigned char )( tempVal & 0xFF );			// modbus Tx of remaining lsb 16bits of A7975 8bits at a time

			    eMBError = MB_ENOERR;
			}


			else
			{
				eMBError = MB_EINVAL;
			}
			break;

		case 8:
		                     // ADS1248, read magnet temp
		                     if ((usNRegs == 2) && (eMode == MB_REG_READ))

		                     {
		                           tempval3=magnet_temp_read(0);
		                           tempVal = tempval3 >> 16;
		                           *pucRegBuffer++ = ( unsigned char )( tempVal >> 8 );              //
		                           *pucRegBuffer++ = ( unsigned char )( tempVal & 0xFF );            //

		                           tempVal = tempval3 & 0xFFFF;
		                           *pucRegBuffer++ = ( unsigned char )( tempVal >> 8 );
		                           *pucRegBuffer++ = ( unsigned char )( tempVal & 0xFF );

		                         eMBError = MB_ENOERR;
		                     }

		                     else
		                     {
		                           eMBError = MB_EINVAL;
		                     }

		                     break;

			/*
		case 8:
			// SPI ADC Board Read "Not sure this code is valid now that Mcbsp is used 11/29"

			if ((usNRegs == 1) && (eMode == MB_REG_READ))
			{
				tempVal = spi_ADC_read(usAddress);								// tempval3 now contains addressed register data
				*pucRegBuffer++ = ( unsigned char )( tempVal >> 8 );			// modbus Tx of msb 16bits of A7975 8bits at a time via *pucRegBuffer
				*pucRegBuffer++ = ( unsigned char )( tempVal & 0xFF );			// modbus Tx of remaining lsb 16bits of A7975 8bits at a time

			    eMBError = MB_ENOERR;
			}


			else
			{
				eMBError = MB_EINVAL;
			}
			break;
*/
		// Read all PLL Register List
		case 10:
		case 11:
		case 12:
		case 13:
		case 14:
		case 15:
		case 16:
		case 17:
		case 18:
		case 19:
		case 20:
		case 21:
		case 22:
		case 23:
		case 24:
		case 25:
		case 26:
		case 27:
		case 28:
		case 29:

			// PLL Read Single
			if ((usNRegs == 2) && (eMode == MB_REG_READ))
			{
				tempval3 = spi_PLL_read(usAddress - 10);						// tempval3 now contains addressed register data
				tempVal = tempval3 >> 16;
				*pucRegBuffer++ = ( unsigned char )( tempVal >> 8 );			// modbus Tx of msb 16bits of A7975 8bits at a time via *pucRegBuffer
				*pucRegBuffer++ = ( unsigned char )( tempVal & 0xFF );			// modbus Tx of remaining lsb 16bits of A7975 8bits at a time

				tempVal = tempval3 & 0xFFFF;
				*pucRegBuffer++ = ( unsigned char )( tempVal >> 8 );
				*pucRegBuffer++ = ( unsigned char )( tempVal & 0xFF );

			    eMBError = MB_ENOERR;
			}

			// PLL Write Single
			else if ((usNRegs == 2) && (eMode == MB_REG_WRITE))
			{
				tempVal= (((unsigned int)(*pucRegBuffer))<<8)+(*(pucRegBuffer+1));
				pucRegBuffer+=2;
				tempVal2= (((unsigned int)(*pucRegBuffer))<<8)+(*(pucRegBuffer+1));
				tempval3 = (((Uint32)tempVal) << 16) + ((Uint32)tempVal2);
				PLL_write(usAddress-10, tempval3);

			    eMBError = MB_ENOERR;
			}
			else
			{
				eMBError = MB_EINVAL;
			}
			break;
/*
		case 100:
			// SPI ASIC Write													// Test ASIC write

			if ((usNRegs == 2) && (eMode == MB_REG_WRITE))
			{
				tempVal= (((unsigned int)(*pucRegBuffer))<<8)+(*(pucRegBuffer+1));
				pucRegBuffer+=2;

				tempVal2= (((unsigned int)(*pucRegBuffer))<<8)+(*(pucRegBuffer+1));
				ASIC_mosi(tempVal, tempVal2);

				eMBError = MB_ENOERR;
			}
			else
			{
				eMBError = MB_EINVAL;
			}

			break;
*/
/*		case 101:
			// SPI ASIC, Do NMR experiments

			if ((usNRegs == 2) && (eMode == MB_REG_WRITE))
			{

				CpuTimer2Regs.TCR.bit.TRB = 0;									// Loads TIMH:TIM with timer value
				CpuTimer2Regs.TCR.bit.TSS = 0;									// Starts timer

				//Do_NMR_experiments(usAddress - 100);

				eMBError = MB_ENOERR;
			}
			else
			{
				eMBError = MB_EINVAL;
			}

			break;
*/
            //ADS1248 Registers by David M 09/29/2017
     case 30:
     case 31:
     case 32:
     case 33:
     case 34:
     case 35:
     case 36:
     case 37:
     case 38:
     case 39:
     case 40:
     case 41:
     case 42:
     case 43:
     case 44:


            // Write Register magnet temp
            if ((usNRegs == 1) && (eMode == MB_REG_WRITE))
            {
                  magnet_temp_write(usAddress-30, *(pucRegBuffer+1));

                eMBError = MB_ENOERR;
            }

            else if ((usNRegs == 1) && (eMode == MB_REG_READ))

            {
                  tempval3 = magnet_reg_read(usAddress-30);                                        // tempval3 now contains addressed register data

                   *pucRegBuffer++ = ( unsigned char )( tempval3 >> 8 );
                  *pucRegBuffer++ = ( unsigned char )( tempval3 & 0xFF );

                eMBError = MB_ENOERR;
            }

            else
            {
                  eMBError = MB_EINVAL;
            }

            break;

     case 45:

            if ((eMode == MB_REG_WRITE) && (usNRegs == 1))
            {
                  magnet_temp_reset();
                  eMBError = MB_ENOERR;
            }
            break;

     case 46:

            if ((eMode == MB_REG_WRITE) && (usNRegs == 1))
            {
                  magnet_temp_sdatac();
                  eMBError = MB_ENOERR;
            }
            break;

     case 47:

            if ((eMode == MB_REG_WRITE) && (usNRegs == 1))
            {
                  magnet_temp_sync();
                  eMBError = MB_ENOERR;
            }
            break;

	// YS. Jan 23, 2017

			//YS dec 14, 2016
		case 101:
			// SPI ASIC, Do NMR experiments
			// write 1 registers, 2 bytes
		    // first byte : experiment code
		    // second byte: number of scans
			if ((usNRegs == 1) && (eMode == MB_REG_WRITE))
			{
				unsigned int x1= (unsigned int)(*pucRegBuffer);
				unsigned int x2 = (unsigned int)*(pucRegBuffer+1);
				//pucRegBuffer+=2;

				// CpuTimer2Regs.TCR.bit.TRB = 0;									// Loads TIMH:TIM with timer value
				// CpuTimer2Regs.TCR.bit.TSS = 0;									// Starts timer

				//Do_NMR_experiments(usAddress - 100);
				// instead of performing experiment here, only an experiment code will be written here.
				// Two bytes of data as an input
				// first  byte=> which experiment;
				// second byte => how many scans

				// need to add check
				nextExpt.index = x1;
				nextExpt.nscan = x2;
				nextExpt.ready2start = 1;
				nextExpt.ndata = 0;
				nextExpt.done = 0;

				eMBError = MB_ENOERR;
			}
			else
			{
				eMBError = MB_EINVAL;
			}

			break;

		case 102:
			// ASIC GAIN

			if ((usNRegs == 1) && (eMode == MB_REG_WRITE))
			{
				tempVal= (((unsigned int)(*pucRegBuffer))<<8)+(*(pucRegBuffer+1));
				AsicGainCtrl (tempVal & 0xFFFF);

				eMBError = MB_ENOERR;
			}
			else if ((usNRegs == 1) && (eMode == MB_REG_READ))
			{
				tempVal = 5;
				*pucRegBuffer++ = ( unsigned char )( tempVal >> 8 );			// modbus Tx of msb 16bits of  8bits at a time via *pucRegBuffer
				*pucRegBuffer++ = ( unsigned char )( tempVal & 0xFF );			// modbus Tx of remaining lsb 16bits of  8bits at a time
				eMBError = MB_ENOERR;
			}
			else

			{
				eMBError = MB_EINVAL;
			}

			break;

		case 103:
			// read the uNMR status,
			// 1. REad two bytes, also reset the read_index to zero in anticipation of data reading via rs485.
			// Feb 4. Read two registers: status, and error code.
			// or
			// read the full list of parameters
			// or
			// set parameters, 6 bytes, first 2 byte is the index to the variables, next four bytes (32 bits) is the parameter value.
			eMBError = MB_EINVAL;
			int i;
						if ((usNRegs == 3) && (eMode == MB_REG_WRITE))		// set 1 parameter
						{
							tempVal= (((Uint16)(*pucRegBuffer))<<8)+(*(pucRegBuffer+1));
							pucRegBuffer += 2;
							tempVal1= (((Uint16)(*pucRegBuffer))<<8)+(*(pucRegBuffer+1));
							pucRegBuffer += 2;
							tempVal2= (((Uint16)(*pucRegBuffer))<<8)+(*(pucRegBuffer+1));

							tempval3 = (Uint32) tempVal1<<16 ;
							tempval3 += (Uint32) tempVal2;

							SetNMRParameters(tempVal,tempval3);	//RunNMR.h

							eMBError = MB_ENOERR;
						}
						else if ((usNRegs == 1) && (eMode == MB_REG_READ))          // read the number of data acquired.
						{
							if (nextExpt.done== 1)
							{
								tempVal = nextExpt.ndata;
							}
							else
							{
								tempVal = 0;
							}

							*pucRegBuffer++ = ( unsigned char )( tempVal>>8);			// modbus Tx of msb 16bits of  8bits at a time via *pucRegBuffer
							*pucRegBuffer++ = ( unsigned char )( tempVal & 0xFF );			// modbus Tx of remaining lsb 16bits of  8bits at a time
							eMBError = MB_ENOERR;
							// reset the nextExpt.read_index to zero to anticipate data transfer
							nextExpt.read_index = 0;
						}
						else if ((usNRegs == 2) && (eMode == MB_REG_READ))
							{
								if (nextExpt.done== 1)
									{
										tempVal = nextExpt.ndata;
									}
								else
									{
										tempVal = 0;
									}

								*pucRegBuffer++ = ( unsigned char )( tempVal>>8);			// modbus Tx of msb 16bits of  8bits at a time via *pucRegBuffer
								*pucRegBuffer++ = ( unsigned char )( tempVal & 0xFF );			// modbus Tx of remaining lsb 16bits of  8bits at a time
								tempVal = GetErrorCode();
								*pucRegBuffer++ = ( unsigned char )( tempVal>>8);			// modbus Tx of msb 16bits of  8bits at a time via *pucRegBuffer
								*pucRegBuffer++ = ( unsigned char )( tempVal & 0xFF );			// modbus Tx of remaining lsb 16bits of  8bits at a time

								eMBError = MB_ENOERR;
								// reset the nextExpt.read_index to zero to anticipate data transfer
								nextExpt.read_index = 0;
							}
						else if ((usNRegs > 2) && (eMode == MB_REG_READ))		// read more than 2 parameters from GetNMRParameters().
						{
							//for (i=1;i<(usNRegs>i_error ? i_error : usNRegs); i++ )
							int k = min(usNRegs/2,i_error ) ;
							for (i=1;i<=k; i++ )
							{
								tempval3 = GetNMRParameters(i);	//32 bit, 4 bytes
								*pucRegBuffer++ = ( unsigned char )(( tempval3 & 0xFF000000) >>24);			// modbus Tx of msb 8bits
								*pucRegBuffer++ = ( unsigned char )(( tempval3 & 0x00FF0000) >>16 );			// modbus Tx of second 8 bits

								*pucRegBuffer++ = ( unsigned char )(( tempval3 & 0x0000FF00) >> 8 );			// modbus Tx of 3rd 8bits
								*pucRegBuffer++ = ( unsigned char )( tempval3 & 0x000000FF );			// modbus Tx of remaining lsb 8bits

							}
							eMBError = MB_ENOERR;
						}
						else
						{
							eMBError = MB_EINVAL;
						}
			break;

		case 104:
			// read the uNMR data, add YS jan 3
			// input is how many data points (counting both real and imag) to read
						if ((usNRegs == 1) && (eMode == MB_REG_WRITE))
						{
							tempVal= (((unsigned int)(*pucRegBuffer))<<8)+(*(pucRegBuffer+1));
							// not used for now.

							eMBError = MB_ENOERR;
						}
						else if ((usNRegs >= 1) && (eMode == MB_REG_READ))	// read 1 or more data points
						{
							int i;
							int16 x, y;
							for ( i=0;i<usNRegs/2; i++)
							{
								tempVal = GetNMRData(nextExpt.read_index, &x, &y);


								// store to serial buffer, real first, then imag
								*pucRegBuffer++ = ( unsigned char )( x>>8);			// modbus Tx of msb 16bits of  8bits at a time via *pucRegBuffer
								*pucRegBuffer++ = ( unsigned char )( x & 0x00FF );	// modbus Tx of remaining lsb 16bits of  8bits at a time
								*pucRegBuffer++ = ( unsigned char )( y>>8);			// modbus Tx of msb 16bits of  8bits at a time via *pucRegBuffer
								*pucRegBuffer++ = ( unsigned char )( y & 0x00FF );	// modbus Tx of remaining lsb 16bits of  8bits at a time

								nextExpt.read_index += 1;
							}
							eMBError = MB_ENOERR;
						}
						else

						{
							eMBError = MB_EINVAL;
						}
			break;


            // Oct 31, 2017. YS
            // add a function to download the entire pulse sequence
            //
        case 110:
            // read/download NMR pulse seq, add YS Oct 31, 2017 --
            // A complete pulse seq is 64 by 64 bits
        {
            Uint32 x1,x2;
            UCHAR   c1,c2,c3,c4;
            int k;
            // usNRegs is 4 times number of pulses to download
            // We will use a fixed usNRegs = 64, for 16 pulses.
            // This will run 4 times to download the full seq.
            if ((usNRegs == 64) && (eMode == MB_REG_WRITE))
            {
                for (k=0;k<usNRegs/4;k++) {
                    c1= (*pucRegBuffer++);
                    c2= (*pucRegBuffer++);
                    c3= (*pucRegBuffer++);
                    c4= (*pucRegBuffer++);
                    x1 = ((Uint32)c1<<24) + ((Uint32)c2<<16)+((Uint32)c3<<8)+((Uint32)c4);

                    c1= (*pucRegBuffer++);
                    c2= (*pucRegBuffer++);
                    c3= (*pucRegBuffer++);
                    c4= (*pucRegBuffer++);
                    x2 = ((Uint32)c1<<24) + ((Uint32)c2<<16)+((Uint32)c3<<8)+((Uint32)c4);

                    k  = nextExpt.read_index;
                    if ((k>=0) && (k<64)) {
                        gPulseSeq.pls[k].dword[1] = x1;
                        gPulseSeq.pls[k].dword[0] = x2;
                    }

                    nextExpt.read_index++;

                }
                eMBError = MB_ENOERR;
            }
            else if ((usNRegs >= 1) && (eMode == MB_REG_READ))  // read 1 or more pulse segment, usNReg is the number of
                                                                // pulse segment. Each is 4 16-bits long
            {


                USHORT nPulses = usNRegs/4;
                for ( i=0;i<nPulses; i++)
                {
                    // get pulse seq segment
                    k  = nextExpt.read_index;
                    if ((k<0) || (k>63))        // if the pulse number is not valid (within 0-63)
                    {   x1=0;
                        x2=0;
                    }
                    else {
                        x1 = gPulseSeq.pls[k].dword[1];
                        x2 = gPulseSeq.pls[k].dword[0];
                    }
                    // store to serial buffer, real first, then imag
                    *pucRegBuffer++ = ( unsigned char )( (x1>>24) & 0x000000FF);            // modbus Tx of msb 16bits of  8bits at a time via *pucRegBuffer
                    *pucRegBuffer++ = ( unsigned char )( (x1>>16) & 0x000000FF );   // modbus Tx of remaining lsb 16bits of  8bits at a time
                    *pucRegBuffer++ = ( unsigned char )( (x1>>8)  & 0x000000FF );   // modbus Tx of remaining lsb 16bits of  8bits at a time
                    *pucRegBuffer++ = ( unsigned char )( (x1)     & 0x000000FF );   // modbus Tx of remaining lsb 16bits of  8bits at a time

                    *pucRegBuffer++ = ( unsigned char )( (x2>>24) & 0x000000FF);            // modbus Tx of msb 16bits of  8bits at a time via *pucRegBuffer
                    *pucRegBuffer++ = ( unsigned char )( (x2>>16) & 0x000000FF );   // modbus Tx of remaining lsb 16bits of  8bits at a time
                    *pucRegBuffer++ = ( unsigned char )( (x2>>8)  & 0x000000FF );   // modbus Tx of remaining lsb 16bits of  8bits at a time
                    *pucRegBuffer++ = ( unsigned char )( (x2)     & 0x000000FF );   // modbus Tx of remaining lsb 16bits of  8bits at a time

                    nextExpt.read_index += 1;
                }
                eMBError = MB_ENOERR;
            }
            else

            {
                eMBError = MB_EINVAL;
            }

        }
            break;

// Enf of the function to read/download the entire pulse sequence


		case 1000 ... 2000:														// ASIC Do_NMR_experiments READ RX_R

			if ((eMode == MB_REG_READ))
			{
				int j;
				for (j = 0; j < usNRegs; j++)
				{
				tempVal = dataBuf_real [j+(usAddress-1000)];					// tempval3 now contains addressed register data
				*pucRegBuffer++ = ( unsigned char )( tempVal >> 8 );			// modbus Tx of msb 16bits of A7975 8bits at a time via *pucRegBuffer
				*pucRegBuffer++ = ( unsigned char )( tempVal & 0xFF );			// modbus Tx of remaining lsb 16bits of A7975 8bits at a time

				}

				eMBError = MB_ENOERR;
			}


			else
			{
				eMBError = MB_EINVAL;
			}
			break;

		case 3000 ... 4000:														// ASIC Do_NMR_experiments READ RX_I

			if ((eMode == MB_REG_READ))
			{
				int j;
				for (j = 0; j < usNRegs; j++)
				{
				tempVal = dataBuf_imag [j+(usAddress-3000)];					// tempval3 now contains addressed register data
				*pucRegBuffer++ = ( unsigned char )( tempVal >> 8 );			// modbus Tx of msb 16bits of A7975 8bits at a time via *pucRegBuffer
				*pucRegBuffer++ = ( unsigned char )( tempVal & 0xFF );			// modbus Tx of remaining lsb 16bits of A7975 8bits at a time

				}

			    eMBError = MB_ENOERR;
			}


			else
			{
				eMBError = MB_EINVAL;
			}
			break;

/*		case 104:																// ASIC GAIN

			if ((usNRegs == 1) && (eMode == MB_REG_WRITE))
			{
				tempVal= (((unsigned int)(*pucRegBuffer))<<8)+(*(pucRegBuffer+1));
				AsicGainCtrl (tempVal & 0xFFFF);

				eMBError = MB_ENOERR;
			}
			else
			{
				eMBError = MB_EINVAL;
			}

			break;
*/
	}
	return eMBError;
}


// INT7.1
__interrupt void cpu_timer2_isr(void)
{
	CpuTimer2Regs.TCR.bit.TSS = 1;												// 1, Timer Stop Status bit is stopped
	CpuTimer2Regs.TCR.bit.TIF = 1;												// 1, Timer Interrupt Flag is cleared
	//CpuTimer2Regs.TCR.bit.TRB = 0;											// Loads TIMH:TIM with timer value
	ReloadCpuTimer0();															// Loads TIMH/TIM with contents of PRD
	StartCpuTimer0();															// Start timer 2
	Do_NMR_experiments(usAddress - 100);										// Sends do_nmr_experiment sellected
	StopCpuTimer0();
	// The CPU acknowledges the interrupt.
}

// INT7.1
__interrupt void local_DINTCH1_ISR(void)     									// DMA Channel 1 ISR
{
  // To receive more interrupts from this PIE group, acknowledge this interrupt
   PieCtrlRegs.PIEACK.all 				= PIEACK_GROUP7;						// acknowledge interrupt from group 7
}

// INT3.1
__interrupt void epwm1_isr(void)												//
{

// Clear INT flag for this timer
   EPwm1Regs.ETCLR.bit.INT 				= 1;									// event trigger clear

// Acknowledge this interrupt to receive more interrupts from group 3
   PieCtrlRegs.PIEACK.all 				= PIEACK_GROUP3;						// acknowledge interrupt from group 3
}
