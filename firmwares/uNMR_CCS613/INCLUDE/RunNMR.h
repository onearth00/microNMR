/*
 * RunNMR.h
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

#ifndef INCLUDE_RUNNMR_H_
#define INCLUDE_RUNNMR_H_

#include "typeDefs.h"


#define dataBufferTD 7000


// NMR System Parameter settings
typedef struct   {

    	int  	asic_ver	; 									// 2013; 2014 - made in 2014
    	int  	tuningcap	; 									// tuning cap voltage, 		default 1650
    	int  	RecGain   	;   								// receiver gain, 			default 9
    	int     NA			;     								// number of aquisitions, 	default 20
    	int     DS			;     								// dummy scans, 			default 0
    	int     dw			;									// dwell time, 				default 10us
    	int     T90			;									// T90 pulse width,			default 13us
    	int     T180		;									// T180 pulse width,		default 26us
    	int     TE			;     								// echo time, 				default 4ms
    	int     TD			;     								// number of points to acq, default 1029
    	int     TD1			;    								// additional dimension, 	default
		int     TD2			;    								// additional dimension, 	default
		int     maxTD		;  									// max Time Delay (TD), 	default
		int     acquiredTD	;  									// actual acquired TD, 		default
		int     echoshape   ;                                   // echo shape recording in CPMG
		long    RD			;     								// recycle delay, 			default
		long    D[10]		;  									// ten delays used in pulse seq
		int     P[10]		;  									// ten pulse length used in pulse seq
		int     C[10]		;  									// counters
		int     vd[10]		; 									// variable delay, for T1, diffusion, other other 2d
		int     PL[10] 		; 									// power level
    	Uint32  Freq        ; 									// Resonant freq, set by fractional PLL
    	long  nint        ;                                   // nint for pll
    	long  nfrac       ;                                   // nfrac for pll
    	int     dummyecho ;
    	char			SEQ[10];
    	char			note[20];
    	Uint32		error		;					// error code
} NMR_Sys_Parameters;


// index to the parameters
enum p_index {
	i_asci_ver=1,
	i_tuningcap,
	i_recgain,
	i_na,
	i_ds,
	i_dwell,
	i_T90,
	i_T180,
	i_TE,
	i_notinuse,
	i_TD,
	i_TD1,
	i_TD2,
	i_maxTD,
	i_acqiredTD,
	i_RD,
	i_freq,
	i_echoshape,
	i_nint,
	i_nfrac,
	i_dummyecho,
	i_error			// always keep i_error the last one
};

#define max(a,b) (a>b) ? a : b
#define min(a,b) (a>b) ? b : a

/*
 * Error code
 * 10 = in Run_NMR_Accumulate_test_tuning,
 * 20 = in Run_NMR_Accumulate_test,
 */


void GetFullParameters(Uint32 *p, int np);


Uint16 GetErrorCode(void);

void SetFreq(Uint32 inValue);
void SetGain(Uint32 inValue);

void SetTD(Uint32 inValue);

int SetPowerLevel(int inPL);

void initNMRParameters();

// index is from p_index
int	SetNMRParameters(int index, Uint32 value);

Uint32 GetAcqTD();
Uint32	GetNMRParameters(int index);


int GetNMRData(int index, int16 *realpart, int16 *imagpart);
void Do_NMR_experiments(int seqnum);
int Run_NMR_FID(void);

int Run_NMR_Tuning(void);
int Run_NMR_CPMG(void);

// local
Uint32 mcsb32bitWordFromADC();


#endif /* INCLUDE_RUNNMR_H_ */
