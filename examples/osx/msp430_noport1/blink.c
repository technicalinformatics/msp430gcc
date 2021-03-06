//***************************************************************************************
//  MSP430 Blink the LED Demo - Software Toggle P1.2
//
//  Description; Toggle P1.2 by xor'ing P1.2 inside of a software loop.
//  ACLK = n/a, MCLK = SMCLK = default DCO
//
//                MSP430x5xx
//             -----------------
//         /|\|              XIN|-
//          | |                 |
//          --|RST          XOUT|-
//            |                 |
//            |             P1.2|-->LED
//
//  J. Stevenson
//  Texas Instruments, Inc
//  July 2011
//  Built with Code Composer Studio v5
//***************************************************************************************

#include <msp430.h>				

int main(void) {
	WDTCTL = WDTPW | WDTHOLD;		// Stop watchdog timer
	P0DIR |= 0x04;					// Set P1.2 to output direction

	for(;;) {
		volatile unsigned int i;	// volatile to prevent optimization

		P0OUT ^= 0x04;				// Toggle P1.2 using exclusive-OR

		i = 10000;					// SW Delay
		do i--;
		while(i != 0);
	}
	
	return 0;
}
