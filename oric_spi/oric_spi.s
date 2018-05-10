#define via_portb   $0300
#define via_porta   $030f
#define via_ddrb    $0302
#define via_ddra    $0303
#define via_t1cl    $0304
#define via_t1ch    $0305
#define via_t1ll    $0306
#define via_t1lh    $0307
#define via_t2ll    $0308
#define via_t2ch    $0309
#define via_sr      $030a
#define via_acr     $030b
#define via_pcr     $030c
#define via_ifr     $030d
#define via_ier     $030e
#define via_porta_hs   $0301
  
///////////////// SPI D0-D3 //////////////////////////
 
// port A 


 //SCLK — Serial Clock, Horloge (généré par le maître)
 //MOSI — Master Output, Slave Input (généré par le maître)
 //MISO — Master Input, Slave Output (généré par l'esclave)
 //SS — Slave Select, Actif à l'état bas (généré par le maître)
  
#define WAIT	16
 
//  b3        b2             b1         b0

// oric master, teensy slave
// SS (tx)  | MISO (rx)  | MOSI (tx) | SCLK (tx)

// oric slave, teensy master
// SS (rx)  | MISO (tx)  | MOSI (rx) | SCLK (rx)

// oric is master, teensy is slave SS select LOW, CLOCK HIGH Send data/Recv data,
 
  ///////////////////////////////////////////////////////////
 ////////////// relocated in $ 400 !!!! ////////////////////
///////////////////////////////////////////////////////////

 
.dsb 256-(*&255) 

SAVE_RETSTACK = $78

///////////////////////////////////////////////////////////
/// readTape()  hires image or execut              ///
//////////////////////////////////////////////////////////
SIZE	= $68
TYPE	= $70
CRC		= $72
RUN		= $74
SUM		= $76

_readTape
.(
 

  
// attention ne pas modifier jusqu apres le inc 405
loop
	jsr _read_byte

//      *=$404$405
	sta $ffff,y



	clc
	adc SUM
	sta SUM
	bcc skipsum
	
	inc SUM+1
			
skipsum





	iny
	bne skipy
     
	inc $405  // start +1

	jsr _deselect_waitslave_select

skipy
	dec SIZE
	bne loop
	
	dec SIZE+1
	bne loop  
	
// crc
	jsr _deselect_waitslave_select
	jsr _read_byte
	sta CRC+1
 	jsr _read_byte
	sta CRC
 

	jsr _deselect  // transaction spi ending

	// checksum ...etc...
	 
	lda SUM
  	cmp CRC
	bne exit_crc_nok

	lda SUM+1
 	cmp CRC+1
	bne exit_crc_nok

	lda TYPE
	cmp #$c7
	beq gorun
	cmp #$04
	bne exit

gorun

	jsr _deinit
  

  	ldx SAVE_RETSTACK
	txs

	lda RUN+1
 	pha
	lda RUN
	pha
	
	cli

	rts
   

exit_crc_nok
	lda #16+1
	sta $bb80+25*40
exit
	lda CRC
	sta _crc
	lda CRC+1
	sta _crc+1
	lda SUM
	sta _sum
	lda SUM+1
	sta _sum+1
	rts
 

.)

_deinit
.(
 	lda #%11111111
	sta via_ddra
	lda #%11111110
	sta via_porta
	lda #3
	sta $26a
	//cli
	//rts
 .)
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// extern void wait(#WAIT); 0=256,1=1...255=255
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
_wait 
.(
  	ldy #WAIT
loop
	dey
	bne loop
  	rts
.)
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// extern void select();
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
_select
.(
	lda #%00000000	// SS = 0
	sta via_porta
	beq _wait
.)
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// extern void deselect();
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
_deselect
.(
	lda #%00001000	// SS = 1
	sta via_porta
	bne _wait
.)
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// extern unsigned char readByte();
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//fastest readByte ?
// result -> X
_read_byte
.(
;  MISO<<<<<<<<<<+ 0	       8cyc  4c  8c   4c ...
;  SCK>>>>>>>>>>+| 1   __.___/¯¯¯¯¯\__/¯¯¯¯\_/¯\_/¯\_/¯\_/¯\_/¯\_/¯\_
;  MOSI>>>>>>>>+|| 0   __.__________________________________.__
;  SS>>>>>>>>>+||| 0   \_.__________________________________._/
;             ||||
;														; times					SCK MISO
	ldx #%00000010	// 2 cycles							;0+2	 		2        0   

	stx via_porta	// sck = 1 // 4 cycles				;2+4			6        1
	lda #%11111111	// 2 cycles (security)				;6+2			12       

	lsr via_porta   // sck = 0 miso-->c					;12+6			18       0   C
	stx via_porta	// 00000010 SCK=1					;18+4			22		 1
	rol 			// bit 7 !!!!!!!!!!!				;22+2			24       

	lsr via_porta	// SCK = 0 + read MISO in carry		;24+6			30       0   C
	stx via_porta	// sck = 1							;30+4			34	     1
	rol 			// bit 6							;34+2			36

	lsr via_porta	//6									;40+6			46		 0   C
	stx via_porta	//4									;46+4			50       1
	rol  			//2 cycles// bit 5					;50+2			52

	lsr via_porta 
	stx via_porta
	rol  			// bit 4

	lsr via_porta 
	stx via_porta	
	rol  			// bit 3

	lsr via_porta 
	stx via_porta
	rol  			// bit 2

	lsr via_porta 
	stx via_porta
	rol  			// bit 1

	lsr via_porta 

   	rol				// bit 0
 
    // result dans   a !

	rts
.)
//////////////////////////////////////////////////////////////////////////////////
// synch with slave ... 0x55 when ready , ??? otherwise
//////////////////////////////////////////////////////////////////////////////////
_deselect_waitslave_select
.(
	jsr _deselect

	lda #1
	sta $bb80+25*40+38
	lda #"W"
	sta $bb80+25*40+39
loop 
	jsr _select
	jsr _read_byte	
	tax
	jsr _deselect 
	cpx #$55
	bne loop
	lda #2
	sta $bb80+25*40+38
	lda #"S"
	sta $bb80+25*40+39
	jmp _select
.)

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

 
_end_loader
  

.dsb 256-(*&255)  


  // $8000

 
 ///////////////////////////////////////////////////////////////////////////////////////////////
 // helps saving precious space !!!
 ////////////////////////////////////////////////////////////////////////////////////////////////

_readTapeHelper
 .(
 
 
  

	lda _start
	sta $404
	sta RUN
	lda _start+1
	sta $405
	sta RUN+1

	lda _length
	sta SIZE	// size 0=256=erreur !!!, 1=1,2=2...255=255

	lda _length+1
	sta SIZE+1				// trick for last dec 
    inc SIZE+1
	
	lda _typ
	sta TYPE
		

	ldy #0
	sty SUM
	sty SUM+1

	sec
	lda RUN
	sbc #1
	sta RUN
	lda RUN+1
	sbc #0
	sta RUN+1
	 

	ldx retstack
	stx SAVE_RETSTACK
	
	// deja deselect avant le call !!!
	jsr _deselect_waitslave_select+3

	jmp $400
 .)


  // synch with slave ... 0x55 when ready , 0xff otherwise
_wait_slave_ready
.(
	lda _screenmode
	bne hires_mode

	lda #0 
 	sta $bb80+35
	lda #"W"
	sta $bb80+36
	lda #"A"
	sta $bb80+37
	lda #"I"
	sta $bb80+38
	lda #"T"
	sta $bb80+39

loop
	
	lda $bb80+35
	cmp #7 
	bne skip
	lda #0 
	sta $bb80+35
	beq skip2
skip
	inc $bb80+35
skip2

	jsr _select
	jsr _read_byte
	pha
	jsr _deselect
	pla
	cmp #$55
	bne loop

	lda #2 
 	sta $bb80+35
	lda #"S"
	sta $bb80+36
	lda #"Y"
	sta $bb80+37
	lda #"N"
	sta $bb80+38
	lda #"C"
	sta $bb80+39
	
	 
	rts



hires_mode
	lda #0
 	sta $bfdb-80
	lda #"W"
	sta $bfdc-80
	lda #"A"
	sta $bfdd-80
	lda #"I"
	sta $bfde-80
	lda #"T"
	sta $bfdf-80


looph
	
	lda $bfdb-80
	cmp #7 
	bne skiph
	lda #0 
	sta $bfdb-80
	beq skip2h
skiph
	inc $bfdb-80
skip2h

	jsr _select
	jsr _read_byte
	pha
	jsr _deselect
	pla
	cmp #$55
	bne looph

	lda #2
 	sta $bfdb-80
	lda #"S"
	sta $bfdc-80
	lda #"Y"
	sta $bfdd-80
	lda #"N"
	sta $bfde-80
	lda #"C"
	sta $bfdf-80

	 
	rts
.)

__cli
.(
	cli
	rts
.)

__sei
.(
	sei
	rts
.)
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// extern void char init();
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
_init
.(
	sei

;  MISO----------+ 0
;  SCK----------+| 1 
;  MOSI--------+|| 1
;  SS---------+||| 1
;             |||| 
	lda #%11111110
	sta via_ddra
	rts
//	jmp _deselect
.)



_readResp
.(
  	jsr _recvString
	
	lda _stringbuff
	cmp #"O"
	beq ok1
	cmp #"N"
	beq nok1
unknown
	ldx #2
	lda #0
	rts

ok1
	lda _stringbuff+1
	cmp #"K"
	bne unknown

	ldx #1
	lda #0
	rts

nok1
	lda _stringbuff+1
	cmp #"O"
	bne unknown
	lda _stringbuff+2
	cmp #"K"
	bne unknown
	
	ldx #0
	lda #0
	rts

.)
 
  

_load_special_chars
.(
	ldy #7
loop1
	lda tilde,y
	sta $b400+126*8,y
	dey
	bpl loop1
	ldy #7
loop2
	lda under,y
	sta $b400+"_"*8,y
	dey
	bpl loop2	
	rts
 

tilde
.byt %000000
.byt %000000
.byt %000000
.byt %011001
.byt %100110
.byt %000000
.byt %000000
.byt %000000

under
.byt %000000
.byt %000000
.byt %000000
.byt %000000
.byt %000000
.byt %000000
.byt %000000
.byt %111111


.)






//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// extern unsigned int readInteger();
//
// returns A = MSB (poids fort)
//         X = LSB (poids faible)  ex: $bb80   , msb= $bb, lsb = $80
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
_readInteger
.(
	jsr _read_byte // msb
	pha
	jsr _read_byte // lsb
 	tax  
	pla
	rts
.)
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// extern void writeInteger(unsigned int value)
//
// sends   A = MSB (poids fort)
//         X = LSB (poids faible)  ex: $bb80   , msb= $bb, lsb = $80
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
_writeInteger
.(
	ldy #0		
	lda (sp),y // msb 
	jsr _write_byte
	ldy #1
	lda (sp),y
	jmp _write_byte
.)
 

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// extern unsigned char transactByte(unsigned char b);
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
_transactByte
.(
	ldy #0
	lda (sp),y

.)
_transact_byte		// bit 7 en premier
.(

INPUT = reg5
OUTPUT = reg1

  	sta INPUT
;		       M M
;	           OSI
;	          SSCS
;	          SIKO	
 	
	ldx #8
loop		;--------------------------------------------------------------------
	asl INPUT
	bcc bit0  

bit1		// pulse 1 sclk=1  // 2 cycles (bcc)
;  MISO----------+ 0
;  SCK----------+| 1 
;  MOSI--------+|| 1
;  SS---------+||| 0
;             ||||
	lda #000000110		// 2 cycles
	bne continue		// 3 cycles 

bit0		// pulse 0 sclk=1			// 3 cycles (bcc)
;  MISO----------+ 0
;  SCK----------+| 1 
;  MOSI--------+|| 0
;  SS---------+||| 0
;             ||||
	lda #%00000010

continue
	sta via_porta		// 4 cycles
 				
;  MISO----------<
;  SCK---------->|
;  MOSI-------->||
;  SS--------->|||
;             ||||
	lda #%00000101		// 2 cycles  // keep mosi & miso
	and via_porta		// 4 cycles
	sta via_porta		// 4 cycles  // clk=0

 	lsr					// 2 cycles
 	rol OUTPUT			// 5 cycles
		
	dex					// 2 cycles
	bne loop			// 2* cycles (* +1 if branch)  ;---------------------------
 	
	ldx OUTPUT			// 3 cycles
	lda #0				// 2 cycles

	rts					// 6 cycles
.)

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// extern void writeByte(unsigned char b);
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
_writeByte
.(
	ldy #0
	lda (sp),y
.)
_write_byte
.(
VALUE = reg4
	sta VALUE
	// A = byte to send
	ldx #8
loop
	asl	VALUE			// 2
 
	bcc low			// 3

high
;  MISO----------+ 0
;  SCK----------+| 1 
;  MOSI--------+|| 0
;  SS---------+||| 0
;             |||| 
	lda #%00000110	// 2 
	sta via_porta   // 4  
	
;  MISO----------+ 0
;  SCK----------+| 1 
;  MOSI--------+|| 0
;  SS---------+||| 0
;             |||| 
	lda #%00000100   // 2
	sta via_porta    // 4

	dex
	bne loop
 
	rts
	
low
;  MISO----------+ 0
;  SCK----------+| 1 
;  MOSI--------+|| 0
;  SS---------+||| 0
;             |||| 
	lda #%00000010	
	sta via_porta   // ----0-01		// 4 cycles

;  MISO----------+ 0
;  SCK----------+| 1 
;  MOSI--------+|| 0
;  SS---------+||| 0
;             |||| 
	lda #%00000000
	sta via_porta  // ----0-00	  
	
	dex
	bne loop

	rts
.)



_waitc
.(
	ldy #0
	lda (sp),y
	sta kpt
	iny
	lda (sp),y
	sta kpt+1
	inc kpt+1
loop
	ldx #0
loopx
	dex 
	bne loopx
	
	dec kpt
	bne loop
	dec kpt+1
	bne loop
	rts

kpt
.dsb 2
.)


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// all inline!!!
// extern void recvimg();
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
_recvimg
.(
cpt  = tmp + 2
  
    ////////jsr _select
	lda #%00000000	// SS = 0
	sta via_porta
	
	lda #$00
	sta scr+1
	lda #$a0
	sta scr+2

	// 200 * 40 = 8000 bytes
	lda #200
	sta cpt
	lda #40
	sta cpt+1
  
	ldy #0
  
loop4
	////////////////jsr _readbyte

// res	=	A
 
;		       M M
;	           OSI
;	          SSCS
;	          SIKO	
	
;  MISO----------+ 0
;  SCK----------+| 1 
;  MOSI--------+|| 0
;  SS---------+||| 0
;             |||| 
  	ldx #%00000010

	stx via_porta	// sck = 1

	lda #%11111111
	lsr via_porta   // sck = 0 cc=miso
	stx via_porta	// 00000010 SCK=1
	rol 			// bit 7 !!!!!!!!!!!

	lsr via_porta	// SCK = 0 + read MISO in carry
	stx via_porta	// sck = 1
	rol 			// bit 6

	lsr via_porta	//6
	stx via_porta	//4
	rol  			// bit 5//2 cycles

	lsr via_porta 
	stx via_porta
	rol  			// bit 4

	lsr via_porta 
	stx via_porta	
	rol  			// bit 3

	lsr via_porta 
	stx via_porta
	rol  			// bit 2

	lsr via_porta 
	stx via_porta
	rol  			// bit 1

	lsr via_porta 

   	rol				// bit 0
 
	
// self mod 

scr
	sta $a000,y
	iny
	bne skip

	inc scr+2

skip
	dec cpt 
	bne loop4
	 
	lda #200
	sta cpt

	dec cpt+1
	beq exit

	// deselect ???
	lda #%00001000	// SS = 1
	sta via_porta
	
loop_wait_slave_ready
 	ldx #%00000000	// SS = 0	//jsr _select
	stx via_porta
	jsr _read_byte
	ldx #%00001000	// SS = 1//jsr _deselect
	stx via_porta
    cmp #$55
	bne loop_wait_slave_ready
 	
	ldx #%00000000	// SS = 0//jsr _select
	stx via_porta
		
//	nop			//jsr _wait

	beq loop4  
	 
exit
	rts
.)

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// extern char* recvString();
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//    0 terminated string or max 255 chars (0)
_recvString
.(	 
	jsr _wait_slave_ready
	jsr _select
	 
	ldy #0
loop
	jsr _read_byte
	sta _stringbuff,y

	beq exit
	iny
 	bne loop
 
	sty _stringbuff+255
exit
	jsr _deselect
	
	ldx #<(_stringbuff)
	lda #>(_stringbuff)
		
	rts
.)

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// extern void sendString(char *s);
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
_sendString
.(
	jsr _wait_slave_ready
 	jsr _select

	// tmp = ptr to string , 0 terminated
	ldy #1
	lda (sp),y
	sta tmp+1
	dey
 
	lda (sp),y
	sta tmp 
loop4
 
	lda (tmp),y
	beq EOS_OR_256
 
 	jsr _write_byte

	iny
	 
	bne loop4
	tya
	
EOS_OR_256	
	jsr _write_byte // write 0 !
 
	jmp _deselect
.)
 
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// extern unsigned int checksum();
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
_checksum
.(
	 
	lda #$00
	sta loop+1

	lda #$a0
	sta loop+2

	lda #0
	sta _checksum_result
	sta _checksum_result+1

	lda #200
	sta _compteur
	lda #40
	sta _compteur+1

	ldy #0
loopg
	clc
	lda _checksum_result
loop
	adc $a000,y
	sta _checksum_result 

	bcc skiiop

	inc _checksum_result+1

skiiop

	iny
	bne skip

	inc loop+2
	

skip
	dec _compteur
	bne loopg
	lda #200
	sta _compteur
	dec _compteur+1
	bne loopg

	 
	ldx _checksum_result
	lda _checksum_result+1

 
	rts
.)
 
_readByte // y preservé !
.(
	jsr _read_byte
	tax
	lda #0
	rts
.)



_checksum_result
.dsb 2
_compteur
.dsb 2
_stringbuff
.dsb 256
 
