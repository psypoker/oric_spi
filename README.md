# oric_spi
SPI like protocol interfacing via6522 (Oric Atmos) with teensy 3.2 
using no breadboard, and no soldering, but only 11 dupont cables

                 (5 cables)        (6 cables)
Oric Atmos VIA 6522 <---> teensy 3.2 <---> SD catalex SPI module

-project on Teensy3.2:
"porta_spî3.2.ino"

-project on Oric Atmos:
"SPI_LOAD.TAP" : the main boot loader application ( tape duration about 7 sec)
  -> send "BOOT" command to teensy
  sources spi_load.s /osdk_config.bat 
  
"ORIC_SPI.TAP" : the oric atmos spi link to teensy demo ( tape duration about 45 sec, loaded in a couple of seconds with spi boot loader)
  sends commands to teensy3.2 via spi link
  "DIR" shows directory of sd card
  "TAPE" loads a tape in oric memory from sd card
    - supported tapes are hires images or binary executables only (full tape support in todolist)
  "SAVE" loads a saved image in PROGMEM in oric memory
  "LOAD" loads a saved image on SD card in oric memory
  "TEXT" loads a text file on SD card in oric display
  sources: main_oric_spi.c / oric_spi.s / osdk_config.bat
  
  

  
  
  
  




