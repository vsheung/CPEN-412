; C:\USERS\VICTO\DOWNLOADS\LAB5 84% COMPLETED.C - Compiled by CC68K  Version 5.00 (c) 1991-2005  Peter J. Fondse
; #include <Bios.h>
; //#include "DebugMonitor.h"
; /*********************************************************************************************
; ** These addresses and definitions were taken from Appendix 7 of the Can Controller
; ** application note and adapted for the 68k assignment
; *********************************************************************************************/
; /*
; ** definition for the SJA1000 registers and bits based on 68k address map areas
; ** assume the addresses for the 2 can controllers given in the assignment
; **
; ** Registers are defined in terms of the following Macro for each Can controller,
; ** where (i) represents an registers number
; */
; #define RS232_Control     *(volatile unsigned char *)(0x00400040)
; #define RS232_Status      *(volatile unsigned char *)(0x00400040)
; #define RS232_TxData      *(volatile unsigned char *)(0x00400042)
; #define RS232_RxData      *(volatile unsigned char *)(0x00400042)
; #define RS232_Baud        *(volatile unsigned char *)(0x00400044)
; #define CAN0_CONTROLLER(i) (*(volatile unsigned char *)(0x00500000 + (i << 1)))
; #define CAN1_CONTROLLER(i) (*(volatile unsigned char *)(0x00500200 + (i << 1)))
; /* Can 0 register definitions */
; #define Can0_ModeControlReg      CAN0_CONTROLLER(0)
; #define Can0_CommandReg          CAN0_CONTROLLER(1)
; #define Can0_StatusReg           CAN0_CONTROLLER(2)
; #define Can0_InterruptReg        CAN0_CONTROLLER(3)
; #define Can0_InterruptEnReg      CAN0_CONTROLLER(4) /* PeliCAN mode */
; #define Can0_BusTiming0Reg       CAN0_CONTROLLER(6)
; #define Can0_BusTiming1Reg       CAN0_CONTROLLER(7)
; #define Can0_OutControlReg       CAN0_CONTROLLER(8)
; /* address definitions of Other Registers */
; #define Can0_ArbLostCapReg       CAN0_CONTROLLER(11)
; #define Can0_ErrCodeCapReg       CAN0_CONTROLLER(12)
; #define Can0_ErrWarnLimitReg     CAN0_CONTROLLER(13)
; #define Can0_RxErrCountReg       CAN0_CONTROLLER(14)
; #define Can0_TxErrCountReg       CAN0_CONTROLLER(15)
; #define Can0_RxMsgCountReg       CAN0_CONTROLLER(29)
; #define Can0_RxBufStartAdr       CAN0_CONTROLLER(30)
; #define Can0_ClockDivideReg      CAN0_CONTROLLER(31)
; /* address definitions of Acceptance Code & Mask Registers - RESET MODE */
; #define Can0_AcceptCode0Reg      CAN0_CONTROLLER(16)
; #define Can0_AcceptCode1Reg      CAN0_CONTROLLER(17)
; #define Can0_AcceptCode2Reg      CAN0_CONTROLLER(18)
; #define Can0_AcceptCode3Reg      CAN0_CONTROLLER(19)
; #define Can0_AcceptMask0Reg      CAN0_CONTROLLER(20)
; #define Can0_AcceptMask1Reg      CAN0_CONTROLLER(21)
; #define Can0_AcceptMask2Reg      CAN0_CONTROLLER(22)
; #define Can0_AcceptMask3Reg      CAN0_CONTROLLER(23)
; /* address definitions Rx Buffer - OPERATING MODE - Read only register*/
; #define Can0_RxFrameInfo         CAN0_CONTROLLER(16)
; #define Can0_RxBuffer1           CAN0_CONTROLLER(17)
; #define Can0_RxBuffer2           CAN0_CONTROLLER(18)
; #define Can0_RxBuffer3           CAN0_CONTROLLER(19)
; #define Can0_RxBuffer4           CAN0_CONTROLLER(20)
; #define Can0_RxBuffer5           CAN0_CONTROLLER(21)
; #define Can0_RxBuffer6           CAN0_CONTROLLER(22)
; #define Can0_RxBuffer7           CAN0_CONTROLLER(23)
; #define Can0_RxBuffer8           CAN0_CONTROLLER(24)
; #define Can0_RxBuffer9           CAN0_CONTROLLER(25)
; #define Can0_RxBuffer10          CAN0_CONTROLLER(26)
; #define Can0_RxBuffer11          CAN0_CONTROLLER(27)
; #define Can0_RxBuffer12          CAN0_CONTROLLER(28)
; /* address definitions of the Tx-Buffer - OPERATING MODE - Write only register */
; #define Can0_TxFrameInfo         CAN0_CONTROLLER(16)
; #define Can0_TxBuffer1           CAN0_CONTROLLER(17)
; #define Can0_TxBuffer2           CAN0_CONTROLLER(18)
; #define Can0_TxBuffer3           CAN0_CONTROLLER(19)
; #define Can0_TxBuffer4           CAN0_CONTROLLER(20)
; #define Can0_TxBuffer5           CAN0_CONTROLLER(21)
; #define Can0_TxBuffer6           CAN0_CONTROLLER(22)
; #define Can0_TxBuffer7           CAN0_CONTROLLER(23)
; #define Can0_TxBuffer8           CAN0_CONTROLLER(24)
; #define Can0_TxBuffer9           CAN0_CONTROLLER(25)
; #define Can0_TxBuffer10          CAN0_CONTROLLER(26)
; #define Can0_TxBuffer11          CAN0_CONTROLLER(27)
; #define Can0_TxBuffer12          CAN0_CONTROLLER(28)
; /* read only addresses */
; #define Can0_TxFrameInfoRd       CAN0_CONTROLLER(96)
; #define Can0_TxBufferRd1         CAN0_CONTROLLER(97)
; #define Can0_TxBufferRd2         CAN0_CONTROLLER(98)
; #define Can0_TxBufferRd3         CAN0_CONTROLLER(99)
; #define Can0_TxBufferRd4         CAN0_CONTROLLER(100)
; #define Can0_TxBufferRd5         CAN0_CONTROLLER(101)
; #define Can0_TxBufferRd6         CAN0_CONTROLLER(102)
; #define Can0_TxBufferRd7         CAN0_CONTROLLER(103)
; #define Can0_TxBufferRd8         CAN0_CONTROLLER(104)
; #define Can0_TxBufferRd9         CAN0_CONTROLLER(105)
; #define Can0_TxBufferRd10        CAN0_CONTROLLER(106)
; #define Can0_TxBufferRd11        CAN0_CONTROLLER(107)
; #define Can0_TxBufferRd12        CAN0_CONTROLLER(108)
; /* CAN1 Controller register definitions */
; #define Can1_ModeControlReg      CAN1_CONTROLLER(0)
; #define Can1_CommandReg          CAN1_CONTROLLER(1)
; #define Can1_StatusReg           CAN1_CONTROLLER(2)
; #define Can1_InterruptReg        CAN1_CONTROLLER(3)
; #define Can1_InterruptEnReg      CAN1_CONTROLLER(4) /* PeliCAN mode */
; #define Can1_BusTiming0Reg       CAN1_CONTROLLER(6)
; #define Can1_BusTiming1Reg       CAN1_CONTROLLER(7)
; #define Can1_OutControlReg       CAN1_CONTROLLER(8)
; /* address definitions of Other Registers */
; #define Can1_ArbLostCapReg       CAN1_CONTROLLER(11)
; #define Can1_ErrCodeCapReg       CAN1_CONTROLLER(12)
; #define Can1_ErrWarnLimitReg     CAN1_CONTROLLER(13)
; #define Can1_RxErrCountReg       CAN1_CONTROLLER(14)
; #define Can1_TxErrCountReg       CAN1_CONTROLLER(15)
; #define Can1_RxMsgCountReg       CAN1_CONTROLLER(29)
; #define Can1_RxBufStartAdr       CAN1_CONTROLLER(30)
; #define Can1_ClockDivideReg      CAN1_CONTROLLER(31)
; /* address definitions of Acceptance Code & Mask Registers - RESET MODE */
; #define Can1_AcceptCode0Reg      CAN1_CONTROLLER(16)
; #define Can1_AcceptCode1Reg      CAN1_CONTROLLER(17)
; #define Can1_AcceptCode2Reg      CAN1_CONTROLLER(18)
; #define Can1_AcceptCode3Reg      CAN1_CONTROLLER(19)
; #define Can1_AcceptMask0Reg      CAN1_CONTROLLER(20)
; #define Can1_AcceptMask1Reg      CAN1_CONTROLLER(21)
; #define Can1_AcceptMask2Reg      CAN1_CONTROLLER(22)
; #define Can1_AcceptMask3Reg      CAN1_CONTROLLER(23)
; /* address definitions Rx Buffer - OPERATING MODE - Read only register*/
; #define Can1_RxFrameInfo         CAN1_CONTROLLER(16)
; #define Can1_RxBuffer1           CAN1_CONTROLLER(17)
; #define Can1_RxBuffer2           CAN1_CONTROLLER(18)
; #define Can1_RxBuffer3           CAN1_CONTROLLER(19)
; #define Can1_RxBuffer4           CAN1_CONTROLLER(20)
; #define Can1_RxBuffer5           CAN1_CONTROLLER(21)
; #define Can1_RxBuffer6           CAN1_CONTROLLER(22)
; #define Can1_RxBuffer7           CAN1_CONTROLLER(23)
; #define Can1_RxBuffer8           CAN1_CONTROLLER(24)
; #define Can1_RxBuffer9           CAN1_CONTROLLER(25)
; #define Can1_RxBuffer10          CAN1_CONTROLLER(26)
; #define Can1_RxBuffer11          CAN1_CONTROLLER(27)
; #define Can1_RxBuffer12          CAN1_CONTROLLER(28)
; /* address definitions of the Tx-Buffer - OPERATING MODE - Write only register */
; #define Can1_TxFrameInfo         CAN1_CONTROLLER(16)
; #define Can1_TxBuffer1           CAN1_CONTROLLER(17)
; #define Can1_TxBuffer2           CAN1_CONTROLLER(18)
; #define Can1_TxBuffer3           CAN1_CONTROLLER(19)
; #define Can1_TxBuffer4           CAN1_CONTROLLER(20)
; #define Can1_TxBuffer5           CAN1_CONTROLLER(21)
; #define Can1_TxBuffer6           CAN1_CONTROLLER(22)
; #define Can1_TxBuffer7           CAN1_CONTROLLER(23)
; #define Can1_TxBuffer8           CAN1_CONTROLLER(24)
; #define Can1_TxBuffer9           CAN1_CONTROLLER(25)
; #define Can1_TxBuffer10          CAN1_CONTROLLER(26)
; #define Can1_TxBuffer11          CAN1_CONTROLLER(27)
; #define Can1_TxBuffer12          CAN1_CONTROLLER(28)
; /* read only addresses */
; #define Can1_TxFrameInfoRd       CAN1_CONTROLLER(96)
; #define Can1_TxBufferRd1         CAN1_CONTROLLER(97)
; #define Can1_TxBufferRd2         CAN1_CONTROLLER(98)
; #define Can1_TxBufferRd3         CAN1_CONTROLLER(99)
; #define Can1_TxBufferRd4         CAN1_CONTROLLER(100)
; #define Can1_TxBufferRd5         CAN1_CONTROLLER(101)
; #define Can1_TxBufferRd6         CAN1_CONTROLLER(102)
; #define Can1_TxBufferRd7         CAN1_CONTROLLER(103)
; #define Can1_TxBufferRd8         CAN1_CONTROLLER(104)
; #define Can1_TxBufferRd9         CAN1_CONTROLLER(105)
; #define Can1_TxBufferRd10        CAN1_CONTROLLER(106)
; #define Can1_TxBufferRd11        CAN1_CONTROLLER(107)
; #define Can1_TxBufferRd12        CAN1_CONTROLLER(108)
; /* bit definitions for the Mode & Control Register */
; #define RM_RR_Bit 0x01 /* reset mode (request) bit */
; #define LOM_Bit 0x02 /* listen only mode bit */
; #define STM_Bit 0x04 /* self test mode bit */
; #define AFM_Bit 0x08 /* acceptance filter mode bit */
; #define SM_Bit  0x10 /* enter sleep mode bit */
; /* bit definitions for the Interrupt Enable & Control Register */
; #define RIE_Bit 0x01 /* receive interrupt enable bit */
; #define TIE_Bit 0x02 /* transmit interrupt enable bit */
; #define EIE_Bit 0x04 /* error warning interrupt enable bit */
; #define DOIE_Bit 0x08 /* data overrun interrupt enable bit */
; #define WUIE_Bit 0x10 /* wake-up interrupt enable bit */
; #define EPIE_Bit 0x20 /* error passive interrupt enable bit */
; #define ALIE_Bit 0x40 /* arbitration lost interr. enable bit*/
; #define BEIE_Bit 0x80 /* bus error interrupt enable bit */
; /* bit definitions for the Command Register */
; #define TR_Bit 0x01 /* transmission request bit */
; #define AT_Bit 0x02 /* abort transmission bit */
; #define RRB_Bit 0x04 /* release receive buffer bit */
; #define CDO_Bit 0x08 /* clear data overrun bit */
; #define SRR_Bit 0x10 /* self reception request bit */
; /* bit definitions for the Status Register */
; #define RBS_Bit 0x01 /* receive buffer status bit */
; #define DOS_Bit 0x02 /* data overrun status bit */
; #define TBS_Bit 0x04 /* transmit buffer status bit */
; #define TCS_Bit 0x08 /* transmission complete status bit */
; #define RS_Bit 0x10 /* receive status bit */
; #define TS_Bit 0x20 /* transmit status bit */
; #define ES_Bit 0x40 /* error status bit */
; #define BS_Bit 0x80 /* bus status bit */
; /* bit definitions for the Interrupt Register */
; #define RI_Bit 0x01 /* receive interrupt bit */
; #define TI_Bit 0x02 /* transmit interrupt bit */
; #define EI_Bit 0x04 /* error warning interrupt bit */
; #define DOI_Bit 0x08 /* data overrun interrupt bit */
; #define WUI_Bit 0x10 /* wake-up interrupt bit */
; #define EPI_Bit 0x20 /* error passive interrupt bit */
; #define ALI_Bit 0x40 /* arbitration lost interrupt bit */
; #define BEI_Bit 0x80 /* bus error interrupt bit */
; /* bit definitions for the Bus Timing Registers */
; #define SAM_Bit 0x80                        /* sample mode bit 1 == the bus is sampled 3 times, 0 == the bus is sampled once */
; /* bit definitions for the Output Control Register OCMODE1, OCMODE0 */
; #define BiPhaseMode 0x00 /* bi-phase output mode */
; #define NormalMode 0x02 /* normal output mode */
; #define ClkOutMode 0x03 /* clock output mode */
; /* output pin configuration for TX1 */
; #define OCPOL1_Bit 0x20 /* output polarity control bit */
; #define Tx1Float 0x00 /* configured as float */
; #define Tx1PullDn 0x40 /* configured as pull-down */
; #define Tx1PullUp 0x80 /* configured as pull-up */
; #define Tx1PshPull 0xC0 /* configured as push/pull */
; /* output pin configuration for TX0 */
; #define OCPOL0_Bit 0x04 /* output polarity control bit */
; #define Tx0Float 0x00 /* configured as float */
; #define Tx0PullDn 0x08 /* configured as pull-down */
; #define Tx0PullUp 0x10 /* configured as pull-up */
; #define Tx0PshPull 0x18 /* configured as push/pull */
; /* bit definitions for the Clock Divider Register */
; #define DivBy1 0x07 /* CLKOUT = oscillator frequency */
; #define DivBy2 0x00 /* CLKOUT = 1/2 oscillator frequency */
; #define ClkOff_Bit 0x08 /* clock off bit, control of the CLK OUT pin */
; #define RXINTEN_Bit 0x20 /* pin TX1 used for receive interrupt */
; #define CBP_Bit 0x40 /* CAN comparator bypass control bit */
; #define CANMode_Bit 0x80 /* CAN mode definition bit */
; /*- definition of used constants ---------------------------------------*/
; #define YES 1
; #define NO 0
; #define ENABLE 1
; #define DISABLE 0
; #define ENABLE_N 0
; #define DISABLE_N 1
; #define INTLEVELACT 0
; #define INTEDGEACT 1
; #define PRIORITY_LOW 0
; #define PRIORITY_HIGH 1
; /* default (reset) value for register content, clear register */
; #define ClrByte 0x00
; /* constant: clear Interrupt Enable Register */
; #define ClrIntEnSJA ClrByte
; /* definitions for the acceptance code and mask register */
; #define DontCare 0xFF
; //GLOBAL VARIABLE FOR COUNT
; int count;
; int ADC_val, Photo_val, Therm_val;
; //#define StartOfExceptionVectorTable 0x0B000000
; /*  bus timing values for
; **  bit-rate : 100 kBit/s
; **  oscillator frequency : 25 MHz, 1 sample per bit, 0 tolerance %
; **  maximum tolerated propagation delay : 4450 ns
; **  minimum requested propagation delay : 500 ns
; **
; **  https://www.kvaser.com/support/calculators/bit-timing-calculator/
; **  T1 	T2 	BTQ 	SP% 	SJW 	BIT RATE 	ERR% 	BTR0 	BTR1
; **  17	8	25	    68	     1	      100	    0	      04	7f
; */
; void InstallExceptionHandler( void (*function_ptr)(), int level)
; {
       section   code
       xdef      _InstallExceptionHandler
_InstallExceptionHandler:
       link      A6,#-4
; volatile long int *RamVectorAddress = (volatile long int *)(StartOfExceptionVectorTable) ;   // pointer to the Ram based interrupt vector table created in Cstart in debug monitor
       move.l    #134414336,-4(A6)
; RamVectorAddress[level] = (long int *)(function_ptr);                       // install the address of our function into the exception table
       move.l    -4(A6),A0
       move.l    12(A6),D0
       lsl.l     #2,D0
       move.l    8(A6),0(A0,D0.L)
       unlk      A6
       rts
; }
; void Timer2_Reset(void)
; {
       xdef      _Timer2_Reset
_Timer2_Reset:
; if(Timer2Status == 1) {       // Did Timer 2 produce the Interrupt?
       move.b    4194358,D0
       cmp.b     #1,D0
       bne.s     Timer2_Reset_1
; Timer2Control = 3;      	// if so clear interrupt and restart timer
       move.b    #3,4194358
Timer2_Reset_1:
       rts
; }
; }
; void Timer2_Init(void)
; {
       xdef      _Timer2_Init
_Timer2_Init:
; Timer2Data = 0x25;		// program 100ms delay
       move.b    #37,4194356
; /*
; ** timer driven off 25Mhz clock so program value so that it counts down in 0.01 secs
; ** the example 0x03 above is loaded into top 8 bits of a 24 bit timer so reads as
; ** 0x03FFFF a value of 0x03 would be 262,143/25,000,000, so is close to 1/100th sec
; **
; **
; ** Now write binary 00000011 to timer control register:
; **	Bit0 = 1 (enable interrupt from that timer)
; **	Bit 1 = 1 enable counting
; */
; Timer2Control = 3;
       move.b    #3,4194358
       rts
; }
; /*********************************************************************************************
; *Subroutine to initialise the RS232 Port by writing some commands to the internal registers
; *********************************************************************************************/
; void Init_RS232(void)
; {
       xdef      _Init_RS232
_Init_RS232:
; RS232_Control = (char)(0x15) ; //  %00010101    divide by 16 clock, set rts low, 8 bits no parity, 1 stop bit transmitter interrupt disabled
       move.b    #21,4194368
; RS232_Baud = (char)(0x1) ;      // program baud rate generator 000 = 230k, 001 = 115k, 010 = 57.6k, 011 = 38.4k, 100 = 19.2, all others = 9600
       move.b    #1,4194372
       rts
; }
; int kbhit(void)
; {
       xdef      _kbhit
_kbhit:
; if(((char)(RS232_Status) & (char)(0x01)) == (char)(0x01))    // wait for Rx bit in status register to be '1'
       move.b    4194368,D0
       and.b     #1,D0
       cmp.b     #1,D0
       bne.s     kbhit_1
; return 1 ;
       moveq     #1,D0
       bra.s     kbhit_3
kbhit_1:
; else
; return 0 ;
       clr.l     D0
kbhit_3:
       rts
; }
; /*********************************************************************************************************
; **  Subroutine to provide a low level output function to 6850 ACIA
; **  This routine provides the basic functionality to output a single character to the serial Port
; **  to allow the board to communicate with HyperTerminal Program
; **
; **  NOTE you do not call this function directly, instead you call the normal putchar() function
; **  which in turn calls _putch() below). Other functions like puts(), printf() call putchar() so will
; **  call _putch() also
; *********************************************************************************************************/
; int _putch( int c)
; {
       xdef      __putch
__putch:
       link      A6,#0
; while(((char)(RS232_Status) & (char)(0x02)) != (char)(0x02))    // wait for Tx bit in status register or 6850 serial comms chip to be '1'
_putch_1:
       move.b    4194368,D0
       and.b     #2,D0
       cmp.b     #2,D0
       beq.s     _putch_3
       bra       _putch_1
_putch_3:
; ;
; (char)(RS232_TxData) = ((char)(c) & (char)(0x7f));                      // write to the data register to output the character (mask off bit 8 to keep it 7 bit ASCII)
       move.l    8(A6),D0
       and.b     #127,D0
       move.b    D0,4194370
; return c ;                                              // putchar() expects the character to be returned
       move.l    8(A6),D0
       unlk      A6
       rts
; }
; /*********************************************************************************************************
; **  Subroutine to provide a low level input function to 6850 ACIA
; **  This routine provides the basic functionality to input a single character from the serial Port
; **  to allow the board to communicate with HyperTerminal Program Keyboard (your PC)
; **
; **  NOTE you do not call this function directly, instead you call the normal _getch() function
; **  which in turn calls _getch() below). Other functions like gets(), scanf() call _getch() so will
; **  call _getch() also
; *********************************************************************************************************/
; int _getch( void )
; {
       xdef      __getch
__getch:
       move.l    D2,-(A7)
; int c ;
; while(((char)(RS232_Status) & (char)(0x01)) != (char)(0x01))    // wait for Rx bit in 6850 serial comms chip status register to be '1'
_getch_1:
       move.b    4194368,D0
       and.b     #1,D0
       cmp.b     #1,D0
       beq.s     _getch_3
       bra       _getch_1
_getch_3:
; ;
; c = (RS232_RxData & (char)(0x7f));                   // read received character, mask off top bit and return as 7 bit ASCII character
       move.b    4194370,D0
       and.l     #255,D0
       and.l     #127,D0
       move.l    D0,D2
; // shall we echo the character? Echo is set to TRUE at reset, but for speed we don't want to echo when downloading code with the 'L' debugger command
; if(1)
; _putch(c);
       move.l    D2,-(A7)
       jsr       __putch
       addq.w    #4,A7
; return c ;
       move.l    D2,D0
       move.l    (A7)+,D2
       rts
; }
; // flush the input stream for any unread characters
; void FlushKeyboard(void)
; {
       xdef      _FlushKeyboard
_FlushKeyboard:
       link      A6,#-4
; char c ;
; while(1)    {
FlushKeyboard_1:
; if(((char)(RS232_Status) & (char)(0x01)) == (char)(0x01))    // if Rx bit in status register is '1'
       move.b    4194368,D0
       and.b     #1,D0
       cmp.b     #1,D0
       bne.s     FlushKeyboard_4
; c = ((char)(RS232_RxData) & (char)(0x7f)) ;
       move.b    4194370,D0
       and.b     #127,D0
       move.b    D0,-1(A6)
       bra.s     FlushKeyboard_5
FlushKeyboard_4:
; else
; return ;
       bra.s     FlushKeyboard_6
FlushKeyboard_5:
       bra       FlushKeyboard_1
FlushKeyboard_6:
       unlk      A6
       rts
; }
; }
; // converts hex char to 4 bit binary equiv in range 0000-1111 (0-F)
; // char assumed to be a valid hex char 0-9, a-f, A-F
; char xtod(int c)
; {
       xdef      _xtod
_xtod:
       link      A6,#0
       move.l    D2,-(A7)
       move.l    8(A6),D2
; if ((char)(c) <= (char)('9'))
       cmp.b     #57,D2
       bgt.s     xtod_1
; return c - (char)(0x30);    // 0 - 9 = 0x30 - 0x39 so convert to number by sutracting 0x30
       move.b    D2,D0
       sub.b     #48,D0
       bra.s     xtod_3
xtod_1:
; else if((char)(c) > (char)('F'))    // assume lower case
       cmp.b     #70,D2
       ble.s     xtod_4
; return c - (char)(0x57);    // a-f = 0x61-66 so needs to be converted to 0x0A - 0x0F so subtract 0x57
       move.b    D2,D0
       sub.b     #87,D0
       bra.s     xtod_3
xtod_4:
; else
; return c - (char)(0x37);    // A-F = 0x41-46 so needs to be converted to 0x0A - 0x0F so subtract 0x37
       move.b    D2,D0
       sub.b     #55,D0
xtod_3:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; int Get2HexDigits(char *CheckSumPtr)
; {
       xdef      _Get2HexDigits
_Get2HexDigits:
       link      A6,#0
       move.l    D2,-(A7)
; register int i = (xtod(_getch()) << 4) | (xtod(_getch()));
       move.l    D0,-(A7)
       jsr       __getch
       move.l    D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _xtod
       addq.w    #4,A7
       and.l     #255,D0
       asl.l     #4,D0
       move.l    D0,-(A7)
       move.l    D1,-(A7)
       jsr       __getch
       move.l    (A7)+,D1
       move.l    D0,-(A7)
       jsr       _xtod
       addq.w    #4,A7
       move.l    D0,D1
       move.l    (A7)+,D0
       and.l     #255,D1
       or.l      D1,D0
       move.l    D0,D2
; if(CheckSumPtr)
       tst.l     8(A6)
       beq.s     Get2HexDigits_1
; *CheckSumPtr += i ;
       move.l    8(A6),A0
       add.b     D2,(A0)
Get2HexDigits_1:
; return i ;
       move.l    D2,D0
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; int Get4HexDigits(char* CheckSumPtr)
; {
       xdef      _Get4HexDigits
_Get4HexDigits:
       link      A6,#0
; return (Get2HexDigits(CheckSumPtr) << 8) | (Get2HexDigits(CheckSumPtr));
       move.l    8(A6),-(A7)
       jsr       _Get2HexDigits
       addq.w    #4,A7
       asl.l     #8,D0
       move.l    D0,-(A7)
       move.l    8(A6),-(A7)
       jsr       _Get2HexDigits
       addq.w    #4,A7
       move.l    D0,D1
       move.l    (A7)+,D0
       or.l      D1,D0
       unlk      A6
       rts
; }
; int Get6HexDigits(char* CheckSumPtr)
; {
       xdef      _Get6HexDigits
_Get6HexDigits:
       link      A6,#0
; return (Get4HexDigits(CheckSumPtr) << 8) | (Get2HexDigits(CheckSumPtr));
       move.l    8(A6),-(A7)
       jsr       _Get4HexDigits
       addq.w    #4,A7
       asl.l     #8,D0
       move.l    D0,-(A7)
       move.l    8(A6),-(A7)
       jsr       _Get2HexDigits
       addq.w    #4,A7
       move.l    D0,D1
       move.l    (A7)+,D0
       or.l      D1,D0
       unlk      A6
       rts
; }
; int Get8HexDigits(char* CheckSumPtr)
; {
       xdef      _Get8HexDigits
_Get8HexDigits:
       link      A6,#0
; return (Get4HexDigits(CheckSumPtr) << 16) | (Get4HexDigits(CheckSumPtr));
       move.l    8(A6),-(A7)
       jsr       _Get4HexDigits
       addq.w    #4,A7
       asl.l     #8,D0
       asl.l     #8,D0
       move.l    D0,-(A7)
       move.l    8(A6),-(A7)
       jsr       _Get4HexDigits
       addq.w    #4,A7
       move.l    D0,D1
       move.l    (A7)+,D0
       or.l      D1,D0
       unlk      A6
       rts
; }
; // initialisation for Can controller 0
; void Init_CanBus_Controller0(void)
; {
       xdef      _Init_CanBus_Controller0
_Init_CanBus_Controller0:
; // TODO - put your Canbus initialisation code for CanController 0 here
; // See section 4.2.1 in the application note for details (PELICAN MODE)
; /* disable interrupts, if used (not necessary after power-on) */
; // EA = DISABLE; /* disable all interrupts */
; Can0_InterruptEnReg = DISABLE; /* disable external interrupt from SJA1000 */
       clr.b     5242888
; /* set reset mode/request (Note: after power-on SJA1000 is in BasicCAN mode)
; leave loop after a time out and signal an error */
; while((Can0_ModeControlReg & RM_RR_Bit ) == ClrByte)
Init_CanBus_Controller0_1:
       move.b    5242880,D0
       and.b     #1,D0
       bne.s     Init_CanBus_Controller0_3
; {
; /* other bits than the reset mode/request bit are unchanged */
; Can0_ModeControlReg = Can0_ModeControlReg | RM_RR_Bit ;
       move.b    5242880,D0
       or.b      #1,D0
       move.b    D0,5242880
       bra       Init_CanBus_Controller0_1
Init_CanBus_Controller0_3:
; }
; /* set the Clock Divider Register according to the given hardware of Figure 3
; select PeliCAN mode
; bypass CAN input comparator as external transceiver is used
; select the clock for the controller S87C654 */
; Can0_ClockDivideReg = CANMode_Bit | CBP_Bit | DivBy2;
       move.b    #192,5242942
; /* disable CAN interrupts, if required (always necessary after power-on)
; (write to SJA1000 Interrupt Enable / Control Register) */
; Can0_InterruptEnReg = ClrIntEnSJA;
       clr.b     5242888
; /* define acceptance code and mask */
; Can0_AcceptCode0Reg = ClrByte;
       clr.b     5242912
; Can0_AcceptCode1Reg = ClrByte;
       clr.b     5242914
; Can0_AcceptCode2Reg = ClrByte;
       clr.b     5242916
; Can0_AcceptCode3Reg = ClrByte;
       clr.b     5242918
; Can0_AcceptMask0Reg = DontCare; /* every identifier is accepted */
       move.b    #255,5242920
; Can0_AcceptMask1Reg = DontCare; /* every identifier is accepted */
       move.b    #255,5242922
; Can0_AcceptMask2Reg = DontCare; /* every identifier is accepted */
       move.b    #255,5242924
; Can0_AcceptMask3Reg = DontCare; /* every identifier is accepted */
       move.b    #255,5242926
; /* configure bus timing */
; /* Values are given to us*/
; Can0_BusTiming0Reg = 0x04;
       move.b    #4,5242892
; Can0_BusTiming1Reg = 0x7f;
       move.b    #127,5242894
; /* configure CAN outputs: float on TX1, Push/Pull on TX0,
; normal output mode */
; Can0_OutControlReg = Tx1Float | Tx0PshPull | NormalMode;
       move.b    #26,5242896
; /* leave the reset mode/request i.e. switch to operating mode,
; the interrupts of the S87C654 are enabled
; but not the CAN interrupts of the SJA1000, which can be done separately
; for the different tasks in a system */
; /* clear Reset Mode bit, select dual Acceptance Filter Mode,
; switch off Self Test Mode and Listen Only Mode,
; clear Sleep Mode (wake up) */
; do /* wait until RM_RR_Bit is cleared */
Init_CanBus_Controller0_4:
; /* break loop after a time out and signal an error */
; {
; Can0_ModeControlReg = ClrByte;
       clr.b     5242880
       move.b    5242880,D0
       and.b     #1,D0
       bne       Init_CanBus_Controller0_4
; } while((Can0_ModeControlReg & RM_RR_Bit ) != ClrByte);
; Can0_InterruptEnReg = ENABLE; /* enable external interrupt from SJA1000 */
       move.b    #1,5242888
; //EA = ENABLE; /* enable all interrupts */
; /*----- end of Initialization Example of the SJA1000 ------------------------*/
; printf("\r\nEnd of Canbus 0 Initialization");
       pea       @lab584~1_1.L
       jsr       _printf
       addq.w    #4,A7
       rts
; }
; // initialisation for Can controller 1
; void Init_CanBus_Controller1(void)
; {
       xdef      _Init_CanBus_Controller1
_Init_CanBus_Controller1:
; // TODO - put your Canbus initialisation code for CanController 1 here
; // See section 4.2.1 in the application note for details (PELICAN MODE)
; /* disable interrupts, if used (not necessary after power-on) */
; // EA = DISABLE; /* disable all interrupts */
; Can1_InterruptEnReg = DISABLE; /* disable external interrupt from SJA1000 */
       clr.b     5243400
; /* set reset mode/request (Note: after power-on SJA1000 is in BasicCAN mode)
; leave loop after a time out and signal an error */
; while((Can1_ModeControlReg & RM_RR_Bit ) == ClrByte)
Init_CanBus_Controller1_1:
       move.b    5243392,D0
       and.b     #1,D0
       bne.s     Init_CanBus_Controller1_3
; {
; /* other bits than the reset mode/request bit are unchanged */
; Can1_ModeControlReg = Can1_ModeControlReg | RM_RR_Bit ;
       move.b    5243392,D0
       or.b      #1,D0
       move.b    D0,5243392
       bra       Init_CanBus_Controller1_1
Init_CanBus_Controller1_3:
; }
; /* set the Clock Divider Register according to the given hardware of Figure 3
; select PeliCAN mode
; bypass CAN input comparator as external transceiver is used
; select the clock for the controller S87C654 */
; Can1_ClockDivideReg = CANMode_Bit | CBP_Bit | DivBy2;
       move.b    #192,5243454
; /* disable CAN interrupts, if required (always necessary after power-on)
; (write to SJA1000 Interrupt Enable / Control Register) */
; Can1_InterruptEnReg = ClrIntEnSJA;
       clr.b     5243400
; /* define acceptance code and mask */
; Can1_AcceptCode0Reg = ClrByte;
       clr.b     5243424
; Can1_AcceptCode1Reg = ClrByte;
       clr.b     5243426
; Can1_AcceptCode2Reg = ClrByte;
       clr.b     5243428
; Can1_AcceptCode3Reg = ClrByte;
       clr.b     5243430
; Can1_AcceptMask0Reg = DontCare; /* every identifier is accepted */
       move.b    #255,5243432
; Can1_AcceptMask1Reg = DontCare; /* every identifier is accepted */
       move.b    #255,5243434
; Can1_AcceptMask2Reg = DontCare; /* every identifier is accepted */
       move.b    #255,5243436
; Can1_AcceptMask3Reg = DontCare; /* every identifier is accepted */
       move.b    #255,5243438
; /* configure bus timing */
; /* Values are given to us*/
; Can1_BusTiming0Reg = 0x04;
       move.b    #4,5243404
; Can1_BusTiming1Reg = 0x7f;
       move.b    #127,5243406
; /* configure CAN outputs: float on TX1, Push/Pull on TX0,
; normal output mode */
; Can1_OutControlReg = Tx1Float | Tx0PshPull | NormalMode;
       move.b    #26,5243408
; /* leave the reset mode/request i.e. switch to operating mode,
; the interrupts of the S87C654 are enabled
; but not the CAN interrupts of the SJA1000, which can be done separately
; for the different tasks in a system */
; /* clear Reset Mode bit, select dual Acceptance Filter Mode,
; switch off Self Test Mode and Listen Only Mode,
; clear Sleep Mode (wake up) */
; do /* wait until RM_RR_Bit is cleared */
Init_CanBus_Controller1_4:
; /* break loop after a time out and signal an error */
; {
; Can1_ModeControlReg = ClrByte;
       clr.b     5243392
       move.b    5243392,D0
       and.b     #1,D0
       bne       Init_CanBus_Controller1_4
; } while((Can1_ModeControlReg & RM_RR_Bit ) != ClrByte);
; Can1_InterruptEnReg = ENABLE; /* enable external interrupt from SJA1000 */
       move.b    #1,5243400
; //EA = ENABLE; /* enable all interrupts */
; /*----- end of Initialization Example of the SJA1000 ------------------------*/
; printf("\r\nEnd of Canbus 1 Initialization");
       pea       @lab584~1_2.L
       jsr       _printf
       addq.w    #4,A7
       rts
; }
; // Transmit for sending a message via Can controller 0
; void CanBus0_Transmit(void)
; {
       xdef      _CanBus0_Transmit
_CanBus0_Transmit:
       link      A6,#-4
       movem.l   D2/A2,-(A7)
       lea       _count.L,A2
; int i, switches = 0;
       clr.l     D2
; // TODO - put your Canbus transmit code for CanController 0 here
; // See section 4.2.2 in the application note for details (PELICAN MODE)
; /* wait until the Transmit Buffer is released */
; do
; {
CanBus0_Transmit_1:
; /* start a polling timer and run some tasks while waiting
; break the loop and signal an error if time too long */
; Timer2_Reset();
       jsr       _Timer2_Reset
; count++;
       addq.l    #1,(A2)
       move.b    5242884,D0
       and.b     #4,D0
       cmp.b     #4,D0
       bne       CanBus0_Transmit_1
; //printf("\r\nValue of count: %d", count);
; // Mason: I mean we can test without a polling timer for now
; } while((Can0_StatusReg & TBS_Bit ) != TBS_Bit );
; /* Transmit Buffer is released, a message may be written into the buffer */
; /* in this example a Standard Frame message shall be transmitted */
; switches = (PortB << 8) | (PortA);
       move.b    4194306,D0
       and.l     #255,D0
       lsl.l     #8,D0
       move.b    4194304,D1
       and.l     #255,D1
       or.l      D1,D0
       move.l    D0,D2
; Can0_TxFrameInfo = 0x08; /* SFF (data), DLC=8 */
       move.b    #8,5242912
; Can0_TxBuffer1 = 0xA5; /* ID1 = A5, (1010 0101) */
       move.b    #165,5242914
; Can0_TxBuffer2 = 0x20; /* ID2 = 20, (0010 0000) */
       move.b    #32,5242916
; Can0_TxBuffer3 = switches; // Switch Status
       move.b    D2,5242918
; if (count%2 == 0){
       move.l    (A2),-(A7)
       pea       2
       jsr       LDIV
       move.l    4(A7),D0
       addq.w    #8,A7
       tst.l     D0
       bne.s     CanBus0_Transmit_3
; Can0_TxBuffer4 = ADC_val; // ADC Potentiometer
       move.l    _ADC_val.L,D0
       move.b    D0,5242920
; ADC_val++;
       addq.l    #1,_ADC_val.L
CanBus0_Transmit_3:
; }
; if (count%5 == 0){
       move.l    (A2),-(A7)
       pea       5
       jsr       LDIV
       move.l    4(A7),D0
       addq.w    #8,A7
       tst.l     D0
       bne.s     CanBus0_Transmit_5
; Can0_TxBuffer5 = Photo_val; // Light Sensor
       move.l    _Photo_val.L,D0
       move.b    D0,5242922
; Photo_val++;
       addq.l    #1,_Photo_val.L
CanBus0_Transmit_5:
; }
; if (count%20 == 0){
       move.l    (A2),-(A7)
       pea       20
       jsr       LDIV
       move.l    4(A7),D0
       addq.w    #8,A7
       tst.l     D0
       bne.s     CanBus0_Transmit_7
; Can0_TxBuffer6 = Therm_val; // Thermistor
       move.l    _Therm_val.L,D0
       move.b    D0,5242924
; Therm_val++;
       addq.l    #1,_Therm_val.L
CanBus0_Transmit_7:
; }
; //Can0_TxBuffer7 = 0x85; /* data5 = 55 */
; //Can0_TxBuffer8 = 0x86; /* data6 = 56 */
; //Can0_TxBuffer9 = 0x87; /* data7 = 57 */
; //Can0_TxBuffer10 = 0x88; /* data8 = 58 */
; /* Start the transmission */
; Can0_CommandReg = TR_Bit ; /* Set Transmission Request bit */
       move.b    #1,5242882
       movem.l   (A7)+,D2/A2
       unlk      A6
       rts
; }
; // Transmit for sending a message via Can controller 1
; void CanBus1_Transmit(void)
; {
       xdef      _CanBus1_Transmit
_CanBus1_Transmit:
; // TODO - put your Canbus transmit code for CanController 1 here
; // See section 4.2.2 in the application note for details (PELICAN MODE)
; /* wait until the Transmit Buffer is released */
; do
; {
CanBus1_Transmit_1:
; /* start a polling timer and run some tasks while waiting
; break the loop and signal an error if time too long */
; // Mason: I mean we can test without a polling timer for now
; } while((Can1_StatusReg & TBS_Bit ) != TBS_Bit );
       move.b    5243396,D0
       and.b     #4,D0
       cmp.b     #4,D0
       bne       CanBus1_Transmit_1
; /* Transmit Buffer is released, a message may be written into the buffer */
; /* in this example a Standard Frame message shall be transmitted */
; Can1_TxFrameInfo = 0x08; /* SFF (data), DLC=8 */
       move.b    #8,5243424
; Can1_TxBuffer1 = 0xA5; /* ID1 = A5, (1010 0101) */
       move.b    #165,5243426
; Can1_TxBuffer2 = 0x20; /* ID2 = 20, (0010 0000) */
       move.b    #32,5243428
; Can1_TxBuffer3 = 0x71; /* data1 = 51 */
       move.b    #113,5243430
; Can1_TxBuffer4 = 0x72; /* data2 = 52 */
       move.b    #114,5243432
; Can1_TxBuffer5 = 0x73; /* data3 = 53 */
       move.b    #115,5243434
; Can1_TxBuffer6 = 0x74; /* data4 = 54 */
       move.b    #116,5243436
; Can1_TxBuffer7 = 0x75; /* data5 = 55 */
       move.b    #117,5243438
; Can1_TxBuffer8 = 0x76; /* data6 = 56 */
       move.b    #118,5243440
; Can1_TxBuffer9 = 0x77; /* data7 = 57 */
       move.b    #119,5243442
; Can1_TxBuffer10 = 0x78; /* data8 = 58 */
       move.b    #120,5243444
; /* Start the transmission */
; Can1_CommandReg = TR_Bit ; /* Set Transmission Request bit */
       move.b    #1,5243394
       rts
; }
; // Receive for reading a received message via Can controller 0
; void CanBus0_Receive(void)
; {
       xdef      _CanBus0_Receive
_CanBus0_Receive:
       link      A6,#-8
       move.l    A2,-(A7)
       lea       _printf.L,A2
; // TODO - put your Canbus receive code for CanController 0 here
; // See section 4.2.4 in the application note for details (PELICAN MODE)
; /* read the Interrupt Register content from SJA1000 and save temporarily
; all interrupt flags are cleared (in PeliCAN mode the Receive
; Interrupt (RI) is cleared first, when giving the Release Buffer command)
; */
; //CANInterrupt = InterruptReg;
; unsigned char CANInterrupt = Can0_InterruptEnReg;
       move.b    5242888,-5(A6)
; unsigned int RI_VarBit = CANInterrupt & (1<<0);
       move.b    -5(A6),D0
       and.l     #255,D0
       and.l     #1,D0
       move.l    D0,-4(A6)
; /* check for the Receive Interrupt and read one or all received messages */
; if (RI_VarBit == YES) /* Receive Interrupt detected */
       move.l    -4(A6),D0
       cmp.l     #1,D0
       bne       CanBus0_Receive_1
; // Mason: might beed to clear the Receive Interrupt bit (bit 0 in the Can0_InterruptEnReg)
; {
; /* get the content of the Receive Buffer from SJA1000 and store the
; message into internal memory of the controller,
; it is possible at once to decode the FrameInfo and Data Length Code
; and adapt the fetch appropriately */
; printf("\r\n CANBUS 0: Receive Buffer Frame Info: %x", Can0_RxFrameInfo) ;
       move.b    5242912,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @lab584~1_3.L
       jsr       (A2)
       addq.w    #8,A7
; printf("\r\n CANBUS 0:Receive Buffer 1: %x", Can0_RxBuffer1) ;
       move.b    5242914,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @lab584~1_4.L
       jsr       (A2)
       addq.w    #8,A7
; printf("\r\n CANBUS 0:Receive Buffer 2: %x", Can0_RxBuffer2) ;
       move.b    5242916,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @lab584~1_5.L
       jsr       (A2)
       addq.w    #8,A7
; printf("\r\n CANBUS 0:Receive Buffer 3: %x", Can0_RxBuffer3) ;
       move.b    5242918,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @lab584~1_6.L
       jsr       (A2)
       addq.w    #8,A7
; printf("\r\n CANBUS 0:Receive Buffer 4: %x", Can0_RxBuffer4) ;
       move.b    5242920,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @lab584~1_7.L
       jsr       (A2)
       addq.w    #8,A7
; printf("\r\n CANBUS 0:Receive Buffer 5: %x", Can0_RxBuffer5) ;
       move.b    5242922,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @lab584~1_8.L
       jsr       (A2)
       addq.w    #8,A7
; printf("\r\n CANBUS 0:Receive Buffer 6: %x", Can0_RxBuffer6) ;
       move.b    5242924,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @lab584~1_9.L
       jsr       (A2)
       addq.w    #8,A7
; printf("\r\n CANBUS 0:Receive Buffer 7: %x", Can0_RxBuffer7) ;
       move.b    5242926,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @lab584~1_10.L
       jsr       (A2)
       addq.w    #8,A7
; printf("\r\n CANBUS 0:Receive Buffer 8: %x", Can0_RxBuffer8) ;
       move.b    5242928,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @lab584~1_11.L
       jsr       (A2)
       addq.w    #8,A7
; printf("\r\n CANBUS 0:Receive Buffer 9: %x", Can0_RxBuffer9) ;
       move.b    5242930,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @lab584~1_12.L
       jsr       (A2)
       addq.w    #8,A7
; printf("\r\n CANBUS 0:Receive Buffer 10: %x", Can0_RxBuffer10) ;
       move.b    5242932,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @lab584~1_13.L
       jsr       (A2)
       addq.w    #8,A7
; /* release the Receive Buffer, now the Receive Interrupt flag is cleared,
; further messages will generate a new interrupt */
; //Can0_InterruptEnReg =
; Can0_CommandReg = RRB_Bit; /* Release Receive Buffer */
       move.b    #4,5242882
CanBus0_Receive_1:
       move.l    (A7)+,A2
       unlk      A6
       rts
; }
; }
; // Receive for reading a received message via Can controller 1
; void CanBus1_Receive(void)
; {
       xdef      _CanBus1_Receive
_CanBus1_Receive:
       link      A6,#-8
       movem.l   D2/A2,-(A7)
       lea       _printf.L,A2
; // TODO - put your Canbus receive code for CanController 1 here
; // See section 4.2.4 in the application note for details (PELICAN MODE)
; /* read the Interrupt Register content from SJA1000 and save temporarily
; all interrupt flags are cleared (in PeliCAN mode the Receive
; Interrupt (RI) is cleared first, when giving the Release Buffer command)
; */
; //CANInterrupt = InterruptReg;
; unsigned char CANInterrupt = Can1_InterruptEnReg;
       move.b    5243400,-5(A6)
; unsigned int RI_VarBit = CANInterrupt & (1<<0);
       move.b    -5(A6),D0
       and.l     #255,D0
       and.l     #1,D0
       move.l    D0,-4(A6)
; int i;
; /* check for the Receive Interrupt and read one or all received messages */
; if (RI_VarBit == YES) /* Receive Interrupt detected */
       move.l    -4(A6),D0
       cmp.l     #1,D0
       bne       CanBus1_Receive_1
; // Mason: might beed to clear the Receive Interrupt bit (bit 0 in the Can1_InterruptEnReg)
; {
; /* get the content of the Receive Buffer from SJA1000 and store the
; message into internal memory of the controller,
; it is possible at once to decode the FrameInfo and Data Length Code
; and adapt the fetch appropriately */
; //printf("\r\n CANBUS 1: Receive Buffer Frame Info: %x", Can1_RxFrameInfo) ;
; //printf("\r\n CANBUS 1: Receive Buffer 1: %x", Can1_RxBuffer1) ;
; //printf("\r\n CANBUS 1: Receive Buffer 2: %x", Can1_RxBuffer2) ;
; printf("\r\n CANBUS 1: Receive Buffer 3 (Switches SW[7-0]): ") ;
       pea       @lab584~1_14.L
       jsr       (A2)
       addq.w    #4,A7
; for (i = (int)(0x00000080); i > 0; i = i >> 1) {
       move.l    #128,D2
CanBus1_Receive_3:
       cmp.l     #0,D2
       ble.s     CanBus1_Receive_5
; if ((Can1_RxBuffer3 & i) == 0)
       move.b    5243430,D0
       and.l     #255,D0
       and.l     D2,D0
       bne.s     CanBus1_Receive_6
; printf("0");
       pea       @lab584~1_15.L
       jsr       (A2)
       addq.w    #4,A7
       bra.s     CanBus1_Receive_7
CanBus1_Receive_6:
; else
; printf("1");
       pea       @lab584~1_16.L
       jsr       (A2)
       addq.w    #4,A7
CanBus1_Receive_7:
       asr.l     #1,D2
       bra       CanBus1_Receive_3
CanBus1_Receive_5:
; }
; printf("\r\n CANBUS 1: ADC Readings: %x", Can1_RxBuffer4) ;
       move.b    5243432,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @lab584~1_17.L
       jsr       (A2)
       addq.w    #8,A7
; printf("\r\n CANBUS 1: Light Sensor: %x", Can1_RxBuffer5) ;
       move.b    5243434,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @lab584~1_18.L
       jsr       (A2)
       addq.w    #8,A7
; printf("\r\n CANBUS 1: Thermistor: %x", Can1_RxBuffer6) ;
       move.b    5243436,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @lab584~1_19.L
       jsr       (A2)
       addq.w    #8,A7
; //printf("\r\n CANBUS 1: Receive Buffer 7: %x", Can1_RxBuffer7) ;
; //printf("\r\n CANBUS 1: Receive Buffer 8: %x", Can1_RxBuffer8) ;
; //printf("\r\n CANBUS 1: Receive Buffer 9: %x", Can1_RxBuffer9) ;
; //printf("\r\n CANBUS 1: Receive Buffer 10: %x", Can1_RxBuffer10) ;
; /* release the Receive Buffer, now the Receive Interrupt flag is cleared,
; further messages will generate a new interrupt */
; Can1_CommandReg = RRB_Bit; /* Release Receive Buffer */
       move.b    #4,5243394
CanBus1_Receive_1:
       movem.l   (A7)+,D2/A2
       unlk      A6
       rts
; }
; }
; void delay(){
       xdef      _delay
_delay:
       movem.l   D2/D3,-(A7)
; int c, d;
; for (c = 1; c <= 3000; c++)
       moveq     #1,D3
delay_1:
       cmp.l     #3000,D3
       bgt.s     delay_3
; for (d = 1; d <= 3000; d++)
       moveq     #1,D2
delay_4:
       cmp.l     #3000,D2
       bgt.s     delay_6
; {}
       addq.l    #1,D2
       bra       delay_4
delay_6:
       addq.l    #1,D3
       bra       delay_1
delay_3:
; return;
       movem.l   (A7)+,D2/D3
       rts
; }
; void CanBusTest(void)
; {
       xdef      _CanBusTest
_CanBusTest:
       move.l    A2,-(A7)
       lea       _printf.L,A2
; // initialise the two Can controllers
; Init_CanBus_Controller0();
       jsr       _Init_CanBus_Controller0
; Init_CanBus_Controller1();
       jsr       _Init_CanBus_Controller1
; printf("\r\n\r\n---- CANBUS Test ----\r\n") ;
       pea       @lab584~1_20.L
       jsr       (A2)
       addq.w    #4,A7
; // simple application to alternately transmit and receive messages from each of two nodes
; delay();                    // write a routine to delay say 1/2 second so we don't flood the network with messages to0 quickly
       jsr       _delay
; //printf("\r\nCanBus0 is transmitting......");
; CanBus0_Transmit() ;       // transmit a message via Controller 0
       jsr       _CanBus0_Transmit
; //printf("\r\nCanBus1 is receiving......");
; CanBus1_Receive() ;        // receive a message via Controller 1 (and display it)
       jsr       _CanBus1_Receive
; printf("\r\n") ;
       pea       @lab584~1_21.L
       jsr       (A2)
       addq.w    #4,A7
; delay();                    // write a routine to delay say 1/2 second so we don't flood the network with messages to0 quickly
       jsr       _delay
; //printf("\r\nCanBus1 is transmitting......");
; CanBus1_Transmit() ;        // transmit a message via Controller 1
       jsr       _CanBus1_Transmit
; //printf("\r\nCanBus0 is receiving......");
; CanBus0_Receive() ;         // receive a message via Controller 0 (and display it)
       jsr       _CanBus0_Receive
; printf("\r\n") ;
       pea       @lab584~1_21.L
       jsr       (A2)
       addq.w    #4,A7
       move.l    (A7)+,A2
       rts
; }
; void Send_Recieve_CANBUS_0(){
       xdef      _Send_Recieve_CANBUS_0
_Send_Recieve_CANBUS_0:
; CanBus0_Transmit();
       jsr       _CanBus0_Transmit
; CanBus1_Receive();
       jsr       _CanBus1_Receive
       rts
; }
; void main(){
       xdef      _main
_main:
; Init_CanBus_Controller0();
       jsr       _Init_CanBus_Controller0
; Init_CanBus_Controller1();
       jsr       _Init_CanBus_Controller1
; //CanBusTest();
; //Timer2_Init();
; printf("\r\nTimer Initialized");
       pea       @lab584~1_22.L
       jsr       _printf
       addq.w    #4,A7
; InstallExceptionHandler(Send_Recieve_CANBUS_0, 30);
       pea       30
       pea       _Send_Recieve_CANBUS_0.L
       jsr       _InstallExceptionHandler
       addq.w    #8,A7
; Timer2_Init();
       jsr       _Timer2_Init
; while(1){;}
main_1:
       bra       main_1
; }
       section   const
@lab584~1_1:
       dc.b      13,10,69,110,100,32,111,102,32,67,97,110,98
       dc.b      117,115,32,48,32,73,110,105,116,105,97,108,105
       dc.b      122,97,116,105,111,110,0
@lab584~1_2:
       dc.b      13,10,69,110,100,32,111,102,32,67,97,110,98
       dc.b      117,115,32,49,32,73,110,105,116,105,97,108,105
       dc.b      122,97,116,105,111,110,0
@lab584~1_3:
       dc.b      13,10,32,67,65,78,66,85,83,32,48,58,32,82,101
       dc.b      99,101,105,118,101,32,66,117,102,102,101,114
       dc.b      32,70,114,97,109,101,32,73,110,102,111,58,32
       dc.b      37,120,0
@lab584~1_4:
       dc.b      13,10,32,67,65,78,66,85,83,32,48,58,82,101,99
       dc.b      101,105,118,101,32,66,117,102,102,101,114,32
       dc.b      49,58,32,37,120,0
@lab584~1_5:
       dc.b      13,10,32,67,65,78,66,85,83,32,48,58,82,101,99
       dc.b      101,105,118,101,32,66,117,102,102,101,114,32
       dc.b      50,58,32,37,120,0
@lab584~1_6:
       dc.b      13,10,32,67,65,78,66,85,83,32,48,58,82,101,99
       dc.b      101,105,118,101,32,66,117,102,102,101,114,32
       dc.b      51,58,32,37,120,0
@lab584~1_7:
       dc.b      13,10,32,67,65,78,66,85,83,32,48,58,82,101,99
       dc.b      101,105,118,101,32,66,117,102,102,101,114,32
       dc.b      52,58,32,37,120,0
@lab584~1_8:
       dc.b      13,10,32,67,65,78,66,85,83,32,48,58,82,101,99
       dc.b      101,105,118,101,32,66,117,102,102,101,114,32
       dc.b      53,58,32,37,120,0
@lab584~1_9:
       dc.b      13,10,32,67,65,78,66,85,83,32,48,58,82,101,99
       dc.b      101,105,118,101,32,66,117,102,102,101,114,32
       dc.b      54,58,32,37,120,0
@lab584~1_10:
       dc.b      13,10,32,67,65,78,66,85,83,32,48,58,82,101,99
       dc.b      101,105,118,101,32,66,117,102,102,101,114,32
       dc.b      55,58,32,37,120,0
@lab584~1_11:
       dc.b      13,10,32,67,65,78,66,85,83,32,48,58,82,101,99
       dc.b      101,105,118,101,32,66,117,102,102,101,114,32
       dc.b      56,58,32,37,120,0
@lab584~1_12:
       dc.b      13,10,32,67,65,78,66,85,83,32,48,58,82,101,99
       dc.b      101,105,118,101,32,66,117,102,102,101,114,32
       dc.b      57,58,32,37,120,0
@lab584~1_13:
       dc.b      13,10,32,67,65,78,66,85,83,32,48,58,82,101,99
       dc.b      101,105,118,101,32,66,117,102,102,101,114,32
       dc.b      49,48,58,32,37,120,0
@lab584~1_14:
       dc.b      13,10,32,67,65,78,66,85,83,32,49,58,32,82,101
       dc.b      99,101,105,118,101,32,66,117,102,102,101,114
       dc.b      32,51,32,40,83,119,105,116,99,104,101,115,32
       dc.b      83,87,91,55,45,48,93,41,58,32,0
@lab584~1_15:
       dc.b      48,0
@lab584~1_16:
       dc.b      49,0
@lab584~1_17:
       dc.b      13,10,32,67,65,78,66,85,83,32,49,58,32,65,68
       dc.b      67,32,82,101,97,100,105,110,103,115,58,32,37
       dc.b      120,0
@lab584~1_18:
       dc.b      13,10,32,67,65,78,66,85,83,32,49,58,32,76,105
       dc.b      103,104,116,32,83,101,110,115,111,114,58,32
       dc.b      37,120,0
@lab584~1_19:
       dc.b      13,10,32,67,65,78,66,85,83,32,49,58,32,84,104
       dc.b      101,114,109,105,115,116,111,114,58,32,37,120
       dc.b      0
@lab584~1_20:
       dc.b      13,10,13,10,45,45,45,45,32,67,65,78,66,85,83
       dc.b      32,84,101,115,116,32,45,45,45,45,13,10,0
@lab584~1_21:
       dc.b      13,10,0
@lab584~1_22:
       dc.b      13,10,84,105,109,101,114,32,73,110,105,116,105
       dc.b      97,108,105,122,101,100,0
       section   bss
       xdef      _count
_count:
       ds.b      4
       xdef      _ADC_val
_ADC_val:
       ds.b      4
       xdef      _Photo_val
_Photo_val:
       ds.b      4
       xdef      _Therm_val
_Therm_val:
       ds.b      4
       xref      LDIV
       xref      _printf
