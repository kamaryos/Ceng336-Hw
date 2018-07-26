;list P=18F8722

#include <p18f8722.inc>
config OSC = HSPLL, FCMEN = OFF, IESO = OFF, PWRT = OFF, BOREN = OFF, WDT = OFF, MCLRE = ON, LPT1OSC = OFF, LVP = OFF, XINST = OFF, DEBUG = OFF

UDATA_ACS
  t1	res 1	; used in delay
  t2	res 1	; used in delay
  t3	res 1	; used in delay
  direc res 1   ; Direction of the ball (0=right, 1=left)
  stateA res 1  ; Pad States (A)
  stateF res 1  ; Pad States (F)
  cordx res 1   ; Row (satir)
  cordy res 1   ; Column (sutun)
  check res 1   ; Used In Table scoreboard
  temp  res 1   ; Used in ISR ball movement
  turn  res 1   ; Used in ISR to display the 7 segment
  rg0   res 1   ; Used ?n button task0
  rg1   res 1   ; Used ?n button task0
  rg2   res 1   ; Used ?n button task0
  rg3   res 1   ; Used ?n button task0
  counter res 1
  w_temp  res 1
  status_temp res 1
  pclath_temp res 1
  lastbit   res 1 ;LASTBIT OF THE TMR0 , calculated in main function
  score1 res 1 ;SCORE OF THE FIRST PLAYER
  score2 res 1 ;SCORE OF THE SECOND PLAYER

RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START

org     0x0008
goto    isr   ;go to interrupt service routine

;MAIN_PROG CODE	; let linker place main program

;ORG     0x0000
;GOTO    init

INIT
    MOVLW   0xFF
    MOVWF   ADCON1
    CLRF    PORTA
    CLRF    PORTB
    CLRF    PORTC
    CLRF    PORTD
    CLRF    PORTE
    CLRF    PORTF
    CLRF    PORTJ
    CLRF    PORTH
    CLRF    rg0
    CLRF    rg1
    CLRF    rg2
    CLRF    rg3
    CLRF    turn
    CLRF    counter
    CLRF    check
    CLRF    score1
    CLRF    score2
    CLRF    lastbit
    CLRF    temp
    CLRF    direc
    CLRF    cordx
    CLRF    cordy
    MOVLW   0x04
    MOVWF   cordx
    MOVWF   cordy
    CLRF    stateA
    CLRF    stateF
    CLRF   TRISA
    CLRF   TRISB
    CLRF   TRISC
    CLRF   TRISD
    CLRF   TRISE
    CLRF   TRISF
    CLRF   TRISJ
    CLRF   TRISH
    MOVLW   0x0F
    MOVWF   TRISG
    ;Disable interrupts
    clrf    INTCON
     ;Initialize Timer0
    movlw   b'01000111' ;Disable Timer0 by setting TMR0ON to 0 (for now)
                        ;Configure Timer0 as an 8-bit timer/counter by setting T08BIT to 1
                        ;Timer0 increment from internal clock with a prescaler of 1:256.
    movwf   T0CON ; T0CON = b'01000111'
    ;Enable interrupts
    movlw   b'11100000' ;Enable Global, peripheral, Timer0 and RB interrupts by setting GIE, PEIE, TMR0IE and RBIE bits to 1
    movwf   INTCON
    CLRF    TMR0
    bsf     T0CON, 7    ;Enable Timer0 by setting TMR0ON to 1
    return

START
    call    INIT
    goto    START_NOW

START_NOW
    clrf    INTCON
     ;Initialize Timer0
    movlw   b'01000111' ;Disable Timer0 by setting TMR0ON to 0 (for now)
                        ;Configure Timer0 as an 8-bit timer/counter by setting T08BIT to 1
                        ;Timer0 increment from internal clock with a prescaler of 1:256.
    movwf   T0CON ; T0CON = b'01000111'
    ;Enable interrupts
    movlw   b'11100000' ;Enable Global, peripheral, Timer0 and RB interrupts by setting GIE, PEIE, TMR0IE and RBIE bits to 1
    movwf   INTCON
    CLRF    TMR0
    bsf     T0CON, 7    ;Enable Timer0 by setting TMR0ON to 1
    MOVLW   b'01000001'
    MOVWF   T1CON       ;Enable timer1
    CLRF    TRISC
    MOVLW   b'00011100'
    MOVWF   stateA
    MOVWF   stateF
    MOVWF   PORTA
    MOVWF   PORTF
    MOVLW   0x04
    MOVWF   cordx
    MOVWF   cordy
    call    BALL_OFF
    call    BALL_ON
    GOTO    MAIN

MAIN
    call    BUTTON_TASK_RG0
    call    BUTTON_TASK_RG1
    call    BUTTON_TASK_RG2
    call    BUTTON_TASK_RG3
    MOVF    TMR1,0
    MOVWF   lastbit
    GOTO    MAIN  ; loop forever

isr:
    call    save_registers  ;Save current content of STATUS and PCLATH registers to be able to restore them later
    MOVLW   0x00
    CPFSEQ  turn
    GOTO    decide2
    decide1:
    CALL    DISP
    GOTO    timer_interrupt
    decide2:
    CALL    DISP2
    GOTO    timer_interrupt
timer_interrupt:
    incf	counter, f              ;Timer interrupt handler part begins here by incrementing count variable
    movf	counter, w              ;Move count to Working register
    sublw	d'60'                    ;Decrement 5 from Working register
    btfss	STATUS, Z               ;Is the result Zero?
    goto	timer_interrupt_exit    ;No, then exit from interrupt service routine
    clrf	counter                 ;Yes, then clear count variable
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    MOVF    lastbit,0 ;BALL MOVEMENT START HERE
    ANDLW   0x03    ;AND with 00000011
    MOVWF   temp    ;temp got the result now
    aaa:
    MOVLW   0x00    ;
    CPFSGT  temp    ;
    goto    ball00  ; ball goes horizontal
    MOVLW   0x01    ;
    CPFSGT  temp    ;
    goto    ball01  ; ball goes up
    MOVLW   0x02    ;
    CPFSGT  temp    ;
    goto    ball10  ; ball goes down
    ball00: ;BALL GOES HORIZONTAL
        MOVLW	0x00
        CPFSEQ	direc
        GOTO    direc001
        direc000:
            MOVLW   0x05
            CPFSLT  cordy ;skip if y < E
            GOTO    checkpad01
            INCF    cordy
            GOTO    ball_interrupt
        direc001:
            MOVLW   0x02
            CPFSGT  cordy ;skip if y > A
            GOTO    checkpad02
            DECF    cordy
            GOTO    ball_interrupt
    ball01: ;BALL GOES UP
        MOVLW	0x00
        CPFSEQ	direc
        GOTO    direc011
        direc010:
            MOVLW   0x01
            CPFSGT  cordx
            GOTO    upperbound1
            MOVLW   0x05
            CPFSLT  cordy
            GOTO    checkpad01
            INCF    cordy
            DECF    cordx
            GOTO    ball_interrupt
        direc011:
            MOVLW   0x01
            CPFSGT  cordx
            GOTO    upperbound2
            MOVLW   0x02
            CPFSGT  cordy
            GOTO    checkpad02
            DECF    cordx
            DECF    cordy
            GOTO    ball_interrupt
        upperbound1:
            MOVLW   0x05
            CPFSLT  cordy
            GOTO    checkpad01
            INCF    cordy
            INCF    cordx
            GOTO    ball_interrupt
        upperbound2:
            MOVLW   0x02
            CPFSGT  cordy
            GOTO    checkpad02
            DECF    cordy
            INCF    cordx
            GOTO    ball_interrupt
    ball10: ;BALL GOES DOWN
        MOVLW	0x00
        CPFSEQ	direc
        GOTO    direc101
        direc100:
            MOVLW   0x06
            CPFSLT  cordx
            GOTO    downbound1
            MOVLW   0x05
            CPFSLT  cordy
            GOTO    checkpad01
            INCF    cordy
            INCF    cordx
            GOTO    ball_interrupt
        direc101:
            MOVLW   0x06
            CPFSLT  cordx
            GOTO    downbound2
            MOVLW   0x02
            CPFSGT  cordy
            GOTO    checkpad02
            INCF    cordx
            DECF    cordy
            GOTO    ball_interrupt
        downbound1:
            MOVLW   0x05
            CPFSLT  cordy
            GOTO    checkpad01
            INCF    cordy
            DECF    cordx
            GOTO    ball_interrupt
        downbound2:
            MOVLW   0x02
            CPFSGT  cordy
            GOTO    checkpad02
            DECF    cordy
            DECF    cordx
            GOTO    ball_interrupt
    checkpad01:
	MOVLW   0x01
	CPFSGT  cordx
	GOTO    test01
	MOVLW   0x02
	CPFSGT  cordx
	GOTO    test02
	MOVLW   0x03
	CPFSGT  cordx
	GOTO    test03
	MOVLW   0x04
	CPFSGT  cordx
	GOTO    test04
	MOVLW   0x05
	CPFSGT  cordx
	GOTO    test05
	MOVLW   0x06
	CPFSGT  cordx
	GOTO    test06
	test01:
	    BTFSS   PORTF,0
	    GOTO    GOAL1
	    COMF    direc
	    GOTO    aaa
	test02:
	    BTFSS   PORTF,1
	    GOTO    GOAL1
	    COMF    direc
	    GOTO    aaa
	test03:
	    BTFSS   PORTF,2
	    GOTO    GOAL1
	    COMF    direc
	    GOTO    aaa
	test04:
	    BTFSS   PORTF,3
	    GOTO    GOAL1
	    COMF    direc
	    GOTO    aaa
	test05:
	    BTFSS   PORTF,4
	    GOTO    GOAL1
	    COMF    direc
	    GOTO    aaa
	test06:
	    BTFSS   PORTF,5
	    GOTO    GOAL1
	    COMF    direc
	    GOTO    aaa
    checkpad02:
	MOVLW   0x01
	CPFSGT  cordx
	GOTO    test011
	MOVLW   0x02
	CPFSGT  cordx
	GOTO    test022
	MOVLW   0x03
	CPFSGT  cordx
	GOTO    test033
	MOVLW   0x04
	CPFSGT  cordx
	GOTO    test044
	MOVLW   0x05
	CPFSGT  cordx
	GOTO    test055
	MOVLW   0x06
	CPFSGT  cordx
	GOTO    test066
	test011:
	    BTFSS   PORTA,0
	    GOTO    GOAL2
	    COMF    direc
	    GOTO    aaa
	test022:
	    BTFSS   PORTA,1
	    GOTO    GOAL2
	    COMF    direc
	    GOTO    aaa
	test033:
	    BTFSS   PORTA,2
	    GOTO    GOAL2
	    COMF    direc
	    GOTO    aaa
	test044:
	    BTFSS   PORTA,3
	    GOTO    GOAL2
	    COMF    direc
	    GOTO    aaa
	test055:
	    BTFSS   PORTA,4
	    GOTO    GOAL2
	    COMF    direc
	    GOTO    aaa
	test066:
	    BTFSS   PORTA,5
	    GOTO    GOAL2
	    COMF    direc
	    GOTO    aaa

ball_interrupt: ;calls BALL_OFF BALL_ON then calls exit
        call    BALL_OFF
        call    BALL_ON
        goto    timer_interrupt_exit

timer_interrupt_exit:
        bcf     INTCON,2            ;Clear TMROIF
        movlw	d'61'               ;256-61=195; 195*256*6 = 301056 instruction cycle;
        movwf	TMR0
        call	restore_registers   ;Restore STATUS and PCLATH registers to their state before interrupt occurs
        retfie

GOAL1 ;player 1 scored
    INCF    score1
    MOVLW   0x05
    CPFSLT  score1
    GOTO    GAME_OVER ;GAME IS OVER
    GOTO    START_NOW
GOAL2 ;player 2 scored
    INCF    score2
    MOVLW   0x05
    CPFSLT  score2
    GOTO    GAME_OVER ;GAME IS OVER
    GOTO    START_NOW

GAME_OVER
    CLRF    PORTA
    CLRF    PORTB
    CLRF    PORTC
    CLRF    PORTD
    CLRF    PORTE
    CLRF    PORTF
    call    DISP
    call    DELAY
    call    DISP2
    call    DELAY
    GOTO    GAME_OVER

DELAY	; Time Delay Routine with 3 nested loops (5ms)
    MOVLW 0x01	; Copy desired value to W
    MOVWF t3	; Copy W into t3
    _loop3:
	MOVLW 0x68  ; Copy desired value to W
	MOVWF t2    ; Copy W into t2
	_loop2:
	    MOVLW 0x9F	; Copy desired value to W
	    MOVWF t1	; Copy W into t1
	    _loop1:
		decfsz t1,F ; Decrement t1. If 0 Skip next instruction
		GOTO _loop1 ; ELSE Keep counting down
		decfsz t2,F ; Decrement t2. If 0 Skip next instruction
		GOTO _loop2 ; ELSE Keep counting down
		decfsz t3,F ; Decrement t3. If 0 Skip next instruction
		GOTO _loop3 ; ELSE Keep counting down
		return

DISP
    COMF    turn
    MOVLW   0x01
    MOVWF   PORTH
    MOVF   score1,w	; prepare WREG before table lookup
    CALL    TABLE	; score1's bit settings for 7-seg. disp. returned into WREG
    MOVWF   LATJ	; apply correct bit settings to portJ (7-seg. disp.)
    return
DISP2
    COMF    turn
    MOVLW   0x04
    MOVWF   PORTH
    MOVF   score2,w	; prepare WREG before table lookup
    CALL    TABLE	; score2's bit settings for 7-seg. disp. returned into WREG
    MOVWF   LATJ	; apply correct bit settings to portJ (7-seg. disp.)
    return

BALL_OFF
    CLRF    PORTB
    CLRF    PORTC
    CLRF    PORTD
    CLRF    PORTE
    return

BALL_ON
    MOVLW   0x01
    CPFSGT  cordy
    GOTO    stateA_
    MOVLW   0x02
    CPFSGT  cordy
    GOTO    stateB_
    MOVLW   0x03
    CPFSGT  cordy
    GOTO    stateC_
    MOVLW   0x04
    CPFSGT  cordy
    GOTO    stateD_
    MOVLW   0x05
    CPFSGT  cordy
    GOTO    stateE_
    MOVLW   0x06
    CPFSGT  cordy
    GOTO    stateF_
    return
    stateA_:
        MOVLW   0x01
        CPFSGT  cordx
        GOTO    stateA1_
        MOVLW   0x02
        CPFSGT  cordx
        GOTO    stateA2_
        MOVLW   0x03
        CPFSGT  cordx
        GOTO    stateA3_
        MOVLW   0x04
        CPFSGT  cordx
        GOTO    stateA4_
        MOVLW   0x05
        CPFSGT  cordx
        GOTO    stateA5_
        MOVLW   0x06
        CPFSGT  cordx
        GOTO    stateA6_
        stateA1_:
            MOVLW 0x01
            MOVWF PORTA
            return
        stateA2_:
            MOVLW 0x02
            MOVWF PORTA
            return
        stateA3_:
            MOVLW 0x04
            MOVWF PORTA
            return
        stateA4_:
            MOVLW 0x08
            MOVWF PORTA
            return
        stateA5_:
            MOVLW 0x10
            MOVWF PORTA
            return
        stateA6_:
            MOVLW 0x20
            MOVWF PORTA
            return
    return

    stateB_:
        MOVLW   0x01
        CPFSGT  cordx
        GOTO    stateB1_
        MOVLW   0x02
        CPFSGT  cordx
        GOTO    stateB2_
        MOVLW   0x03
        CPFSGT  cordx
        GOTO    stateB3_
        MOVLW   0x04
        CPFSGT  cordx
        GOTO    stateB4_
        MOVLW   0x05
        CPFSGT  cordx
        GOTO    stateB5_
        MOVLW   0x06
        CPFSGT  cordx
        GOTO    stateB6_
        stateB1_:
            MOVLW 0x01
            MOVWF PORTB
            return
        stateB2_:
            MOVLW 0x02
            MOVWF PORTB
            return
        stateB3_:
            MOVLW 0x04
            MOVWF PORTB
            return
        stateB4_:
            MOVLW 0x08
            MOVWF PORTB
            return
        stateB5_:
            MOVLW 0x10
            MOVWF PORTB
            return
        stateB6_:
            MOVLW 0x20
            MOVWF PORTB
            return
    return

    stateC_:
        MOVLW   0x01
        CPFSGT  cordx
        GOTO    stateC1_
        MOVLW   0x02
        CPFSGT  cordx
        GOTO    stateC2_
        MOVLW   0x03
        CPFSGT  cordx
        GOTO    stateC3_
        MOVLW   0x04
        CPFSGT  cordx
        GOTO    stateC4_
        MOVLW   0x05
        CPFSGT  cordx
        GOTO    stateC5_
        MOVLW   0x06
        CPFSGT  cordx
        GOTO    stateC6_
        stateC1_:
            MOVLW 0x01
            MOVWF PORTC
            return
        stateC2_:
            MOVLW 0x02
            MOVWF PORTC
            return
        stateC3_:
            MOVLW 0x04
            MOVWF PORTC
            return
        stateC4_:
            MOVLW 0x08
            MOVWF PORTC
            return
        stateC5_:
            MOVLW 0x10
            MOVWF PORTC
            return
        stateC6_:
            MOVLW 0x20
            MOVWF PORTC
            return
    return

    stateD_:
        MOVLW   0x01
        CPFSGT  cordx
        GOTO    stateD1_
        MOVLW   0x02
        CPFSGT  cordx
        GOTO    stateD2_
        MOVLW   0x03
        CPFSGT  cordx
        GOTO    stateD3_
        MOVLW   0x04
        CPFSGT  cordx
        GOTO    stateD4_
        MOVLW   0x05
        CPFSGT  cordx
        GOTO    stateD5_
        MOVLW   0x06
        CPFSGT  cordx
        GOTO    stateD6_
        stateD1_:
            MOVLW 0x01
            MOVWF PORTD
            return
        stateD2_:
            MOVLW 0x02
            MOVWF PORTD
            return
        stateD3_:
            MOVLW 0x04
            MOVWF PORTD
            return
        stateD4_:
            MOVLW 0x08
            MOVWF PORTD
            return
        stateD5_:
            MOVLW 0x10
            MOVWF PORTD
            return
        stateD6_:
            MOVLW 0x20
            MOVWF PORTD
    return

    stateE_:
        MOVLW   0x01
        CPFSGT  cordx
        GOTO    stateE1_
        MOVLW   0x02
        CPFSGT  cordx
        GOTO    stateE2_
        MOVLW   0x03
        CPFSGT  cordx
        GOTO    stateE3_
        MOVLW   0x04
        CPFSGT  cordx
        GOTO    stateE4_
        MOVLW   0x05
        CPFSGT  cordx
        GOTO    stateE5_
        MOVLW   0x06
        CPFSGT  cordx
        GOTO    stateE6_
        stateE1_:
            MOVLW 0x01
            MOVWF PORTE
            return
        stateE2_:
            MOVLW 0x02
            MOVWF PORTE
            return
        stateE3_:
            MOVLW 0x04
            MOVWF PORTE
            return
        stateE4_:
            MOVLW 0x08
            MOVWF PORTE
            return
        stateE5_:
            MOVLW 0x10
            MOVWF PORTE
            return
        stateE6_:
            MOVLW 0x20
            MOVWF PORTE
            return
    return

    stateF_:
        MOVLW   0x01
        CPFSGT  cordx
        GOTO    stateF1_
        MOVLW   0x02
        CPFSGT  cordx
        GOTO    stateF2_
        MOVLW   0x03
        CPFSGT  cordx
        GOTO    stateF3_
        MOVLW   0x04
        CPFSGT  cordx
        GOTO    stateF4_
        MOVLW   0x05
        CPFSGT  cordx
        GOTO    stateF5_
        MOVLW   0x06
        CPFSGT  cordx
        GOTO    stateF6_
        stateF1_:
            MOVLW 0x01
            MOVWF PORTF
            return
        stateF2_:
            MOVLW 0x02
            MOVWF PORTF
            return
        stateF3_:
            MOVLW 0x04
            MOVWF PORTF
            return
        stateF4_:
            MOVLW 0x08
            MOVWF PORTF
            return
        stateF5_:
            MOVLW 0x10
            MOVWF PORTF
            return
        stateF6_:
            MOVLW 0x20
            MOVWF PORTF
            return
    return

BUTTON_TASK_RG0
    BTFSC   PORTG,0
    GOTO    rgfirst
    CLRF    rg0
    return
    rgfirst:
        MOVLW   0x00
        CPFSEQ  rg0
        return
        MOVLW   0x38
        CPFSLT  stateF
        return
        RLNCF   stateF,1
        MOVF    stateF,0
        MOVWF   PORTF
        COMF    rg0
        return

BUTTON_TASK_RG1
    BTFSC   PORTG,1
    GOTO    rgsecond
    CLRF    rg1
    return
    rgsecond:
        MOVLW   0x00
        CPFSEQ  rg1
        return
        MOVLW   0x07
        CPFSGT  stateF
        return
        RRNCF   stateF,1
        MOVF    stateF,0
        MOVWF   PORTF
        COMF    rg1
        return

BUTTON_TASK_RG2
    BTFSC   PORTG,2
    GOTO    rgthird
    CLRF    rg2
    return
    rgthird:
        MOVLW   0x00
        CPFSEQ  rg2
        return        
        MOVLW   0x38
        CPFSLT  stateA
        return
        RLNCF   stateA,1
        MOVF    stateA,0
        MOVWF   PORTA
        COMF    rg2
        return

BUTTON_TASK_RG3
    BTFSC   PORTG,3
    GOTO    rgforth
    CLRF    rg3
    return
    rgforth:
        MOVLW   0x00
        CPFSEQ  rg3
        return
        MOVLW   0x07
        CPFSGT  stateA
        return
        RRNCF   stateA,1
        MOVF    stateA,0
        MOVWF   PORTA
        COMF    rg3
        return

save_registers:
    movwf 	w_temp          ;Copy W to TEMP register
    swapf 	STATUS, w       ;Swap status to be saved into W
    clrf 	STATUS          ;bank 0, regardless of current bank, Clears IRP,RP1,RP0
    movwf 	status_temp     ;Save status to bank zero STATUS_TEMP register
    movf 	PCLATH, w       ;Only required if using pages 1, 2 and/or 3
    movwf 	pclath_temp     ;Save PCLATH into W
    clrf 	PCLATH          ;Page zero, regardless of current page
    return

restore_registers:
    movf 	pclath_temp, w  ;Restore PCLATH
    movwf 	PCLATH          ;Move W into PCLATH
    swapf 	status_temp, w  ;Swap STATUS_TEMP register into W
    movwf 	STATUS          ;Move W into STATUS register
    swapf 	w_temp, f       ;Swap W_TEMP
    swapf 	w_temp, w       ;Swap W_TEMP into W
    return

TABLE
    MOVWF check
    MOVLW 0x00
    CPFSGT check
    RETLW b'00111111' ;0 representation in 7-seg. disp. portJ
    MOVLW 0x01
    CPFSGT check
    RETLW b'00000110' ;1 representation in 7-seg. disp. portJ
    MOVLW 0x02
    CPFSGT check
    RETLW b'01011011' ;2 representation in 7-seg. disp. portJ
    MOVLW 0x03
    CPFSGT check
    RETLW b'01001111' ;3 representation in 7-seg. disp. portJ
    MOVLW 0x04
    CPFSGT check
    RETLW b'01100110' ;4 representation in 7-seg. disp. portJ
    MOVLW 0x05
    CPFSGT check
    RETLW b'01101101' ;5 representation in 7-seg. disp. portJ

END