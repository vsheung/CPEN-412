#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <stdlib.h>
/*************************************************************
** SPI Controller registers
**************************************************************/
// I2C Registers
#define PRERlo              (*(volatile unsigned char *)(0x00408000))
#define PRERhi              (*(volatile unsigned char *)(0x00408002))
#define CTR                 (*(volatile unsigned char *)(0x00408004))
#define TXR_RXR             (*(volatile unsigned char *)(0x00408006))
#define CR_SR              ( *(volatile unsigned char *)(0x00408008))

#define RS232_Control     *(volatile unsigned char *)(0x00400040)
#define RS232_Status      *(volatile unsigned char *)(0x00400040)
#define RS232_TxData      *(volatile unsigned char *)(0x00400042)
#define RS232_RxData      *(volatile unsigned char *)(0x00400042)
#define RS232_Baud        *(volatile unsigned char *)(0x00400044)

// these two macros enable or disable the flash memory chip enable off SSN_O[7..0]
// in this case we assume there is only 1 device connected to SSN_O[0] so we can
// write hex FE to the SPI_CS to enable it (the enable on the flash chip is active low)
// and write FF to disable it

typedef int bool;
#define false 0
#define true 1

#define   Enable_SPI_CS()             SPI_CS = 0xFE
#define   Disable_SPI_CS()            SPI_CS = 0xFF

// Defining commands

int Write_Enable_Command =  0x06;
int Page_Program_Command =  0x02;
int Erase_Chip_Command   =  0xC7;
int Read_Status_Register_Command = 0x05;
int Read_Flash_Chip_Command = 0x03;
int First_Address_Byte   =  0x00;
int Test_Data_Byte       =  0x09;
int Dummy_Data_Byte      =  0xFF;

/*********************************************************************************************
*Subroutine to initialise the RS232 Port by writing some commands to the internal registers
*********************************************************************************************/
void Init_RS232(void)
{
    RS232_Control = (char)(0x15) ; //  %00010101    divide by 16 clock, set rts low, 8 bits no parity, 1 stop bit transmitter interrupt disabled
    RS232_Baud = (char)(0x1) ;      // program baud rate generator 000 = 230k, 001 = 115k, 010 = 57.6k, 011 = 38.4k, 100 = 19.2, all others = 9600
}

int kbhit(void)
{
    if(((char)(RS232_Status) & (char)(0x01)) == (char)(0x01))    // wait for Rx bit in status register to be '1'
        return 1 ;
    else
        return 0 ;
}

/*********************************************************************************************************
**  Subroutine to provide a low level output function to 6850 ACIA
**  This routine provides the basic functionality to output a single character to the serial Port
**  to allow the board to communicate with HyperTerminal Program
**
**  NOTE you do not call this function directly, instead you call the normal putchar() function
**  which in turn calls _putch() below). Other functions like puts(), printf() call putchar() so will
**  call _putch() also
*********************************************************************************************************/

int _putch( int c)
{
    while(((char)(RS232_Status) & (char)(0x02)) != (char)(0x02))    // wait for Tx bit in status register or 6850 serial comms chip to be '1'
        ;

    (char)(RS232_TxData) = ((char)(c) & (char)(0x7f));                      // write to the data register to output the character (mask off bit 8 to keep it 7 bit ASCII)
    return c ;                                              // putchar() expects the character to be returned
}

/*********************************************************************************************************
**  Subroutine to provide a low level input function to 6850 ACIA
**  This routine provides the basic functionality to input a single character from the serial Port
**  to allow the board to communicate with HyperTerminal Program Keyboard (your PC)
**
**  NOTE you do not call this function directly, instead you call the normal _getch() function
**  which in turn calls _getch() below). Other functions like gets(), scanf() call _getch() so will
**  call _getch() also
*********************************************************************************************************/

int _getch( void )
{
    int c ;
    while(((char)(RS232_Status) & (char)(0x01)) != (char)(0x01))    // wait for Rx bit in 6850 serial comms chip status register to be '1'
        ;

    c = (RS232_RxData & (char)(0x7f));                   // read received character, mask off top bit and return as 7 bit ASCII character

    // shall we echo the character? Echo is set to TRUE at reset, but for speed we don't want to echo when downloading code with the 'L' debugger command
    if(1)
        _putch(c);

    return c ;
}

// flush the input stream for any unread characters

void FlushKeyboard(void)
{
    char c ;

    while(1)    {
        if(((char)(RS232_Status) & (char)(0x01)) == (char)(0x01))    // if Rx bit in status register is '1'
            c = ((char)(RS232_RxData) & (char)(0x7f)) ;
        else
            return ;
     }
}

// converts hex char to 4 bit binary equiv in range 0000-1111 (0-F)
// char assumed to be a valid hex char 0-9, a-f, A-F

char xtod(int c)
{
    if ((char)(c) <= (char)('9'))
        return c - (char)(0x30);    // 0 - 9 = 0x30 - 0x39 so convert to number by sutracting 0x30
    else if((char)(c) > (char)('F'))    // assume lower case
        return c - (char)(0x57);    // a-f = 0x61-66 so needs to be converted to 0x0A - 0x0F so subtract 0x57
    else
        return c - (char)(0x37);    // A-F = 0x41-46 so needs to be converted to 0x0A - 0x0F so subtract 0x37
}

int Get2HexDigits(char *CheckSumPtr)
{
    register int i = (xtod(_getch()) << 4) | (xtod(_getch()));

    if(CheckSumPtr)
        *CheckSumPtr += i ;

    return i ;
}
int Get4HexDigits(char* CheckSumPtr)
{
    return (Get2HexDigits(CheckSumPtr) << 8) | (Get2HexDigits(CheckSumPtr));
}

int Get6HexDigits(char* CheckSumPtr)
{
    return (Get4HexDigits(CheckSumPtr) << 8) | (Get2HexDigits(CheckSumPtr));
}

int Get8HexDigits(char* CheckSumPtr)
{
    return (Get4HexDigits(CheckSumPtr) << 16) | (Get4HexDigits(CheckSumPtr));
}

void DELAY(void){
    int i, j;
    for (i = 0; i<1000; i++){
        for (i = 0; i<10000; i++){
        ;
    }
    }

}
//Initialize and Enable the IIC Controller
void IIC_Init(void){
    PRERlo = 0x31;
    PRERhi = 0x00;
    CTR = 0x80;

}

//Check Status Register TIP bit (bit 1) to see when transmit finished
void WaitForIICTransmitComplete(void){
    //printf("\r\nWaiting For Transmit Complete");
    while(CR_SR & (1<<1)){
        //printf("\r\n%d", CR_SR);
    }
    return;
}

//Wait for acknowledgement from slave
void WaitForACK(void){
    //printf("\r\nWaiting For ACK");
    while(CR_SR&(1<<7)){
        //printf("\r\n%d", CR_SR);
    }
    return;
}

//Polling IIC Status Register to see if data has been read
void CheckDataReceived(void){
    //printf("\r\n%d", CR_SR);
    while(!CR_SR&(1<<0)){
    }
    return;
}
//Read Byte from EEProm
void ReadByteEEProm(int high_addr, int low_addr, int count, int block_num){
    int c;
    DELAY();
    //Write Slave Address, Enable Start Condition
    //printf("\r\nWriting to slave address.....");
    if (block_num == 0) // Block 0 Selected
        TXR_RXR = 0xA4; // Write Slave Address to TX register 10100100
    else //Block 1
        TXR_RXR = 0xAC; // Write Slave Address to TX register 10101100
    CR_SR = 0x91; //10010001: Bit 7 START, BIT 4 Write to Slave, BIT 0 Clear Interrupts
    WaitForIICTransmitComplete(); //Check if transmit is complete
    WaitForACK();

    //Write Two Bytes for Internal Address
    //printf("\r\nWriting high byte internal address.....");
    TXR_RXR = high_addr; // Write High Byte Internal Address to TX register
    CR_SR = 0x11;
    WaitForIICTransmitComplete(); //Check if transmit is complete
    WaitForACK();

    //printf("\r\nWriting low byte internal address.....");
    TXR_RXR = low_addr; // Write Low Byte Internal Address to TX register
    CR_SR =0x11;
    WaitForIICTransmitComplete(); //Check if transmit is complete
    WaitForACK();

    //Write Slave Address Again and Enable Start Condition, but this time its a read
    //printf("\r\nReading data byte.....");
    if (block_num == 0) // Block 0 Selected
        TXR_RXR = 0xA5; // Write Slave Address to TX register 10100101
    else
        TXR_RXR = 0xAD; // Write Slave Address to TX register 10101101
    CR_SR =  0x91;//10010001: Bit 7 START, BIT 5 Write to Slave, BIT 0 Clear Interrupts
    WaitForIICTransmitComplete(); //Check if transmit is complete
    WaitForACK();

    while(count>1){
        CR_SR = 0x21; // 00100001 Read , ACK, IACK
        WaitForIICTransmitComplete(); //Check if transmit is complete
        CheckDataReceived(); //Check if byte is recieved
        c = TXR_RXR; //Read Byte
        printf("\r\nThe data byte read is %x", c);
        count--;
    }

    CR_SR = 0x29; // 00101001 Read , NACK, IACK
    WaitForIICTransmitComplete(); //Check if transmit is complete
    CheckDataReceived(); //Check if byte is recieved
    c = TXR_RXR; //Read Byte
    printf("\r\nThe data byte read is %x", c);
    CR_SR = 0x41;//01000001
    WaitForIICTransmitComplete(); //Check if transmit is complete

    //return c;
}

//Write Byte to EEProm
void WriteByteEEProm(int byte, int upper_addr, int lower_addr, int count, int block_num){
    //Write Slave Address, Enable Start Condition
    //printf("\r\nWriting to slave address.....");
    //printf("\r\nCOUNT: %d",count);
    DELAY();
    if (block_num == 0) // Block 0 Selected
        TXR_RXR = 0xA4; // Write Slave Address to TX register 10100100
    else //Block 1
        TXR_RXR = 0xAC; // Write Slave Address to TX register 10101100
    CR_SR = 0x91;//10010001: Bit 7 START, BIT 4 Write to Slave, BIT 0 Clear Interrupts
    WaitForIICTransmitComplete(); //Check if transmit is complete
    WaitForACK();

    //Write Two Bytes for Internal Address
    //printf("\r\nWriting high byte internal address.....");
    TXR_RXR = upper_addr; // Write High Byte Internal Address to TX register
    CR_SR = 0x11;
    WaitForIICTransmitComplete(); //Check if transmit is complete
    WaitForACK();

    //printf("\r\nWriting low byte internal address.....");
    TXR_RXR = lower_addr; // Write Low Byte Internal Address to TX register
    CR_SR = 0x11;
    WaitForIICTransmitComplete(); //Check if transmit is complete
    WaitForACK();

    //Write Data Byte, Enable Stop Condition
    //printf("\r\nWriting data byte....");

    while (count>0){
        TXR_RXR = byte; // Write Low Byte Internal Address to TX register
        CR_SR = 0x11; //10000001: BIT 6 Stop, BIT 0 IACk
        WaitForIICTransmitComplete(); //Check if transmit is complete
        WaitForACK();
        count--;
        byte++;
    }

    CR_SR = 0x40; //STOP
    WaitForIICTransmitComplete(); //Check if transmit is complete
    //Process Complete
    //printf("\r\nByte written to TX register: %x", byte);
}

//Write 128 bytes starting at any address
int* PageWriteEEProm(int upper_addr, int lower_addr, int block_num){
    int remainingbytes = 0;
    int count = 0; //How much we can fill in the page initially
    int flag = 0;
    int arr[2];
    if (lower_addr>=0x00 && lower_addr<=0x7F){
        count = 0x7F - lower_addr + 1;
        remainingbytes = lower_addr - 0x00;
        printf("\r\nLower address count: %d", count);
        printf("\r\nRemaining bytes for Lower address: %d", remainingbytes);
        //flag = 0;
    }
    else{ // Implies that lower_addr is in range 0x80-0xFF
        count = 0xFF - lower_addr + 1;
        remainingbytes = lower_addr - 0x80;
        flag = 1;
        printf("\r\nUpper address count: %d", count);
        printf("\r\nRemaining bytes for Upper address: %d", remainingbytes);
    }
    WriteByteEEProm(0x00, upper_addr, lower_addr, count, block_num);
    if (flag == 1){
        lower_addr = 0x00;
        upper_addr++;
        if (remainingbytes >0){
            //printf("\r\nShould be upper, remaining bytes is %x", remainingbytes);
            WriteByteEEProm(0x00, upper_addr, lower_addr, remainingbytes, block_num);
        }
    }
    else{
        lower_addr = 0x80;
        if (remainingbytes >0){
            //printf("\r\nShould be lower, remaining bytes is %x", remainingbytes);
            WriteByteEEProm(0x00, upper_addr, lower_addr, remainingbytes, block_num);
        }
    }
    lower_addr = lower_addr + remainingbytes;
    arr[0] = lower_addr;
    arr[1] = upper_addr;
    return arr;
}

//Read a page

void PageReadEEProm(int upper_addr, int lower_addr, int block_num){
    //int count = 0; //How much we can fill in the page initially
    /*
    if (lower_addr>=0x00 && lower_addr<=0x7F){
        count = 0x7F - lower_addr + 1;
    }
    else{ // Implies that lower_addr is in range 0x7F-0xFF
        count = 0xFF - lower_addr + 1;
    }*/
    ReadByteEEProm(upper_addr, lower_addr, 128, block_num);
}

//Write block of up to 128k Bytes starting at any address
void Write128kEEProm(int upper_start_addr, int lower_start_addr, int block_to_write, int write_num){
    int pagewritenumber;
    int indiwritenumber;
    int initialPageFill;
    int i;
    int count;
    int remainingbytes;
    int *temp;
    int flag = 0;

    if (lower_start_addr>=0x00 && lower_start_addr<=0x7F){
        initialPageFill = 0x7F - lower_start_addr + 1;
        printf("\r\nLower address initial page fill: %d", initialPageFill);
    }
    else{ // Implies that lower_addr is in range 0x80-0xFF
        initialPageFill = 0xFF - lower_start_addr + 1;
        printf("\r\nUpper address initial page fill: %d", initialPageFill);
        flag = 1;
    }

    if(initialPageFill >= write_num) {
        pagewritenumber = 0;
        indiwritenumber = 0;
        WriteByteEEProm(0x00, upper_start_addr, lower_start_addr, write_num, block_to_write);
    } else {
        pagewritenumber = (write_num-initialPageFill)/128;
        indiwritenumber = (write_num-initialPageFill)%128;
        WriteByteEEProm(0x00, upper_start_addr, lower_start_addr, initialPageFill, block_to_write);
    }

    printf("\r\nPage writes: %d", pagewritenumber);
    printf("\r\nIndividual writes: %d", indiwritenumber);
    if (pagewritenumber >0 || indiwritenumber>0){
        if (flag == 1){
            if(upper_start_addr == 0xFF && lower_start_addr>= 0x80){
                if (block_to_write ==0){
                    block_to_write = 1;
                }
                else{
                    block_to_write = 0;
                }
                upper_start_addr = 0x00;
            }
            else{
                upper_start_addr++;
            }
            lower_start_addr = 0x00;
        }
        else{
            lower_start_addr = 0x80;
        }
    }

    for (i = 0; i <pagewritenumber; i++){
        if (upper_start_addr == 0xFF && lower_start_addr > 0x80){
            //Calculate how much to put in this block and the new block
            printf("\r\nFILLS UP REMAINDER OF BLOCK %d, THEN SWITCHES BLOCK", block_to_write);
            count = 0xFF - lower_start_addr + 1;
            remainingbytes = lower_start_addr - 0x80;
            WriteByteEEProm(0x80, upper_start_addr, lower_start_addr, count, block_to_write);
            if (block_to_write ==0){
                block_to_write = 1;
            }
            else{
                block_to_write = 0;
            }
            upper_start_addr = 0x00;
            lower_start_addr = 0x00;
            WriteByteEEProm(0x25, upper_start_addr, lower_start_addr, remainingbytes, block_to_write);
            lower_start_addr = lower_start_addr + remainingbytes;
        }
        else if (upper_start_addr == 0xFF && lower_start_addr == 0x80){
            printf("\r\nFILLS UP BLOCK %d, THEN SWITCHES BLOCK", block_to_write);
            PageWriteEEProm(upper_start_addr,lower_start_addr,block_to_write);
            upper_start_addr = 0x00;
            lower_start_addr = 0x00;
            if (block_to_write ==0){
                block_to_write = 1;
            }
            else{
                block_to_write = 0;
            }
        }
        temp = PageWriteEEProm(upper_start_addr,lower_start_addr,block_to_write);
        upper_start_addr = temp[1];
        lower_start_addr = temp[0];
    }

    if (indiwritenumber>0){
        if (lower_start_addr>=0x00 && lower_start_addr<=0x7F){
            count = 0x7F - lower_start_addr + 1;
        }
        else{ // Implies that lower_addr is in range 0x80-0xFF
            count = 0xFF - lower_start_addr + 1;
            flag = 1;
        }
        remainingbytes = indiwritenumber - count;
        printf("\r\nIndiwritenumber: %d", indiwritenumber);
        printf("\r\nCount: %d", count);
        printf("\r\nRemaining bytes: %d", remainingbytes);
        printf("\r\nLower address: %x",lower_start_addr);

        if (count>=indiwritenumber){
            printf("\r\nFill rest of the write in the page");
            WriteByteEEProm(0xA0, upper_start_addr, lower_start_addr,indiwritenumber, block_to_write);
        }
        else{
            printf("\r\nFill rest of the write in the page and the rest in the remaining in next page");
            WriteByteEEProm(0xF2, upper_start_addr, lower_start_addr,count, block_to_write);z
        }
    }


}
//Read block of up to 128k Bytes starting at Any address
void Read128kEEProm(int upper_start_addr, int lower_start_addr, int block_to_read, int read_num){

    //ReadByteEEProm(upper_start_addr, lower_start_addr, read_num, block_to_read);

    int iterations, new_start, new_stop;
    new_start = 0xFF-upper_start_addr;
    new_stop = 0xFF-lower_start_addr;
    iterations = new_start*16*16+new_stop+1;
    printf("\r\nInitial Iterations: %d", iterations);
    printf("\r\nInitial ReadNum: %d", read_num);
    if (read_num<=iterations){
        ReadByteEEProm(upper_start_addr, lower_start_addr, read_num, block_to_read);
    }
    else{
        read_num = read_num - iterations;
        ReadByteEEProm(upper_start_addr, lower_start_addr, iterations, block_to_read);
        if (block_to_read ==0){
            block_to_read = 1;
        }
        else{
            block_to_read = 0;
        }
        upper_start_addr = 0x00;
        lower_start_addr = 0x00;
        printf("\r\nBLOCK SWITCH: block is now %d",block_to_read);
        iterations = 0xFF*16*16+0xFF + 1;
        if(read_num<=iterations){
             ReadByteEEProm(upper_start_addr, lower_start_addr, read_num, block_to_read);
        }
        else{
            read_num = read_num - iterations;
            ReadByteEEProm(upper_start_addr, lower_start_addr, iterations, block_to_read);
            if (block_to_read ==0){
                block_to_read = 1;
            }
            else{
                block_to_read = 0;
            }
            upper_start_addr = 0x00;
            lower_start_addr = 0x00;
            printf("\r\nBLOCK SWITCH: block is now %d",block_to_read);
            ReadByteEEProm(upper_start_addr, lower_start_addr, read_num, block_to_read);
        }
    }

}

void DAC_function(void){
    int temp = 0x00;
    //printf("\r\nSENDING SLAVE ADDR");
    TXR_RXR = 0x92; //10010010
    CR_SR = 0x91;
    WaitForIICTransmitComplete();
    WaitForACK();

    //printf("\r\nSENDING CONTROL BYTE");
    TXR_RXR = 0x44; //01000100
    CR_SR = 0x11;
    WaitForIICTransmitComplete();
    WaitForACK();

    //int temp = 0x00;
    //printf("\r\nTURNING ON LED");
    while(1){
        //printf("\r\nTEMP: %x", temp);
        TXR_RXR = temp;
        CR_SR = 0x11;
        WaitForIICTransmitComplete();
        WaitForACK();
        temp++;
        DELAY();
    }

}

void ADC_function(void){
    int c;
    int count = 0;
    TXR_RXR = 0x93; //10010011
    CR_SR =  0x91;//10010001: Bit 7 START, BIT 5 Write to Slave, BIT 0 Clear Interrupts
    WaitForIICTransmitComplete();
    WaitForACK();

    while(count<3){
        CR_SR = 0x21;
        WaitForIICTransmitComplete();
        CheckDataReceived();
        c = TXR_RXR;
        if (count%3==0)
            ;//printf("\r\nValue of EXTERNAL:%x",c);
        else if(count%3==1)
            printf("\r\nValue of PHOTORESISTOR:%x",c);
        else
            printf("\r\nValue of THERMISTOR:%x",c);

        count++;
    }

    CR_SR =  0x29;//READ, NACK, IACK
    WaitForIICTransmitComplete();
    CheckDataReceived();
    c = TXR_RXR;
    printf("\r\nValue of POTENTIOMETER:%x",c);
    CR_SR =  0x41;
    WaitForIICTransmitComplete();
}



void main(void){

    int *testarr;

    int val;
    IIC_Init();


    //DAC_function();
    //ADC_function();
    //Write byte to EEPROM
    //Write128kEEProm(0xFF, 0x81, 0, 256);
    //printf("\r\n********NEW ADDRESSES*********");
    //printf("\r\nLower addr: %x , Upper Address: %x",testarr[0], testarr[1]);
    //Read byte from EEPROM
    //printf("\r\nFIRST READ USING 128K READ");
    //Read128kEEProm(0xFF, 0x80, 0, 256);

    //PageReadEEProm(0xFF, 0x80, 0);
    printf("\r\n*************************************");
    printf("\r\nWelcome to EEPROM and ADC/DAC Testing");
    printf("\r\n*************************************");
    printf("\r\n");
    while(1){
        int command_selection;
        int byte_to_write, bytes_to_read, upper_addr, lower_addr, block_num, bytes_to_write;
        printf("\r\nInput 1 For Write Byte");
        printf("\r\nInput 2 For Read Byte");
        printf("\r\nInput 3 For Write (up to) 128K bytes");
        printf("\r\nInput 4 For Read (up to) 128K bytes");
        printf("\r\nInput 5 For LED (DAC Function)");
        printf("\r\nInput 6 For All Sensor Readings (ADC Function)");

        printf("\r\nENTER SELECTION: ");
        command_selection = _getch();

        if (command_selection == '1'){
            printf("\r\nYou have selected Write Byte");
            printf("\r\nEnter byte to write: ");
            byte_to_write = Get2HexDigits(0);
            printf("\r\nEnter upper address: ");
            upper_addr = Get2HexDigits(0);
            printf("\r\nEnter lower address: ");
            lower_addr = Get2HexDigits(0);
            printf("\r\nEnter block number (0 or 1): ");
            block_num = _getch();
            printf("\r\nWriting byte %x to upper addr %x, lower addr %x, block number %d....", byte_to_write, upper_addr, lower_addr,block_num-'0');
            WriteByteEEProm(byte_to_write, upper_addr, lower_addr, 1, block_num-'0');
            printf("\r\nByte write completed");
        }
        else if (command_selection == '2'){
            printf("\r\nYou have selected Read Byte");
            printf("\r\nEnter upper address: ");
            upper_addr = Get2HexDigits(0);
            printf("\r\nEnter lower address: ");
            lower_addr = Get2HexDigits(0);
            printf("\r\nEnter block number (0 or 1): ");
            block_num = _getch();
            printf("\r\nReading byte from upper addr %x, lower addr %x, block number %d....",upper_addr, lower_addr, block_num-'0');
            ReadByteEEProm(upper_addr, lower_addr, 1, block_num-'0');
            printf("\r\nByte read completed");

        }
        else if (command_selection == '3'){
            printf("\r\nYou have selected Write 128k Byte");
            printf("\r\nEnter bytes to write: ");
            bytes_to_write = Get6HexDigits(0);
            printf("\r\nEnter upper address: ");
            upper_addr = Get2HexDigits(0);
            printf("\r\nEnter lower address: ");
            lower_addr = Get2HexDigits(0);
            printf("\r\nEnter block number (0 or 1): ");
            block_num = _getch();
            printf("\r\nWriting %d bytes to upper addr %x, lower addr %x, block number %d....", bytes_to_write, upper_addr, lower_addr,block_num-'0');
            Write128kEEProm(upper_addr, lower_addr, block_num-'0',bytes_to_write);
            printf("\r\n(Up to) 128k Byte write completed");
        }
        else if (command_selection == '4'){
            printf("\r\nYou have selected Read 128k Byte");
            printf("\r\nEnter bytes to read: ");
            bytes_to_read = Get6HexDigits(0);
            printf("\r\nEnter upper address: ");
            upper_addr = Get2HexDigits(0);
            printf("\r\nEnter lower address: ");
            lower_addr = Get2HexDigits(0);
            printf("\r\nEnter block number (0 or 1): ");
            block_num = _getch();
            printf("\r\nReading %d bytes from upper addr %x, lower addr %x, block number %d....", bytes_to_read, upper_addr, lower_addr,block_num-'0');
            Read128kEEProm(upper_addr, lower_addr, block_num-'0',bytes_to_read);
            printf("\r\n(Up to) 128k Byte read completed");

        }
        else if (command_selection == '5'){
            printf("\r\nYou have selected LED (DAC)");
            printf("\r\nShowing continous streaming data on LED....");
            DAC_function();
        }
        else{
            printf("\r\nYou have selected Sensor Reads (ADC Function)");
            printf("\r\nShowing readings from 3 sensors....");
            ADC_function();

        }

        printf("\r\n***********************************************");
    }
}