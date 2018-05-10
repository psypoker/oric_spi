#include <lib.h>
#include "oric_spi.h"

//todo list

// logo ORIC-SPI-LINK
// 
extern void *memset(unsigned int buffer, int c, int count);


unsigned int i;
char *s;

unsigned int address, size, flags, crc;
unsigned int start, length, typ, sum;
extern unsigned int checksum_result;

#define TRUE 1
#define FALSE 0

#define STATUS_NOK 0 
#define STATUS_OK 1
#define STATUS_NOSTATUS 2

#define MODE_TEXT 0
#define MODE_HIRES 1
#define MODE_TAP 2

unsigned char screenmode = 0xff;

void cls_text()
{
	memset(0xbb80 + 40, 16, 27 * 40);
}
void cls_footer()
{
	memset(0xbf68, 16, 3 * 40);
}

void printBanner()
{
	gotoxy(0, 0);
	printf("  ORIC SPI TEENSY LINK SD 2018 DEMO     ");

	poke(0xbb80, 16);

	poke(0xbb81, 6);
	for (i = 2; i < 35; i++)
		poke(0xbb80 + i, peek(0xbb80 + i) | 128);
}
void screenText()
{
	 
	if (screenmode == MODE_TEXT)
	{
		cls_text(); 
		return;
	}

	screenmode = MODE_TEXT;
	text();
	cls_text();

	poke(0x27e, 24);
	doke(0x27c, 24 * 40);

	poke(0x26a, 10);

	init();//????

	load_special_chars();

	//paper(0);
	//	ink(7);
	poke(0x26a, peek(0x26a) | 0x32); // 40 colonnes 1 ligne ???
	poke(0x26a, peek(0x26a) & 0xbf); // 40 colonnes 1 ligne ???

	printBanner();
	//paper(0);
}

void screenHires()
{

	if (screenmode == MODE_HIRES)
	{
		return;
	}

	hires();

	screenmode = MODE_HIRES;

	init(); //????
	//poke(0x26a, peek(0x26a) | 0x32); // 40 colonnes 1 ligne ???
	poke(0x26a, peek(0x26a) & 0xdf); // 40 colonnes 1 ligne ???
	poke(0x26a, peek(0x26a) & 0xbf); //   1 ligne ???
	//paper(4);
}

void readtextresp(int x, int y, int c)
{
	poke(0xbf68 + y * 40, c);
	gotoxy(x+1, y);
	do
	{
		s = recvString(); // 256 max !!!

		printf(s);


	} while (s[0]);


}



void printCrcSum()
{
	if (sum != crc)
	{
		paper(1);
		printf("%c%c%x/%x", 27, 1 + '@', sum, crc);
		waitc(2000);
	}
	else
		printf("%c%c%x/%x", 27, 2 + '@', sum, crc);
	waitc(2000);

}

// 0 0 !!!
void relocate()
{
	unsigned char ope;
	unsigned int add;
	unsigned int a;
	unsigned int c;

	unsigned int delta;

	unsigned int target = 0x400;
	unsigned int source = (unsigned int)readTape;
	delta = source - 0x400;
	printf("relocating routines to $400\r\n");
	printf("delta=%x\n", delta);

	memcpy((void*)0x400, (void*)source, 256);


	for (i = 0; i < 256; i++)
	{
		ope = peek(0x400 + i);

		if (ope == 0x20 || ope == 0x4c) // jsr ou jmp ?
		{
			//	printf("%x %x ", 0x400 + i, ope);
			i++;
			a = peek(target + i);
			a += peek(target + i + 1) << 8;
			//	printf("%x => ", a);
			c = a;
			if (a >= 0x1000 && a <= 0x3000)
			{

				c = a - delta;
				poke(target + i, (c & 255));
				poke(target + i + 1, c >> 8); //4

			}

			//	printf("%x  \n", c);

			i++;


		}



	}



}



void readTapeResponse()
{
	wait_slave_ready();
	select();
	start = readInteger();
	length = readInteger();
	typ = readByte();
	deselect();

	if (typ == 0xc7 || typ == 0x04)
		screenText();
	else
		screenHires();

	printStatus(STATUS_OK);
	gotoxy(1, 27);
	printf("Loading tape %x %x %x", start, length, typ);

	readTapeHelper(); // _readTape relocated @ 0x400

	printCrcSum();

}



void readBinaryImageResponse()
{


	wait_slave_ready();

	select();
	address = readInteger();
	size = readInteger();
	flags = readByte();
	deselect();

	gotoxy(1, 27);
	printf("Loading binary %x %x %x", address, size, 2);


	wait_slave_ready();

	recvimg();

	wait_slave_ready();
	select();
	crc = readInteger();
	deselect();

	sum = checksum();

	printCrcSum();

}

void printat(int y, char *s, char *cmd, char c)
{
	poke(0xbb80 + 40 * y, c);
	gotoxy(1, y);
	printf("%s%s", s, cmd);

}

extern char stringbuff[];

void printStatus(int status)
{
	// status string dans stringbuffer
	// apres appel a readResp()

	switch (status)
	{
	case STATUS_OK:
		printat(26, "<- ", stringbuff, A_FWGREEN); 
		break;
	case STATUS_NOK:
		printat(26, "<- ", stringbuff, A_FWRED); 
		break;
	case STATUS_NOSTATUS:
		printat(26, "<- ", "NO STATUS", A_FWCYAN); 
		break;
	}

}

char *lastcmd;

void sendCmdAndProcResp(char *cmd, unsigned char str, unsigned int delay)
{
	unsigned char cmd_status;

	lastcmd = cmd;

	cls_footer();

	printat(25, "-> ", lastcmd, A_FWRED);

	sendString(cmd);

	cmd_status = readResp(); // ok ou nok ?

	switch (cmd_status)
	{
	case STATUS_NOK:
		printStatus(STATUS_NOK);
		readtextresp(1, 27, A_FWRED);
		break;
	case STATUS_OK:
		if (str == MODE_TEXT)
		{
			screenText();
			printat(25, "-> ", lastcmd, A_FWRED);
			printStatus(STATUS_OK);
			readtextresp(0, 1, A_FWGREEN);
		}
		else if (str == MODE_HIRES)
		{
			screenHires();
			printat(25, "-> ", lastcmd, A_FWRED);
			printStatus(STATUS_OK);
			readBinaryImageResponse();
		}
		else if (str == MODE_TAP)
		{
			printat(25, "-> ", lastcmd, A_FWRED);
			printStatus(STATUS_OK);
			readTapeResponse();
		}
		break;
	case STATUS_NOSTATUS:
		printat(25, "-> ", lastcmd, A_FWRED);
		printStatus(STATUS_NOSTATUS);
		printat(27, "<- ", "no status !", A_FWCYAN);
		break;
	}

	waitc(delay);

}





void main()
{

	init();
 

	deselect();


	relocate();

	screenText();

	while (1)
	{
		
		sendCmdAndProcResp("DIR", MODE_TEXT, 500);

		 
		sendCmdAndProcResp("TEXT", MODE_TEXT, 500);

		 
		sendCmdAndProcResp("SAVE", MODE_HIRES, 500);

		 
		sendCmdAndProcResp("LOAD", MODE_HIRES, 500);
	 
 
		sendCmdAndProcResp("TAPE", MODE_TAP, 500);


	}

}
