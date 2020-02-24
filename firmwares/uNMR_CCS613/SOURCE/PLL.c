/*
 * PLL.c
 *
 *  Created on: Mar 6, 2017
 *      Author: ysong
 */



// orginal from Mandal.
// Hittite frequency synthesizer board
// Tested with Cerebot MX7cK, modify pin names for other Cerebot boards
// v0.1 Soumyajit Mandal, 07/28/13

/* ------------------------------------------------------------ */
/*				Include File Definitions						*/
/* ------------------------------------------------------------ */
#include "DSP28x_Project.h"										// Device Headerfile and Examples Include File
#include "stdlib.h"
#include <string.h>

//#include "RunNMR.h"
//#include "nmr.h"
//#include "nmr_plsq.h"
#include "gpio_init.h"
//#include "asic.h"


/* ------------------------------------------------------------ */
/*				Local Type Definitions							*/
/* ------------------------------------------------------------ */

// Synthesizer registers (PLL subsystem)
// -----------------------------
#define SYNTH_PLL_ID 0x00 // Chip ID (read only)
#define SYNTH_PLL_ID_DEF 0x0A7975 // Default value
#define SYNTH_PLL_RST 0x01 // Reset
#define SYNTH_PLL_RST_DEF 0x0000002 // Default value
#define SYNTH_PLL_REFDIV 0x02 // Reset
#define SYNTH_PLL_REFDIV_DEF 0x000001 // Default value
#define SYNTH_PLL_FINT 0x03 // Frequency (integer part)
#define SYNTH_PLL_FINT_DEF 0x000019 // Default value
#define SYNTH_PLL_FFRAC 0x04 // Frequency (fractional part)
#define SYNTH_PLL_FFRAC_DEF 0x000000 // Default value
#define SYNTH_PLL_VCOSPI 0x05 // Indirect addressing of VCO subsystem via SPI
#define SYNTH_PLL_VCOSPI_DEF 0x000000 // Default value
#define SYNTH_PLL_DELSIG 0x06 // Delta-sigma configuration
#define SYNTH_PLL_DELSIG_DEF 0x200B4A // Default value
#define SYNTH_PLL_LD 0x07 // Lock detect
#define SYNTH_PLL_LD_DEF 0x00014D // Default value
#define SYNTH_PLL_AEN 0x08 // Analog enable
#define SYNTH_PLL_AEN_DEF 0xC1BEFF // Default value
#define SYNTH_PLL_CP 0x09 // Charge pump
#define SYNTH_PLL_CP_DEF 0x403264 // Default value
#define SYNTH_PLL_ACAL 0x0A // VCO auto calibration configuration
#define SYNTH_PLL_ACAL_DEF 0x002205 // Default value
#define SYNTH_PLL_PD 0x0B // Phase detector
#define SYNTH_PLL_PD_DEF 0x0F8061 // Default value
#define SYNTH_PLL_EXFRQ 0x0C // Exact frequency mode
#define SYNTH_PLL_EXFRQ_DEF 0x000000 // Default value
#define SYNTH_PLL_GPIO 0x0F // GPIO pin configuration
#define SYNTH_PLL_GPIO_DEF 0x000001 // Default value

// Synthesizer registers (VCO subsystem)
// -----------------------------
#define SYNTH_VCO_TUNING 0x00 // VCO tuning
#define SYNTH_VCO_TUNING_DEF 0x020 // Default value
#define SYNTH_VCO_EN 0x01 // VCO enable signals
#define SYNTH_VCO_EN_DEF 0x17F // Default value
#define SYNTH_VCO_ODIV 0x02 // VCO output divider
#define SYNTH_VCO_ODIV_DEF 0x0C1 // Default value
#define SYNTH_VCO_CFG 0x03 // VCO configuration
#define SYNTH_VCO_CFG_DEF 0x092 // Default value
#define SYNTH_VCO_OPOW 0x07 // VCO configuration
#define SYNTH_VCO_OPOW_DEF 0x0E1 // Default value

// Constants for synthesizer
// -----------------------------
#define F_XTAL 32 // TCXO frequency (MHz) = 20 MHz. 32 for MCC board
#define F_VCO_INIT 3000 // Approximate VCO frequency (MHz) = 3000 MHz
#define REF_DIV_INIT 1 // Default reference divider
#define TWO_POW_24 16777216 // 2^24




/* ------------------------------------------------------------ */
/*				Global Variables								*/
/* ------------------------------------------------------------ */

/* ------------------------------------------------------------ */
/*				Local Variables									*/
/* ------------------------------------------------------------ */

/* ------------------------------------------------------------ */
/*				Forward Declarations							*/
/* ------------------------------------------------------------ */

void synth_fset(double fout, unsigned int rf_gain);
unsigned int update_regval(unsigned int dcurr, unsigned int data, unsigned int bstart, unsigned int bstop);
void program_synth_register(unsigned int regaddr, unsigned int dnew);


/* ------------------------------------------------------------ */
/*				Procedure Definitions							*/
/* ------------------------------------------------------------ */



//Program synthesizer output frequency (specified in MHz) & output rf gain (0-11) dB
//Assume fractional-N mode
// rf_gain to be 5 (db)
void synth_fset(double fout, unsigned int rf_gain)
{
	int i;
	int k; // Output divider
	int R; // Reference divider
	unsigned int Nint, Nfrac; // Integer and fractional divider values
	double f_PD, I_CP_off; // Phase detector frequency (MHz), charge pump offset current (uA)

	unsigned int I_CP_off_code; // Code for setting charge pump offset current (7-bit)
	unsigned int dvco, dpll;

	// Calculate output, reference, integer, and fractional divider values
	k = 2*floor(F_VCO_INIT/(2*fout)); // Must be even (except 1)
	if (k>62) k=62; // Output divider range = 1:62

	R = REF_DIV_INIT;
	f_PD = (double)F_XTAL/R;

	Nint = floor(k*R*fout/F_XTAL);
	Nfrac = floor(TWO_POW_24*(k*R*fout/F_XTAL-Nint));

	// Calculate charge pump offset current assuming I_CP = 2 mA (default value)
	// Calculation based on Fig. 45 of datasheet
	I_CP_off = 500*f_PD/58; // uA
	if (I_CP_off>500) I_CP_off = 500;
	I_CP_off_code = (unsigned int)I_CP_off/5;

	// 1. Program synthesizer: output divider
	dvco = update_regval(SYNTH_VCO_ODIV_DEF, k, 5, 0); // 6 bits
	dpll = update_regval(SYNTH_PLL_VCOSPI_DEF, dvco, 15, 7);
	dpll = update_regval(dpll,SYNTH_VCO_ODIV, 6, 3);
	program_synth_register(SYNTH_PLL_VCOSPI, dpll);

	// 2. Program synthesizer: output RF gain
	dvco = update_regval(SYNTH_VCO_OPOW_DEF, rf_gain, 3, 0); // Gain (4 bits)
	dvco = update_regval(dvco, 1, 4, 4); // Initialization (1 bit)
	dvco = update_regval(dvco, 0x4, 8, 5); // Initialization (4 bit)
	dpll = update_regval(SYNTH_PLL_VCOSPI_DEF, dvco, 15, 7);
	dpll = update_regval(dpll,SYNTH_VCO_OPOW, 6, 3);
	program_synth_register(SYNTH_PLL_VCOSPI, dpll);

	// 3. Program synthesizer: performance mode & output enable
	dvco = update_regval(SYNTH_VCO_CFG_DEF, 0x3, 1, 0); // High-performance mode (2 bits)
	dvco = update_regval(dvco, 0x3, 3, 2); // Enable RF_N and RF_P outputs (2 bits)
	dpll = update_regval(SYNTH_PLL_VCOSPI_DEF, dvco, 15, 7);
	dpll = update_regval(dpll,SYNTH_VCO_CFG, 6, 3);
	program_synth_register(SYNTH_PLL_VCOSPI, dpll);

	// 4. Program synthesizer: reference divider
	dpll = update_regval(SYNTH_PLL_REFDIV_DEF, R, 13, 0);
	program_synth_register(SYNTH_PLL_REFDIV, dpll);

	// 5. Program synthesizer: delta-sigma
	dpll = update_regval(SYNTH_PLL_DELSIG_DEF, 0x7, 10, 8); // Initialization (3 bits)
	dpll = update_regval(dpll, 0, 21, 21); // Auto clock configuration (1 bit)
	program_synth_register(SYNTH_PLL_DELSIG, dpll);

	// 6. Progam synthesizer: charge pump
	dpll = update_regval(SYNTH_PLL_CP_DEF, I_CP_off_code, 20, 14); // Charge pump offset current (7-bit)
	dpll = update_regval(dpll, 0x1, 22, 21); // Enable UP offset, disable DN offset
	program_synth_register(SYNTH_PLL_CP, dpll);

	// 7. Program synthesizer: integer divider
	dpll = update_regval(SYNTH_PLL_FINT_DEF, Nint, 18, 0);
	program_synth_register(SYNTH_PLL_FINT, dpll);

	// 8. Program synthesizer: effectively retrigger AutoCal state machine by setting SYNTH_PLL_VCOSPI[6:0] = 0
	// Note that this also sets the VCO sub-band selection to 0 (highest frequency, i.e. 3 GHz), so set F_VCO_INIT = 3 GHz for fastest lock
	dpll = update_regval(SYNTH_PLL_VCOSPI_DEF, 0x0, 23, 0);
	program_synth_register(SYNTH_PLL_VCOSPI, dpll);

	// 9. Program synthesizer: fractional divider -> trigger frequency update
	dpll = update_regval(SYNTH_PLL_FFRAC_DEF, Nfrac, 23, 0);
	program_synth_register(SYNTH_PLL_FFRAC, dpll);

}

// Update a specific portion of a register
// dcurr = current register value
// data = data to insert into register (start bit: bstart, stop bit: bstop)
unsigned int update_regval(unsigned int dcurr, unsigned int data, unsigned int bstart, unsigned int bstop)
{
	unsigned int dnew, dshifted;
	unsigned int mask = 0;
	int i, istart, istop;

	dshifted = data<<bstop;

	istart = bstart; istop = bstop - 1;
	for(i=istart;i>istop;i--)
	{
		mask = mask|(1<<i);
	}

	dnew = (dcurr&(~mask))|(dshifted&(mask));
	return dnew;
}

// Program any register of the frequency synthesizer
void program_synth_register(unsigned int regaddr, unsigned int dnew)
{
	int i;


//	void PLL_write(Uint8 reg, Uint32 data);
	 PLL_write(regaddr, dnew);


	/*
	CLK = 1; // Assert clock
	SYNTH_CS = 1; // Select chip

    for(i=23;i>-1;i--) // Shift in 24-bit register data, MSB first
	{
		CLK = 0;
    	MOSI = (dnew & (1<<i))>0;
		CLK = 1;
	}

	for(i=4;i>-1;i--) // Shift in 5-bit register address, MSB first
	{
		CLK = 0;
    	MOSI = (regaddr & (1<<i))>0;
		CLK = 1;
	}

	MOSI = 0;
	for(i=2;i>-1;i--) // Shift in 3-bit chip address = 0x0, MSB first
	{
		CLK = 0;
		CLK = 1;
	}

	SYNTH_CS = 0;
	SYNTH_CS = 1; // Chip registers data at this rising edge

	SYNTH_CS = 0; // Deselect chip
	CLK = 0; // De-assert clock
	*/


}


