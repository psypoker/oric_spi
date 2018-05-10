#ifdef ORIC_SPI

#else
#define ORIC_SPI 1

// spi primitives 
extern void init();
// begin transaction (wait for slave readyness (mosi==1))
extern void select();
// end transaction
extern void deselect();
// read a byte (no select)
unsigned char readByte(); 
// read an integer (msb first) (no select)
extern unsigned int readInteger();
// writes an integer (msb first ) (no select)
extern void writeInteger(unsigned int value);
// read write a byte (no select)
extern unsigned char transactByte(unsigned char b);
// write a byte (no select)
extern void writeByte(unsigned char b);
// wait (see oric_spi.s)
extern void wait();
// receive a string  (0-ended)(select)
extern char* recvString();
// send a string (0 = terminator send) (select)
extern void sendString(char* s);
extern void readTape();
// 0xa000-0xbf3f
// receive a hires image 
extern void recvimg();
// compute the checksum from data received
extern unsigned int checksum();

/*
 TODO

unsigned int checksum(unsigned int address, unsigned int size)

*/

// SPI ORIC MASTER 
//
//              _____                                  ______
//  D3     SS        \________________________________/
//                     _   _   _   _   _   _   _   _
//  D1   SCLK   ______/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ \________ 
//
//  D2   MOSI   ______[b7][b6][b5][b4][b3][b2][b1][b0]_______
//
//  D0   MISO   ______[b7][b6][b5][b4][b3][b2][b1][b0]_______  SLAVE READY (+ SS=1)
//
//
 
// PROTOCOL ORIC <-------------------------> TEENSY <--------------------------------------------------------------------------> SD ou autre !!!
// 
//  ORIC ATMOS <--------SPI BUS------------> TEENSY
//
//  > "REQUEST",0 ------------------------->
//				  <------------------------- "OK REQUEST ...",0
//				  <------------------------- <request data> (string or binary)
//
// SUPPORTED COMMANDS 
//
//  > "DIR",0    --------------------------->   
//   
//   
//				 <--------------------------- "OK DIR",0
//   
//   
//		         <--------------------------- "directory formatted string (write & writeln)",0
//   
//ERROR //	     <--------------------------- "NOK",0
        //								      "NO SD CARD/ERROR",0
		//  
		//
		//
//  
//  >REQUEST    ---------------------------> "LOAD "NAME"",0  
//  
//  
//	<RESPONSE   <--------------------------- "OK",0
//  <PARAMS     <--------------------------- #ADDRESS,#SIZE,#FLAGS(0 autorun,1 hires,2)
//  <LOAD       <--------------------------- #DATA
//  
//
		//  <ERROR      <------------------- "NOK",0,
		//									 "FILE NOT FOUND/NO DISK/ERROR/UNKNOWN ERROR",0
		//  ss 0
		//   
		//
//  ss 1
//  >REQUEST    ---------------------------> "SAVE "NAME",#ADDRESS,#SIZE,#FLAGS(0 autorun,1 hires,2),#overwrite=1/0
//  ss 0
//  ss 1
//	<RESPONSE   <--------------------------- "OK",0
//  ss 0	
//  ss 1
//  >WRITE      ---------------------------> #DATA
//  ss 0
//
		//  <ERROR      <------------------- "NOK",0,"FILE NOT FOUND/FILE EXISTS/DISK FULL/NO DISK/ERROR/UNKNOWN ERROR",0
		//  ss 0
		//
		//


#endif // ORIC_SPI


