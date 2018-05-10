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
#define MAXSTRINGBUFF 255  
#define WAIT	16
_stringbuff =  $aa00

//  b3        b2             b1         b0

// oric master, teensy slave
// SS (tx)  | MISO (rx)  | MOSI (tx) | SCLK (tx)

// oric slave, teensy master
// SS (rx)  | MISO (tx)  | MOSI (rx) | SCLK (rx)

// oric is master, teensy is slave SS select LOW, CLOCK HIGH Send data/Recv data,
 
  ///////////////////////////////////////////////////////////
 ////////////// relocated in $ 400 !!!! ////////////////////
///////////////////////////////////////////////////////////
   
_run_spi_load
	jmp osdk_start
////////////////////////////////////////////////////////////
/// readTape()  spi_load.tap (boot image on sd)         ///
//////////////////////////////////////////////////////////
_readTape
.(
 
SIZE	= $72
TYPE	= $74
CRC		= $76
RUN		= $78
SUM		= $80
  
	

loop
	jsr _read_byte

//      *=  _readTape+4 et 5 !!!
	sta $5555,y  // start,y

	clc
	adc SUM
	sta SUM
	bcc skipsum
	
	inc SUM+1
			
skipsum

	ora #$40
	sta $bb80+160,y

	iny
	bne skipy
  
	inc _readTape+5  // start +1
  	
	ldy #0
	
	jsr _wait_slave_ready_lite

skipy
	dec SIZE
	bne loop
	
	dec SIZE+1
	bne loop  
	
// crc
	jsr _wait_slave_ready_lite
	jsr _read_byte
	sta CRC+1
	sta _crc+1
	jsr _read_byte
	sta CRC
	sta _crc

	jsr _deselect  // transaction spi ending

	// checksum ...etc...
	lda SUM+1
	sta _sum+1
	lda SUM
	sta _sum

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
	
  //  jsr $f8b8  // reset via nmi etc...
//	sei
	ldx retstack
	 
	 
	lda RUN
 
	sta $101,x
	lda RUN+1
	 
	sta $102,x

	txs
	cli

	lda #"R"+128
	sta $bb80+39

	rts
	

   

exit_crc_nok
	lda #1
	sta $bb80+38
exit
	rts
.)

_deinit
.(
	
 	lda #%11111111
	sta via_ddra
	lda #%11111110
	sta via_porta
 
	
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

 

// vide le flux 
_readtextresp
.(
	lda #0
	sta _stringbuff
	jsr _recvString
	lda _stringbuff
	bne _readtextresp
	rts
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
// extern unsigned char readByte();
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 
//fastest readByte ?
// result -> A
_read_byte
.(                            // 83333 bauds read byte...
;                         02468024680246802468     
;  MISO<<<<<<<<<<+ 0	        
;  SCK>>>>>>>>>>+| 1     .___/¯¯¯\__/¯¯¯\__/¯¯¯\__..._____ 
;  MOSI>>>>>>>>+|| 0     .________________________...
;  SS>>>>>>>>>+||| 0  ¯¯\.________________________..._/¯¯¯ 
;             ||||
;														; times					SCK MISO
	ldx #%00000010	// 2 cycles							; 2	 		    2        0   

	stx via_porta	// sck = 1 // 4 cycles				; 4				6        1
	lda #%11111111	// 2 cycles (security)				; 2				12       1..

	lsr via_porta   // sck = 0 miso-->c					;6				18       0   C
	stx via_porta	// 00000010 SCK=1					;4				22		 1
	rol 			// bit 7 !!!!!!!!!!!				;2				24       1..

	lsr via_porta	// SCK = 0 + read MISO in carry		;6				30       0   C
	stx via_porta	// sck = 1							;4				34	     1
	rol 			// bit 6							;2				36		 1..

	lsr via_porta	//6									;40+6			46		 0   C
	stx via_porta	//4									;46+4			50       1
	rol  			//2 cycles// bit 5					;50+2			52		 1..

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
_wait_slave_ready_lite
.(
	jsr _deselect
loop
	lda #6
	sta $bb80+38
	lda #"W"+128
	sta $bb80+39
   
    jsr _select
	jsr _read_byte	
	pha
	and #7
	ora #128
	sta $bb80+38
	jsr _deselect 

	pla
	cmp #$55
	bne loop

	lda #5 
	sta $bb80+38
	lda #"S"+128
	sta $bb80+39
	jmp _select
.)

_start
.dsb 2
_length
.dsb 2
_typ
.dsb 1
_crc
.dsb 2
_sum
.dsb 2


 
_end_loader
  

  ////////////////////////////////////////////////////////////////////
 
 // helps saving precious space !!!
_readTapeHelper
 .(
 
SIZE	= $72
TYPE	= $74
CRC		= $76
RUN		= $78
SUM		= $80
  

	lda _start
	sta _readTape+4
	sta RUN

	lda _start+1
	sta _readTape+5
	sta RUN+1

	lda _length
	sta SIZE	// size 0=256=erreur !!!, 1=1,2=2...255=255

	lda _length+1
	sta SIZE+1				// trick for last dec 
    inc SIZE+1
	
	lda _typ
	sta TYPE

	// deja deselect avant le call !!!
	jsr _wait_slave_ready_lite+3
	

	ldy #0
	sty SUM
	sty SUM+1
	
 
	jmp _readTape
 .)


  // synch with slave ... 0x55 when ready , 0xff otherwise
_wait_slave_ready
.(
	lda #0 
 	sta $bb80+35
	sta $bb80+38
	lda #"W"
	sta $bb80+39
	
loop
	lda $bb80+38
	cmp #7 
	bne skip
	lda #0 
	sta $bb80+38
	bne skip2
skip
	inc $bb80+38
skip2
	jsr _select
	jsr _read_byte
	pha
	jsr _deselect
	pla
	cmp #$55
	bne loop

	lda #2 
 	sta $bb80+38
	lda #"S"
	sta $bb80+39
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
	jmp _deselect
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

 


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// extern void writeByte(unsigned char b);
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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
	sta $bb80+80,y
	beq exit
	iny
	cpy #MAXSTRINGBUFF
 	bne loop
	lda #0
	sta _stringbuff,y
exit
	jsr _deselect
	
 
		
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
	sta $bb80,y
	beq EOS_OR_256
 
 	jsr _write_byte

	iny
	 
	bne loop4
	tya
	
EOS_OR_256	
	jsr _write_byte // write 0 !
 
	jmp _deselect
.)
 

 
_readByte // y preservé !
.(
	jsr _read_byte
	tax
	lda #0
	rts
.)

  
_readTapeResponse
.(
	
	jsr _wait_slave_ready 
	jsr _select 
	jsr _readInteger 
	stx _start 
	sta _start+1 
	jsr _readInteger 
	stx _length 
	sta _length+1 
	jsr _readByte 
	stx tmp0 
	sta tmp0+1 
	lda tmp0 
	sta _typ 
	jsr _deselect 
	jmp _readTapeHelper 

.)

//////////////////////////////////////////////////////
//////////////////////////////////////////////////////
 
.zero

	*= $50

ap		.dsb 2		
fp		.dsb 2		
sp		.dsb 2		

tmp0	.dsb 2
tmp1	.dsb 2
tmp2	.dsb 2
tmp3	.dsb 2
tmp4	.dsb 2
tmp5	.dsb 2
tmp6	.dsb 2
tmp7	.dsb 2

op1		.dsb 2
op2		.dsb 2

tmp		.dsb 2

reg0	.dsb 2
reg1	.dsb 2
reg2	.dsb 2
reg3	.dsb 2
reg4	.dsb 2
reg5	.dsb 2
reg6	.dsb 2
reg7	.dsb 2


.text

osdk_start
.(  
	tsx
	lda #<osdk_stack
	sta sp
	lda #>osdk_stack
	sta sp+1

	stx retstack
	jsr _load_special_chars
	jmp _main
.)

retstack	
	.byt 0

 
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

///////////////////////////////////////////////////////
///////////// main ////////////////////////////////////
///////////////////////////////////////////////////////
_main 
.(
 	lda #$0a
	sta $26a

	lda #0
	tay
	sta (sp),y 
	iny 
	sta (sp),y 

	jsr _paper 

	lda #2 
	ldy #0 
	sta (sp),y 
	tya
	iny 
 	sta (sp),y 
 
	jsr _ink 
 
	jsr $ccce // _cls 


loop
 
	jsr _init 
 
	jsr _sendBOOTCommand 

	jmp loop 
.)

////////////////////////////// send "BOOT" command //////////////////////////////////

_boot
.byt "BOOT",0
_sendBOOTCommand
.(
cmd_status = $50
	lda #<(_boot)
	ldy #0
	sta (sp),y
	iny
	lda #>(_boot)
	sta (sp),y
	
	jsr _sendString

	jsr _readResp

	cpx #0 // nok
	bne skip0
	jmp _readtextresp

skip0
	cpx #1  // ok
	bne skip1
	jmp _readTapeResponse

skip1	//no status
	rts
.)

 
 
// OSDK lib 
_paper
.(
		ldx #1         
        jsr getXparm
        jsr $f204      
        jmp grexit     
.)

_ink
.(
		ldx #1         
        jsr getXparm
        jsr $f210      
        jmp grexit     
.)
 
getXparm               
.(
		ldy #0         
        sty $2e0       
        stx tmp        
        ldx #0

getXloop
        lda (sp),y
        sta $2e1,x
        inx    
        iny    
        lda (sp),y
        sta $2e1,x
        inx 
        iny            
        dec tmp        
        bne getXloop
        rts
.)
        
grexit        
.(
		lda $2e0       
grexit2        
		tax
		lda #0
		rts      
.)    

 
 
osdk_stack
.dsb 0
   
