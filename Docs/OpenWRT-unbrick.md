### Unbricking the Creality Wifi Box
*Forsooth, I have bricked my wifi box*

The term "brick" (in this technical context) is used when you have broken something to the point that it is about as useful as a brick. That is to say, naught but a paperweight. The term "unbrick", as follows, means to reverse that action. Unless you physically damaged the wifi box, it is very unlikely that you have permanently bricked it.

---

#### Requirements
- Creality Wifi Box
- CWB Power cable (Micro USB)
- USB (A) storage device (Realistically any size should work)
- Computer with a USB (A) port
- Ethernet (Aka: RJ45, internet) cable
- Sim card ejector tool, needle, tweezers, or similar (long, thin object)


#### Unbricking
1. Preparing the recovery media
    - Format your USB drive with an MBR (also known as MSDOS) partition table
        - Unless you know what this means and you have changed it yourself, it will most likely be this way already
        - 
    - Create a Fat32 partition
    - Copy the `sysupgrade*.bin` file to the root of the USB drive, and rename it (`root_uImage`/`root_uImage.bin`)
2. Unbricking
    - Make sure the wifi box is disconnected from power. Then;
        - Plug the USB drive into either USB port
        - Using your long, thin object of choice, press the reset button
            - The reset button is on the side, right next to the MicroSD card slot
        - While holding the reset button down, connect the wifi box to power
        - Hold the reset button until the LED on the front turns green (6-10 seconds)
        - Release the reset button, and leave it for ~2 minutes. Once finished, the green LED will be solid, the orange LED flashing