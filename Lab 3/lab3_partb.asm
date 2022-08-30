; C:\M68KV6.0 - 800BY480[LAB5]\M68KV6.0 - 800BY480 - (VERILOG) FOR STUDENTS (2020)\LAB3_PARTB.C - Compiled by CC68K  Version 5.00 (c) 1991-2005  Peter J. Fondse
; #include <stdio.h>
; #include <string.h>
; #include <ctype.h>
; #include <stdlib.h>
; /*************************************************************
; ** SPI Controller registers
; **************************************************************/
; // I2C Registers
; #define PRERlo              (*(volatile unsigned char *)(0x00408000))
; #define PRERhi              (*(volatile unsigned char *)(0x00408002))
; #define CTR                 (*(volatile unsigned char *)(0x00408004))
; #define TXR_RXR             (*(volatile unsigned char *)(0x00408006))
; #define CR_SR              ( *(volatile unsigned char *)(0x00408008))
; #define RS232_Control     *(volatile unsigned char *)(0x00400040)
; #define RS232_Status      *(volatile unsigned char *)(0x00400040)
; #define RS232_TxData      *(volatile unsigned char *)(0x00400042)
; #define RS232_RxData      *(volatile unsigned char *)(0x00400042)
; #define RS232_Baud        *(volatile unsigned char *)(0x00400044)
; // these two macros enable or disable the flash memory chip enable off SSN_O[7..0]
; // in this case we assume there is only 1 device connected to SSN_O[0] so we can
; // write hex FE to the SPI_CS to enable it (the enable on the flash chip is active low)
; // and write FF to disable it
; typedef int bool;
; #define false 0
; #define true 1
; #define   Enable_SPI_CS()             SPI_CS = 0xFE
; #define   Disable_SPI_CS()            SPI_CS = 0xFF
; // Defining commands
; int Write_Enable_Command =  0x06;
; int Page_Program_Command =  0x02;
; int Erase_Chip_Command   =  0xC7;
; int Read_Status_Register_Command = 0x05;
; int Read_Flash_Chip_Command = 0x03;
; int First_Address_Byte   =  0x00;
; int Test_Data_Byte       =  0x09;
; int Dummy_Data_Byte      =  0xFF;
; /*********************************************************************************************
; *Subroutine to initialise the RS232 Port by writing some commands to the internal registers
; *********************************************************************************************/
; void Init_RS232(void)
; {
       section   code
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
; void DELAY(void){
       xdef      _DELAY
_DELAY:
       link      A6,#-4
       move.l    D2,-(A7)
; int i, j;
; for (i = 0; i<1000; i++){
       clr.l     D2
DELAY_1:
       cmp.l     #1000,D2
       bge.s     DELAY_3
; for (i = 0; i<10000; i++){
       clr.l     D2
DELAY_4:
       cmp.l     #10000,D2
       bge.s     DELAY_6
; ;
       addq.l    #1,D2
       bra       DELAY_4
DELAY_6:
       addq.l    #1,D2
       bra       DELAY_1
DELAY_3:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; }
; }
; //Initialize and Enable the IIC Controller
; void IIC_Init(void){
       xdef      _IIC_Init
_IIC_Init:
; PRERlo = 0x31;
       move.b    #49,4227072
; PRERhi = 0x00;
       clr.b     4227074
; CTR = 0x80;
       move.b    #128,4227076
       rts
; }
; //Check Status Register TIP bit (bit 1) to see when transmit finished
; void WaitForIICTransmitComplete(void){
       xdef      _WaitForIICTransmitComplete
_WaitForIICTransmitComplete:
; //printf("\r\nWaiting For Transmit Complete");
; while(CR_SR & (1<<1)){
WaitForIICTransmitComplete_1:
       move.b    4227080,D0
       and.b     #2,D0
       beq.s     WaitForIICTransmitComplete_3
; //printf("\r\n%d", CR_SR);
; }
       bra       WaitForIICTransmitComplete_1
WaitForIICTransmitComplete_3:
; return;
       rts
; }
; //Wait for acknowledgement from slave
; void WaitForACK(void){
       xdef      _WaitForACK
_WaitForACK:
; //printf("\r\nWaiting For ACK");
; while(CR_SR&(1<<7)){
WaitForACK_1:
       move.b    4227080,D0
       and.b     #128,D0
       beq.s     WaitForACK_3
; //printf("\r\n%d", CR_SR);
; }
       bra       WaitForACK_1
WaitForACK_3:
; return;
       rts
; }
; //Polling IIC Status Register to see if data has been read
; void CheckDataReceived(void){
       xdef      _CheckDataReceived
_CheckDataReceived:
; //printf("\r\n%d", CR_SR);
; while(!CR_SR&(1<<0)){
CheckDataReceived_1:
       tst.b     4227080
       bne.s     CheckDataReceived_4
       moveq     #1,D0
       bra.s     CheckDataReceived_5
CheckDataReceived_4:
       clr.l     D0
CheckDataReceived_5:
       and.b     #1,D0
       beq.s     CheckDataReceived_3
; }
       bra       CheckDataReceived_1
CheckDataReceived_3:
; return;
       rts
; }
; //Read Byte from EEProm
; void ReadByteEEProm(int high_addr, int low_addr, int count, int block_num){
       xdef      _ReadByteEEProm
_ReadByteEEProm:
       link      A6,#0
       movem.l   D2/A2/A3,-(A7)
       lea       _WaitForIICTransmitComplete.L,A2
       lea       _WaitForACK.L,A3
; int c;
; DELAY();
       jsr       _DELAY
; //Write Slave Address, Enable Start Condition
; //printf("\r\nWriting to slave address.....");
; if (block_num == 0) // Block 0 Selected
       move.l    20(A6),D0
       bne.s     ReadByteEEProm_1
; TXR_RXR = 0xA4; // Write Slave Address to TX register 10100100
       move.b    #164,4227078
       bra.s     ReadByteEEProm_2
ReadByteEEProm_1:
; else //Block 1
; TXR_RXR = 0xAC; // Write Slave Address to TX register 10101100
       move.b    #172,4227078
ReadByteEEProm_2:
; CR_SR = 0x91; //10010001: Bit 7 START, BIT 4 Write to Slave, BIT 0 Clear Interrupts
       move.b    #145,4227080
; WaitForIICTransmitComplete(); //Check if transmit is complete
       jsr       (A2)
; WaitForACK();
       jsr       (A3)
; //Write Two Bytes for Internal Address
; //printf("\r\nWriting high byte internal address.....");
; TXR_RXR = high_addr; // Write High Byte Internal Address to TX register
       move.l    8(A6),D0
       move.b    D0,4227078
; CR_SR = 0x11;
       move.b    #17,4227080
; WaitForIICTransmitComplete(); //Check if transmit is complete
       jsr       (A2)
; WaitForACK();
       jsr       (A3)
; //printf("\r\nWriting low byte internal address.....");
; TXR_RXR = low_addr; // Write Low Byte Internal Address to TX register
       move.l    12(A6),D0
       move.b    D0,4227078
; CR_SR =0x11;
       move.b    #17,4227080
; WaitForIICTransmitComplete(); //Check if transmit is complete
       jsr       (A2)
; WaitForACK();
       jsr       (A3)
; //Write Slave Address Again and Enable Start Condition, but this time its a read
; //printf("\r\nReading data byte.....");
; if (block_num == 0) // Block 0 Selected
       move.l    20(A6),D0
       bne.s     ReadByteEEProm_3
; TXR_RXR = 0xA5; // Write Slave Address to TX register 10100101
       move.b    #165,4227078
       bra.s     ReadByteEEProm_4
ReadByteEEProm_3:
; else
; TXR_RXR = 0xAD; // Write Slave Address to TX register 10101101
       move.b    #173,4227078
ReadByteEEProm_4:
; CR_SR =  0x91;//10010001: Bit 7 START, BIT 5 Write to Slave, BIT 0 Clear Interrupts
       move.b    #145,4227080
; WaitForIICTransmitComplete(); //Check if transmit is complete
       jsr       (A2)
; WaitForACK();
       jsr       (A3)
; while(count>1){
ReadByteEEProm_5:
       move.l    16(A6),D0
       cmp.l     #1,D0
       ble.s     ReadByteEEProm_7
; CR_SR = 0x21; // 00100001 Read , ACK, IACK
       move.b    #33,4227080
; WaitForIICTransmitComplete(); //Check if transmit is complete
       jsr       (A2)
; CheckDataReceived(); //Check if byte is recieved
       jsr       _CheckDataReceived
; c = TXR_RXR; //Read Byte
       move.b    4227078,D0
       and.l     #255,D0
       move.l    D0,D2
; printf("\r\nThe data byte read is %x", c);
       move.l    D2,-(A7)
       pea       @lab3_p~1_1.L
       jsr       _printf
       addq.w    #8,A7
; count--;
       subq.l    #1,16(A6)
       bra       ReadByteEEProm_5
ReadByteEEProm_7:
; }
; CR_SR = 0x29; // 00101001 Read , NACK, IACK
       move.b    #41,4227080
; WaitForIICTransmitComplete(); //Check if transmit is complete
       jsr       (A2)
; CheckDataReceived(); //Check if byte is recieved
       jsr       _CheckDataReceived
; c = TXR_RXR; //Read Byte
       move.b    4227078,D0
       and.l     #255,D0
       move.l    D0,D2
; printf("\r\nThe data byte read is %x", c);
       move.l    D2,-(A7)
       pea       @lab3_p~1_1.L
       jsr       _printf
       addq.w    #8,A7
; CR_SR = 0x41;//01000001
       move.b    #65,4227080
; WaitForIICTransmitComplete(); //Check if transmit is complete
       jsr       (A2)
       movem.l   (A7)+,D2/A2/A3
       unlk      A6
       rts
; //return c;
; }
; //Write Byte to EEProm
; void WriteByteEEProm(int byte, int upper_addr, int lower_addr, int count, int block_num){
       xdef      _WriteByteEEProm
_WriteByteEEProm:
       link      A6,#0
       movem.l   A2/A3,-(A7)
       lea       _WaitForIICTransmitComplete.L,A2
       lea       _WaitForACK.L,A3
; //Write Slave Address, Enable Start Condition
; //printf("\r\nWriting to slave address.....");
; //printf("\r\nCOUNT: %d",count);
; DELAY();
       jsr       _DELAY
; if (block_num == 0) // Block 0 Selected
       move.l    24(A6),D0
       bne.s     WriteByteEEProm_1
; TXR_RXR = 0xA4; // Write Slave Address to TX register 10100100
       move.b    #164,4227078
       bra.s     WriteByteEEProm_2
WriteByteEEProm_1:
; else //Block 1
; TXR_RXR = 0xAC; // Write Slave Address to TX register 10101100
       move.b    #172,4227078
WriteByteEEProm_2:
; CR_SR = 0x91;//10010001: Bit 7 START, BIT 4 Write to Slave, BIT 0 Clear Interrupts
       move.b    #145,4227080
; WaitForIICTransmitComplete(); //Check if transmit is complete
       jsr       (A2)
; WaitForACK();
       jsr       (A3)
; //Write Two Bytes for Internal Address
; //printf("\r\nWriting high byte internal address.....");
; TXR_RXR = upper_addr; // Write High Byte Internal Address to TX register
       move.l    12(A6),D0
       move.b    D0,4227078
; CR_SR = 0x11;
       move.b    #17,4227080
; WaitForIICTransmitComplete(); //Check if transmit is complete
       jsr       (A2)
; WaitForACK();
       jsr       (A3)
; //printf("\r\nWriting low byte internal address.....");
; TXR_RXR = lower_addr; // Write Low Byte Internal Address to TX register
       move.l    16(A6),D0
       move.b    D0,4227078
; CR_SR = 0x11;
       move.b    #17,4227080
; WaitForIICTransmitComplete(); //Check if transmit is complete
       jsr       (A2)
; WaitForACK();
       jsr       (A3)
; //Write Data Byte, Enable Stop Condition
; //printf("\r\nWriting data byte....");
; while (count>0){
WriteByteEEProm_3:
       move.l    20(A6),D0
       cmp.l     #0,D0
       ble.s     WriteByteEEProm_5
; TXR_RXR = byte; // Write Low Byte Internal Address to TX register
       move.l    8(A6),D0
       move.b    D0,4227078
; CR_SR = 0x11; //10000001: BIT 6 Stop, BIT 0 IACk
       move.b    #17,4227080
; WaitForIICTransmitComplete(); //Check if transmit is complete
       jsr       (A2)
; WaitForACK();
       jsr       (A3)
; count--;
       subq.l    #1,20(A6)
; byte++;
       addq.l    #1,8(A6)
       bra       WriteByteEEProm_3
WriteByteEEProm_5:
; }
; CR_SR = 0x40; //STOP
       move.b    #64,4227080
; WaitForIICTransmitComplete(); //Check if transmit is complete
       jsr       (A2)
       movem.l   (A7)+,A2/A3
       unlk      A6
       rts
; //Process Complete
; //printf("\r\nByte written to TX register: %x", byte);
; }
; //Write 128 bytes starting at any address
; int* PageWriteEEProm(int upper_addr, int lower_addr, int block_num){
       xdef      _PageWriteEEProm
_PageWriteEEProm:
       link      A6,#-8
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3/A4,-(A7)
       move.l    12(A6),D2
       move.l    8(A6),D5
       lea       _printf.L,A2
       lea       -8(A6),A3
       move.l    16(A6),D6
       lea       _WriteByteEEProm.L,A4
; int remainingbytes = 0;
       clr.l     D3
; int count = 0; //How much we can fill in the page initially
       clr.l     D4
; int flag = 0;
       moveq     #0,D7
; int arr[2];
; if (lower_addr>=0x00 && lower_addr<=0x7F){
       cmp.l     #0,D2
       blt       PageWriteEEProm_1
       cmp.l     #127,D2
       bgt       PageWriteEEProm_1
; count = 0x7F - lower_addr + 1;
       moveq     #127,D0
       ext.w     D0
       ext.l     D0
       sub.l     D2,D0
       addq.l    #1,D0
       move.l    D0,D4
; remainingbytes = lower_addr - 0x00;
       move.l    D2,D0
       move.l    D0,D3
; printf("\r\nLower address count: %d", count);
       move.l    D4,-(A7)
       pea       @lab3_p~1_2.L
       jsr       (A2)
       addq.w    #8,A7
; printf("\r\nRemaining bytes for Lower address: %d", remainingbytes);
       move.l    D3,-(A7)
       pea       @lab3_p~1_3.L
       jsr       (A2)
       addq.w    #8,A7
       bra       PageWriteEEProm_2
PageWriteEEProm_1:
; //flag = 0;
; }
; else{ // Implies that lower_addr is in range 0x80-0xFF
; count = 0xFF - lower_addr + 1;
       move.w    #255,D0
       ext.l     D0
       sub.l     D2,D0
       addq.l    #1,D0
       move.l    D0,D4
; remainingbytes = lower_addr - 0x80;
       move.l    D2,D0
       sub.l     #128,D0
       move.l    D0,D3
; flag = 1;
       moveq     #1,D7
; printf("\r\nUpper address count: %d", count);
       move.l    D4,-(A7)
       pea       @lab3_p~1_4.L
       jsr       (A2)
       addq.w    #8,A7
; printf("\r\nRemaining bytes for Upper address: %d", remainingbytes);
       move.l    D3,-(A7)
       pea       @lab3_p~1_5.L
       jsr       (A2)
       addq.w    #8,A7
PageWriteEEProm_2:
; }
; WriteByteEEProm(0x00, upper_addr, lower_addr, count, block_num);
       move.l    D6,-(A7)
       move.l    D4,-(A7)
       move.l    D2,-(A7)
       move.l    D5,-(A7)
       clr.l     -(A7)
       jsr       (A4)
       add.w     #20,A7
; if (flag == 1){
       cmp.l     #1,D7
       bne.s     PageWriteEEProm_3
; lower_addr = 0x00;
       clr.l     D2
; upper_addr++;
       addq.l    #1,D5
; if (remainingbytes >0){
       cmp.l     #0,D3
       ble.s     PageWriteEEProm_5
; //printf("\r\nShould be upper, remaining bytes is %x", remainingbytes);
; WriteByteEEProm(0x00, upper_addr, lower_addr, remainingbytes, block_num);
       move.l    D6,-(A7)
       move.l    D3,-(A7)
       move.l    D2,-(A7)
       move.l    D5,-(A7)
       clr.l     -(A7)
       jsr       (A4)
       add.w     #20,A7
PageWriteEEProm_5:
       bra.s     PageWriteEEProm_7
PageWriteEEProm_3:
; }
; }
; else{
; lower_addr = 0x80;
       move.l    #128,D2
; if (remainingbytes >0){
       cmp.l     #0,D3
       ble.s     PageWriteEEProm_7
; //printf("\r\nShould be lower, remaining bytes is %x", remainingbytes);
; WriteByteEEProm(0x00, upper_addr, lower_addr, remainingbytes, block_num);
       move.l    D6,-(A7)
       move.l    D3,-(A7)
       move.l    D2,-(A7)
       move.l    D5,-(A7)
       clr.l     -(A7)
       jsr       (A4)
       add.w     #20,A7
PageWriteEEProm_7:
; }
; }
; lower_addr = lower_addr + remainingbytes;
       add.l     D3,D2
; arr[0] = lower_addr;
       move.l    D2,(A3)
; arr[1] = upper_addr;
       move.l    D5,4(A3)
; return arr;
       move.l    A3,D0
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3/A4
       unlk      A6
       rts
; }
; //Read a page
; void PageReadEEProm(int upper_addr, int lower_addr, int block_num){
       xdef      _PageReadEEProm
_PageReadEEProm:
       link      A6,#0
; //int count = 0; //How much we can fill in the page initially
; /*
; if (lower_addr>=0x00 && lower_addr<=0x7F){
; count = 0x7F - lower_addr + 1;
; }
; else{ // Implies that lower_addr is in range 0x7F-0xFF
; count = 0xFF - lower_addr + 1;
; }*/
; ReadByteEEProm(upper_addr, lower_addr, 128, block_num);
       move.l    16(A6),-(A7)
       pea       128
       move.l    12(A6),-(A7)
       move.l    8(A6),-(A7)
       jsr       _ReadByteEEProm
       add.w     #16,A7
       unlk      A6
       rts
; }
; //Write block of up to 128k Bytes starting at any address
; void Write128kEEProm(int upper_start_addr, int lower_start_addr, int block_to_write, int write_num){
       xdef      _Write128kEEProm
_Write128kEEProm:
       link      A6,#-12
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3/A4/A5,-(A7)
       move.l    12(A6),D2
       move.l    16(A6),D3
       move.l    8(A6),D4
       lea       _printf.L,A2
       lea       _WriteByteEEProm.L,A3
; int pagewritenumber;
; int indiwritenumber;
; int initialPageFill;
; int i;
; int count;
; int remainingbytes;
; int *temp;
; int flag = 0;
       clr.l     -4(A6)
; if (lower_start_addr>=0x00 && lower_start_addr<=0x7F){
       cmp.l     #0,D2
       blt.s     Write128kEEProm_1
       cmp.l     #127,D2
       bgt.s     Write128kEEProm_1
; initialPageFill = 0x7F - lower_start_addr + 1;
       moveq     #127,D0
       ext.w     D0
       ext.l     D0
       sub.l     D2,D0
       addq.l    #1,D0
       move.l    D0,D7
; printf("\r\nLower address initial page fill: %d", initialPageFill);
       move.l    D7,-(A7)
       pea       @lab3_p~1_6.L
       jsr       (A2)
       addq.w    #8,A7
       bra.s     Write128kEEProm_2
Write128kEEProm_1:
; }
; else{ // Implies that lower_addr is in range 0x80-0xFF
; initialPageFill = 0xFF - lower_start_addr + 1;
       move.w    #255,D0
       ext.l     D0
       sub.l     D2,D0
       addq.l    #1,D0
       move.l    D0,D7
; printf("\r\nUpper address initial page fill: %d", initialPageFill);
       move.l    D7,-(A7)
       pea       @lab3_p~1_7.L
       jsr       (A2)
       addq.w    #8,A7
; flag = 1;
       move.l    #1,-4(A6)
Write128kEEProm_2:
; }
; if(initialPageFill >= write_num) {
       cmp.l     20(A6),D7
       blt.s     Write128kEEProm_3
; pagewritenumber = 0;
       move.w    #0,A5
; indiwritenumber = 0;
       clr.l     D5
; WriteByteEEProm(0x00, upper_start_addr, lower_start_addr, write_num, block_to_write);
       move.l    D3,-(A7)
       move.l    20(A6),-(A7)
       move.l    D2,-(A7)
       move.l    D4,-(A7)
       clr.l     -(A7)
       jsr       (A3)
       add.w     #20,A7
       bra       Write128kEEProm_4
Write128kEEProm_3:
; } else {
; pagewritenumber = (write_num-initialPageFill)/128;
       move.l    20(A6),D0
       sub.l     D7,D0
       move.l    D0,-(A7)
       pea       128
       jsr       LDIV
       move.l    (A7),D0
       addq.w    #8,A7
       move.l    D0,A5
; indiwritenumber = (write_num-initialPageFill)%128;
       move.l    20(A6),D0
       sub.l     D7,D0
       move.l    D0,-(A7)
       pea       128
       jsr       LDIV
       move.l    4(A7),D0
       addq.w    #8,A7
       move.l    D0,D5
; WriteByteEEProm(0x00, upper_start_addr, lower_start_addr, initialPageFill, block_to_write);
       move.l    D3,-(A7)
       move.l    D7,-(A7)
       move.l    D2,-(A7)
       move.l    D4,-(A7)
       clr.l     -(A7)
       jsr       (A3)
       add.w     #20,A7
Write128kEEProm_4:
; }
; printf("\r\nPage writes: %d", pagewritenumber);
       move.l    A5,-(A7)
       pea       @lab3_p~1_8.L
       jsr       (A2)
       addq.w    #8,A7
; printf("\r\nIndividual writes: %d", indiwritenumber);
       move.l    D5,-(A7)
       pea       @lab3_p~1_9.L
       jsr       (A2)
       addq.w    #8,A7
; if (pagewritenumber >0 || indiwritenumber>0){
       move.l    A5,D0
       cmp.l     #0,D0
       bgt.s     Write128kEEProm_7
       cmp.l     #0,D5
       ble       Write128kEEProm_9
Write128kEEProm_7:
; if (flag == 1){
       move.l    -4(A6),D0
       cmp.l     #1,D0
       bne.s     Write128kEEProm_8
; if(upper_start_addr == 0xFF && lower_start_addr>= 0x80){
       cmp.l     #255,D4
       bne.s     Write128kEEProm_10
       cmp.l     #128,D2
       blt.s     Write128kEEProm_10
; if (block_to_write ==0){
       tst.l     D3
       bne.s     Write128kEEProm_12
; block_to_write = 1;
       moveq     #1,D3
       bra.s     Write128kEEProm_13
Write128kEEProm_12:
; }
; else{
; block_to_write = 0;
       clr.l     D3
Write128kEEProm_13:
; }
; upper_start_addr = 0x00;
       clr.l     D4
       bra.s     Write128kEEProm_11
Write128kEEProm_10:
; }
; else{
; upper_start_addr++;
       addq.l    #1,D4
Write128kEEProm_11:
; }
; lower_start_addr = 0x00;
       clr.l     D2
       bra.s     Write128kEEProm_9
Write128kEEProm_8:
; }
; else{
; lower_start_addr = 0x80;
       move.l    #128,D2
Write128kEEProm_9:
; }
; }
; for (i = 0; i <pagewritenumber; i++){
       clr.l     -12(A6)
Write128kEEProm_14:
       move.l    A5,D0
       cmp.l     -12(A6),D0
       ble       Write128kEEProm_16
; if (upper_start_addr == 0xFF && lower_start_addr > 0x80){
       cmp.l     #255,D4
       bne       Write128kEEProm_17
       cmp.l     #128,D2
       ble       Write128kEEProm_17
; //Calculate how much to put in this block and the new block
; printf("\r\nFILLS UP REMAINDER OF BLOCK %d, THEN SWITCHES BLOCK", block_to_write);
       move.l    D3,-(A7)
       pea       @lab3_p~1_10.L
       jsr       (A2)
       addq.w    #8,A7
; count = 0xFF - lower_start_addr + 1;
       move.w    #255,D0
       ext.l     D0
       sub.l     D2,D0
       addq.l    #1,D0
       move.l    D0,D6
; remainingbytes = lower_start_addr - 0x80;
       move.l    D2,D0
       sub.l     #128,D0
       move.l    D0,A4
; WriteByteEEProm(0x80, upper_start_addr, lower_start_addr, count, block_to_write);
       move.l    D3,-(A7)
       move.l    D6,-(A7)
       move.l    D2,-(A7)
       move.l    D4,-(A7)
       pea       128
       jsr       (A3)
       add.w     #20,A7
; if (block_to_write ==0){
       tst.l     D3
       bne.s     Write128kEEProm_19
; block_to_write = 1;
       moveq     #1,D3
       bra.s     Write128kEEProm_20
Write128kEEProm_19:
; }
; else{
; block_to_write = 0;
       clr.l     D3
Write128kEEProm_20:
; }
; upper_start_addr = 0x00;
       clr.l     D4
; lower_start_addr = 0x00;
       clr.l     D2
; WriteByteEEProm(0x25, upper_start_addr, lower_start_addr, remainingbytes, block_to_write);
       move.l    D3,-(A7)
       move.l    A4,-(A7)
       move.l    D2,-(A7)
       move.l    D4,-(A7)
       pea       37
       jsr       (A3)
       add.w     #20,A7
; lower_start_addr = lower_start_addr + remainingbytes;
       add.l     A4,D2
       bra       Write128kEEProm_24
Write128kEEProm_17:
; }
; else if (upper_start_addr == 0xFF && lower_start_addr == 0x80){
       cmp.l     #255,D4
       bne       Write128kEEProm_24
       cmp.l     #128,D2
       bne       Write128kEEProm_24
; printf("\r\nFILLS UP BLOCK %d, THEN SWITCHES BLOCK", block_to_write);
       move.l    D3,-(A7)
       pea       @lab3_p~1_11.L
       jsr       (A2)
       addq.w    #8,A7
; PageWriteEEProm(upper_start_addr,lower_start_addr,block_to_write);
       move.l    D3,-(A7)
       move.l    D2,-(A7)
       move.l    D4,-(A7)
       jsr       _PageWriteEEProm
       add.w     #12,A7
; upper_start_addr = 0x00;
       clr.l     D4
; lower_start_addr = 0x00;
       clr.l     D2
; if (block_to_write ==0){
       tst.l     D3
       bne.s     Write128kEEProm_23
; block_to_write = 1;
       moveq     #1,D3
       bra.s     Write128kEEProm_24
Write128kEEProm_23:
; }
; else{
; block_to_write = 0;
       clr.l     D3
Write128kEEProm_24:
; }
; }
; temp = PageWriteEEProm(upper_start_addr,lower_start_addr,block_to_write);
       move.l    D3,-(A7)
       move.l    D2,-(A7)
       move.l    D4,-(A7)
       jsr       _PageWriteEEProm
       add.w     #12,A7
       move.l    D0,-8(A6)
; upper_start_addr = temp[1];
       move.l    -8(A6),A0
       move.l    4(A0),D4
; lower_start_addr = temp[0];
       move.l    -8(A6),A0
       move.l    (A0),D2
       addq.l    #1,-12(A6)
       bra       Write128kEEProm_14
Write128kEEProm_16:
; }
; if (indiwritenumber>0){
       cmp.l     #0,D5
       ble       Write128kEEProm_30
; if (lower_start_addr>=0x00 && lower_start_addr<=0x7F){
       cmp.l     #0,D2
       blt.s     Write128kEEProm_27
       cmp.l     #127,D2
       bgt.s     Write128kEEProm_27
; count = 0x7F - lower_start_addr + 1;
       moveq     #127,D0
       ext.w     D0
       ext.l     D0
       sub.l     D2,D0
       addq.l    #1,D0
       move.l    D0,D6
       bra.s     Write128kEEProm_28
Write128kEEProm_27:
; }
; else{ // Implies that lower_addr is in range 0x80-0xFF
; count = 0xFF - lower_start_addr + 1;
       move.w    #255,D0
       ext.l     D0
       sub.l     D2,D0
       addq.l    #1,D0
       move.l    D0,D6
; flag = 1;
       move.l    #1,-4(A6)
Write128kEEProm_28:
; }
; remainingbytes = indiwritenumber - count;
       move.l    D5,D0
       sub.l     D6,D0
       move.l    D0,A4
; printf("\r\nIndiwritenumber: %d", indiwritenumber);
       move.l    D5,-(A7)
       pea       @lab3_p~1_12.L
       jsr       (A2)
       addq.w    #8,A7
; printf("\r\nCount: %d", count);
       move.l    D6,-(A7)
       pea       @lab3_p~1_13.L
       jsr       (A2)
       addq.w    #8,A7
; printf("\r\nRemaining bytes: %d", remainingbytes);
       move.l    A4,-(A7)
       pea       @lab3_p~1_14.L
       jsr       (A2)
       addq.w    #8,A7
; printf("\r\nLower address: %x",lower_start_addr);
       move.l    D2,-(A7)
       pea       @lab3_p~1_15.L
       jsr       (A2)
       addq.w    #8,A7
; if (count>=indiwritenumber){
       cmp.l     D5,D6
       blt.s     Write128kEEProm_29
; printf("\r\nFill rest of the write in the page");
       pea       @lab3_p~1_16.L
       jsr       (A2)
       addq.w    #4,A7
; WriteByteEEProm(0xA0, upper_start_addr, lower_start_addr,indiwritenumber, block_to_write);
       move.l    D3,-(A7)
       move.l    D5,-(A7)
       move.l    D2,-(A7)
       move.l    D4,-(A7)
       pea       160
       jsr       (A3)
       add.w     #20,A7
       bra.s     Write128kEEProm_30
Write128kEEProm_29:
; }
; else{
; printf("\r\nFill rest of the write in the page and the rest in the remaining in next page");
       pea       @lab3_p~1_17.L
       jsr       (A2)
       addq.w    #4,A7
; WriteByteEEProm(0xF2, upper_start_addr, lower_start_addr,count, block_to_write);
       move.l    D3,-(A7)
       move.l    D6,-(A7)
       move.l    D2,-(A7)
       move.l    D4,-(A7)
       pea       242
       jsr       (A3)
       add.w     #20,A7
Write128kEEProm_30:
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3/A4/A5
       unlk      A6
       rts
; }
; }
; //FYI: For individual writes, check if we need a new page/or new block
; }
; //Read block of up to 128k Bytes starting at Any address
; void Read128kEEProm(int upper_start_addr, int lower_start_addr, int block_to_read, int read_num){
       xdef      _Read128kEEProm
_Read128kEEProm:
       link      A6,#-8
       movem.l   D2/D3/D4/D5/D6/A2/A3,-(A7)
       move.l    16(A6),D2
       move.l    20(A6),D4
       move.l    12(A6),D5
       move.l    8(A6),D6
       lea       _ReadByteEEProm.L,A2
       lea       _printf.L,A3
; //ReadByteEEProm(upper_start_addr, lower_start_addr, read_num, block_to_read);
; int iterations, new_start, new_stop;
; new_start = 0xFF-upper_start_addr;
       move.w    #255,D0
       ext.l     D0
       sub.l     D6,D0
       move.l    D0,-8(A6)
; new_stop = 0xFF-lower_start_addr;
       move.w    #255,D0
       ext.l     D0
       sub.l     D5,D0
       move.l    D0,-4(A6)
; iterations = new_start*16*16+new_stop+1;
       move.l    -8(A6),-(A7)
       pea       16
       jsr       LMUL
       move.l    (A7),D0
       addq.w    #8,A7
       move.l    D0,-(A7)
       pea       16
       jsr       LMUL
       move.l    (A7),D0
       addq.w    #8,A7
       add.l     -4(A6),D0
       addq.l    #1,D0
       move.l    D0,D3
; printf("\r\nInitial Iterations: %d", iterations);
       move.l    D3,-(A7)
       pea       @lab3_p~1_18.L
       jsr       (A3)
       addq.w    #8,A7
; printf("\r\nInitial ReadNum: %d", read_num);
       move.l    D4,-(A7)
       pea       @lab3_p~1_19.L
       jsr       (A3)
       addq.w    #8,A7
; if (read_num<=iterations){
       cmp.l     D3,D4
       bgt.s     Read128kEEProm_1
; ReadByteEEProm(upper_start_addr, lower_start_addr, read_num, block_to_read);
       move.l    D2,-(A7)
       move.l    D4,-(A7)
       move.l    D5,-(A7)
       move.l    D6,-(A7)
       jsr       (A2)
       add.w     #16,A7
       bra       Read128kEEProm_6
Read128kEEProm_1:
; }
; else{
; read_num = read_num - iterations;
       sub.l     D3,D4
; ReadByteEEProm(upper_start_addr, lower_start_addr, iterations, block_to_read);
       move.l    D2,-(A7)
       move.l    D3,-(A7)
       move.l    D5,-(A7)
       move.l    D6,-(A7)
       jsr       (A2)
       add.w     #16,A7
; if (block_to_read ==0){
       tst.l     D2
       bne.s     Read128kEEProm_3
; block_to_read = 1;
       moveq     #1,D2
       bra.s     Read128kEEProm_4
Read128kEEProm_3:
; }
; else{
; block_to_read = 0;
       clr.l     D2
Read128kEEProm_4:
; }
; upper_start_addr = 0x00;
       clr.l     D6
; lower_start_addr = 0x00;
       clr.l     D5
; printf("\r\nBLOCK SWITCH: block is now %d",block_to_read);
       move.l    D2,-(A7)
       pea       @lab3_p~1_20.L
       jsr       (A3)
       addq.w    #8,A7
; iterations = 0xFF*16*16+0xFF + 1;
       move.l    #65536,D3
; if(read_num<=iterations){
       cmp.l     D3,D4
       bgt.s     Read128kEEProm_5
; ReadByteEEProm(upper_start_addr, lower_start_addr, read_num, block_to_read);
       move.l    D2,-(A7)
       move.l    D4,-(A7)
       move.l    D5,-(A7)
       move.l    D6,-(A7)
       jsr       (A2)
       add.w     #16,A7
       bra       Read128kEEProm_6
Read128kEEProm_5:
; }
; else{
; read_num = read_num - iterations;
       sub.l     D3,D4
; ReadByteEEProm(upper_start_addr, lower_start_addr, iterations, block_to_read);
       move.l    D2,-(A7)
       move.l    D3,-(A7)
       move.l    D5,-(A7)
       move.l    D6,-(A7)
       jsr       (A2)
       add.w     #16,A7
; if (block_to_read ==0){
       tst.l     D2
       bne.s     Read128kEEProm_7
; block_to_read = 1;
       moveq     #1,D2
       bra.s     Read128kEEProm_8
Read128kEEProm_7:
; }
; else{
; block_to_read = 0;
       clr.l     D2
Read128kEEProm_8:
; }
; upper_start_addr = 0x00;
       clr.l     D6
; lower_start_addr = 0x00;
       clr.l     D5
; printf("\r\nBLOCK SWITCH: block is now %d",block_to_read);
       move.l    D2,-(A7)
       pea       @lab3_p~1_20.L
       jsr       (A3)
       addq.w    #8,A7
; ReadByteEEProm(upper_start_addr, lower_start_addr, read_num, block_to_read);
       move.l    D2,-(A7)
       move.l    D4,-(A7)
       move.l    D5,-(A7)
       move.l    D6,-(A7)
       jsr       (A2)
       add.w     #16,A7
Read128kEEProm_6:
       movem.l   (A7)+,D2/D3/D4/D5/D6/A2/A3
       unlk      A6
       rts
; }
; }
; }
; void DAC_function(void){
       xdef      _DAC_function
_DAC_function:
       movem.l   D2/A2/A3,-(A7)
       lea       _WaitForACK.L,A2
       lea       _WaitForIICTransmitComplete.L,A3
; int temp = 0x00;
       clr.l     D2
; //printf("\r\nSENDING SLAVE ADDR");
; TXR_RXR = 0x92; //10010010
       move.b    #146,4227078
; CR_SR = 0x91;
       move.b    #145,4227080
; WaitForIICTransmitComplete();
       jsr       (A3)
; WaitForACK();
       jsr       (A2)
; //printf("\r\nSENDING CONTROL BYTE");
; TXR_RXR = 0x44; //01000100
       move.b    #68,4227078
; CR_SR = 0x11;
       move.b    #17,4227080
; WaitForIICTransmitComplete();
       jsr       (A3)
; WaitForACK();
       jsr       (A2)
; //int temp = 0x00;
; //printf("\r\nTURNING ON LED");
; while(1){
DAC_function_1:
; //printf("\r\nTEMP: %x", temp);
; TXR_RXR = temp;
       move.b    D2,4227078
; CR_SR = 0x11;
       move.b    #17,4227080
; WaitForIICTransmitComplete();
       jsr       (A3)
; WaitForACK();
       jsr       (A2)
; temp++;
       addq.l    #1,D2
; DELAY();
       jsr       _DELAY
       bra       DAC_function_1
; }
; }
; void ADC_function(void){
       xdef      _ADC_function
_ADC_function:
       movem.l   D2/D3/A2/A3,-(A7)
       lea       _WaitForIICTransmitComplete.L,A2
       lea       _printf.L,A3
; int c;
; int count = 0;
       clr.l     D3
; TXR_RXR = 0x93; //10010011
       move.b    #147,4227078
; CR_SR =  0x91;//10010001: Bit 7 START, BIT 5 Write to Slave, BIT 0 Clear Interrupts
       move.b    #145,4227080
; WaitForIICTransmitComplete();
       jsr       (A2)
; WaitForACK();
       jsr       _WaitForACK
; while(count<3){
ADC_function_1:
       cmp.l     #3,D3
       bge       ADC_function_3
; CR_SR = 0x21;
       move.b    #33,4227080
; WaitForIICTransmitComplete();
       jsr       (A2)
; CheckDataReceived();
       jsr       _CheckDataReceived
; c = TXR_RXR;
       move.b    4227078,D0
       and.l     #255,D0
       move.l    D0,D2
; if (count%3==0)
       move.l    D3,-(A7)
       pea       3
       jsr       LDIV
       move.l    4(A7),D0
       addq.w    #8,A7
       tst.l     D0
       bne.s     ADC_function_4
       bra       ADC_function_7
ADC_function_4:
; ;//printf("\r\nValue of EXTERNAL:%x",c);
; else if(count%3==1)
       move.l    D3,-(A7)
       pea       3
       jsr       LDIV
       move.l    4(A7),D0
       addq.w    #8,A7
       cmp.l     #1,D0
       bne.s     ADC_function_6
; printf("\r\nValue of PHOTORESISTOR:%x",c);
       move.l    D2,-(A7)
       pea       @lab3_p~1_21.L
       jsr       (A3)
       addq.w    #8,A7
       bra.s     ADC_function_7
ADC_function_6:
; else
; printf("\r\nValue of THERMISTOR:%x",c);
       move.l    D2,-(A7)
       pea       @lab3_p~1_22.L
       jsr       (A3)
       addq.w    #8,A7
ADC_function_7:
; count++;
       addq.l    #1,D3
       bra       ADC_function_1
ADC_function_3:
; }
; CR_SR =  0x29;//READ, NACK, IACK
       move.b    #41,4227080
; WaitForIICTransmitComplete();
       jsr       (A2)
; CheckDataReceived();
       jsr       _CheckDataReceived
; c = TXR_RXR;
       move.b    4227078,D0
       and.l     #255,D0
       move.l    D0,D2
; printf("\r\nValue of POTENTIOMETER:%x",c);
       move.l    D2,-(A7)
       pea       @lab3_p~1_23.L
       jsr       (A3)
       addq.w    #8,A7
; CR_SR =  0x41;
       move.b    #65,4227080
; WaitForIICTransmitComplete();
       jsr       (A2)
       movem.l   (A7)+,D2/D3/A2/A3
       rts
; }
; void main(void){
       xdef      _main
_main:
       link      A6,#-8
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3/A4/A5,-(A7)
       lea       _printf.L,A2
       lea       _Get2HexDigits.L,A3
       lea       __getch.L,A4
; int *testarr;
; int val;
; IIC_Init();
       jsr       _IIC_Init
; //DAC_function();
; //ADC_function();
; //Write byte to EEPROM
; //Write128kEEProm(0xFF, 0x81, 0, 256);
; //printf("\r\n********NEW ADDRESSES*********");
; //printf("\r\nLower addr: %x , Upper Address: %x",testarr[0], testarr[1]);
; //Read byte from EEPROM
; //printf("\r\nFIRST READ USING 128K READ");
; //Read128kEEProm(0xFF, 0x80, 0, 256);
; //PageReadEEProm(0xFF, 0x80, 0);
; printf("\r\n*************************************");
       pea       @lab3_p~1_24.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\nWelcome to EEPROM and ADC/DAC Testing");
       pea       @lab3_p~1_25.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\n*************************************");
       pea       @lab3_p~1_24.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\n");
       pea       @lab3_p~1_26.L
       jsr       (A2)
       addq.w    #4,A7
; while(1){
main_1:
; int command_selection;
; int byte_to_write, bytes_to_read, upper_addr, lower_addr, block_num, bytes_to_write;
; printf("\r\nInput 1 For Write Byte");
       pea       @lab3_p~1_27.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\nInput 2 For Read Byte");
       pea       @lab3_p~1_28.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\nInput 3 For Write (up to) 128K bytes");
       pea       @lab3_p~1_29.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\nInput 4 For Read (up to) 128K bytes");
       pea       @lab3_p~1_30.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\nInput 5 For LED (DAC Function)");
       pea       @lab3_p~1_31.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\nInput 6 For All Sensor Readings (ADC Function)");
       pea       @lab3_p~1_32.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\nENTER SELECTION: ");
       pea       @lab3_p~1_33.L
       jsr       (A2)
       addq.w    #4,A7
; command_selection = _getch();
       jsr       (A4)
       move.l    D0,D5
; if (command_selection == '1'){
       cmp.l     #49,D5
       bne       main_4
; printf("\r\nYou have selected Write Byte");
       pea       @lab3_p~1_34.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\nEnter byte to write: ");
       pea       @lab3_p~1_35.L
       jsr       (A2)
       addq.w    #4,A7
; byte_to_write = Get2HexDigits(0);
       clr.l     -(A7)
       jsr       (A3)
       addq.w    #4,A7
       move.l    D0,A5
; printf("\r\nEnter upper address: ");
       pea       @lab3_p~1_36.L
       jsr       (A2)
       addq.w    #4,A7
; upper_addr = Get2HexDigits(0);
       clr.l     -(A7)
       jsr       (A3)
       addq.w    #4,A7
       move.l    D0,D4
; printf("\r\nEnter lower address: ");
       pea       @lab3_p~1_37.L
       jsr       (A2)
       addq.w    #4,A7
; lower_addr = Get2HexDigits(0);
       clr.l     -(A7)
       jsr       (A3)
       addq.w    #4,A7
       move.l    D0,D3
; printf("\r\nEnter block number (0 or 1): ");
       pea       @lab3_p~1_38.L
       jsr       (A2)
       addq.w    #4,A7
; block_num = _getch();
       jsr       (A4)
       move.l    D0,D2
; printf("\r\nWriting byte %x to upper addr %x, lower addr %x, block number %d....", byte_to_write, upper_addr, lower_addr,block_num-'0');
       move.l    D2,D1
       sub.l     #48,D1
       move.l    D1,-(A7)
       move.l    D3,-(A7)
       move.l    D4,-(A7)
       move.l    A5,-(A7)
       pea       @lab3_p~1_39.L
       jsr       (A2)
       add.w     #20,A7
; WriteByteEEProm(byte_to_write, upper_addr, lower_addr, 1, block_num-'0');
       move.l    D2,D1
       sub.l     #48,D1
       move.l    D1,-(A7)
       pea       1
       move.l    D3,-(A7)
       move.l    D4,-(A7)
       move.l    A5,-(A7)
       jsr       _WriteByteEEProm
       add.w     #20,A7
; printf("\r\nByte write completed");
       pea       @lab3_p~1_40.L
       jsr       (A2)
       addq.w    #4,A7
       bra       main_13
main_4:
; }
; else if (command_selection == '2'){
       cmp.l     #50,D5
       bne       main_6
; printf("\r\nYou have selected Read Byte");
       pea       @lab3_p~1_41.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\nEnter upper address: ");
       pea       @lab3_p~1_36.L
       jsr       (A2)
       addq.w    #4,A7
; upper_addr = Get2HexDigits(0);
       clr.l     -(A7)
       jsr       (A3)
       addq.w    #4,A7
       move.l    D0,D4
; printf("\r\nEnter lower address: ");
       pea       @lab3_p~1_37.L
       jsr       (A2)
       addq.w    #4,A7
; lower_addr = Get2HexDigits(0);
       clr.l     -(A7)
       jsr       (A3)
       addq.w    #4,A7
       move.l    D0,D3
; printf("\r\nEnter block number (0 or 1): ");
       pea       @lab3_p~1_38.L
       jsr       (A2)
       addq.w    #4,A7
; block_num = _getch();
       jsr       (A4)
       move.l    D0,D2
; printf("\r\nReading byte from upper addr %x, lower addr %x, block number %d....",upper_addr, lower_addr, block_num-'0');
       move.l    D2,D1
       sub.l     #48,D1
       move.l    D1,-(A7)
       move.l    D3,-(A7)
       move.l    D4,-(A7)
       pea       @lab3_p~1_42.L
       jsr       (A2)
       add.w     #16,A7
; ReadByteEEProm(upper_addr, lower_addr, 1, block_num-'0');
       move.l    D2,D1
       sub.l     #48,D1
       move.l    D1,-(A7)
       pea       1
       move.l    D3,-(A7)
       move.l    D4,-(A7)
       jsr       _ReadByteEEProm
       add.w     #16,A7
; printf("\r\nByte read completed");
       pea       @lab3_p~1_43.L
       jsr       (A2)
       addq.w    #4,A7
       bra       main_13
main_6:
; }
; else if (command_selection == '3'){
       cmp.l     #51,D5
       bne       main_8
; printf("\r\nYou have selected Write 128k Byte");
       pea       @lab3_p~1_44.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\nEnter bytes to write: ");
       pea       @lab3_p~1_45.L
       jsr       (A2)
       addq.w    #4,A7
; bytes_to_write = Get6HexDigits(0);
       clr.l     -(A7)
       jsr       _Get6HexDigits
       addq.w    #4,A7
       move.l    D0,D7
; printf("\r\nEnter upper address: ");
       pea       @lab3_p~1_36.L
       jsr       (A2)
       addq.w    #4,A7
; upper_addr = Get2HexDigits(0);
       clr.l     -(A7)
       jsr       (A3)
       addq.w    #4,A7
       move.l    D0,D4
; printf("\r\nEnter lower address: ");
       pea       @lab3_p~1_37.L
       jsr       (A2)
       addq.w    #4,A7
; lower_addr = Get2HexDigits(0);
       clr.l     -(A7)
       jsr       (A3)
       addq.w    #4,A7
       move.l    D0,D3
; printf("\r\nEnter block number (0 or 1): ");
       pea       @lab3_p~1_38.L
       jsr       (A2)
       addq.w    #4,A7
; block_num = _getch();
       jsr       (A4)
       move.l    D0,D2
; printf("\r\nWriting %d bytes to upper addr %x, lower addr %x, block number %d....", bytes_to_write, upper_addr, lower_addr,block_num-'0');
       move.l    D2,D1
       sub.l     #48,D1
       move.l    D1,-(A7)
       move.l    D3,-(A7)
       move.l    D4,-(A7)
       move.l    D7,-(A7)
       pea       @lab3_p~1_46.L
       jsr       (A2)
       add.w     #20,A7
; Write128kEEProm(upper_addr, lower_addr, block_num-'0',bytes_to_write);
       move.l    D7,-(A7)
       move.l    D2,D1
       sub.l     #48,D1
       move.l    D1,-(A7)
       move.l    D3,-(A7)
       move.l    D4,-(A7)
       jsr       _Write128kEEProm
       add.w     #16,A7
; printf("\r\n(Up to) 128k Byte write completed");
       pea       @lab3_p~1_47.L
       jsr       (A2)
       addq.w    #4,A7
       bra       main_13
main_8:
; }
; else if (command_selection == '4'){
       cmp.l     #52,D5
       bne       main_10
; printf("\r\nYou have selected Read 128k Byte");
       pea       @lab3_p~1_48.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\nEnter bytes to read: ");
       pea       @lab3_p~1_49.L
       jsr       (A2)
       addq.w    #4,A7
; bytes_to_read = Get6HexDigits(0);
       clr.l     -(A7)
       jsr       _Get6HexDigits
       addq.w    #4,A7
       move.l    D0,D6
; printf("\r\nEnter upper address: ");
       pea       @lab3_p~1_36.L
       jsr       (A2)
       addq.w    #4,A7
; upper_addr = Get2HexDigits(0);
       clr.l     -(A7)
       jsr       (A3)
       addq.w    #4,A7
       move.l    D0,D4
; printf("\r\nEnter lower address: ");
       pea       @lab3_p~1_37.L
       jsr       (A2)
       addq.w    #4,A7
; lower_addr = Get2HexDigits(0);
       clr.l     -(A7)
       jsr       (A3)
       addq.w    #4,A7
       move.l    D0,D3
; printf("\r\nEnter block number (0 or 1): ");
       pea       @lab3_p~1_38.L
       jsr       (A2)
       addq.w    #4,A7
; block_num = _getch();
       jsr       (A4)
       move.l    D0,D2
; printf("\r\nReading %d bytes from upper addr %x, lower addr %x, block number %d....", bytes_to_read, upper_addr, lower_addr,block_num-'0');
       move.l    D2,D1
       sub.l     #48,D1
       move.l    D1,-(A7)
       move.l    D3,-(A7)
       move.l    D4,-(A7)
       move.l    D6,-(A7)
       pea       @lab3_p~1_50.L
       jsr       (A2)
       add.w     #20,A7
; Read128kEEProm(upper_addr, lower_addr, block_num-'0',bytes_to_read);
       move.l    D6,-(A7)
       move.l    D2,D1
       sub.l     #48,D1
       move.l    D1,-(A7)
       move.l    D3,-(A7)
       move.l    D4,-(A7)
       jsr       _Read128kEEProm
       add.w     #16,A7
; printf("\r\n(Up to) 128k Byte read completed");
       pea       @lab3_p~1_51.L
       jsr       (A2)
       addq.w    #4,A7
       bra       main_13
main_10:
; }
; else if (command_selection == '5'){
       cmp.l     #53,D5
       bne.s     main_12
; printf("\r\nYou have selected LED (DAC)");
       pea       @lab3_p~1_52.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\nShowing continous streaming data on LED....");
       pea       @lab3_p~1_53.L
       jsr       (A2)
       addq.w    #4,A7
; DAC_function();
       jsr       _DAC_function
       bra.s     main_13
main_12:
; }
; else{
; printf("\r\nYou have selected Sensor Reads (ADC Function)");
       pea       @lab3_p~1_54.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\nShowing readings from 3 sensors....");
       pea       @lab3_p~1_55.L
       jsr       (A2)
       addq.w    #4,A7
; ADC_function();
       jsr       _ADC_function
main_13:
; }
; printf("\r\n***********************************************");
       pea       @lab3_p~1_56.L
       jsr       (A2)
       addq.w    #4,A7
       bra       main_1
; }
; }
       section   const
@lab3_p~1_1:
       dc.b      13,10,84,104,101,32,100,97,116,97,32,98,121
       dc.b      116,101,32,114,101,97,100,32,105,115,32,37,120
       dc.b      0
@lab3_p~1_2:
       dc.b      13,10,76,111,119,101,114,32,97,100,100,114,101
       dc.b      115,115,32,99,111,117,110,116,58,32,37,100,0
@lab3_p~1_3:
       dc.b      13,10,82,101,109,97,105,110,105,110,103,32,98
       dc.b      121,116,101,115,32,102,111,114,32,76,111,119
       dc.b      101,114,32,97,100,100,114,101,115,115,58,32
       dc.b      37,100,0
@lab3_p~1_4:
       dc.b      13,10,85,112,112,101,114,32,97,100,100,114,101
       dc.b      115,115,32,99,111,117,110,116,58,32,37,100,0
@lab3_p~1_5:
       dc.b      13,10,82,101,109,97,105,110,105,110,103,32,98
       dc.b      121,116,101,115,32,102,111,114,32,85,112,112
       dc.b      101,114,32,97,100,100,114,101,115,115,58,32
       dc.b      37,100,0
@lab3_p~1_6:
       dc.b      13,10,76,111,119,101,114,32,97,100,100,114,101
       dc.b      115,115,32,105,110,105,116,105,97,108,32,112
       dc.b      97,103,101,32,102,105,108,108,58,32,37,100,0
@lab3_p~1_7:
       dc.b      13,10,85,112,112,101,114,32,97,100,100,114,101
       dc.b      115,115,32,105,110,105,116,105,97,108,32,112
       dc.b      97,103,101,32,102,105,108,108,58,32,37,100,0
@lab3_p~1_8:
       dc.b      13,10,80,97,103,101,32,119,114,105,116,101,115
       dc.b      58,32,37,100,0
@lab3_p~1_9:
       dc.b      13,10,73,110,100,105,118,105,100,117,97,108
       dc.b      32,119,114,105,116,101,115,58,32,37,100,0
@lab3_p~1_10:
       dc.b      13,10,70,73,76,76,83,32,85,80,32,82,69,77,65
       dc.b      73,78,68,69,82,32,79,70,32,66,76,79,67,75,32
       dc.b      37,100,44,32,84,72,69,78,32,83,87,73,84,67,72
       dc.b      69,83,32,66,76,79,67,75,0
@lab3_p~1_11:
       dc.b      13,10,70,73,76,76,83,32,85,80,32,66,76,79,67
       dc.b      75,32,37,100,44,32,84,72,69,78,32,83,87,73,84
       dc.b      67,72,69,83,32,66,76,79,67,75,0
@lab3_p~1_12:
       dc.b      13,10,73,110,100,105,119,114,105,116,101,110
       dc.b      117,109,98,101,114,58,32,37,100,0
@lab3_p~1_13:
       dc.b      13,10,67,111,117,110,116,58,32,37,100,0
@lab3_p~1_14:
       dc.b      13,10,82,101,109,97,105,110,105,110,103,32,98
       dc.b      121,116,101,115,58,32,37,100,0
@lab3_p~1_15:
       dc.b      13,10,76,111,119,101,114,32,97,100,100,114,101
       dc.b      115,115,58,32,37,120,0
@lab3_p~1_16:
       dc.b      13,10,70,105,108,108,32,114,101,115,116,32,111
       dc.b      102,32,116,104,101,32,119,114,105,116,101,32
       dc.b      105,110,32,116,104,101,32,112,97,103,101,0
@lab3_p~1_17:
       dc.b      13,10,70,105,108,108,32,114,101,115,116,32,111
       dc.b      102,32,116,104,101,32,119,114,105,116,101,32
       dc.b      105,110,32,116,104,101,32,112,97,103,101,32
       dc.b      97,110,100,32,116,104,101,32,114,101,115,116
       dc.b      32,105,110,32,116,104,101,32,114,101,109,97
       dc.b      105,110,105,110,103,32,105,110,32,110,101,120
       dc.b      116,32,112,97,103,101,0
@lab3_p~1_18:
       dc.b      13,10,73,110,105,116,105,97,108,32,73,116,101
       dc.b      114,97,116,105,111,110,115,58,32,37,100,0
@lab3_p~1_19:
       dc.b      13,10,73,110,105,116,105,97,108,32,82,101,97
       dc.b      100,78,117,109,58,32,37,100,0
@lab3_p~1_20:
       dc.b      13,10,66,76,79,67,75,32,83,87,73,84,67,72,58
       dc.b      32,98,108,111,99,107,32,105,115,32,110,111,119
       dc.b      32,37,100,0
@lab3_p~1_21:
       dc.b      13,10,86,97,108,117,101,32,111,102,32,80,72
       dc.b      79,84,79,82,69,83,73,83,84,79,82,58,37,120,0
@lab3_p~1_22:
       dc.b      13,10,86,97,108,117,101,32,111,102,32,84,72
       dc.b      69,82,77,73,83,84,79,82,58,37,120,0
@lab3_p~1_23:
       dc.b      13,10,86,97,108,117,101,32,111,102,32,80,79
       dc.b      84,69,78,84,73,79,77,69,84,69,82,58,37,120,0
@lab3_p~1_24:
       dc.b      13,10,42,42,42,42,42,42,42,42,42,42,42,42,42
       dc.b      42,42,42,42,42,42,42,42,42,42,42,42,42,42,42
       dc.b      42,42,42,42,42,42,42,42,42,0
@lab3_p~1_25:
       dc.b      13,10,87,101,108,99,111,109,101,32,116,111,32
       dc.b      69,69,80,82,79,77,32,97,110,100,32,65,68,67
       dc.b      47,68,65,67,32,84,101,115,116,105,110,103,0
@lab3_p~1_26:
       dc.b      13,10,0
@lab3_p~1_27:
       dc.b      13,10,73,110,112,117,116,32,49,32,70,111,114
       dc.b      32,87,114,105,116,101,32,66,121,116,101,0
@lab3_p~1_28:
       dc.b      13,10,73,110,112,117,116,32,50,32,70,111,114
       dc.b      32,82,101,97,100,32,66,121,116,101,0
@lab3_p~1_29:
       dc.b      13,10,73,110,112,117,116,32,51,32,70,111,114
       dc.b      32,87,114,105,116,101,32,40,117,112,32,116,111
       dc.b      41,32,49,50,56,75,32,98,121,116,101,115,0
@lab3_p~1_30:
       dc.b      13,10,73,110,112,117,116,32,52,32,70,111,114
       dc.b      32,82,101,97,100,32,40,117,112,32,116,111,41
       dc.b      32,49,50,56,75,32,98,121,116,101,115,0
@lab3_p~1_31:
       dc.b      13,10,73,110,112,117,116,32,53,32,70,111,114
       dc.b      32,76,69,68,32,40,68,65,67,32,70,117,110,99
       dc.b      116,105,111,110,41,0
@lab3_p~1_32:
       dc.b      13,10,73,110,112,117,116,32,54,32,70,111,114
       dc.b      32,65,108,108,32,83,101,110,115,111,114,32,82
       dc.b      101,97,100,105,110,103,115,32,40,65,68,67,32
       dc.b      70,117,110,99,116,105,111,110,41,0
@lab3_p~1_33:
       dc.b      13,10,69,78,84,69,82,32,83,69,76,69,67,84,73
       dc.b      79,78,58,32,0
@lab3_p~1_34:
       dc.b      13,10,89,111,117,32,104,97,118,101,32,115,101
       dc.b      108,101,99,116,101,100,32,87,114,105,116,101
       dc.b      32,66,121,116,101,0
@lab3_p~1_35:
       dc.b      13,10,69,110,116,101,114,32,98,121,116,101,32
       dc.b      116,111,32,119,114,105,116,101,58,32,0
@lab3_p~1_36:
       dc.b      13,10,69,110,116,101,114,32,117,112,112,101
       dc.b      114,32,97,100,100,114,101,115,115,58,32,0
@lab3_p~1_37:
       dc.b      13,10,69,110,116,101,114,32,108,111,119,101
       dc.b      114,32,97,100,100,114,101,115,115,58,32,0
@lab3_p~1_38:
       dc.b      13,10,69,110,116,101,114,32,98,108,111,99,107
       dc.b      32,110,117,109,98,101,114,32,40,48,32,111,114
       dc.b      32,49,41,58,32,0
@lab3_p~1_39:
       dc.b      13,10,87,114,105,116,105,110,103,32,98,121,116
       dc.b      101,32,37,120,32,116,111,32,117,112,112,101
       dc.b      114,32,97,100,100,114,32,37,120,44,32,108,111
       dc.b      119,101,114,32,97,100,100,114,32,37,120,44,32
       dc.b      98,108,111,99,107,32,110,117,109,98,101,114
       dc.b      32,37,100,46,46,46,46,0
@lab3_p~1_40:
       dc.b      13,10,66,121,116,101,32,119,114,105,116,101
       dc.b      32,99,111,109,112,108,101,116,101,100,0
@lab3_p~1_41:
       dc.b      13,10,89,111,117,32,104,97,118,101,32,115,101
       dc.b      108,101,99,116,101,100,32,82,101,97,100,32,66
       dc.b      121,116,101,0
@lab3_p~1_42:
       dc.b      13,10,82,101,97,100,105,110,103,32,98,121,116
       dc.b      101,32,102,114,111,109,32,117,112,112,101,114
       dc.b      32,97,100,100,114,32,37,120,44,32,108,111,119
       dc.b      101,114,32,97,100,100,114,32,37,120,44,32,98
       dc.b      108,111,99,107,32,110,117,109,98,101,114,32
       dc.b      37,100,46,46,46,46,0
@lab3_p~1_43:
       dc.b      13,10,66,121,116,101,32,114,101,97,100,32,99
       dc.b      111,109,112,108,101,116,101,100,0
@lab3_p~1_44:
       dc.b      13,10,89,111,117,32,104,97,118,101,32,115,101
       dc.b      108,101,99,116,101,100,32,87,114,105,116,101
       dc.b      32,49,50,56,107,32,66,121,116,101,0
@lab3_p~1_45:
       dc.b      13,10,69,110,116,101,114,32,98,121,116,101,115
       dc.b      32,116,111,32,119,114,105,116,101,58,32,0
@lab3_p~1_46:
       dc.b      13,10,87,114,105,116,105,110,103,32,37,100,32
       dc.b      98,121,116,101,115,32,116,111,32,117,112,112
       dc.b      101,114,32,97,100,100,114,32,37,120,44,32,108
       dc.b      111,119,101,114,32,97,100,100,114,32,37,120
       dc.b      44,32,98,108,111,99,107,32,110,117,109,98,101
       dc.b      114,32,37,100,46,46,46,46,0
@lab3_p~1_47:
       dc.b      13,10,40,85,112,32,116,111,41,32,49,50,56,107
       dc.b      32,66,121,116,101,32,119,114,105,116,101,32
       dc.b      99,111,109,112,108,101,116,101,100,0
@lab3_p~1_48:
       dc.b      13,10,89,111,117,32,104,97,118,101,32,115,101
       dc.b      108,101,99,116,101,100,32,82,101,97,100,32,49
       dc.b      50,56,107,32,66,121,116,101,0
@lab3_p~1_49:
       dc.b      13,10,69,110,116,101,114,32,98,121,116,101,115
       dc.b      32,116,111,32,114,101,97,100,58,32,0
@lab3_p~1_50:
       dc.b      13,10,82,101,97,100,105,110,103,32,37,100,32
       dc.b      98,121,116,101,115,32,102,114,111,109,32,117
       dc.b      112,112,101,114,32,97,100,100,114,32,37,120
       dc.b      44,32,108,111,119,101,114,32,97,100,100,114
       dc.b      32,37,120,44,32,98,108,111,99,107,32,110,117
       dc.b      109,98,101,114,32,37,100,46,46,46,46,0
@lab3_p~1_51:
       dc.b      13,10,40,85,112,32,116,111,41,32,49,50,56,107
       dc.b      32,66,121,116,101,32,114,101,97,100,32,99,111
       dc.b      109,112,108,101,116,101,100,0
@lab3_p~1_52:
       dc.b      13,10,89,111,117,32,104,97,118,101,32,115,101
       dc.b      108,101,99,116,101,100,32,76,69,68,32,40,68
       dc.b      65,67,41,0
@lab3_p~1_53:
       dc.b      13,10,83,104,111,119,105,110,103,32,99,111,110
       dc.b      116,105,110,111,117,115,32,115,116,114,101,97
       dc.b      109,105,110,103,32,100,97,116,97,32,111,110
       dc.b      32,76,69,68,46,46,46,46,0
@lab3_p~1_54:
       dc.b      13,10,89,111,117,32,104,97,118,101,32,115,101
       dc.b      108,101,99,116,101,100,32,83,101,110,115,111
       dc.b      114,32,82,101,97,100,115,32,40,65,68,67,32,70
       dc.b      117,110,99,116,105,111,110,41,0
@lab3_p~1_55:
       dc.b      13,10,83,104,111,119,105,110,103,32,114,101
       dc.b      97,100,105,110,103,115,32,102,114,111,109,32
       dc.b      51,32,115,101,110,115,111,114,115,46,46,46,46
       dc.b      0
@lab3_p~1_56:
       dc.b      13,10,42,42,42,42,42,42,42,42,42,42,42,42,42
       dc.b      42,42,42,42,42,42,42,42,42,42,42,42,42,42,42
       dc.b      42,42,42,42,42,42,42,42,42,42,42,42,42,42,42
       dc.b      42,42,42,42,0
       section   data
       xdef      _Write_Enable_Command
_Write_Enable_Command:
       dc.l      6
       xdef      _Page_Program_Command
_Page_Program_Command:
       dc.l      2
       xdef      _Erase_Chip_Command
_Erase_Chip_Command:
       dc.l      199
       xdef      _Read_Status_Register_Command
_Read_Status_Register_Command:
       dc.l      5
       xdef      _Read_Flash_Chip_Command
_Read_Flash_Chip_Command:
       dc.l      3
       xdef      _First_Address_Byte
_First_Address_Byte:
       dc.l      0
       xdef      _Test_Data_Byte
_Test_Data_Byte:
       dc.l      9
       xdef      _Dummy_Data_Byte
_Dummy_Data_Byte:
       dc.l      255
       xref      LDIV
       xref      LMUL
       xref      _printf
