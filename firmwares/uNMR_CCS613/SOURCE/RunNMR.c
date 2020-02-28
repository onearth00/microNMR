/*
 * RunNMR.c
 *
 *  Created on: Aug 1, 2016
 *      Author: mccowan1
 */
//###########################################################################
// Revision History:
//
// Aug 1st:- Code to RUN FID -> FID2 only dmc
/*
 * YS
 * Feb. spi to read ADC.
 * Feb 4. FID works, CPMG not.
 * Feb 6. FID and CPMG working on simulated signal. One serial problem with matlab/modbus. Transmitting a byte of value 10 does not work.
 * Feb 7. FID getting signal from high res magnet. Find PLL problem.
 *
 */
//
//

//
//###########################################################################

#include "DSP28x_Project.h"										// Device Headerfile and Examples Include File
#include "stdlib.h"
#include <string.h>
#include <math.h>

#include "RunNMR.h"
#include "nmr.h"
#include "nmr_plsq.h"
#include "gpio_init.h"
#include "asic.h"

#include "noe1dseq.h"   // new seq


// NMR System Parameter settings
/* definition is in RunNMR.h
 *
*/

// NMR parameters

#define ver_code 2014*65536+19*256 + 1; //2014*2^16 + 19*2^8 + 1; // 2014 - ASIC ver; 19=> 2019; 1=>sub ver 1
                                        //version code from 2019, nov. YS.
                                        //version will always have a year, then subversion number
                                        //NMR_Sys_Parameters change: update asic_ver to Uint32.

NMR_Sys_Parameters NMR_system_settings;
PlsSeq gPulseSeq; 												// store the pulse seq, global

// defined in RunNMR.h
// #define dataBufferTD 1000										// dataBufferTD = 2600 x 16bits

int16	dataBuf_real[dataBufferTD];								// real data buffer
int16	dataBuf_imag[dataBufferTD];								// imaginary data buffer

// local functions
// final.
int Run_NMR_Accumulate(PlsSeq *inSeq, unsigned long expTime, int DwellTime, int TD,   int inAcqPhase);
int Run_NMR_Accumulate_mcbsp(PlsSeq *inSeq, unsigned long expTime, int DwellTime, int TD,   int inAcqPhase);
int Run_NMR_Accumulate_CPMG_mcbsp(PlsSeq *inSeq, unsigned long expTime, int DwellTime,  int dummyecho, int TD, int inAcqPhase, int NPTS, int *echoFilter1);

void PrepareNMRADC();
void FinishNMRADC();

// in testing
int Run_NMR_Accumulate_CPMG(PlsSeq *inSeq, unsigned long expTime, int DwellTime, int TD,   int inAcqPhase, int NPTS, int *p);

int Run_NMR_Accumulate_test_tuning(PlsSeq *inSeq, unsigned long expTime, int DwellTime, int TD,  int inAcqPhase);
int Run_NMR_Accumulate_tuning_mcbsp(PlsSeq *inSeq, unsigned long expTime, int DwellTime, int TD, int inAcqPhase);

//local
int Run_NMR_test(void )	;		// use as a test

// from tempcontroller.c
//float ADS1248_init();


/*
 * CODES
 */
Uint16 GetErrorCode(void)
{
	return NMR_system_settings.error;
}

void SetErrorCode(Uint16 inCode)
{
	NMR_system_settings.error = inCode;
}




void SetFreq(Uint32 inValue)
{
	SetNMRParameters(i_freq, inValue);
}

void SetGain(Uint32 inValue)
{
	SetNMRParameters(i_recgain, inValue);
}

void SetTD(Uint32 inValue)
{
	SetNMRParameters(i_TD, inValue);
}

// return the number of data points that have been acquired.
Uint32 GetAcqTD()
{
	return GetNMRParameters(i_acquiredTD);
}




Uint32	GetNMRParameters(int index)
{
	Uint32 theValue=0;

	switch(index)
	{
		case 	i_asci_ver: theValue = (Uint32) NMR_system_settings.asic_ver; 	break;
		case i_tuningcap: theValue = (Uint32) NMR_system_settings.tuningcap; break;
		case i_recgain :  theValue =  (Uint32) NMR_system_settings.RecGain ; break;
		case i_na :  theValue =  (Uint32) NMR_system_settings.NA ;break;
		case i_ds :  theValue =  NMR_system_settings.DS ;break;
		case i_dwell :  theValue =  NMR_system_settings.dw ;break;
		case i_T90 :  theValue =  NMR_system_settings.T90 ; break;
		case i_T180 :  theValue =  NMR_system_settings.T180 ; break;
		case i_TE:  theValue =  NMR_system_settings.TE ; break;
		case i_TD:  theValue =  NMR_system_settings.TD ; break;
		case i_freq:  theValue =  NMR_system_settings.Freq ; break;
		case i_RD: 	theValue = NMR_system_settings.RD; break;
		case i_tau: theValue = NMR_system_settings.tau; break;
		case i_TD1: theValue = NMR_system_settings.TD1; break;
		case i_TD2: theValue = NMR_system_settings.TD2; break;
		case i_maxTD: theValue = NMR_system_settings.maxTD; break;
		case i_acquiredTD: theValue = NMR_system_settings.acquiredTD; break;
		case i_echoshape: theValue = NMR_system_settings.echoshape;break;
		case i_nint: theValue = NMR_system_settings.nint;break;
		case i_nfrac: theValue = NMR_system_settings.nfrac;break;
		case i_dummyecho: theValue = NMR_system_settings.dummyecho;break;

		case i_error: theValue = NMR_system_settings.error; break;
		default: theValue = 0;
	}
	return theValue;
}

void GetFullParameters(Uint32 *p, int np)
{
	int i=0;

	for (i=1; i<np; i++)
	{
		if (i<= i_error)
			p[i] = GetNMRParameters(i);
	}
}

void synth_fset(double fout, unsigned int rf_gain);

int	SetNMRParameters(int index, Uint32 value)
{
//	Uint32 res;
	double d;

	switch(index)
	{
	case 	i_asci_ver: 	break;

	case i_tuningcap:NMR_system_settings.tuningcap=value; break;
	case i_recgain : NMR_system_settings.RecGain = value; break;
	case i_na : NMR_system_settings.NA = value; break;
	case i_ds : NMR_system_settings.DS = value; break;
	case i_dwell : NMR_system_settings.dw = value; break;
	case i_T90 : NMR_system_settings.T90 = value; break;
	case i_T180 :
		NMR_system_settings.T180 = value; break;
	case i_TE :
		NMR_system_settings.TE = value; break;
	case i_TD :

		NMR_system_settings.TD = min(value,GetNMRParameters(i_maxTD));
		break;
	case i_freq :
		NMR_system_settings.Freq = value;

		PLL_freq_set3(NMR_system_settings.Freq*2);

		//d = (double)NMR_system_settings.Freq/500000.0;
		//PLL_freq_set(value*2);

		//synth_fset(d, 5);
		//NMR_system_settings.error = (int)(d*100);
		break;
	case i_nint :
	    NMR_system_settings.nint = value;
//	    PLL_freq_set2(value);;
	case i_nfrac :
	        NMR_system_settings.nfrac = value;
	//      PLL_freq_set2(value);;

	case i_RD: 		NMR_system_settings.RD= value; break;

	case i_TD1: 		NMR_system_settings.TD1= value; break;
	case i_TD2: 		NMR_system_settings.TD2= value; break;
	case i_tau:         NMR_system_settings.tau= value; break;
	case i_maxTD: 	 NMR_system_settings.maxTD= value; break;
	case i_acquiredTD: NMR_system_settings.acquiredTD= value; break;
	case i_echoshape: NMR_system_settings.echoshape = value;break;
	case i_dummyecho: NMR_system_settings.dummyecho = value;break;
	case i_error :
		NMR_system_settings.error = value; break;
	}
	return 0;
}


void initNMRParameters()
{
	int i;

	NMR_system_settings.Freq = 23300000;		// 23.3 MHz for microNMR

    NMR_system_settings.asic_ver = ver_code; // 2014*2^16 + 19*2^8 + 1; // 2014 - ASIC ver; 19=> 2019; 1=>sub ver 1
    NMR_system_settings.tuningcap=3500;
    NMR_system_settings.RecGain = 9;   // 15

    NMR_system_settings.NA =1;     // number of scans
    NMR_system_settings.DS = 0;     // dummy scans
    NMR_system_settings.dw = 10;   //YT Aug 17 2017 - set to be consistent with mcbsp dw
    NMR_system_settings.T90 = 12;
    NMR_system_settings.T180 = 24;
    NMR_system_settings.TE = 1000;     // echo time
    NMR_system_settings.TD = 1000;     // number of points to acq
    NMR_system_settings.PL[0]=30;       //power level
    NMR_system_settings.maxTD = dataBufferTD;  // max T
    NMR_system_settings.tau= 1000;
    NMR_system_settings.TD1 = 1;
    NMR_system_settings.TD2 = 1;
    NMR_system_settings.acquiredTD = 0;
    NMR_system_settings.RD = 100000;     // recycle delay
    NMR_system_settings.echoshape = 0;     // recycle delay
    NMR_system_settings.nint = 1;     // N_int for PLL
    NMR_system_settings.nfrac = 1;     // N_frac for PLL
    NMR_system_settings.nfrac = 1;     // recycle delay
    NMR_system_settings.dummyecho = 0;
    strcpy(NMR_system_settings.note, "note.");

    SetPowerLevel (30); // set NMR_system_settings.PL[0] = 30; // power level

    for (i=0;i<dataBufferTD;i++)
    {
    		dataBuf_imag[i] =0;
    		dataBuf_imag[i]=0;
    }
}

// to support output data via serial
int GetNMRData(int index, int16 *realpart, int16 *imagpart)
{
	if (index < dataBufferTD)
		{
			*realpart = dataBuf_real[index];
			*imagpart = dataBuf_imag[index];
			return 1;
			}
	else
	{
		*realpart = 0;
		*imagpart = 0;
		return 0;

	}
}


// if input is zero, then use default
int SetTuningCap(int inCap)
{
    if (inCap > 0) {
                // use the input value
        NMR_system_settings.tuningcap = (inCap % 4096);
    }

//    SetVarCap(NMR_system_settings.tuningcap);

   return(NMR_system_settings.tuningcap);
}


// set recgain
// if input is zero, then use default
int SetRecGain(int inRG)
{
    if (inRG > 0) {  // use existing NMR_system_settings
                // use the input value
        NMR_system_settings.RecGain = (inRG % 16);
    }

    return (NMR_system_settings.RecGain);
}

int SetPowerLevel(int inPL)
{
    if (inPL > 0)
        NMR_system_settings.PL[0] = (inPL % 32); // 5-bits

    return NMR_system_settings.PL[0];
}




void Do_NMR_experiments(int inSeqNum)
{

    int i, res;
    Uint32 data;
    float x = 1.1;

   switch(inSeqNum)														// switch to select run sequence
    {
   	   case 0: Run_NMR_FID();             								// Single FID sequence
   	   break;

   	   case 1: Run_NMR_Tuning(); 										// Tuning command
   	   break;

       case 2: res = Run_NMR_FID_mcbsp();							// FID shimming sequence
       break;

       case 3:
    	   	   Run_NMR_CPMG(); 									// CPMG sequence
    	   	   //Run_NMR_FID();
       break;

       case 4: res = Run_NMR_CPMG_mcbsp(); 									// IRCPMG sequence
       break;

       case 5: res = Run_NMR_Tuning_mcbsp();                                  // Store file
       break;

       case 6: res = Run_NMR_TuningCurve_mcbsp();
       break;
       /*
       case 5: res = StoreFileTest(1);									// Store file
       break;
       case 6: res = SetNMRss();										// Set NMR Rss
       break;
       */
       case 7: res = Run_NMR_IR_mcbsp();								//
       break;
       case 8: res = Run_NMR_IRCPMG_mcbsp();
       break;

       case 100:
               res = Run_NMR_test( );
           break;

   	   default:
   	   	   	   for (i=0;i<20;i++)
   	   	   	   {
   	   	   		   //data = SPIRead32bitWordFromADC();

   	   	   		   dataBuf_real[i] = (int16) ((data & 0x3FFF0000) >>16 );
   	   	   		   dataBuf_imag[i]= (int16) (data & 0x00003FFF) ;

   	   	   	   }
   	   	   	   SetNMRParameters(i_TD,20);

   	  // 	   	   x = ADS1248_init();

   	   	   	   SetNMRParameters(i_error, (Uint32) x);
       break;
    }

}




// *****************************************************
//     NMR sequences and data acquisition
// *****************************************************

/*
 *
 * set NMR parameters
 *
 */

int Run_NMR_FID(void)
{
    int ii = 0, acqPTs;   												// ii= index, acqpoints
    int DS = 0, NA;             											// Dummy Scan

    // pulse seq parameters
    // phase table
    int ph1[] 	 = {0,2,1,3};   											// in unit of 90 deg
    int phacq[] = {0,2,1,3};
    int phlength = 4;

    // parameters used in assisting the running of the seq
    Uint32  expTime;    												// total time for 1 run of pulse seq, obtain from the pulse seq itself
    Uint32 	p[6];// = {500000,20,30,0,10,500};        						//{500000,20,30,0,10,500}

    // update freq, scan
    strcpy(NMR_system_settings.SEQ, "FID");

    DS = NMR_system_settings.DS;
    NA = NMR_system_settings.NA;

    p[0]=NMR_system_settings.RD		;   								// RD
    p[1]=NMR_system_settings.T90	;        							// T90 RF pulse width
    p[2]=30	;        							// amp, PL[0]
    p[3]=ph1[0]*8					;         							// phase, 32 steps, to be cycled by ph1
    p[4]=NMR_system_settings.dw		;       							// dw time, us
    p[5]=NMR_system_settings.TD		;

    for (ii=0; ii<p[5]; ii++) dataBuf_real[ii] = dataBuf_imag[ii] = 0;	// reset data mem to 0
    // ---------------------------------------------
    // internal loop for phase cycling and averaging

    for (ii=-DS;ii<NA;ii++)
    {

        // update phase cycling
        if (ii<0)
            p[3]=ph1[0]*8;              								// set the phase of the pulse, first ph1 for dummy scan
        else
            p[3]=ph1[ii % phlength]*8; 								// set the phase of the pulse

        expTime = FID2(&gPulseSeq,p);    							// recreate the seq with the proper phase
                                                        				// total time for the experiment in US
                                        								// gPulseSeq global record of pulse seq results
                                        								// FID2 pulse gen code
        // do NMR, ii<0 is dummy scans
        if (ii<0)
            acqPTs = Run_NMR_Accumulate(&gPulseSeq, expTime, p[4],p[5],  -1); 	//dummy scan
        else
            acqPTs = Run_NMR_Accumulate(&gPulseSeq, expTime, p[4],p[5], phacq[(ii % phlength)]);
    }
    NMR_system_settings.acquiredTD = acqPTs;

    return(acqPTs);

} // end of Run_NMR_FID



// version that uses mcbsp serial bus. Not the SPI.
int Run_NMR_FID_mcbsp(void)
{
    int ii = 0, acqPTs;                                                 // ii= index, acq points
    int DS = 0, NA;                                                         // Dummy Scan
//    long Nint, Nfrac;

    // pulse seq parameters
    // phase table
    // int ph1[]    = {0,2,1,3};                                               // in unit of 90 deg
    // int phacq[] = {0,2,1,3};
    // int phlength = 4;

    int ph1[]    = {0, 2, 1 , 3};                                               // in unit of 90 deg
    int phacq[]     = {0,2,1,3};
    int phlength = 4;

//    Nint = NMR_system_settings.nint;
//    Nfrac = NMR_system_settings.nfrac;

//    PLL_freq_set2(Nint,Nfrac);
//    PLL_freq_set3(NMR_system_settings.Freq*2);

    spi_dac_MCC(NMR_system_settings.tuningcap & 0x0000FFFF);    //using the lower 2 bytes
    AsicGainCtrl (NMR_system_settings.RecGain);

    DELAY_US(10000);

    strcpy(NMR_system_settings.SEQ, "FID");

    // parameters used in assisting the running of the seq
    Uint32  expTime;                                                    // total time for 1 run of pulse seq, obtain from the pulse seq itself
    Uint32  p[6];// = {500000,20,30,0,10,500};                              //{500000,20,30,0,10,500}

    // update freq, scan


    DS = NMR_system_settings.DS;
    NA = NMR_system_settings.NA;

    p[0]=NMR_system_settings.RD     ;                                   // RD
    p[1]=NMR_system_settings.T90    ;                                   // T90 RF pulse width
    p[2]=30 ;                                   // amp, PL[0]
    p[3]=ph1[0]*8                   ;                                   // phase, 32 steps, to be cycled by ph1
    p[4]=NMR_system_settings.dw     ;                                   // dw time, us
    p[5]=NMR_system_settings.TD     ;

    for (ii=0; ii<p[5]; ii++) dataBuf_real[ii] = dataBuf_imag[ii] = 0;  // reset data mem to 0
    // ---------------------------------------------
    // internal loop for phase cycling and averaging

    for (ii=-DS;ii<NA;ii++)
    {
        // update phase cycling
        if (ii<0)
            p[3]=ph1[0]*8;                                              // set the phase of the pulse, first ph1 for dummy scan
        else
            p[3]=ph1[ii % phlength]*8;                              // set the phase of the pulse

        expTime = FID2(&gPulseSeq,p);                               // recreate the seq with the proper phase
                                                                        // total time for the experiment in US
                                                                        // gPulseSeq global record of pulse seq results
                                                                        // FID2 pulse gen code
        // do NMR, ii<0 is dummy scans
        if (ii<0)
            acqPTs = Run_NMR_Accumulate_mcbsp(&gPulseSeq, expTime, p[4],p[5],  -1);   //dummy scan
        else
            acqPTs = Run_NMR_Accumulate_mcbsp(&gPulseSeq, expTime, p[4],p[5], phacq[(ii % phlength)]);
    }
    NMR_system_settings.acquiredTD = acqPTs;

    return(acqPTs);

} // end of Run_NMR_FID

int Run_NMR_IR_mcbsp(void)
{
    int ii = 0, acqPTs;                                                 // ii= index, acq points
    int DS = 0, NA;                                                         // Dummy Scan
    long Nint, Nfrac;

    // pulse seq parameters
    // phase table
    int ph1[]={0,2,1,3};   // in unit of 90 deg
    int ph2[]={1,1,0,0};
    int phacq[] = {0,2,1,3};
    int phlength = 4;

//    Nint = NMR_system_settings.nint;
//    Nfrac = NMR_system_settings.nfrac;
//
//    PLL_freq_set2(Nint,Nfrac);
    PLL_freq_set3(NMR_system_settings.Freq*2);
    spi_dac_MCC(NMR_system_settings.tuningcap & 0x0000FFFF);    //using the lower 2 bytes
    AsicGainCtrl (NMR_system_settings.RecGain);

    DELAY_US(100);

    strcpy(NMR_system_settings.SEQ, "IR");

    // parameters used in assisting the running of the seq
    Uint32  expTime;                                                    // total time for 1 run of pulse seq, obtain from the pulse seq itself
    Uint32  p[9];// = {500000,20,30,0,10,500};                              //{500000,20,30,0,10,500}

    // update freq, scan


    DS = NMR_system_settings.DS     ;
    NA = NMR_system_settings.NA     ;

    p[0]=NMR_system_settings.RD     ;                                   // RD
    p[1]=NMR_system_settings.T90    ;                                   // T90 RF pulse width
    p[2]=30                         ;                                   // amp, PL[0]
    p[3]=ph1[0]*8                   ;                                   // phase, 32 steps, to be cycled by ph1
    p[4]=NMR_system_settings.T180   ;
    p[5]=8                          ;
    p[6]=NMR_system_settings.dw     ;                                   // dw time, us
    p[7]=NMR_system_settings.TD     ;
    p[8]=NMR_system_settings.tau    ;                                   // recovery for IR

    for (ii=0; ii<p[7]; ii++) dataBuf_real[ii] = dataBuf_imag[ii] = 0;  // reset data mem to 0
    // ---------------------------------------------
    // internal loop for phase cycling and averaging

    for (ii=-DS;ii<NA;ii++)
    {
        // update phase cycling
        if (ii<0)
        {   p[3]=ph1[0]*8;                                          // set the phase of the pulse, first ph1 for dummy scan
            p[5]=ph2[0]*8;
        }
        else
        {    p[3]=ph1[ii % phlength]*8;                              // set the phase of the pulse
             p[5]=ph2[ii % phlength]*8;
        }

        expTime = IR(&gPulseSeq,p);                                      // recreate the seq with the proper phase
                                                                        // total time for the experiment in US
                                                                        // gPulseSeq global record of pulse seq results
        // do NMR, ii<0 is dummy scans
        if (ii<0)
            acqPTs = Run_NMR_Accumulate_mcbsp(&gPulseSeq, expTime, p[6],p[7],  -1);   //dummy scan
        else
            acqPTs = Run_NMR_Accumulate_mcbsp(&gPulseSeq, expTime, p[6],p[7], phacq[(ii % phlength)]);
    }
    NMR_system_settings.acquiredTD = acqPTs;

    return(acqPTs);

} // end of Run_NMR_FID


// use mcbsp for providing the adc ticks and acquisition -Ray 7/2017
int Run_NMR_Accumulate_mcbsp(PlsSeq *inSeq, unsigned long expTime, int DwellTime, int TD, int inAcqPhase)
    {
        int    index;
        const Uint32    US_CT = 75;                                    // CPU clock count per microsecond
        long        timeStamp1=0;
        int16  tmpTop, tmpBottom, tmpReal, tmpImag;


        if (inSeq != NULL)
        {
            DlPlSeq(inSeq);                                                         // this downloads the sequence
        }

            ReloadCpuTimer0() ;
            StartCpuTimer0();
            EN_NMR_mode();

           // PrepareNMRADC();            // set ADC SPI conf.

            index=0;

            // and start acquiring data
            //PieCtrlRegs.PIEIFR1.bit.INTx4 = 0;

//
            DINT;
//                // start the pulse sequence.
            StartNMRASIC_SEQ();
//
//                // store the start time stamp
//                // timer counts down!
           timeStamp1 = ReadCpuTimer0Counter() - expTime*US_CT;                    // this is the end time of the sequence. /2 added because
//                //                                                                 // prescalar = 2;
           while( (ReadCpuTimer0Counter() > timeStamp1 ))
                {
          //  while( PieCtrlRegs.PIEIFR1.bit.INTx4 == 0 ) {asm(" nop");}              // Master waits until XINT1

            if (mReadNMR_ACQ_ &&  (index < TD) )
            {
                McbspbRegs.SPCR2.bit.GRST   = 1;                                        // Sample rate generator enabled
                delay_loop();
                McbspbRegs.SPCR2.bit.XRST   = 1;                                        // Transmitter enabled, not required for uNMR
                McbspbRegs.SPCR1.bit.RRST   = 1;                                        // Release RX from Reset
                McbspbRegs.SPCR2.bit.FRST   = 1;                                        // Frame Sync Generator enabled, this must be after GRST
                McbspbRegs.SPCR2.bit.XRDY   = 1;                                        // Transmitter ready to accept new data


   //         while(index < TD)
   //         {
                while( McbspbRegs.SPCR1.bit.RRDY == 0 ) {asm(" nop");}              // Master waits until RX data is ready

                tmpTop = McbspbRegs.DRR2.all & 0x3fff;                              // Read DRR2 first.
                tmpBottom = McbspbRegs.DRR1.all & 0x3fff;                           // Then read DRR1 to complete receiving of data

                GpioDataRegs.GPCTOGGLE.bit.GPIO76  = 1;                             // LED Indicator, Only used for testing Mcbsp

                // ii < 0 means dummy scans, do not accumulate

                    switch (inAcqPhase)
                    {
                    case 0:tmpReal = tmpTop; tmpImag = tmpBottom;break;
                    case 3:tmpReal = -tmpBottom; tmpImag = tmpTop;break;            // case numbers changed and tested by Ray. 08/17/2017
                    case 2:tmpReal = -tmpTop; tmpImag = -tmpBottom;break;
                    case 1:tmpReal = tmpBottom; tmpImag = -tmpTop;break;
                    default:tmpReal = 0; tmpImag = 0;                               // all other values, do not accumulate
                    break;
                    };

                    dataBuf_real[index] += tmpReal/10;                              // normalize data to the number of acquisition
                    dataBuf_imag[index] += tmpImag/10;
                    index ++;                                                           // next data point

            }
            else
            {
            McbspbRegs.SPCR2.bit.XRST   = 0;                                        // Transmitter enabled, not required for uNMR
            McbspbRegs.SPCR1.bit.RRST   = 0;                                        // Release RX from Reset
            McbspbRegs.SPCR2.bit.FRST   = 0;                                        // Release RX from Reset
            McbspbRegs.SPCR2.bit.GRST   = 0;
            }
         }
            // Sample rate generator disabled
            StopNMRASIC_SEQ();
            DELAY_US(10);
            EINT;

            return(index); // return the total data point acquired

} // end of int Run_NMR_Accumulate_test

int Run_NMR_Accumulate_tuning_mcbsp(PlsSeq *inSeq, unsigned long expTime, int DwellTime, int TD, int inAcqPhase)
{
      int    index;
      const Uint32    US_CT = 150;                                    // CPU clock count per microsecond
      long        timeStamp1=0;
      int32  tmpTop, tmpBottom, tmpReal, tmpImag;


      if (inSeq != NULL)
      {
          DlPlSeq(inSeq);                                                         // this downloads the sequence
      }

          ReloadCpuTimer0() ;
          StartCpuTimer0();
          EN_Tuning_mode();

          index=0;

          // and start acquiring data
          //PieCtrlRegs.PIEIFR1.bit.INTx4 = 0;
//
          DINT;
//                // start the pulse sequence.
          StartNMRASIC_SEQ();
//
//                // store the start time stamp
//                // timer counts down!
         timeStamp1 = ReadCpuTimer0Counter() - expTime*US_CT;                    // this is the end time of the sequence
//                //
         while( (ReadCpuTimer0Counter() > timeStamp1 ))
              {
        //  while( PieCtrlRegs.PIEIFR1.bit.INTx4 == 0 ) {asm(" nop");}              // Master waits until XINT1

          if ((index < TD))
          {
              McbspbRegs.SPCR2.bit.GRST   = 1;                                        // Sample rate generator enabled
              delay_loop();
              McbspbRegs.SPCR2.bit.XRST   = 1;                                        // Transmitter enabled, not required for uNMR
              McbspbRegs.SPCR1.bit.RRST   = 1;                                        // Release RX from Reset
              McbspbRegs.SPCR2.bit.FRST   = 1;                                        // Frame Sync Generator enabled, this must be after GRST
              McbspbRegs.SPCR2.bit.XRDY   = 1;                                        // Transmitter ready to accept new data

 //         while(index < TD)
 //         {
              while( McbspbRegs.SPCR1.bit.RRDY == 0 ) {asm(" nop");}              // Master waits until RX data is ready

              tmpTop = McbspbRegs.DRR2.all & 0x3fff;                              // Read DRR2 first.
              tmpBottom = McbspbRegs.DRR1.all & 0x3fff;                           // Then read DRR1 to complete receiving of data

              GpioDataRegs.GPCTOGGLE.bit.GPIO76  = 1;                             // LED Indicator, Only used for testing Mcbsp

              // ii < 0 means dummy scans, do not accumulate

              switch (inAcqPhase)
              {
                  case 0:tmpReal = tmpTop; tmpImag = tmpBottom;break;
                  case 1:tmpReal = -tmpBottom; tmpImag = tmpTop;break;
                  case 2:tmpReal = -tmpTop; tmpImag = -tmpBottom;break;
                  case 3:tmpReal = tmpBottom; tmpImag = -tmpTop;break;
                  default:tmpReal = 0; tmpImag = 0;                               // all other values, do not accumulate
                  break;
              };

                  dataBuf_real[index] += tmpReal/10;                              // normalize data to the number of acquisition
                  dataBuf_imag[index] += tmpImag/10;
                  index ++;                                                           // next data point
          }
          else
          {
              McbspbRegs.SPCR2.bit.XRST   = 0;                                        // Transmitter enabled, not required for uNMR
              McbspbRegs.SPCR1.bit.RRST   = 0;                                        // Release RX from Reset
              McbspbRegs.SPCR2.bit.FRST   = 0;                                        // Release RX from Reset
              McbspbRegs.SPCR2.bit.GRST   = 0;
          }
       }
          // Sample rate generator disabled
          StopNMRASIC_SEQ();
          DELAY_US(10);
          EINT;

          return(index); // return the total data point acquired

} // end of int Run_NMR_Accumulate_test

/*
 * Run_NMR_Tuning
 * Measure the response of the resonant circuit
 * Duplexers setting for tuning, receive signal during the pulse
 */
int Run_NMR_Tuning(void)
{
    int ii = 0, acqPTs;   												// ii= index, acqpoints

    // pulse seq parameters
    int DS = 0, NA;             											// Dummy Scan

    // phase table
    int ph1[4] 	 = {1, 3};   											// in unit of 90 deg
    int phacq[4] = {0, 2};
    int phlength = 2;

 //   Nint = NMR_system_settings.nint;
 //   Nfrac = NMR_system_settings.nfrac;

 //   PLL_freq_set2(Nint,Nfrac);

    DS = NMR_system_settings.DS;
    NA = NMR_system_settings.NA;
    NMR_system_settings.TD = 100 ;
    NMR_system_settings.T90 = 300 ;
    NMR_system_settings.RD = 100000;
    // parameters used in assisting the running of the seq
    Uint32  expTime;    												// total time for 1 run of pulse seq, obtain from the pulse seq itself
    Uint32 	p[6];// = {500000,20,30,0,10,500};        						//{500000,20,30,0,10,500}
    //Uint32 	p[6] = {5005,20,30,0,10,500};        						//{500000,20,30,0,10,500}


    /*
    p[0]=NMR_system_settings.RD		;   								// RD
    p[1]=NMR_system_settings.T90	;        							// T90 RF pulse width
    p[2]=NMR_system_settings.PL[0]	;        							// amp, PL[0]
    p[3]=0							;         							// phase, 32 steps, to be cycled by ph1
    p[4]=NMR_system_settings.dw		;       							// dw time, us
    p[5]=NMR_system_settings.TD		;
    */
    p[0]=NMR_system_settings.RD;   													// RD
    p[1]=NMR_system_settings.T90;							// T90 RF pulse width
    p[2]=30;        													// amp, PL[0]
    p[3]=0;         													// phase, 32 steps, to be cycled by ph1
    p[4]=NMR_system_settings.dw;       														// dw time, us typical is 10us
    p[5]=NMR_system_settings.TD;															// number of point to acq

    for (ii=0; ii<p[5]; ii++) dataBuf_real[ii] = dataBuf_imag[ii] = 0;	// reset data mem to 0

    // ---------------------------------------------
    // internal loop for phase cycling and averaging

    for (ii=-DS;ii<NA;ii++)
    {
        // update phase cycling
        if (ii<0)
            p[3]=0;              								// set the phase of the pulse, first ph1 for dummy scan
        else
            p[3]=ph1[ii % phlength]*8; 									// set the phase of the pulse

        expTime = TuningSeq(&gPulseSeq,p);    						// recreate the seq with the proper phase
                                                        				// total time for the experiment in US
                                        								// gPulseSeq global record of pulse seq results
                                        								// TuningSeq, RD + pulse. Acq during pulse
        // do NMR, ii<0 is dummy scans
        if (ii<0)
            acqPTs = Run_NMR_Accumulate_test_tuning(&gPulseSeq, expTime, p[4],p[5],  -1); 	//dummy scan
        else
            acqPTs = Run_NMR_Accumulate_test_tuning(&gPulseSeq, expTime, p[4],p[5],  phacq[ii % phlength]);
    }
    NMR_system_settings.acquiredTD = acqPTs;

    return(acqPTs);

} // end of Run_NMR_Tuning



/*
 * Use Run_NMR_Tuning_mcbsp() to obtain the full tuning curves.
 * scan freq: center freq = NMR_system_settings.Freq, scan (o1) plus/minus 0.5 Mhz
 * scan tuning cap bias: from 100 to 4000 every 100
 */
int Run_NMR_TuningCurve_mcbsp(void)
{
    long ii, kk, j;
    long origFreq, origCapBias;
    long theAmpl1, theAmpl2, theTD;
    double x;

    origFreq = NMR_system_settings.Freq;
    origCapBias = NMR_system_settings.tuningcap;

    for (kk=0;kk<20;kk++) {

        NMR_system_settings.tuningcap =  100+(4000-100)/(20-1)*kk;
        for (ii=0;ii<20;ii++) {
            DELAY_US(100);
            NMR_system_settings.Freq = origFreq + 1000000/(20-1)*(ii)-500000;
            theTD = Run_NMR_Tuning_mcbsp();

            // acquire the amplitude
            theAmpl1 = 0;
            theAmpl2 = 0;
            for (j=25;j<45;j++) {
                theAmpl1 += dataBuf_real[j];
                theAmpl2 += dataBuf_imag[j];
            }
            theAmpl1 = theAmpl1/20/NMR_system_settings.NA;
            theAmpl2 = theAmpl2/20/NMR_system_settings.NA;
            x = (theAmpl1*theAmpl1+theAmpl2*theAmpl2);
            x = sqrt(x);
            dataBuf_real[theTD + kk*20 + ii] = (int) x;
            dataBuf_imag[theTD + kk*20 + ii] = (int) 1000*(ii)/(20-1)-500;
        }
        dataBuf_imag[theTD + kk] = (int) NMR_system_settings.tuningcap;
    }
    //return the total number of data points acquired
    SetNMRParameters(i_acquiredTD, theTD+20*20);
    SetNMRParameters(i_freq, origFreq);
    SetNMRParameters(i_tuningcap, origCapBias);

    //NMR_system_settings.acquiredTD = theTD + 20*20;
    return (theTD + 20*20);
}


int Run_NMR_Tuning_mcbsp(void)
{

    int ii, acqPTs;                                                 // ii= index, acqpoints

    // pulse seq parameters
    int DS, NA;                                                         // Dummy Scan

    // phase table
    int ph1[4]   = {0,2,1,3};                                               // in unit of 90 deg
    int phacq[4] = {0,2,1,3};
    int phlength = 4;

//    Nint = NMR_system_settings.nint;
//    Nfrac = NMR_system_settings.nfrac;
//    PLL_freq_set2(Nint,Nfrac);                  // Ray Tang add spi_dac for frequency sweeping 11/02/2017

    PLL_freq_set3(NMR_system_settings.Freq*2);

    spi_dac_MCC(NMR_system_settings.tuningcap & 0x0000FFFF);    //using the lower 2 bytes. YS 2019/11/25
    AsicGainCtrl (NMR_system_settings.RecGain);

//    AsicGainCtrl(NMR_system_settings.RecGain); // Ray Tang add for winding down rec gain 11/03/2017
//    spi_dac_MCC(NMR_system_settings.tuningcap); // Ray Tang add spi_dac for tuning 11/02/2017

    DELAY_US(10000);

    DS = NMR_system_settings.DS;
    NA = NMR_system_settings.NA;
    NMR_system_settings.TD = 100 ;
    NMR_system_settings.T90 = 300 ;
    NMR_system_settings.RD = 1000;
    // parameters used in assisting the running of the seq
    Uint32  expTime;                                                    // total time for 1 run of pulse seq, obtain from the pulse seq itself
    Uint32  p[6];// = {500000,20,30,0,10,500};                              //{500000,20,30,0,10,500}
    //Uint32    p[6] = {5005,20,30,0,10,500};                               //{500000,20,30,0,10,500}

    /*
    p[0]=NMR_system_settings.RD     ;                                   // RD
    p[1]=NMR_system_settings.T90    ;                                   // T90 RF pulse width
    p[2]=NMR_system_settings.PL[0]  ;                                   // amp, PL[0]
    p[3]=0                          ;                                   // phase, 32 steps, to be cycled by ph1
    p[4]=NMR_system_settings.dw     ;                                   // dw time, us
    p[5]=NMR_system_settings.TD     ;
    */
    p[0]=NMR_system_settings.RD;                                                    // RD
    p[1]=NMR_system_settings.T90;                           // T90 RF pulse width
    p[2]=5;                                                            // amp, PL[0]
    p[3]=0;                                                             // phase, 32 steps, to be cycled by ph1
    p[4]=NMR_system_settings.dw;                                                            // dw time, us typical is 10us
    p[5]=NMR_system_settings.TD;                                                            // number of point to acq

    for (ii=0; ii<p[5]; ii++) dataBuf_real[ii] = dataBuf_imag[ii] = 0;  // reset data mem to 0

    // ---------------------------------------------
    // internal loop for phase cycling and averaging
    for (ii=-DS;ii<NA;ii++)
    {
        // update phase cycling
        if (ii<0)
            p[3]=0;                                             // set the phase of the pulse, first ph1 for dummy scan
        else
            p[3]=ph1[ii % phlength]*8;                                  // set the phase of the pulse

        expTime = TuningSeq(&gPulseSeq,p);                          // recreate the seq with the proper phase
                                                                        // total time for the experiment in US
                                                                        // gPulseSeq global record of pulse seq results
                                                                        // TuningSeq, RD + pulse. Acq during pulse
        // do NMR, ii<0 is dummy scans
        if (ii<0)
            acqPTs = Run_NMR_Accumulate_tuning_mcbsp(&gPulseSeq, expTime, p[4],p[5],  -1);   //dummy scan
        else
            acqPTs = Run_NMR_Accumulate_tuning_mcbsp(&gPulseSeq, expTime, p[4],p[5],  phacq[ii % phlength]);
    }
    NMR_system_settings.acquiredTD = acqPTs;

    return(acqPTs);
} // end of Run_NMR_Tuning



/* ------------------------------------------------------------ */
/*				Procedure Definitions							*/
/* ------------------------------------------------------------ */
/* 	Run_NMR_CPMG
**
**	Parameters:
**		none
**
**	Return Value:
**		not meaningful
**
**	Errors:
**		none
**
**	Description:
**		Perform CPMG with ph cycling
*/
int Run_NMR_CPMG(void)
{
    long    ii=0;
    int     GetechoShape = 0; // no echo shape:0, get echo shape: 1
    // ----------------------------------------------------
    // pulse seq parameters

    int NA=1;
    int DS = 0;

    int Necho ;   // number of echoes
    int NPTS ;       // acq points per echo

    // phase table
    int ph1[]={0,2,1,3};   // in unit of 90 deg
    int ph2[]={1,1,0,0};
    int phacq[] = {0,2,1,3};
    int phlength = 4;

    // reset the system parameters. Could be interactive
    strcpy(NMR_system_settings.SEQ, "CPMG");
    NA = NMR_system_settings.NA;
    DS = NMR_system_settings.DS;

    NPTS = NMR_system_settings.TE/NMR_system_settings.dw/2;

    if (GetechoShape == 0)
        Necho = NMR_system_settings.TD;
    else
        Necho = NMR_system_settings.TD/NPTS;

    // ----------------
    // parameters use in assisting the running of the seq
    Uint32  expTime;    // total time for 1 run of pulse seq, obtain from the pulse seq itself

    //PlsSeq thePulseSeq; // store the pulse seq - use the global def
    Uint32 theParameters[10];//"10, 1000, 32, 0, 500, 0"
    int acqPTs;

// download the pulse seq
// [0]  : RD,
// [1-3]: T90, amp, ph1,
// [4-5]: T180, ph2: P180 time and phase
// [6-8]: TE, Necho, NPTS : echo time, and number of echoes, and number of pt per echo
// [9] : dw

    theParameters[0]=NMR_system_settings.RD;   // RD
    theParameters[1]=NMR_system_settings.T90;        // T90 RF pulse width
    theParameters[2]=30;        // amp, PL[0]
    theParameters[3]=0;         // phase, 32 steps, to be cycled by ph1
    theParameters[4]=NMR_system_settings.T180;       //  T180 time, us
    theParameters[5]=8;         // phase of P180
    theParameters[6]=NMR_system_settings.TE;         // TE
    theParameters[7]=Necho;         // number of echoes
    theParameters[8]=NPTS;         // NPTS
    theParameters[9] = NMR_system_settings.dw;

    for (ii=0;ii<NMR_system_settings.TD;ii++) dataBuf_real[ii] = dataBuf_imag[ii] = 0;

// ---------------------------------------------
    // internal loop for phase cycling and averaging
    for (ii=-DS;ii<NA;ii++){
        // update phase cycling
        if (ii<0)
        {
            theParameters[3]=ph1[0]*8;              // set the phase of the pulse, first ph1 for dummy scan
            theParameters[5]=ph2[0]*8;
        }
        else
        {
            theParameters[3]=ph1[ii % phlength]*8; // set the phase of the pulse
            theParameters[5]=ph2[ii % phlength]*8;
        }

        expTime = CPMG2(&gPulseSeq,theParameters);    // recreate the seq with the proper phase
                                                        // total time for the experiment in US

        // do NMR, ii<0 is dummy scans
        if (GetechoShape==0) { // do not acquire echo shape
            if (ii<0)
            		acqPTs = Run_NMR_Accumulate_CPMG(&gPulseSeq, expTime, NMR_system_settings.dw,Necho, -1,NPTS, NULL);
            else
            		acqPTs = Run_NMR_Accumulate_CPMG(&gPulseSeq, expTime, NMR_system_settings.dw,Necho, phacq[ii % phlength],NPTS, NULL);
        } else { // acquire echo shape
            if (ii<0)
            		acqPTs = Run_NMR_Accumulate(&gPulseSeq, expTime, theParameters[9],Necho*NPTS, -1);
            else
            		acqPTs = Run_NMR_Accumulate(&gPulseSeq, expTime, theParameters[9],Necho*NPTS,phacq[ii % phlength]);
        }

        NMR_system_settings.acquiredTD = acqPTs;

    } // loop acquistion
      // end internal loop for phase cycling

    return(acqPTs);

} // end of Run_NMR_CPMG

int Run_NMR_CPMG_mcbsp(void)
{
    long    ii=0, GetechoShape;
    // ----------------------------------------------------
    // pulse seq parameters
    int dummyecho; //dummyecho is the number of dummy echoes
    int NA=1;
    int DS = 0;
    long Nint, Nfrac;

    int Necho ;   // number of echoes
    int NPTS ;       // acq points per echo

    // phase table


    int ph1[]={0,2,1,3};   // in unit of 90 deg
    int ph2[]={1,1,0,0};
    int phacq[] = {0,2,1,3};
    int phlength = 4;

//    Nint = NMR_system_settings.nint;
//    Nfrac = NMR_system_settings.nfrac;

//    PLL_freq_set2(Nint,Nfrac);
    PLL_freq_set3(NMR_system_settings.Freq*2);

    spi_dac_MCC(NMR_system_settings.tuningcap & 0x0000FFFF);    //using the lower 2 bytes
    AsicGainCtrl (NMR_system_settings.RecGain);


    DELAY_US(100);

    // reset the system parameters. Could be interactive
    strcpy(NMR_system_settings.SEQ, "CPMG");
    NA = NMR_system_settings.NA;
    DS = NMR_system_settings.DS;
    GetechoShape = NMR_system_settings.echoshape; // no echo shape:0, get echo shape: 1
    NPTS = NMR_system_settings.TE/NMR_system_settings.dw/2;
    dummyecho = NMR_system_settings.dummyecho;

    if (GetechoShape == 0)
        Necho = NMR_system_settings.TD*(1+dummyecho); //add dummy echo 9/4/17 Ray Tang
    else
        Necho = NMR_system_settings.TD/NPTS;

    // ----------------
    // parameters use in assisting the running of the seq
    Uint32  expTime;    // total time for 1 run of pulse seq, obtain from the pulse seq itself

    //PlsSeq thePulseSeq; // store the pulse seq - use the global def
    Uint32 theParameters[10];//"10, 1000, 32, 0, 500, 0"
    int acqPTs;

// download the pulse seq
// [0]  : RD,
// [1-3]: T90, amp, ph1,
// [4-5]: T180, ph2: P180 time and phase
// [6-8]: TE, Necho, NPTS : echo time, and number of echoes, and number of pt per echo
// [9] : dw

    theParameters[0]=NMR_system_settings.RD;   // RD
    theParameters[1]=NMR_system_settings.T90;        // T90 RF pulse width
    theParameters[2]=30;        // amp, PL[0]
    theParameters[3]=0;         // phase, 32 steps, to be cycled by ph1
    theParameters[4]=NMR_system_settings.T180;       //  T180 time, us
    theParameters[5]=8;         // phase of P180
    theParameters[6]=NMR_system_settings.TE;         // TE
    theParameters[7]=Necho;         // number of echoes
    theParameters[8]=NPTS;         // NPTS
    theParameters[9] = NMR_system_settings.dw;

    for (ii=0;ii<NMR_system_settings.TD;ii++) dataBuf_real[ii] = dataBuf_imag[ii] = 0;
// ---------------------------------------------
    // internal loop for phase cycling and averaging
    for (ii=-DS;ii<NA;ii++){
        // update phase cycling
        if (ii<0)
        {
            theParameters[3]=ph1[0]*8;              // set the phase of the pulse, first ph1 for dummy scan
            theParameters[5]=ph2[0]*8;
        }
        else
        {
            theParameters[3]=ph1[ii % phlength]*8; // set the phase of the pulse
            theParameters[5]=ph2[ii % phlength]*8;
        }

        expTime = CPMG2(&gPulseSeq,theParameters);    // recreate the seq with the proper phase
                                                        // total time for the experiment in US

        // do NMR, ii<0 is dummy scans
        if (GetechoShape==0) { // do not acquire echo shape
            if (ii<0)
                    acqPTs = Run_NMR_Accumulate_CPMG_mcbsp(&gPulseSeq, expTime, NMR_system_settings.dw,dummyecho,Necho, -1,NPTS, NULL);
            else
                    acqPTs = Run_NMR_Accumulate_CPMG_mcbsp(&gPulseSeq, expTime, NMR_system_settings.dw,dummyecho,Necho, phacq[ii % phlength],NPTS, NULL);
        } else { // acquire echo shape
            if (ii<0)
                    acqPTs = Run_NMR_Accumulate_mcbsp(&gPulseSeq, expTime, theParameters[9],Necho*NPTS, -1);
            else
                    acqPTs = Run_NMR_Accumulate_mcbsp(&gPulseSeq, expTime, theParameters[9],Necho*NPTS,phacq[ii % phlength]);
        }

        NMR_system_settings.acquiredTD = acqPTs;

    } // loop acquistion
      // end internal loop for phase cycling

    return(acqPTs);

} // end of Run_NMR_CPMG


int Run_NMR_IRCPMG_mcbsp(void)
{
    long    ii=0, GetechoShape;
    // ----------------------------------------------------
    // pulse seq parameters
    int dummyecho; //dummyecho is the number of dummy echoes
    int NA=1;
    int DS = 0;
  //  long Nint, Nfrac;

    int Necho ;   // number of echoes
    int NPTS ;       // acq points per echo

    // phase table
    int ph0[]={0,0,0,0};
    int ph1[]={0,2,1,3};   // in unit of 90 deg
    int ph2[]={1,1,0,0};
    int phacq[] = {0,2,1,3};
    int phlength = 4;

    PLL_freq_set3(NMR_system_settings.Freq*2);

    spi_dac_MCC(NMR_system_settings.tuningcap & 0x0000FFFF);    //using the lower 2 bytes
    AsicGainCtrl (NMR_system_settings.RecGain);


    // reset the system parameters. Could be interactive
    strcpy(NMR_system_settings.SEQ, "CPMG");
    NA = NMR_system_settings.NA;
    DS = NMR_system_settings.DS;
    GetechoShape = 0; // no echo shape:0 for T1T2
    NPTS = NMR_system_settings.TE/NMR_system_settings.dw/2;
    dummyecho = NMR_system_settings.dummyecho;

    if (GetechoShape == 0)
        Necho = NMR_system_settings.TD*(1+dummyecho); //add dummy echo 9/4/17 Ray Tang
    else
        Necho = NMR_system_settings.TD/NPTS;

    // ----------------
    // parameters use in assisting the running of the seq
    Uint32  expTime;    // total time for 1 run of pulse seq, obtain from the pulse seq itself

    //PlsSeq thePulseSeq; // store the pulse seq - use the global def
    Uint32 theParameters[12];//"10, 1000, 32, 0, 500, 0"
    int acqPTs;

// download the pulse seq
// [0]  : RD,
// [1-3]: T90, amp, ph1,
// [4-5]: T180, ph2: P180 time and phase
// [6-8]: TE, Necho, NPTS : echo time, and number of echoes, and number of pt per echo
// [9] : dw
// [10]: encoding time
// [11]: phase for 1st 180 pulse
    theParameters[0]=NMR_system_settings.RD;   // RD
    theParameters[1]=NMR_system_settings.T90;        // T90 RF pulse width
    theParameters[2]=30;        // amp, PL[0]
    theParameters[3]=0;         // phase, 32 steps, to be cycled by ph1
    theParameters[4]=NMR_system_settings.T180;       //  T180 time, us
    theParameters[5]=8;         // phase of P180
    theParameters[6]=NMR_system_settings.TE;         // TE
    theParameters[7]=Necho;         // number of echoes
    theParameters[8]=NPTS;         // NPTS
    theParameters[9] = NMR_system_settings.dw;
    theParameters[10] = NMR_system_settings.tau;
    theParameters[11] = 0;

    for (ii=0;ii<NMR_system_settings.TD;ii++) dataBuf_real[ii] = dataBuf_imag[ii] = 0;

// ---------------------------------------------
    // internal loop for phase cycling and averaging
    for (ii=-DS;ii<NA;ii++){
        // update phase cycling
        if (ii<0)
        {
            theParameters[3]=ph1[0]*8;              // set the phase of the pulse, first ph1 for dummy scan
            theParameters[5]=ph2[0]*8;
            theParameters[11]=ph0[0]*8;
        }
        else
        {
            theParameters[3]=ph1[ii % phlength]*8; // set the phase of the pulse
            theParameters[5]=ph2[ii % phlength]*8;
            theParameters[11]=ph0[ii % phlength]*8;
        }

        expTime = IRCPMG(&gPulseSeq,theParameters);    // recreate the seq with the proper phase
                                                        // total time for the experiment in US

        // do NMR, ii<0 is dummy scans
        if (GetechoShape==0) { // do not acquire echo shape
            if (ii<0)
                    acqPTs = Run_NMR_Accumulate_CPMG_mcbsp(&gPulseSeq, expTime, NMR_system_settings.dw,dummyecho,Necho, -1,NPTS, NULL);
            else
                    acqPTs = Run_NMR_Accumulate_CPMG_mcbsp(&gPulseSeq, expTime, NMR_system_settings.dw,dummyecho,Necho, phacq[ii % phlength],NPTS, NULL);
        } else { // acquire echo shape
            if (ii<0)
                    acqPTs = Run_NMR_Accumulate_mcbsp(&gPulseSeq, expTime, theParameters[9],Necho*NPTS, -1);
            else
                    acqPTs = Run_NMR_Accumulate_mcbsp(&gPulseSeq, expTime, theParameters[9],Necho*NPTS,phacq[ii % phlength]);
        }

        NMR_system_settings.acquiredTD = acqPTs;

    } // loop acquistion
      // end internal loop for phase cycling

    return(acqPTs);

} // end of Run_NMR_CPMG


int Run_NMR_Accumulate_CPMG_mcbsp(PlsSeq *inSeq, unsigned long expTime, int DwellTime, int dummyecho, int TD, int inAcqPhase, int NPTS, int *echoFilter1)
{
            int   i, echoNumber=0;
            unsigned long k=0;
            unsigned long   index;
            const Uint32    US_CT = 75;                                  // CPU clock count per microsecond divided by 2. Ray 9/15/2017
            unsigned long   timeStamp1=0,timeStamp2=0;                  // change to unsigned by Ray Tang 9/14/2017
            int16  tmpTop, tmpBottom, tmpReal, tmpImag;

            //   int     echoShape_real[NPTS],echoShape_imag[NPTS];

        //    int     filterWeight = 0;
            unsigned long   totalPTs;

            totalPTs = (long) TD*NPTS;

           unsigned long ptsPerEcho = NPTS;  // this needs to be consistent with NPTS in the main program
           int echoFilter[500];

//                for (i=0;i<ptsPerEcho;i++)
//                {
//                    echoShape_real[i] = echoShape_imag[i] = 0;
//                }

  //              make a flat filter
                int i1 = NPTS/2;

                for (i=0;i<NPTS;i++)
                    echoFilter[i]=0;

                for (i=(i1-1);i<(i1+1);i++)
                    echoFilter[i]=1;
//
//                for (i=i1;i<NPTS;i++)
//                    echoFilter[i]=0;
//                for (i=0;i<NPTS;i++)
//                    filterWeight += echoFilter [i];

            if (inSeq != NULL)
            {
                DlPlSeq(inSeq);                                                         // this downloads the sequence
            }

                ReloadCpuTimer0() ;
                StartCpuTimer0();
                EN_NMR_mode();
                index=0;

              //  PrepareNMRADC();            // set ADC SPI conf.


                // and start acquiring data
                //PieCtrlRegs.PIEIFR1.bit.INTx4 = 0;

    //
                DINT;
    //                // start the pulse sequence.
                StartNMRASIC_SEQ();
    //
    //                // store the start time stamp
    //                // timer counts down!
                timeStamp2 = ReadCpuTimer0Counter();
                timeStamp1 = ReadCpuTimer0Counter() - expTime*US_CT;                    // this is the end time of the sequence

               //                //
               while(ReadCpuTimer0Counter() > timeStamp1 )
                    {
              //  while( PieCtrlRegs.PIEIFR1.bit.INTx4 == 0 ) {asm(" nop");}              // Master waits until XINT1

                if (mReadNMR_ACQ_ &&  (index < totalPTs) )
                {
                    McbspbRegs.SPCR2.bit.GRST   = 1;                                        // Sample rate generator enabled
                    delay_loop();
                    McbspbRegs.SPCR2.bit.XRST   = 1;                                        // Transmitter enabled, not required for uNMR
                    McbspbRegs.SPCR1.bit.RRST   = 1;                                        // Release RX from Reset
                    McbspbRegs.SPCR2.bit.FRST   = 1;                                        // Frame Sync Generator enabled, this must be after GRST
                    McbspbRegs.SPCR2.bit.XRDY   = 1;                                        // Transmitter ready to accept new data

        //            k = (long)(index % (ptsPerEcho-1)); //track points collected within an echo
        //            echoNumber = index / (ptsPerEcho-1); //track the number of echoes

                    k = (long)(index % (ptsPerEcho)); //track points collected within an echo
                    echoNumber = index / (ptsPerEcho); //track the number of echoes

       //         while(index < TD)
       //         {
                    while( McbspbRegs.SPCR1.bit.RRDY == 0 ) {asm(" nop");}              // Master waits until RX data is ready

                    tmpTop = McbspbRegs.DRR2.all & 0x3fff;                              // Read DRR2 first.
                    tmpBottom = McbspbRegs.DRR1.all & 0x3fff;                           // Then read DRR1 to complete receiving of data

                    GpioDataRegs.GPCTOGGLE.bit.GPIO76  = 1;                             // LED Indicator, Only used for testing Mcbsp

                    // ii < 0 means dummy scans, do not accumulate
                      // put in dummyecho Ray Tang 09/01/2017

                        switch (inAcqPhase)
                        {
                        case 0:tmpReal = tmpTop; tmpImag = tmpBottom;break;
                        case 3:tmpReal = -tmpBottom; tmpImag = tmpTop;break;            // case numbers changed and tested by Ray. 08/17/2017
                        case 2:tmpReal = -tmpTop; tmpImag = -tmpBottom;break;
                        case 1:tmpReal = tmpBottom; tmpImag = -tmpTop;break;
                        case -1:tmpReal = 0; tmpImag = 0; break;                      // all other values, do not accumulate

                        };

                        if (echoNumber%(dummyecho+1) !=0) {tmpReal = 0; tmpImag = 0;};

                        dataBuf_real[echoNumber/(dummyecho+1)] += tmpReal*echoFilter[k]/10;   // add dummy echo in 9/3/2017                           // normalize data to the number of acquisition
                        dataBuf_imag[echoNumber/(dummyecho+1)] += tmpImag*echoFilter[k]/10;

//                        dataBuf_real[echoNumber] += tmpReal/10;                              // normalize data to the number of acquisition
//                        dataBuf_imag[echoNumber] += tmpImag/10;
                        index ++;                                                           // next data point

                }
                else
                {
                McbspbRegs.SPCR2.bit.XRST   = 0;                                        // Transmitter enabled, not required for uNMR
                McbspbRegs.SPCR1.bit.RRST   = 0;                                        // Release RX from Reset
                McbspbRegs.SPCR2.bit.FRST   = 0;                                        // Release RX from Reset
                McbspbRegs.SPCR2.bit.GRST   = 0;
                }
             }
                // Sample rate generator disabled
                StopNMRASIC_SEQ();
                DELAY_US(10);
                EINT;

                return(index); // return the total data point acquired

} // end of int Run_NMR_Accumulate_CPMG


/* **************************************************
 * *************** END OF PULSE SEQ *****************
 * **************************************************
 */

// local supporting routines

/* ************************************************** ********************************
 * *************** PULSE SEQ SUPPORT **************** ********************************
 * ************************************************** ********************************
*/
/* run nmr with SPI data acquisition
 * duplexer in tuning mode
 * This should only be used with tuning sequence.
*/
int Run_NMR_Accumulate_test_tuning(PlsSeq *inSeq, unsigned long expTime, int DwellTime, int TD,  int inAcqPhase)
{
	int     index;
	Uint32	tmpData;
	const Uint32 	US_CT = 150;									// CPU clock count per microsecond
	Uint32	timeStamp1=0, timeStamp2=0, DWInTicks = DwellTime*US_CT - 52;

	if (inSeq != NULL)
	{
		DlPlSeq(inSeq);                                     // this downloads the sequence, only the tuning seq
	}
	else {
		SetErrorCode(10);
	}
	DELAY_US(1000);										// wait some time for PLL to settle
	PrepareNMRADC();										// initialze spi for ADC

	ReloadCpuTimer0() ;									// timer0 starts
    StartCpuTimer0();

	EN_Tuning_mode();									// Enable acquisition during the RF pulses. On ASIC, this is SNS->high
	DELAY_US(1000);											// wait some time

	index=0;
    // Disable Interrupts at the CPU level:
    DINT;

	// start the pulse sequence.
	StartNMRASIC_SEQ();
	// store the start time stamp
	timeStamp1 = ReadCpuTimer0Counter() - expTime*US_CT;					// this is the end time of the sequence
	//
	while( (ReadCpuTimer0Counter() > timeStamp1 ))
	{
		// do not use mReadNMR_ACQ_, just acquire from before the pulse, during the pulse and afterward.
		if (  (index < TD) )
		{
			timeStamp2=ReadCpuTimer0Counter() - DWInTicks;			// may need to adjust/reduce it a bit to make it accurately DwellTime

			tmpData = SPIRead32bitWordFromADCFast();
			switch (inAcqPhase)
				{
				case 0:
					dataBuf_real[index] += (int16) ((tmpData & 0x3fff0000) >> 18)  ;
					dataBuf_imag[index] += (int16) ((tmpData & 0x00003fff) >>2) ;
					break;
				case 2:
					dataBuf_real[index] -= (int16) ((tmpData & 0x3fff0000) >> 18)  ;;
					dataBuf_imag[index] -= (int16) ((tmpData & 0x00003fff) >>2) ;
				break;
				case 1:
					dataBuf_real[index] += (int16) ((tmpData & 0x00003fff) >>2) ;
					dataBuf_imag[index] -= (int16) ((tmpData & 0x3fff0000) >> 18)  ;;
				break;
				case 3:
					dataBuf_real[index] -= (int16) ((tmpData & 0x00003fff) >>2) ;
					dataBuf_imag[index] += (int16) ((tmpData & 0x3fff0000) >> 18)  ;;
				break;
				};
			index ++;
			while(ReadCpuTimer0Counter() >  timeStamp2) {};				// wait till the dwell is up
		}// next data point
	}

	StopNMRASIC_SEQ();
	FinishNMRADC();
	DELAY_US(1);

	// return to normal NMR mode.
	EN_NMR_mode();
	// Enable Interrupts at the CPU level
    EINT;

	return(index); // return the total data point acquired

} // end of int Run_NMR_Accumulate_test_tuning

// YS test
// run nmr with SPI data acquisition
// duplexer in normal mode
/*
 * Tested with FID and CPMG. Finalized. 2017, Feb 18
 */
int Run_NMR_Accumulate(PlsSeq *inSeq, unsigned long expTime, int DwellTime, int TD,  int inAcqPhase)
{
	int     index=0,i;
	Uint32	tmpData;
	int16	x,y;
//	int16 	tmpReal, tmpImag;
	const Uint32 	US_CT = 150;									// CPU clock count per microsecond
	long		timeStamp1=0, timeStamp2=0,
			DWInTicks = DwellTime*US_CT- 63;		// the offset, checked for FID and CPMG. YS FEb 24,2017.
												// Disabled interrupts (DINT). Timing much more stable.
	if (inSeq != NULL)
	{
		DlPlSeq(inSeq);                                     // this downloads the sequence
	}
	else{
		SetErrorCode(20);								// if no input seq
	}
	DELAY_US(1000);

	PrepareNMRADC();			// set ADC SPI conf.

    ReloadCpuTimer0() ;
    StartCpuTimer0();
	EN_NMR_mode();

	DELAY_US(1000);											// wait some time for PLL to settle

	index=0;
	// test YS. feb 25. 2017
    // Disable Interrupts at the CPU level:
    DINT;

	// start the pulse sequence.
	StartNMRASIC_SEQ();

	// store the start time stamp
	// timer counts down!
	timeStamp1 = ReadCpuTimer0Counter() - expTime*US_CT;					// this is the end time of the sequence
	//
	while( (ReadCpuTimer0Counter() > timeStamp1 ))
	{
		// Uint16 mReadNMR_ACQ(void) or mReadNMR_ACQ_ is defined in asic.c
		if (mReadNMR_ACQ_ &&  (index < TD) )								// if data is ready
		{
			timeStamp2=ReadCpuTimer0Counter() - DWInTicks;			// may need to adjust/reduce it a bit to make it accurately DwellTime
			for (i=0;i<3;i++) {asm(" NOP");}

			if (mReadNMR_ACQ_)			// if still ok to acquire.
			{
				tmpData = SPIRead32bitWordFromADCFast();		//tmpData = SPIRead32bitWordFromADC();
				x = (int16) ((tmpData & 0x3fff0000) >> 18)  ;
				y = (int16) ((tmpData & 0x00003fff) >>2) ;
				// ADC result is always positive
				// only 14 bit ADC, thus 0x3fff, then shift right two bits
				switch (inAcqPhase)
					{
					case 0:
						dataBuf_real[index] += x  ;
						dataBuf_imag[index] += y ;
						break;
					case 2:
						dataBuf_real[index] -= x  ;
						dataBuf_imag[index] -= y;
					break;
					case 1:
						dataBuf_real[index] += y ;
						dataBuf_imag[index] -= x  ;
					break;
					case 3:
						dataBuf_real[index] -= y ;
						dataBuf_imag[index] += x  ;
					break;
					default:
						break;
					};
				index++;
			}
			while(ReadCpuTimer0Counter() >=  timeStamp2) {};				// wait till the dwell is up
		}// next data point
	}
	StopNMRASIC_SEQ();
	FinishNMRADC();
	DELAY_US(1);
	EN_NMR_mode();

	// Enable Interrupts at the CPU level
    EINT;

	return(index); // return the total data point acquired

} // end of int Run_NMR_Accumulate

// CPMG acq
/*
 * Tested with FID and CPMG. Finalized. 2017, Feb 18
 * Turn off interrupt (by DINT) during data acquisition.
 */
/*
 * NPts : number of points to acquire for an echo
 * echoFilter : an int array, so far real
 * The full echo shape will be multiplied with the echoFilter to yield echo amplitude (complex)
 * the ptsPerEcho should be consistent with NPTS, which is not the case. needs further coding  -Ray 8/2017
 */
int Run_NMR_Accumulate_CPMG(PlsSeq *inSeq, unsigned long expTime, int DwellTime, int TD,  int inAcqPhase, int NPts, int *echoFilter1)
{
	int     index=0,i, echoNumber=0 , k;
	Uint32	tmpData;
	int16 	tmpReal, tmpImag;
	const Uint32 	US_CT = 150;									// CPU clock count per microsecond
	long		timeStamp1=0, timeStamp2=0,
			DWInTicks = DwellTime*US_CT- 52;		// the offset, checked for FID and CPMG. YS FEb 24,2017.
												// Disabled interrupts (DINT). Timing much more stable.
	int		echoFilter[20];						// temp: 20 point
	int		echoShape_real[20],echoShape_imag[20];

	int		filterWeight = 0;
	int		totalPTs = 20*TD;
	int		ptsPerEcho=20;  // this needs to be consistent with NPTS in the main program?

	for (i=0;i<ptsPerEcho;i++)
	{
		echoShape_real[i] = echoShape_imag[i] = 0;
	}

	//make a flat filter
	for (i=0;i<8;i++)
		echoFilter [i]=0;

	for (i=12;i<20;i++)
		echoFilter [i]=0;

	for (i=8;i<12;i++)
		echoFilter [i]=1;

	for (i=0;i<20;i++)
		filterWeight += echoFilter [i];


	if (inSeq != NULL)
	{
		DlPlSeq(inSeq);                                     // this downloads the sequence
	}
	else{
		SetErrorCode(20);								// if no input seq
	}
	DELAY_US(1000);

	PrepareNMRADC();			// set ADC SPI config

    ReloadCpuTimer0() ;
    StartCpuTimer0();
	EN_NMR_mode();
	DELAY_US(1000);											// wait some time for PLL to settle

    // Disable Interrupts at the CPU level:
    DINT;
	echoNumber = 0;		// echo number
	index = 0;

	// start the pulse sequence.
	StartNMRASIC_SEQ();

	// store the start time stamp
	// timer counts down!
	timeStamp1 = ReadCpuTimer0Counter() - expTime*US_CT;					// this is the end time of the sequence
	//
	while( (ReadCpuTimer0Counter() > timeStamp1 ))
	{
		// Uint16 mReadNMR_ACQ(void) or mReadNMR_ACQ_ is defined in asic.c
		if (mReadNMR_ACQ_ &&  (index < totalPTs))								// if data is ready
		{
			timeStamp2=ReadCpuTimer0Counter() - DWInTicks;			// may need to adjust/reduce it a bit to make it accurately DwellTime
			for (i=0;i<3;i++) {asm(" NOP");}
			tmpReal = 0;
			tmpImag = 0;
			k = (index % ptsPerEcho );
			echoNumber = index / ptsPerEcho;

			if (mReadNMR_ACQ_)			// if still ok to acquire, then get one point
			{
				tmpData = SPIRead32bitWordFromADCFast();			//or tmpData = SPIRead32bitWordFromADC();
				switch (inAcqPhase)
					{
					case 0:
						tmpReal = (int16) ((tmpData & 0x3fff0000) >> 18)  ;
						tmpImag = (int16) ((tmpData & 0x00003fff) >>2) ;
						break;
					case 2:
						tmpReal -= (int16) ((tmpData & 0x3fff0000) >> 18)  ;
						tmpImag -= (int16) ((tmpData & 0x00003fff) >>2) ;
					break;
					case 1:
						tmpReal += (int16) ((tmpData & 0x00003fff) >>2) ;
						tmpImag -= (int16) ((tmpData & 0x3fff0000) >> 18)  ;
					break;
					case 3:
						tmpReal -= (int16) ((tmpData & 0x00003fff) >>2) ;
						tmpImag += (int16) ((tmpData & 0x3fff0000) >> 18)  ;
					break;
					};
				index ++;
			}

			dataBuf_real[echoNumber] += tmpReal*echoFilter[k];
			dataBuf_imag[echoNumber] += tmpImag*echoFilter[k];

			// save the echo shape
			if ((echoNumber < 100) && (1))
			{
				echoShape_real[k] +=tmpReal;
				echoShape_imag[k] +=tmpImag;
			}
			while(ReadCpuTimer0Counter() >  timeStamp2) {};				// wait till the dwell is up
		}// next data point
	}
	StopNMRASIC_SEQ();
	FinishNMRADC();
	DELAY_US(1);
	EN_NMR_mode();

	// Enable Interrupts at the CPU level
    EINT;
	return(index); // return the total data point acquired

} // end of int Run_NMR_Accumulate_CPMG



// FID accumulate function -- McCowan
/*
int Run_NMR_Accumulate_test(PlsSeq *inSeq, unsigned long expTime, int DwellTime, int TD,  int NA, int DS, int inAcqPhase)
    {
		int     index, ii;

        if (inSeq != NULL)
        {
            DlPlSeq(inSeq);                                     // this downloads the sequence
        }

            index=0;

            // and start acquiring data
            PieCtrlRegs.PIEIFR1.bit.INTx4 = 0;
            StartNMRASIC_SEQ();

        	while( PieCtrlRegs.PIEIFR1.bit.INTx4 == 0 ) {asm(" nop");}         	// Master waits until XINT1
            McbspbRegs.SPCR2.bit.GRST	= 1;         							// Sample rate generator enabled
            delay_loop();
            McbspbRegs.SPCR2.bit.XRST	= 1;         							// Transmitter enabled, not required for uNMR
        	McbspbRegs.SPCR1.bit.RRST	= 1; 									// Release RX from Reset
            McbspbRegs.SPCR2.bit.FRST	= 1;         							// Frame Sync Generator enabled, this must be after GRST
            McbspbRegs.SPCR2.bit.XRDY   = 1;									// Transmitter ready to accept new data


            while(index < 1000)
            {
				while( McbspbRegs.SPCR1.bit.RRDY == 0 ) {asm(" nop");}         				// Master waits until RX data is ready
				tmpTop = McbspbRegs.DRR2.all & 0x3fff;                      				// Read DRR2 first.
				tmpBottom = McbspbRegs.DRR1.all & 0x3fff;                      				// Then read DRR1 to complete receiving of data
				GpioDataRegs.GPCTOGGLE.bit.GPIO76  = 1;										// Only used for testing Mcbsp

				// ii < 0 means dummy scans, do not accumulate
				if (ii>=0) {
					switch (inAcqPhase)
					{
					case 0:tmpReal = tmpTop; tmpImag = tmpBottom;break;
					case 1:tmpReal = -tmpBottom; tmpImag = tmpTop;break;
					case 2:tmpReal = -tmpTop; tmpImag = -tmpBottom;break;
					case 3:tmpReal = tmpBottom; tmpImag = -tmpTop;break;
					default:tmpReal = 0; tmpImag = 0;       					// all other values, do not accumulate
					break;
					};

					dataBuf_real[index] += tmpReal/10; 							// normalize data to the number of acquisition
					dataBuf_imag[index] += tmpImag/10;
				}
				index ++;        												// next data point

			}
            McbspbRegs.SPCR2.bit.XRST	= 0;         							// Transmitter enabled, not required for uNMR
            McbspbRegs.SPCR1.bit.RRST	= 0; 									// Release RX from Reset
            McbspbRegs.SPCR2.bit.FRST	= 0; 									// Release RX from Reset
			McbspbRegs.SPCR2.bit.GRST	= 0;         							// Sample rate generator disabled
			StopNMRASIC_SEQ();
			DELAY_US(10);
			return(index); // return the total data point acquired

} // end of int Run_NMR_Accumulate_test

*/



/* ------------------------------------------------------------ */
/*				Procedure Definitions							*/
/* ------------------------------------------------------------ */
/* 	Run_NMR_CPMG
**
**	Parameters:
**		none
**
**	Return Value:
**		not meaningful
**
**	Errors:
**		none
**
**	Description:
**		Perform CPMG with ph cycling
*/
/*
int Run_NMR_CPMG(void)
{

    //int     res;
    long    ii=0;
    int     GetechoShape = 1; // no echo shape:0, get echo shape: 1
    // ----------------------------------------------------
    // pulse seq parameters

    int NA=1;
    int DS = 0;

    int Necho ;   // number of echoes
    int NPTS ;       // acq points per echo

    // phase table
    int ph1[2]={0,2};   // in unit of 90 deg
    int ph2[2]={1,1};
    int phacq[2] = {0,2};
    int phlength = 2;


    //ResetNMR();															// default config of NMR ASIC found in nmr.c
    //InitNMR();															// found in nmr.c

    //AsicGainCtrl (NMR_system_settings.RecGain);
    //DELAY_US(1000);

    // reset the system parameters. Could be interactive
    strcpy(NMR_system_settings.SEQ, "CPMG");
    NA = NMR_system_settings.NA;
    DS = NMR_system_settings.DS;

    NPTS = NMR_system_settings.TE/NMR_system_settings.dw/2;

    if (GetechoShape == 0)
        Necho = NMR_system_settings.TD;
    else
        Necho = NMR_system_settings.TD/NPTS;


    // ----------------
    // parameters use in assisting the running of the seq
    Uint32  expTime;    // total time for 1 run of pulse seq, obtain from the pulse seq itself

    //PlsSeq thePulseSeq; // store the pulse seq - use the global def
    Uint32 theParameters[10];//"10, 1000, 32, 0, 500, 0"
    int acqPTs;

// download the pulse seq
// [0]  : RD,
// [1-3]: T90, amp, ph1,
// [4-5]: T180, ph2: P180 time and phase
// [6-8]: TE, Necho, NPTS : echo time, and number of echoes, and number of pt per echo
// [9] : dw

    theParameters[0]=NMR_system_settings.RD;   // RD
    theParameters[1]=NMR_system_settings.T90;        // T90 RF pulse width
    theParameters[2]=30;        // amp, PL[0]
    theParameters[3]=0;         // phase, 32 steps, to be cycled by ph1
    theParameters[4]=NMR_system_settings.T180;       //  T180 time, us
    theParameters[5]=8;         // phase of P180
    theParameters[6]=NMR_system_settings.TE;         // TE
    theParameters[7]=Necho;         // number of echoes
    theParameters[8]=NPTS;         // NPTS
    theParameters[9] = NMR_system_settings.dw;

    for (ii=0;ii<NMR_system_settings.TD;ii++) dataBuf_real[ii] = dataBuf_imag[ii] = 0;

// ---------------------------------------------
    // internal loop for phase cycling and averaging
    for (ii=-DS;ii<NA;ii++){
        // update phase cycling
        if (ii<0)
        {
            theParameters[3]=ph1[0]*8;              // set the phase of the pulse, first ph1 for dummy scan
            theParameters[5]=ph2[0]*8;
        }
        else
        {
            theParameters[3]=ph1[ii % phlength]*8; // set the phase of the pulse
            theParameters[5]=ph2[ii % phlength]*8;
        }

        expTime = CPMG2(&gPulseSeq,theParameters);    // recreate the seq with the proper phase
                                                        // total time for the experiment in US

        // do NMR, ii<0 is dummy scans
        if (GetechoShape==0) { // do not acquire echo shape
//            if (ii<0)
//            acqPTs = Run_NMR_Accumulate_CPMG(&gPulseSeq, expTime, NMR_system_settings.dw,Necho, 1,  0, -1,NPTS);
//            else
//            acqPTs = Run_NMR_Accumulate_CPMG(&gPulseSeq, expTime, NMR_system_settings.dw,Necho, 1,  0, phacq[ii % phlength],NPTS);
        } else { // acquire echo shape
            if (ii<0)
            		acqPTs = Run_NMR_Accumulate(&gPulseSeq, expTime, theParameters[9],Necho*NPTS, -1);
            else
            		acqPTs = Run_NMR_Accumulate(&gPulseSeq, expTime, theParameters[9],Necho*NPTS,phacq[ii % phlength]);
        }

        NMR_system_settings.acquiredTD = acqPTs;


    } // loop acquistion
      // end internal loop for phase cycling

    return(acqPTs);

} // end of Run_NMR_CPMG
*/

void PrepareNMRADC()
{
 //    ResetNMR();															// default config of NMR ASIC found in nmr.c
 //    InitNMR();															// found in nmr.c

//	PLL_init();
// 	PLL_freq_set(NMR_system_settings.Freq*2);			// initialize PLL every time the sequecne starts. May help with phase coherence.

// 	 spi_dac(NMR_system_settings.tuningcap);
 	 spi_dac_MCC(NMR_system_settings.tuningcap);
     AsicGainCtrl (NMR_system_settings.RecGain);

    // configure spi for ADC
  	// POL=0, PHA=1, 16-bits word, 2 FIFO reg, speed=>18.5 MHz, max 75/4=18.5 MHz
  	// ClkSpeedDiv set to 3
    //  configure_SPI(0, 1, 15, 2, 3); //, Uint16 PHA, Uint16 BITS, Uint16 nFIFO, Uint16 ClkSpeedDiv)

  	// GPIO0, uC CLK ADC 3V3. This is the conversion trigger for ADC.
  	//GpioDataRegs.GPACLEAR.bit.GPIO0 		= 1;				// uC CLK ADC 3V3, set to low
  	//GpioCtrlRegs.GPAPUD.bit.GPIO0 			= 0;			// pull-up enabled

}

void FinishNMRADC()
{
	GpioCtrlRegs.GPAPUD.bit.GPIO0 			= 1;			// disable pull-up

}

/*
 * This routine is used to test new methods, sequences.
 * For serial communication, this is experiment 100 (0x64), used in "Do_NMR_experiments(100)"
 * For the serial command from matlab:
 * NMR_job = 101;
 * code1 = hex2dec('6401'); % run Run_NMR_test() command, the second byte (0x01) means 1 scan
 *
 */
int Run_NMR_test(void )
{

    return Run_NMR_NOE1dFID_mcbsp();
}


// FEb 2017. test seq phase problem
// FID sometime jump phase by pi.
// code 07
/* test 2017, feb 15. Received signals show smetime a pi phase jump. Try to find the cause.
* Conclusion: TX and RX phases are made in different electronics. TX phase is made from RF in the multiphase generator by DLL
* with guarranteed phase and duty cycle. RX phase is made from LO by division of 2. It is possible that it can have two stable output, 0 or pi phase.
* The test showed that only resetting the freq (PLL) can result in such RX phase jump.
*/
/*
 * Test 2. feb 20. how to run faster acquisition. spi=>18.5 Mhz,
 * Simplify the code in adc
 */
int Run_NMR_test2017(void )
{
    long    ii=0, phase=0;
    int acqPTs = 20;
	Uint32 i;												// 0, 0 all transmit's on rising edge. Inactive lo
	Uint32 data;
	Uint32 x1, x2;


    for (ii=0; ii<acqPTs; ii++) dataBuf_real[ii] = dataBuf_imag[ii] = 0;	// reset data mem to 0


    PrepareNMRADC();	// set SPI

    	for (ii=0;ii<acqPTs;ii++)
    	{
			// GPIO0, uC CLK ADC 3V3. This is the conversion trigger for ADC.
//			GpioDataRegs.GPACLEAR.bit.GPIO0 		= 1;				// uC CLK ADC 3V3, set to low
//			GpioCtrlRegs.GPAPUD.bit.GPIO0 			= 0;			// pull-up enabled


			// read SPI bus to get a 32-bit word, or two 16-bits words
			//EALLOW;
			// David uses 0, 1. Try others
			// According to NMR4YD, 1407A expect falling edge
	//    	SpiaRegs.SPICCR.bit.CLKPOLARITY		= 0;				// 0, 1 all transmit's on rising edge delayed by 1/2 clk. Inactive lo   0 1
	//    	SpiaRegs.SPICTL.bit.CLK_PHASE 		= 1;				// 1, 0 all transmit's on falling edge. Inactive Hi 1 0
																// 1, 1 all transmit's on falling edge delayed by 1/2 clk. Inactive Hi
			// try to enable this pull-up.
	//    	GpioCtrlRegs.GPBPUD.bit.GPIO55 		= 0;	   			// disable (1) pull-up for GPIO55 SPI_MISOA, enable (0)

	//    	SpiaRegs.SPICCR.bit.SPICHAR 		= 0x0F;				// 16 bit word length
	//    	SpiaRegs.SPIFFRX.bit.RXFFIL			= 2;				// number states how many words fill FIFO, YS. 2 should be good.
			SpiaRegs.SPIFFRX.bit.RXFIFORESET 	= 0;				// 0 to reset the FIFO and hold in reset
			SpiaRegs.SPIFFRX.bit.RXFIFORESET 	= 1;				// 1 to Re-enable FIFO
	//		SpiaRegs.SPIFFRX.bit.RXFFINTCLR 	= 1;				// 1 to clear fag of RXFIFORESET
			//EDIS;

			GpioDataRegs.GPASET.bit.GPIO0 		= 1;				// set to high for a moment to trigger ADC conversion.

			for (i=0;i<1;i++){asm(" NOP");}
			GpioDataRegs.GPACLEAR.bit.GPIO0 		= 1;				// uC CLK ADC 3V3, set to low
//			for (i=0;i<1;i++){asm(" NOP");}

			// does not matter what the values are transmitted.
			SpiaRegs.SPITXBUF = 0x00F0;
			SpiaRegs.SPITXBUF = 0x00FF;
			while(SpiaRegs.SPIFFRX.bit.RXFFINT != 1){}				// while RXFFINT FIFO interupt bit !=1, wait

/*			data = (Uint32)(SpiaRegs.SPIRXBUF) << 16;
			data += SpiaRegs.SPIRXBUF;
			data = data <<1;			// for some reason this shift will get the right data.

			dataBuf_real[ii] = (data & 0x3FFF0000) >> 16;
			dataBuf_imag[ii] = (data & 0x00003FFF) ;
*/
			if (phase == 0) {
			dataBuf_real[ii] = (Uint16) ( SpiaRegs.SPIRXBUF & 0x1FFF) ;
			dataBuf_imag[ii] = (Uint16) ( SpiaRegs.SPIRXBUF & 0x1FFF) ;
			}
    	} //ii

    //	GpioCtrlRegs.GPAPUD.bit.GPIO0 			= 1;			// disable pull-up
    	FinishNMRADC();

    	NMR_system_settings.TD = acqPTs;
	NMR_system_settings.acquiredTD = acqPTs;

    return(acqPTs);

} // end of Run_NMR_test

