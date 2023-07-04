# FROM v1.4
 Flashjacks FlashROM

Attention!!!. 
This version is not the latest version. This is because as of 1.5, third parties intervened in the source code and it is not freely distributed.
Serve this version as an example of use and training of the possibilities of loading ROM through Flashjacks.

For run, first:

FROM xxx.ROM ...of your favorite game.


For compile, first:

sjasm.exe FROM.asm FROM.COM


Sources:

https://retromsx.com


Synthesis “FROM.COM”

The idea of the system is based on two modes. The manual mode where you configure at will and the automatic mode that with a standard configuration can access most of the catalog of programs and games that were made for MSX.

With FROM.COM is intended to address this automatic press and ready.
The standard configuration is optimized to have a bit of everything.
In sublot 0 we have the disk drive, in the subslot 1 RAM, in the 2 a free FlashROM and in the 3 a complete FMPAC which we can throw it so that a second FlashROM coexists.

Having said that we comment your options:

FROM NOMBRE1.ROM NOMBRE2.ROM

In this mode, if we do not place options, it will accept the loading of two simultaneous ROMS. These will place them in the first two FlashROMs you find. In our case they are located in the sublot2 and 3. The disk drive is forbidden to become FlashROM.
If we just put a ROM (the usual), it will load us in sublot 2 leaving us the FMPAC in sublot 3.



When there are no parameters, it will load the mapper in AUTO mode.
The AUTO mode chooses the mapper that best suits that ROM for you. It even autoconfigures to primary Slot if it observes in the code of the ROM some incompatibility with the subslot.

We have not yet talked about the AUTO system of the mappers.
When this mode is chosen, internally the ROMs are analyzed with a double method. On the one hand there is a heuristic type method, where you look for marks in the jump type ROM to find out how the most accurate mapper behaves and adapt to it. This system makes a multiple crossing of these brands and the winner is the one selected by the system. In addition, they cross paths with a small database where they fill in those gaps where they have doubts.

It really behaves similar to what an antivirus does.
The process is performed in the Flashjacks hardware at vertigo speed while loading the ROM without it being affected in speed.
Besides the previous search, the system tries to look for incompatibility marks before subslots and in the case of finding them, pulls the configuration of the Slot expander, leaving as primary the first load ROM.

Of course the system is not infallible and that is why FROM.COM has a manual system. Let's go for this second loading mode:

FROM /R /Sxx /My NOMBRE.ROM

Here it only allows us to load a ROM with parameters.
In /R we will force a softreset after loading.
In /Sxx we can force Slot and Subslot, as long as there is a FlashROM of FlashJacks in that slot.
If we place only one digit instead of two, we are telling the system that we want to force the ROM into the main slot so it will cancel the Slot expander.

In /My allows us to form the mapper where "and" can be:

0: AUTO        1:KONAMI   2:ASCII8K
3: KONAMI4     4:ASCII16K 5:SUNRISE
6: SINFOX      7:ROM16K	  8:ROM32K
9: ROM64K      A:RTYPE	  B:ZEMINA6480
C: ZEMINA126   D:FMPAC	  E:CROSSBLAIM
F: SLODERUN

Each name intuits the type of mapper that will load.
All these mappers, are expanded to the maximum that can address that format, surpassing the address and capacity for which they were thought.
The mapper that has the capacity to address the 4Mb (or 32Mbits) of Flashjacks is the ASCII16K type.

Once we press ENTER, the magic happens. Although apparently it gives you a result and the MSX continues to work as if nothing, the device already has those instructions in the breech for the next reset.
FROM.COM does not work like other EPROM loaders where it dumps through the MSX CPU.

FROM.COM is a program that sends instructions to FLASHJACKS, where after a reset, the beast of the internal hardware will process at a speed infinitely superior to what the Z80 could do.
This mode of operation will continue like this until we do not perform a Power OFF.
If we indicate a softreset in the parameters, this will happen when pressing enter in the confirmation screen. This is ideal for those MSXs that do not have a reset button.



Indicate that other EPROM loaders can be used since our FlashROM will behave as if it were an original EPROM.
The system FlashJacks internally has an adaptive system that makes give the appropriate reference of EPROM depending on what the software asks.

This process is slow since it is the Z80 that is responsible for transferring and even patching our ROM to work in the EPROM (in our case a RAM simulates this EPROM).

By the way, our system is pure hardware and behaves as such. We will never patch a ROM to load emulating a mapper, which is what traditional systems do. FlashJacks contributes that mapper as if it were real (well, in fact it is).

And little more than commenting from FROM.COM. Remember to do Reset to execute the requested and Power to start over.
Remember that in the self-saving settings of ROMs or SRAM, that saving is done at the next reset. If we want to save an SRAM file, we must do a reset after having played and saved.

