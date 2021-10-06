//#define F_CPU 16000000
#include <avr/io.h>
#include <util/delay.h>
#include <avr/pgmspace.h>
#include <avr/interrupt.h>
#include <unistd.h>

#define USART_BAUDRATE 9600
#define BAUD_PRESCALE (((F_CPU/(USART_BAUDRATE*16UL)))-1)

// asm functions
void renderVerticalSync();
void slipperyslide();

void (*lineFunction)();
uint8_t scanlinebuffer[24];
uint8_t charbuffer[32*32];
uint8_t uartBuffer[128];

uint8_t uartWrite;
uint8_t uartRead;
uint8_t counter;
uint8_t rowoffset;
uint8_t cursorx;
uint8_t cursory;
uint8_t frame;
uint8_t lastChar;

void invertLine(uint8_t y) {
    uint8_t * b = &charbuffer[y*32];
    b[0] = b[1] = b[2] = 0xff;
}

void print(uint8_t x, uint8_t y, char * string) {
    uint8_t * b = &charbuffer[(y*32)+x+4];
    uint8_t c;
    while ((c = *string++) != 0) {
        *b++ = c;
    }
}

void writeUart(uint8_t data) {
    while (((UCSR0A & (1<<UDRE0)) == 0));
    UDR0=data;
}

void writeUartString(char * string) {
    uint8_t c;
    while ((c = *string++) != 0) {
        writeUart(c);
    }
}

int main() {
    DDRB = 1;   // black level out
    DDRC = 1;   // white level out
    DDRD = (1<<2);// | (1<<3);

    // 64 microsecond ISR at 16mhz
    TCCR1A = 0;
    TCCR1B = 0;
    TCNT1  = 0;
    OCR1A = 3;
    TCCR1B |= (1 << WGM12) | (1 << CS12);
    TIMSK1 |= (1 << OCIE1A);

    // UART
    UCSR0B |= (1<<RXEN0) | (1<<TXEN0);
    UCSR0C |= (1<<UCSZ00) | (1<<UCSZ01);
    UBRR0H  = (BAUD_PRESCALE >> 8);
    UBRR0L  = BAUD_PRESCALE;

    lineFunction = renderVerticalSync;
    cursory = 23;

    print((24-14)/2, 5, "SlipperyVISION");
    invertLine(4);
    invertLine(5);
    invertLine(6);
    print(0, 11, "PAL generator + terminal");
    print(0, 13, "github.com/slipperyseal/");
    print((24-7)/2, 17, "\xc1  \xd8  \xd3  \xda");

    print(0, 22, "READY.");

    sei();
    slipperyslide();
}
