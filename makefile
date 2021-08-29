DEVICE = atmega328p
MCU    = atmega328p
F_CPU  = 16000000
TARGET = slipperyvision

CC      = avr-gcc 
OBJCOPY = avr-objcopy 

INCLUDES = -I./ -I/usr/lib/avr/include 

CFLAGS = -mmcu=$(MCU) -I.
CFLAGS += -DF_CPU=$(F_CPU)UL
CFLAGS += -O3
CFLAGS += -funsigned-bitfields
CFLAGS += -fpack-struct
CFLAGS += -fshort-enums
CFLAGS += -Wall
CFLAGS += -Wundef

LDFLAGS  = -Wl,-gc-sections -Wl,-relax 

all: 
	$(CC) $(CFLAGS) $(LDFLAGS) slipperyvision.c slipperyslide.s font.s scanline.s -o $(TARGET)

clean: 
	rm -rf *.o *.hex *.obj $(TARGET)

