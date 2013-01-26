/*
 *  main.c
 */

#include "main.h"

/* 
 Pin assignments
 RA0 / AN0: Left channel  (common pin of multiplexer)
 RA1 / AN1: Right channel (common pin of multiplexer)
 RB0: S0 on multiplexers
 RB1: S1 on multiplexers
 RB2: S2 on multiplexers
 RB3: S3 on multiplexers
 RB4:
 RB5:
 RB6: Signal found light / transmitter power control
 RB7: Debug light
 */

#define NUM_CHANNELS 4
#define NUM_SAMPLES 40
#define ACTIVITY_THRESHOLD 128
#define DWELL_TIME 500
#define INACTIVE_THRESHOLD_CYCLES 512
#define MIN_ADC_READING 300

typedef unsigned char ubyte;
typedef char sbyte;
typedef unsigned short ushort;
typedef short sshort;

#define INTERRUPT_ROUTINE(name) void name() __interrupt 0
#define SLEEP(x)     \
__asm\
sleep\
__endasm

typedef struct {
    ubyte bestChannel;
    ushort bestActivity;
} scan_result_t;
static scan_result_t scan_result;

static ushort measure_activity();
static void configure();
static void wait(ushort waitTime);
static void scan();

void main() {
    ubyte channel = 0;
    ushort activeTimeCredit = 0;
    
    configure();
    
    PORTB = 0;
    activeTimeCredit = 0;
    
    while (1) {
        //Scan and find a good signal source
        scan();
        
        //Flash the debug LED slowly to show scan
        activeTimeCredit++;
        RB7 = activeTimeCredit & 0x8 ? 0 : 1;
        
        //If there's nothing good enough, scan again
        if (scan_result.bestActivity < ACTIVITY_THRESHOLD) continue;
        
        //Give the best source some credit
        PORTB = (PORTB & 0b11110000) | scan_result.bestChannel;
        activeTimeCredit = 20;
        
        //Turn on the transmitter power
        RB6 = 1;
        
        //While it's got positive credit
        while (activeTimeCredit) {
            //Check the signal
            ushort activity;
            RB7 = 0;
            activity = measure_activity();
            
            //If it's active, add to its credit
            if (activity > ACTIVITY_THRESHOLD) {
                if (activeTimeCredit < INACTIVE_THRESHOLD_CYCLES)
                    activeTimeCredit += 2;
                RB7 = 1;
            }
            //Otherwise reduce the credit
            else {
                if (activeTimeCredit > 0) activeTimeCredit--;
            }
        }
        
        //Turn off transmitter and start scanning again
        RB6 = 0;
    }
    
//    while (bestActivity < ACTIVITY_THRESHOLD) {
//        //Scan
//        bestActivity = 0;
//        for (channel = 0; channel < NUM_CHANNELS; channel++) {
//            //Select the channel
//            PORTB = (PORTB & 0b11110000) | channel;
//            
//            //Measure activity
//            activity = measure_activity();
//            
//            //Save if best
//            if (activity > bestActivity) {
//                bestActivity = activity;
//                bestChannel = channel;
//            }
//        }
//        
//        //Flash the debug light slowly while no signal is found
//        inactiveTime++;
//        RB7 = inactiveTime & 0x8 ? 0 : 1;
//    }
//    
//    //Select the channel and light the 'signal found' light
//    PORTB = (PORTB & 0b11110000) | bestChannel | 0b11000000;
//    inactiveTime = 0;
//    do {
//        //Dwell for a while
//        wait(DWELL_TIME);
//        
//        //Measure activity again
//        RB7 = 0;
//        activity = measure_activity();
//        
//        if (activity < ACTIVITY_THRESHOLD) {
//            inactiveTime++;
//        }
//        else {
//            inactiveTime = 0;
//            RB7 = 1;
//        }
//    } while (inactiveTime < INACTIVE_THRESHOLD);
}

static void scan()
{
    ubyte oldChannel = PORTB & 0b00001111;
    ubyte channel = 0;
    ushort activity = 0;
    scan_result.bestChannel = 0xFF;
    scan_result.bestActivity = 0;
        
    for (channel = 0; channel < NUM_CHANNELS; channel++) {
        //Select the channel
        PORTB = (PORTB & 0b11110000) | channel;
        
        //Measure activity
        activity = measure_activity();
        
        //Save if best
        if (activity > scan_result.bestActivity) {
            scan_result.bestActivity = activity;
            scan_result.bestChannel = channel;
        }
    }

    PORTB = (PORTB & 0b11110000) | oldChannel;
}

static short abs(short i) {
    return i < 0 ? -i : i;
}

static void wait(ushort waitTime) {
    while (waitTime) waitTime--;
}

static ushort measure_activity() {
    ushort plusact = 0, minusact = 0;
    ushort prevMeas = 0;
    ushort curMeas = 0;
    ubyte i = 0;
    //Select channel 0
    CHS0 = 0;
    while (1) {
        //Wait a little for the channel change
        wait(50);
        
        //Take samples
        for (i = 0; i < NUM_SAMPLES; i++) {
            GO = 1;
            while (NOT_DONE);
            curMeas = ADRESL | (ADRESH << 8);
            if (curMeas < MIN_ADC_READING) return 0;
            if (prevMeas != 0) {
                if (curMeas > prevMeas) plusact += curMeas - prevMeas;
                if (curMeas < prevMeas) minusact += prevMeas - curMeas;
            }
            prevMeas = curMeas;
            wait(5);
        }
        
        //Switch channels
        CHS0 = !CHS0;
        
        //If we just switched back to zero, we're done
        if (CHS0 == 0) break;
        
        //Reset the previous measurement
        prevMeas = 0;
    }
    if (plusact > minusact) return minusact;
    return plusact;
}

INTERRUPT_ROUTINE(interrupt_routine) {
    
}

static void configure() {
    INTCON = 0; // Disable all interrupts
    GIE = 0;    // Disable all interrupts
    CMCON = 0;  // Comparators off
    NOT_RBPU = 1;       //Disable PORTB pull-up resistory
    TRISA = 0b00000011; //PORTA two inputs,analog
    TRISB = 0b00000000; //PORTB all outputs
    PORTA = PORTB = 0;  //Bring all pins low
    ANSEL = 0b00000011; //Two analog pins
    CMCON = 0x7;        //Comparators off
    ADCON0 = 0b00000001;//Enable A/D converter
    ADCON1 = 0b10000000;//Configure for right justified A/D conversion
    OSCCON = 0b01000000; //1MHz internal oscillator
}

