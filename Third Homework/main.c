// Abdullah Mert Tuncay  2099422
// Baris Sugur           2099315
#include <p18cxxx.h>
#include <p18f8722.h>
#pragma config OSC = HSPLL, FCMEN = OFF, IESO = OFF, PWRT = OFF, BOREN = OFF, WDT = OFF, MCLRE = ON, LPT1OSC = OFF, LVP = OFF, XINST = OFF, DEBUG = OFF

#define _XTAL_FREQ   40000000

#include "Includes.h"
#include "LCD.h"
// VARIABLES //
volatile unsigned int truflag = 0;              // If pin entered correctly, truflag is set to one!
volatile unsigned int timer_counter=0;          // Used in blinking # character. (Used with timer0 to produce 250ms interval)
volatile unsigned int timer_counter_ADC=0;      // Used in starting the AD conversion. (Used with timer0 to produce 100ms interval)
volatile unsigned int check_adc=0;              // Used in checking the AD value if changed. (state_2)
volatile unsigned int flag_ADC=0;               // Used in checking the AD value if changed. (Used in both state 2 and state 3)
volatile unsigned char c1;                      // Used in blinking the # digit. (c1=' ')
volatile unsigned char c2;                      // Used in blinking the # digit. (c2='#')
volatile unsigned char c3;                      // Used in writing the converted AD value to the LCD. (Used in both state 2 and state 3)
volatile unsigned int state_2_states=0;         // Shows the state of LCD. (state_2_states=0--->blinking)
volatile unsigned int digit1=0;                 // 1. digit of the pin.  
volatile unsigned int digit2=0;                 // 2. digit of the pin. 
volatile unsigned int digit3=0;                 // 3. digit of the pin. 
volatile unsigned int digit4=0;                 // 4. digit of the pin.
volatile unsigned int digit1_new=0;             // 1. digit of the pin that is tried. 
volatile unsigned int digit2_new=0;             // 2. digit of the pin that is tried.
volatile unsigned int digit3_new=0;             // 3. digit of the pin that is tried.
volatile unsigned int digit4_new=0;             // 4. digit of the pin that is tried.
volatile unsigned int digit_state=1;            // Used in state 2, for blinking the nonactive digit (#). 
volatile unsigned int digit_number=1;           // Shows the active digit while setting the pin and also trying the pin. (Used both in state two and three)
volatile unsigned int try_end_flag=0;           // Shows a try is ended. Activated by either RB7 push or 120 sec is up.) (Used in state 3)
volatile unsigned int second_state_over_flag=0; // Show whether the second state is over. (Used in second state)
volatile unsigned int new_pin_is_counter=0;     // Used in showing the new pin for 3 seconds. (Used to create 500ms intervals in timer0)
volatile unsigned int new_pin_how_many_times=0; // Shows how many times new pin is blinked. (Main function checks it and continues if it is greater than 6)
volatile unsigned int show_state=0;             // Used in blinking the selected pin for 3 seconds.
volatile unsigned int attempts=2;               // Shows number of remaining attempts.
volatile unsigned int general_state=1;          // Shows the state we are in. (1 or 2 or 3)
volatile int seconds=120;              // Shows number of remaining seconds.
volatile unsigned int timer1_counter=0;         // Used in timer1 ISR to calculate 1 second interval.
volatile unsigned int segment_state=1;          // Show which segment is active in seven segment display.
volatile unsigned int sec_20_counter=0;         // If we are waiting, (is_waiting==1), do nothing until sec_20_counter reaches 19. (Used in 20 sec wait.) 
volatile unsigned int is_waiting=0;             // Shows whether we are waiting 20 sec. (penalty) or not.
volatile unsigned int is_finished=0;            // Shows whether the program is finished or not. Activated when either 120 sec up or true pin entered. If=1, state_3 is finished.
volatile unsigned int rb6_flag=1;               // Used in busy check RB ports
volatile unsigned int rb7_flag=1;               // Used in busy check RB ports

// FUNCTION DECLERATIONS //
void init_variables();
void delay_3sec();
void segment_disp();
void waiting_state();
void state_2_interrupt();
void state_3_interrupt();
void show_new_pin();
void busy_rb();
void first_state();
void second_state();
void third_state();
int convert_adc(int adc_value);
void table(int a);

/* EXPLANATION
 * We divide the program to three states. In the first state the initial screen is shown.
 * In the second state the pin is set by the user. And in third state the pin enter is 
 * happening. We decided to divide the ISR into two parts called state_2_interrupt and 
 * state_3_interrupt to make it simpler to work on. A global variable called general_state 
 * shows the current state and main ISR function calls either state_2 or state_3 according
 * to this variable. Main function calls first second and third states one after the other 
 * and provides the needed wait phases between states. (3 second blink between second and 
 * third state.) Also main is the function that updates the general_state variable before
 * calling those states.
 *    For state_2_interrupt function:
 * This function is called on state_2. It first check where the interrupt came from. (TIMER0, 
 * AD or RB interrupt.) It blinks the digit if the bit is inactive. Shows the A/D value if 
 * digit become active. And with the RB interrupts it sets the corresponding digit and proceed 
 * the next digit. If last digit is also set, it waits RB7 action to proceed to the next state.
 *    For state_3_interrupt function:
 * This is the function that called by ISR in state_3. Similar to state_2, it checks where the 
 * interrupt comes and do the things necessary. However, it also includes interrupt from timer1. 
 * Timer1 is used in creating 1 second delay while counting down from 120 seconds. Other than
 * that it also have number of attempts that updated with each try. If attempts becomes 0 ISR 
 * raises a flag and program enters a 20 second loop. During this loop only TIMER1 interrupt is 
 * active (To make seconds decrease for 20 seconds). After the wait for 20 seconds, (also if 
 * seconds!=0 obviously), third state is entered again (with a general while loop in third 
 * state). If pin is entered correctly, the flag called "truflag" is set to 1 and the program 
 * is terminated with the related message is shown in the LCD together with the remaining second 
 * shown in the 7-segment display. Note that during this time ALL the interrupts are closed so 
 * that time does not decrease anymore. The safe is now opened by the user, (or a talented thief).
 */ // EXPLANATION

// FUNCTIONS //
void main(void){
    init_variables();
    InitLCD();          // Initialize function.
    first_state();      // Call first state.
    ClearLCDScreen();   // First state is over. Clear LCD and GOTO second state.
    general_state=2;    // update general state.
    second_state();     // Call second state.
    while(1){ if(second_state_over_flag==1){break;}} // Wait until second state is over.
    ClearLCDScreen();   // Second state is over. Clear LCD and blink the new pin (3 times).
    while(new_pin_how_many_times<6){continue;} // Wait until new pin is blinked for 3 seconds.
    general_state=3;    // Third state starts.
    third_state();      // Call third state.
    INTCON=0b00000000;  
    if(truflag==1){
        while(1){
            __delay_ms(2);
            segment_disp();
            __delay_ms(2);
        }
    }
}                     // MAIN FUNCTION

void interrupt ISR(){
    //Check whether we are in second state of third state.
    if(general_state==2){
        state_2_interrupt();
    }
    else if(general_state==3){
        state_3_interrupt();
    }
}                 // Main Interrupt Handler Function

void state_2_interrupt(){
    unsigned int timer_flag=0;
    unsigned int rb_interrupt_flag=0;
    unsigned int t = 0b00000100;
    unsigned int t1 = 0b01000000;
    unsigned int t2 = 0b00000001;
    unsigned int q = 0b00000010;
    timer_flag = (INTCON & t);
    rb_interrupt_flag = (INTCON & t2);
    if (timer_flag==4){ // Interrupt comes from TIMER
        if(second_state_over_flag==1){ // PIN IS SET! SHOW THREE SECONDS.
            new_pin_is_counter+=1;
            if(new_pin_is_counter>=99){
                new_pin_is_counter=0;
                if(show_state==0){
                    show_new_pin();
                    show_state=1;
                }
                else if(show_state==1){
                    ClearLCDScreen();
                    show_state=0;
                }
                new_pin_how_many_times+=1;
            }
        }
        else{
            timer_counter_ADC+=1;
            if(timer_counter_ADC>=19){
                timer_counter_ADC=0;
                ADCON0=ADCON0 | q; //set Go bit to 1, conversion started.
            }
            if(state_2_states == 0){ // Blink the # character
                timer_counter+=1;
                if(timer_counter>=49){ // Did 250 ms passed?
                    timer_counter=0;
                    if(digit_state==1){
                        c1 = (char)(' ');
                        if(digit_number==1){
                            WriteCommandToLCD(0x8B);
                            WriteDataToLCD(c1);}
                        else if(digit_number==2){
                            WriteCommandToLCD(0x8C);
                            WriteDataToLCD(c1);}
                        else if(digit_number==3){
                            WriteCommandToLCD(0x8D);
                            WriteDataToLCD(c1);}
                        else if(digit_number==4){
                            WriteCommandToLCD(0x8E);
                            WriteDataToLCD(c1);}
                        digit_state=0;
                    }
                    else{
                        c2 = (char)('#');
                        if(digit_number==1){
                            WriteCommandToLCD(0x8B);
                            WriteDataToLCD(c2);}
                        else if(digit_number==2){
                            WriteCommandToLCD(0x8C);
                            WriteDataToLCD(c2);}
                        else if(digit_number==3){
                            WriteCommandToLCD(0x8D);
                            WriteDataToLCD(c2);}
                        else if(digit_number==4){
                            WriteCommandToLCD(0x8E);
                            WriteDataToLCD(c2);}
                        digit_state=1;
                    }
                }
            }
        }
        TMR0=61;
        INTCON=0b11101000;
    }
    
    else if((PIR1 & t1) != 0){ // Interrupt came from ADC
        unsigned int templ = ADRESL;
        unsigned int k = 0b00000011;
        unsigned int temph = (ADRESH & k);
        temph = temph << 8;
        templ+=temph; // templ=value read from ADC registers 0 < templ < 1023
        unsigned int temp = convert_adc(templ);
        if(state_2_states ==0){ // STILL BLINKING, CHECK WHETHER ADC VALUE CHANGED OR NOT!
            if(flag_ADC==0){ // THIS IS THE FIRST CHECK, assign check_ADC the value in temp.
                check_adc=temp;
                flag_ADC=1;
            }
            else if(flag_ADC==1){ // CHECK WHETHER temp CHANGED!
                if(check_adc!=temp){ // CHANGED, STOP BLINKING AND SET state_2_states to 1!
                    state_2_states=1;
                }
            }
        }
        else if(state_2_states == 1){ // NOT BLINKING WRITE READED AD VALUES TO THE CORRESPONDING LCD AREAS!
            c3 = (char)(((int)'0')+temp);
            if(digit_number==1){
                WriteCommandToLCD(0x8B);
                WriteDataToLCD(c3);
            }
            else if(digit_number==2){
                WriteCommandToLCD(0x8C);
                WriteDataToLCD(c3);
            }
            else if(digit_number==3){
                WriteCommandToLCD(0x8D);
                WriteDataToLCD(c3);
            }
            else if(digit_number==4){
                WriteCommandToLCD(0x8E);
                WriteDataToLCD(c3);
            }
        }
        unsigned int p = 0b10111111;
        PIR1 = PIR1 & p;

    }
    else if(rb_interrupt_flag == 1){ // If interrupt is RB 
        unsigned int useless = PORTB; // Read PORTB so that INTCON.RBIF can be set to 0.
        rb_interrupt_flag=0;
        INTCONbits.RBIF=0;
        if(state_2_states==1){
            unsigned int templ = ADRESL;
            unsigned int k = 0b00000011;
            unsigned int temph = (ADRESH & k);
            temph = temph << 8;
            templ+=temph; // templ=value read from ADC registers 0 < templ < 1023
            unsigned int temp = convert_adc(templ);
            c3 = (char)(((int)'0')+temp);
            if(digit_number==1){
                digit1=temp;
                WriteCommandToLCD(0x8B);
                WriteDataToLCD(c3);
                digit_number+=1;
            }
            else if(digit_number==2){
                digit2=temp;
                WriteCommandToLCD(0x8C);
                WriteDataToLCD(c3);
                digit_number+=1;
            }
            else if(digit_number==3){
                digit3=temp;
                WriteCommandToLCD(0x8D);
                WriteDataToLCD(c3);
                digit_number+=1;
            }
            else if(digit_number==4){
                digit4=temp;
                WriteCommandToLCD(0x8E);
                WriteDataToLCD(c3);
                TRISB = 0b10000000; // Make RB6 and RB7 Input (Already digital)
                state_2_states=2;
            }
        }
        else if(state_2_states==2){
            second_state_over_flag = 1;
        }
        busy_rb();
        if(state_2_states!=2){
            state_2_states=0;
            flag_ADC=0;
        }
    }
}           // ISR function for the second state

void state_3_interrupt(){
    unsigned int timer_flag=0;
    unsigned int t = 0b00000100;
    unsigned int t1 = 0b01000000;
    unsigned int t3 = 0b00000001;
    unsigned int q = 0b00000010;
    timer_flag = (INTCON & t);
    if (timer_flag==4){ // Interrupt comes from TIMER
        segment_disp();
        timer_counter_ADC+=1;
        if(timer_counter_ADC>=19){
            timer_counter_ADC=0;
            ADCON0=ADCON0 | q; //set Go bit to 1, conversion started.
        }
        if(state_2_states == 0){ // Blink the # character
            timer_counter+=1;
            if(timer_counter>=49){ // Did 250 ms passed?
                timer_counter=0;
                if(digit_state==1){
                    c1 = (char)(' ');
                    if(digit_number==1){
                        WriteCommandToLCD(0x8B);
                        WriteDataToLCD(c1);}
                    else if(digit_number==2){
                        WriteCommandToLCD(0x8C);
                        WriteDataToLCD(c1);}
                    else if(digit_number==3){
                        WriteCommandToLCD(0x8D);
                        WriteDataToLCD(c1);}
                    else if(digit_number==4){
                        WriteCommandToLCD(0x8E);
                        WriteDataToLCD(c1);}
                    digit_state=0;
                }
                else{
                    c2 = (char)('#');
                    if(digit_number==1){
                        WriteCommandToLCD(0x8B);
                        WriteDataToLCD(c2);}
                    else if(digit_number==2){
                        WriteCommandToLCD(0x8C);
                        WriteDataToLCD(c2);}
                    else if(digit_number==3){
                        WriteCommandToLCD(0x8D);
                        WriteDataToLCD(c2);}
                    else if(digit_number==4){
                        WriteCommandToLCD(0x8E);
                        WriteDataToLCD(c2);}
                    digit_state=1;
                }
            }
        }
        TMR0=61;
        INTCON=0b11101000;
    }
    
    else if((PIR1 & t3) != 0){ // Interrupt came from TIMER1
        if(is_waiting==1){segment_disp();}
        timer1_counter+=1;
        if(timer1_counter>=249){
            timer1_counter=0;
            if(is_waiting==1){
                sec_20_counter+=1;
            }
            seconds-=1;
            if(seconds==0){
                try_end_flag=1;
            }
        }
        TMR1=25535;
        PIR1bits.TMR1IF=0;
    }
    
    else if((PIR1 & t1) != 0){ // Interrupt came from ADC
        unsigned int templ = ADRESL;
        unsigned int k = 0b00000011;
        unsigned int temph = (ADRESH & k);
        temph = temph << 8;
        templ+=temph; // templ=value read from ADC registers 0 < templ < 1023
        unsigned int temp = convert_adc(templ);
        if(state_2_states ==0){ // STILL BLINKING, CHECK WHETHER ADC VALUE CHANGED OR NOT!
            if(flag_ADC==0){ // THIS IS THE FIRST CHECK, assign check_ADC the value in temp.
                check_adc=temp;
                flag_ADC=1;
            }
            else if(flag_ADC==1){ // CHECK WHETHER templ CHANGED!
                if(check_adc!=temp){ // CHANGED, STOP BLINKING AND SET state_2_states to 1!
                    state_2_states=1;
                }
            }
        }
        else if(state_2_states == 1){ // NOT BLINKING WRITE READED AD VALUES TO THE CORRESPONDING LCD AREAS!
            c3 = (char)(((int)'0')+temp);
            if(digit_number==1){
                WriteCommandToLCD(0x8B);
                WriteDataToLCD(c3);
            }
            else if(digit_number==2){
                WriteCommandToLCD(0x8C);
                WriteDataToLCD(c3);
            }
            else if(digit_number==3){
                WriteCommandToLCD(0x8D);
                WriteDataToLCD(c3);
            }
            else if(digit_number==4){
                WriteCommandToLCD(0x8E);
                WriteDataToLCD(c3);
            }
        }
        PIR1bits.ADIF=0;
    }
    
    else if(INTCONbits.RBIF==1){ //RB INTERRUPTS
        unsigned int useless = PORTB;
        INTCONbits.RBIF=0;
        if(state_2_states==1){
            if(PORTBbits.RB6==0 && rb6_flag==1){
                rb6_flag=0;
                return;
            }
            else if(PORTBbits.RB6==0 && rb6_flag!=1){
                return;
            }
            else if(PORTBbits.RB6!=0 && rb6_flag==0){
                rb6_flag=1;
            }
        }
        else if(state_2_states==2){
            if(PORTBbits.RB7==0 && rb7_flag==1){
                rb7_flag=0;
                return;
            }
            else if(PORTBbits.RB7==0 && rb7_flag!=1){
                return;
            }
            else if(PORTBbits.RB7!=0 && rb7_flag==0){
                rb7_flag=1;
            }
            else if(PORTBbits.RB7!=0 && rb7_flag==1){
                PORTB=0;
                TRISB = 0b10000000;
            }
        }
        if(state_2_states==1){
            unsigned int templ = ADRESL;
            unsigned int k = 0b00000011;
            unsigned int temph = (ADRESH & k);
            temph = temph << 8;
            templ+=temph; // templ=value read from ADC resigters 0 < templ < 1023
            unsigned int temp = convert_adc(templ);
            c3 = (char)(((int)'0')+temp);
            if(digit_number==1){
                digit1_new=temp;
                WriteCommandToLCD(0x8B);
                WriteDataToLCD(c3);
                digit_number=2;
            }
            else if(digit_number==2){
                digit2_new=temp;
                WriteCommandToLCD(0x8C);
                WriteDataToLCD(c3);
                digit_number=3;
            }
            else if(digit_number==3){
                digit3_new=temp;
                WriteCommandToLCD(0x8D);
                WriteDataToLCD(c3);
                digit_number=4;
            }
            else if(digit_number==4){
                digit4_new=temp;
                WriteCommandToLCD(0x8E);
                WriteDataToLCD(c3);
                state_2_states=2;
//                unsigned int kkk = PORTB;
//                TRISBbits.RB6=0;
//                TRISBbits.RB7=1; // Make RB7 Input (Already digital)
//                kkk = PORTB;
                TRISBbits.TRISB7=1;
                TRISBbits.TRISB6=0;
                digit_number=1;
            }
        }
        else if(state_2_states==2){
            if(digit1==digit1_new){
                if(digit2==digit2_new){
                    if(digit3==digit3_new){
                        if(digit4==digit4_new){
                            truflag = 1;        // Pin entered correctly, set truflag=1.
                            try_end_flag = 1;   // Try is ended, set try_ended_flag=1.
                        }
                    }
                }
            }
            else{
                if(attempts>0){attempts-=1;} // Pin entered wrong, decrement attempts.
                truflag=0;      // Pin entered wrong, set truflag=0.
                try_end_flag=1; // Try ended, set try_end_flag=1.
            }
        }
        if(state_2_states!=2){
            state_2_states=0;
            flag_ADC=0;
        }
    }
}           // ISR function for the third state

void first_state(){
    ClearLCDScreen();
    WriteCommandToLCD(0x81);
    WriteStringToLCD("$>Very  Safe<$");
    WriteCommandToLCD(0xC1);
    WriteStringToLCD("$$$$$$$$$$$$$$");
    while(1){                           // Button Task  (For Push)
        if(PORTEbits.RE1 == 1){continue;}
        else{break;}
    }
    while(1){                           // Button Task (For Release)
        if(PORTEbits.RE1 == 0){ continue;}
        else{break;}
    }
    delay_3sec();
}                  // First State - Initial screen $$$$>Very  Safe<$$$$ is shown. RE1 action and GOTO second_state.

void second_state(){
    WriteCommandToLCD(0x81);
    WriteStringToLCD("Set a pin:####");
    T0CON = 0b11000111;  // TIMER0 Initialize (prescaler 1:256)
    INTCON = 0b11101000; //Enable Global, peripheral, Timer0 and RB interrupts by setting GIE, PEIE, TMR0IE and RBIE bits to 1
    TMR0=61;
    ADCON1 = 0b00000010; // ADC initialize
    ADCON0 = 0b00110001; // ADC initialize
    ADCON2 = 0b10111000; // ADC initialize
    PIE1 = 0b01000000;
    PORTH=0b00001111;
    PORTJ=0b01000000;
}                 // Second State - Setting the pin state. RB6 to set digit RB7 to set the password. After RB7 GOTO third_state.

void third_state(){
    while(is_finished==0){
        try_end_flag=0;
        ClearLCDScreen();
        WriteCommandToLCD(0x81);
        WriteStringToLCD("Enter pin:####");
        WriteCommandToLCD(0xC2);
        WriteStringToLCD("Attempts:");
        unsigned char c4;
        c4=(char)(((int) '0') + attempts);
        WriteCommandToLCD(0xCB);
        WriteDataToLCD(c4);
        T1CON= 0b10000001;
        TMR1=25536;
        T0CON = 0b11000111;  // TIMER0 Initialize (prescaler 1:256)
        INTCON = 0b11101000; //Enable Global, peripheral, Timer0 and RB interrupts by setting GIE, PEIE, TMR0IE and RBIE bits to 1
        TMR0=61;
        ADCON1 = 0b00000010; // ADC initialize
        ADCON0 = 0b00110001; // ADC initialize
        ADCON2 = 0b10111000; // ADC initialize
        PIE1 = 0b01000001;
        IPR1 = 0b00000001;
        timer_counter_ADC=0;
        state_2_states=0;
        timer_counter=0;
        digit_state=1;
        digit_number=1;
        flag_ADC=0;
        TRISB = 0b11000000;
        while(1){
            if(try_end_flag==1){
                break;
            }
        }
        if(seconds<=0){ // 120 seconds is up, finish the program by setting is_finished to 1.
            is_finished=1;
        }
        else if(truflag==1){ // Pin entered correctly, open the safe and finish the program by setting is_finish to 1.
            WriteCommandToLCD(0x80);
            WriteStringToLCD("Safe is opening!");
            WriteCommandToLCD(0xC0);
            WriteStringToLCD("$$$$$$$$$$$$$$$$");
            is_finished=1;
        }
        else if(truflag==0 && attempts<=0){ // Pin entered wrong and no more attempts left. Wait 20 seconds and continue, set attempts to 1.
            INTCONbits.TMR0IE=0;
            T0CONbits.TMR0ON=0;
            INTCONbits.RBIE=0;
            PIE1bits.ADIE=0;
            ClearLCDScreen();
            waiting_state();
            is_waiting=1;
            while(sec_20_counter!=19){
                if(seconds<=0){
                    is_finished=1;
                    break;
                }
            }
            is_waiting=0;
            sec_20_counter=0;
            attempts=2;
        }
    }
}                  // Third State - Pin checking state. If true pin is entered in 120 seconds, viola! If not, check attempts and proceed accordingly.

void busy_rb(){
    if(state_2_states==1){
        while(PORTBbits.RB6 == 0){
            continue;
        }
    }
    else if(state_2_states==2){
        while(PORTBbits.RB7==0){
            continue;
        }
    }
}                      // BUSY WAIT, NEED TO BE FIXED!!! (Busy wait for RB button release)

void show_new_pin(){
    unsigned char temp;
    WriteCommandToLCD(0x81);
    WriteStringToLCD("The new pin is");
    WriteCommandToLCD(0xC3);
    WriteStringToLCD("---");
    WriteCommandToLCD(0xC6);
    temp=(char)(((int)'0')+digit1);// digit1
    WriteDataToLCD(temp);
    WriteCommandToLCD(0xC7);
    temp=(char)(((int)'0')+digit2);// digit1
    WriteDataToLCD(temp);
    WriteCommandToLCD(0xC8);
    temp=(char)(((int)'0')+digit3);// digit1
    WriteDataToLCD(temp);// digit3
    WriteCommandToLCD(0xC9);
    temp=(char)(((int)'0')+digit4);// digit1
    WriteDataToLCD(temp);// digit4
    WriteCommandToLCD(0xCA);
    WriteStringToLCD("---");
}                 // After setting the pin LCD shows this screen. (This function only shows new pin, does NOT blink !!)

int convert_adc(int adc_value){
    if(adc_value >= 0 && adc_value<=99){
        return 0;
    }
    else if(adc_value > 99 && adc_value<=199){
        return 1;
    }
    else if(adc_value > 199 && adc_value<=299){
        return 2;
    }
    else if(adc_value > 299 && adc_value<=399){
        return 3;
    }
    else if(adc_value > 399 && adc_value<=499){
        return 4;
    }
    else if(adc_value > 499 && adc_value<=599){
        return 5;
    }
    else if(adc_value > 599 && adc_value<=699){
        return 6;
    }
    else if(adc_value > 699 && adc_value<=799){
        return 7;
    }
    else if(adc_value > 799 && adc_value<=899){
        return 8;
    }
    else if(adc_value > 899 && adc_value<=1024){
        return 9;
    }
    return 0;
}      // Converts 0-1023 ----> 0-9 according the table given in the homework text

void waiting_state(){
    ClearLCDScreen();
    WriteCommandToLCD(0x81);
    WriteStringToLCD("Enter pin:XXXX");
    WriteCommandToLCD(0xC0);
    WriteStringToLCD("Try after");
    WriteCommandToLCD(0xCA);
    unsigned char c5;
    c5=(char)(((int)'0') + 2);
    WriteDataToLCD(c5);
    WriteCommandToLCD(0xCB);
    c5=(char)(((int)'0') + 0);
    WriteDataToLCD(c5);
    WriteCommandToLCD(0xCC);
    WriteStringToLCD("sec.");
}                // After 2 consecutive wrong attempts, LCD shows this screen. (This function does NOT wait 20 seconds !!)

void segment_disp(){
    if(segment_state==1){
        PORTH=0b00000001;
        PORTJ=0b00111111;
        segment_state=2;
    }
    else if(segment_state==2){
        PORTH=0b00000010;
        if(seconds>99){
            PORTJ=0b00000110;
        }
        else{
            PORTJ=0b00111111;
        }
        segment_state=3;
    }
    else if(segment_state==3){
        PORTH=0b00000100;
        int k = (seconds/10)%10;
        table(k);
        segment_state=4;
    }
    else if(segment_state==4){
        PORTH=0b00001000;
        int k = seconds%10;
        table(k);
        segment_state=1;
    }
}                 // This is the function that sets the seven-segment display. It uses the current seconds(global variable) to show.

void table(int k){
    if(k==0){
        PORTJ=0x3F;
    }
    else if(k==1){
        PORTJ=0x06;
    }
    else if(k==2){
        PORTJ=0x5B;
    }
    else if(k==3){
        PORTJ=0x4F;
    }
    else if(k==4){
        PORTJ=0x66;
    }
    else if(k==5){
        PORTJ=0x6D;
    }
    else if(k==6){
        PORTJ=0x7D;
    }
    else if(k==7){
        PORTJ=0x07;
    }
    else if(k==8){
        PORTJ=0x7F;
    }
    else if(k==9){
        PORTJ=0x6F;
    }
}                   // Table lookup for the segment display function

void delay_3sec(){                                 // Wait 3 seconds in busy loop
    for(int i=0; i<32667;i++){
        for (int j=0; j<76; j++){
        }
    }
}                    // Delay function (waits for 3 seconds)

void init_variables(){
    truflag = 0;              // If pin entered correctly, truflag is set to one!
    timer_counter=0;          // Used in blinking # character. (Used with timer0 to produce 250ms interval)
    timer_counter_ADC=0;      // Used in starting the AD conversion. (Used with timer0 to produce 100ms interval)
    check_adc=0;              // Used in checking the AD value if changed. (state_2)
    flag_ADC=0;               // Used in checking the AD value if changed. (Used in both state 2 and state 3)
    state_2_states=0;         // Shows the state of LCD. (state_2_states=0--->blinking)
    digit1=0;                 // 1. digit of the pin.  
    digit2=0;                 // 2. digit of the pin. 
    digit3=0;                 // 3. digit of the pin. 
    digit4=0;                 // 4. digit of the pin.
    digit1_new=0;             // 1. digit of the pin that is tried. 
    digit2_new=0;             // 2. digit of the pin that is tried.
    digit3_new=0;             // 3. digit of the pin that is tried.
    digit4_new=0;             // 4. digit of the pin that is tried.
    digit_state=1;            // Used in state 2, for blinking the nonactive digit (#). 
    digit_number=1;           // Shows the active digit while setting the pin and also trying the pin. (Used both in state two and three)
    try_end_flag=0;           // Shows a try is ended. Activated by either RB7 push or 120 sec is up.) (Used in state 3)
    second_state_over_flag=0; // Show whether the second state is over. (Used in second state)
    new_pin_is_counter=0;     // Used in showing the new pin for 3 seconds. (Used to create 500ms intervals in timer0)
    new_pin_how_many_times=0; // Shows how many times new pin is blinked. (Main function checks it and continues if it is greater than 6)
    show_state=0;             // Used in blinking the selected pin for 3 seconds.
    attempts=2;               // Shows number of remaining attempts.
    general_state=1;          // Shows the state we are in. (1 or 2 or 3)
    seconds=120;              // Shows number of remaining seconds.
    timer1_counter=0;         // Used in timer1 ISR to calculate 1 second interval.
    segment_state=1;          // Show which segment is active in seven segment display.
    sec_20_counter=0;         // If we are waiting, (is_waiting==1), do nothing until sec_20_counter reaches 19. (Used in 20 sec wait.) 
    is_waiting=0;             // Shows whether we are waiting 20 sec. (penalty) or not.
    is_finished=0;
    rb6_flag=1;               // Used in busy check rb ports
    rb7_flag=1;               // Used in busy check rb ports
}               // Initialization function.