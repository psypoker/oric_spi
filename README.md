# oric_spi
SPI like protocol DEMO interfacing via6522 (Oric Atmos) with teensy 3.2 
using no breadboard, and no soldering, but only 11 dupont cables

Project state : alpha release (no license)

Connections:
                 (5 cables)        (6 cables)
Oric Atmos VIA 6522 <---> teensy 3.2 <---> SD catalex SPI module
D1                      2           SCK(13)       SCK
D2                      3           DOUT(12)      MOSI
D0                      4           DIN(11)       MISO
D3                      5           CS(10)        CS
                        VIN(+5V)    VIN
GND                     GND         GND           GND


-project on Teensy3.2:
"porta_spi3.2.ino"
warning i have to modify a library for correct SPI speed between teensy and catalex ...
test with standard sketch before !

warning don't mess with the analog and digital pins on teensy, only digital pins are 5v tolerant. if you send more than 3.3v
in analog inputs , you are sure to burn the Teensy.

-project on Oric Atmos:
"SPI_LOAD.TAP" : the main boot loader application 
                 (about 840 bytes loader routines, tape duration is about 6 sec)
     
  -> send "BOOT" command to Teensy
  sources: spi_load.s /osdk_config.bat 
  
"ORIC_SPI.TAP" : the Oric Atmos SPI link to Teensy demo ( tape duration about 45 sec, loaded in a couple of seconds with spi boot loader)
  sends commands to teensy3.2 via spi link
  "DIR" shows directory of sd card
  "TAPE" loads a tape in oric memory from sd card
    - supported tapes are hires images or binary executables only (full tape support in todolist)
  "SAVE" loads a saved image in PROGMEM in oric memory
  "LOAD" loads a saved image on SD card in oric memory
  "TEXT" loads a text file on SD card in oric display
  sources: main_oric_spi.c / oric_spi.s / osdk_config.bat
     
   
  History:
  As I wanted to make speaking my oric atmos with external world via serial at first, I went to interface it with a microcontroller, 
  trying with a teensy++2.0, it worked but was a bit slow in bauds as on oric side , I have to wait for the data to be read on     
  microcontroller side... So I've changed for a more powerful teensy running at 96Mhz (it works at 72Mhz), enable to catch at 
  microsecond scale the changes on digital pins, no more delay on Oric side, best speed achieved !
    -Raw transfert (no checksum) from teensy progmem to oric ram done at 65K bauds
    -Transfert from sd to oric with checksum calculation/check done at 52K bauds
  
  Credits & Special thanks to:
  OSDK, ALL oric user forums ! (forum-defence.force.org, retrowiki.es, ceo ...), SPI protocol on wikipedia, implementations in 6502,
  VIA documentation (and pages talking about !), Ana de Armas (for my repeating slide show pictures) ...  
  
  
   


