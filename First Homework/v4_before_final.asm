#include "p18f8722.inc"
; CONFIG1H
  CONFIG  OSC = HSPLL, FCMEN = OFF, IESO = OFF
; CONFIG2L
  CONFIG  PWRT = OFF, BOREN = OFF, BORV = 3
; CONFIG2H
  CONFIG  WDT = OFF, WDTPS = 32768
; CONFIG3L
  CONFIG  MODE = MC, ADDRBW = ADDR20BIT, DATABW = DATA16BIT, WAIT = OFF
; CONFIG3H
  CONFIG  CCP2MX = PORTC, ECCPMX = PORTE, LPT1OSC = OFF, MCLRE = ON
; CONFIG4L
  CONFIG  STVREN = ON, LVP = OFF, BBSIZ = BB2K, XINST = OFF
; CONFIG5L
  CONFIG  CP0 = OFF, CP1 = OFF, CP2 = OFF, CP3 = OFF, CP4 = OFF, CP5 = OFF
  CONFIG  CP6 = OFF, CP7 = OFF
; CONFIG5H
  CONFIG  CPB = OFF, CPD = OFF
; CONFIG6L
  CONFIG  WRT0 = OFF, WRT1 = OFF, WRT2 = OFF, WRT3 = OFF, WRT4 = OFF
  CONFIG  WRT5 = OFF, WRT6 = OFF, WRT7 = OFF
; CONFIG6H
  CONFIG  WRTC = OFF, WRTB = OFF, WRTD = OFF
; CONFIG7L
  CONFIG  EBTR0 = OFF, EBTR1 = OFF, EBTR2 = OFF, EBTR3 = OFF, EBTR4 = OFF
  CONFIG  EBTR5 = OFF, EBTR6 = OFF, EBTR7 = OFF
; CONFIG7H
  CONFIG  EBTRB = OFF

  ;*******************************************************************************
  ; Variables & Constants
  ;*******************************************************************************
  UDATA_ACS
    t1	res 1	; used in delay
    t2	res 1	; used in delay
    t3	res 1	; used in delay
    state res 1	; controlled by RB5 button
  ;*******************************************************************************
  ; Reset Vector
  ;*******************************************************************************

  RES_VECT  CODE    0x0000            ; processor reset vector
      GOTO    START                   ; go to beginning of program

  ;*******************************************************************************
  ; MAIN PROGRAM
  ;*******************************************************************************

  MAIN_PROG CODE	; let linker place main program


  START
      call INIT	; initialize variables and ports


  MAIN_LOOP

      MOVLW  0x0F   ;To turn on all
      MOVWF  LATA
      MOVWF  LATB
      MOVWF  LATC
      MOVWF  LATD
      call   DELAY     ;2 seconds delay
      call   DELAY
      CLRF   LATC    ;Turn off Led c and d
      CLRF   LATD
      GOTO _state0
      _state0:
      CLRF   PORTA
      CLRF   PORTB
      CLRF   PORTC
      CLRF   PORTD
      MOVLW  0x01
      MOVWF  LATA   ; Changing to the position Ra0-Rb0
      MOVWF  LATB


      call   DELAY_400
      CLRF   WREG	
      CPFSEQ state
      call BUTTON_TASK_2
      CLRF   WREG
      CPFSEQ state
      GOTO   _stateB
      call   DELAY_350
      GOTO   _state1
      _state1:
      CLRF   PORTA
      CLRF   PORTB
      CLRF   PORTC
      CLRF   PORTD
      MOVLW  0x01
      MOVWF  LATB
      MOVWF  LATC

      call   DELAY_400
      CLRF   WREG	; check whether state is 0x00 or 0xFF
      CPFSEQ state
      GOTO   _state0
      call   DELAY_350
      GOTO   _state2
      _state2:
      CLRF   PORTA
      CLRF   PORTB
      CLRF   PORTC
      CLRF   PORTD
      MOVLW  0x01
      MOVWF  LATC
      MOVWF  LATD


      call   DELAY_400
      CLRF   WREG
      CPFSEQ state
      GOTO   _state1
      call BUTTON_TASK_2
      CLRF   WREG
      CPFSEQ state
      GOTO   _state1
      call   DELAY_350
      GOTO   _state3
      _state3:
      CLRF   PORTA
      CLRF   PORTB
      CLRF   PORTC
      CLRF   PORTD
      MOVLW  0x03
      MOVWF  LATD

      call   DELAY_400
      CLRF   WREG
      CPFSEQ state
      call BUTTON_TASK_2
      CLRF   WREG
      CPFSEQ state
      GOTO   _state2
      call   DELAY_350
      GOTO   _state4
      _state4:
      CLRF   PORTA
      CLRF   PORTB
      CLRF   PORTC
      CLRF   PORTD
      MOVLW  0x06
      MOVWF  LATD

      call   DELAY_400
      CLRF   WREG	; check whether state is 0x00 or 0xFF
      CPFSEQ state
      GOTO   _state3
      call   DELAY_350
      GOTO   _state5

      _state5:
      CLRF   PORTA
      CLRF   PORTB
      CLRF   PORTC
      CLRF   PORTD
      MOVLW  0x0C
      MOVWF  LATD

      call   DELAY_400


      CLRF   WREG	; check whether state is 0x00 or 0xFF
      CPFSEQ state
      GOTO   _state4
      call BUTTON_TASK_2
      CLRF   WREG
      CPFSEQ state
      GOTO   _state1
      call   DELAY_350
      GOTO   _state6

      _state6:
      CLRF   PORTA
      CLRF   PORTB
      CLRF   PORTC
      CLRF   PORTD
      MOVLW  0x08
      MOVWF  LATC
      MOVWF  LATD

      call   DELAY_400
      CLRF   WREG
      CPFSEQ state
      call BUTTON_TASK_2
      CLRF   WREG
      CPFSEQ state
      GOTO   _state5
      call   DELAY_350
      GOTO   _state7


      _state7:
      CLRF   PORTA
      CLRF   PORTB
      CLRF   PORTC
      CLRF   PORTD
      MOVLW  0x08
      MOVWF  LATB
      MOVWF  LATC

      call   DELAY_400
      CLRF   WREG	; check whether state is 0x00 or 0xFF
      CPFSEQ state
      GOTO   _state6
      call   DELAY_350
      GOTO   _state8


      _state8:
      CLRF   PORTA
      CLRF   PORTB
      CLRF   PORTC
      CLRF   PORTD
      MOVLW  0x08
      MOVWF  LATA
      MOVWF  LATB



      call   DELAY_400
      CLRF   WREG
      CPFSEQ state
      GOTO   _state7
      call BUTTON_TASK_2
      CLRF   WREG
      CPFSEQ state
      GOTO   _state1
      call DELAY_350
      GOTO   _state9
      _state9:
      CLRF   PORTA
      CLRF   PORTB
      CLRF   PORTC
      CLRF   PORTD
      MOVLW  0x0C
      MOVWF  LATA

      call   DELAY_400
      CLRF   WREG
      CPFSEQ state
      call BUTTON_TASK_2
      CLRF   WREG
      CPFSEQ state
      GOTO   _state8
      call   DELAY_350
      GOTO   _stateA

      _stateA:
      CLRF   PORTA
      CLRF   PORTB
      CLRF   PORTC
      CLRF   PORTD
      MOVLW  0x06
      MOVWF  LATA

      call   DELAY_400
      CLRF   WREG
      CPFSEQ state
      GOTO   _state9
      call   DELAY_350
      GOTO   _stateB
      _stateB:
      CLRF   PORTA
      CLRF   PORTB
      CLRF   PORTC
      CLRF   PORTD
      MOVLW  0x03
      MOVWF  LATA



      call   DELAY_400
      CLRF   WREG
      CPFSEQ state
      GOTO   _stateA
      call   BUTTON_TASK_2
      CLRF   WREG
      CPFSEQ state
      GOTO   _state1
      call   DELAY_350
      GOTO   _state0
      return



      GOTO MAIN_LOOP  ; loop forever

  DELAY
        MOVLW 81
        MOVWF t3
        _loop3:
        MOVLW 0xA0
        MOVWF t2
        _loop2:
  	    MOVLW 0x9F
  	    MOVWF t1
  	    _loop1:
  		decfsz t1,F
  		GOTO _loop1
  		decfsz t2,F
  		GOTO _loop2
  		decfsz t3,F
  		GOTO _loop3
  		return

 DELAY_350	; Time Delay 350 ms
        MOVLW 0x2d
        MOVWF t3
        _loop6:
        MOVLW 0xA0
        MOVWF t2
        _loop5:
  	    MOVLW 0x9F
  	    MOVWF t1
  	    _loop4:
  		decfsz t1,F
  		GOTO _loop4
  		decfsz t2,F
  		GOTO _loop5
  		decfsz t3,F
  		GOTO _loop6
  		return

 DELAY_400	; Time Delay 400 ms
        MOVLW 0x14
        MOVWF t3
        _loop9:
        MOVLW 0x9c
        MOVWF t2
        _loop8:
  	    MOVLW 0x9F
  	    MOVWF t1
  	    _loop7:
  		call BUTTON_TASK_1
        decfsz t1,F
  		GOTO _loop7
  		decfsz t2,F
  		GOTO _loop8
  		decfsz t3,F
  		GOTO _loop9
  		return


  BUTTON_TASK_1 ;reverse
    BTFSS PORTA,4
    return
    _debounce1:
	BTFSC PORTA,4
	goto _debounce1
	BTG state, 0
	return

   BUTTON_TASK_2 ;corner I can change this so can be reversed while waiting
    CLRF WREG
    MOVFF state,WREG ;move state to wreg
    call BUTTON_TASK_1 ;call that whether the state is reversed or not
    CPFSEQ state ;compare the state is changed or not
    return
    BTFSS PORTB,5
    GOTO BUTTON_TASK_2
    _debounce:
	BTFSC PORTB,5
	goto _debounce
	return

  INIT
    CLRF   PORTA
    MOVLW  0xFF
    MOVWF  ADCON1
    MOVLW  b'00010000'
    MOVWF  TRISA
    CLRF   PORTB
    MOVLW  b'00100000'
    MOVWF  TRISB
    CLRF   TRISC
    CLRF   TRISD
    CLRF state
    return


END


