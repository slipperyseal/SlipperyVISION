# SlipperyVISION

### A PAL signal generator and VT Terminal for the AVR microcontroller.

This project implements a true text mode with reverse mode and circular text buffer.

But wait, there's more..

- 24 x 24 character display
- Commodore 64 font
- "Hardware" reverse character mode.
- Receives and renders ASCII via UART (serial) 
- Component colour channels

This project is based on the ATmega328p. Other AVRs may be supported which have compatible
instructions, timing characteristics, memory etc, etc.

In development:

- Capacitance effects
- Printed Circuit Board
- Escape code handling

![SlipperyVISION](https://github.com/slipperyseal/SlipperyVISION/blob/main/doc/slipperyvision.jpg)

The AVR microcontroller cannot natively generate an old school television video signal, but using some minimal
hardware (some diodes and resistors), and some precisely timed code, we can generate a signal like a proper
graphics device would.

So what do we mean by true text mode? Internally, the contents of the display are represented as a
buffer of ASCII characters, not a bitmap representing every pixel, which uses more memory and is slower to update.
This buffer is also circular, which means, as we need to add a line and scroll the display, we only
need to update a vertical index in the circular buffer.  As the screen is drawn, it may draw the lower
section of the buffer in the upper part of the screen, and then the upper section of the buffer in the
lower part of the screen.

A PAL video signal is made up of a series of frames (50 interlaced fields becomes 25 frames per second).
Each frame contains a series of horizontal scan lines (625).
And scan lines are made up of pixels (up to about 720 depending on how quick you can draw your pixels).
A pixel appears on screen when we "turn on and off" the signal as the scan line progresses over time.

At the start of each scan line SlipperyVISION will work out which characters need to be drawn, and which of
the 8 lines within the font are required (characters are 8x8 pixels in size).  It grabs this font data from the
AVRs flash memory and assembles this into a buffer of 24 bytes which represents one scan line (192 pixels).
When it is time to draw the pixels on the scan line, a highly optimized sequence of assembler instructions
sends these bits to a GPIO pin at just the right rate to render the image to the video signal.  It does this
192 times per field (half an interlaced frame) to draw all 24 x 24 characters, totaling 192 x 192 pixels.

The AVR runs at 16 million cycles per second (16mhz). If a single one cycle instruction was to be added or removed
in this critical code, pixels would be the wrong dimensions.

When television first began it was black and white. The basic video signal represents the brightness of the image displayed.
This is referred to as luminance. The colour aspect is represented by two separate signals Cr and Cb, component red and blue.
SlipperyVISION con plug straight into TVs which support the three compoenent video plugs, plus the two audio.
Composite video is where the lumunance and two colour singals are combined into one plug. SlipperyVISION doesn't support
this, but due to the way composite works, you can plug just the luminance cable into a composite input and get a black and white image only.

![SlipperyVISION](https://github.com/slipperyseal/SlipperyVISION/blob/main/doc/slipperyvision-blue.jpg)

Colour is working in various ways, by adding two more similar channels (Cr Cb)
which can be connected to a Y Cr Cb (component) compatible TV or device.

![SlipperyVISION](https://github.com/slipperyseal/SlipperyVISION/blob/main/doc/slipperyvision-autopak-pcb.png)

I accidentally left caps on the board and noticed it messing with the image, then decided I could have capacitors
put in circuit on purpose...

![SlipperyVISION](https://github.com/slipperyseal/SlipperyVISION/blob/main/doc/slipperyvision-fx.jpg)

Fuse settings (16mhz external, SPI)

```
-U lfuse:w:0xff:m -U hfuse:w:0xd9:m -U efuse:w:0xff:m
```
