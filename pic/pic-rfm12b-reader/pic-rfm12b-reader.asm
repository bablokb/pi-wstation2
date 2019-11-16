; ############################################################
; Datei: uartw2.asm	        			Steinau, 03.09.19
; Wetter-Teilprojekt UART
; ############################################################
; ############################################################
; A: LCD-Anzeige, mit TC1602 mit Adapter Wartung, o.k.
; B: Teil 3, RFM-Epfang integrieren
; ############################################################
; Kennungen:	Ort (Beispiele von mir):
; 213dez	Garage, Balkon
; 205dez	Gästezimmer		
; 198dez	Wohnzimmer
; 219dez 	Gefrierschrank		
; usw.
;
; ############################################################
; ############################################################
;
; Senden der Wetterstationsdaten 5 Bytes vom PIC zum Raspi 
; per EUSART-Modul des PIC 16F690.
; RX = RB5, TX => RB7	o.K.
;
; Quarz 4 MHz (mit _INTOSCIO)
; 
; ############################################################
;
; Bestueckung des Gesamtprojekts (incl. SPI mit RFM12):
; Pull-up-Widerstand fuer RA5 (Jumper I2CENA), 
; kein I-O-C an Port A und B.
;
; Port A:
; 	RA0	Ausgang, ICSP: DAT
;	RA1	Ausgang, ICSP: CLK
;	RA2	Ausgang, frei
;	RA3	MCLR\
;	RA4	Ausgang, o.C., frei
;	RA5	Eingang, I2CENA=0: erlaubt RC6-3 Software-I2C
;
; Port B:	Funkmodul, siehe auch RC7 und UART
;	RB4	Eingang, SDI an SDO des Funkmoduls, rfsdo
;	RB5	Eingang, RX (Empfaenger: Jumper gruen)
;	RB6	Ausgang, SCK
;	RB7	Eingang, TX (Sender: Jumper gelb)
;
; Port C:	
;	Software-I2C-Modul fuer Pruefzwecke mit ext. Adapter
;	(Wenn RA5=1, Modul deaktiviert, RC6-3 wenn nicht beschal-
;	tet wegen Aufladungsgefahr alle 4 Pins Ausgaenge ! )
;
;	RC0	Ausgang, LED gruen / 1k
;	RC1	Ausgang, LED rot / 1k,  <= deaktiviert
;	RC2	Ausgang, nSEL des RFM
;	RC3	Ausgang, frei / SCL in
;	RC4	Ausgang, frei / SDA out
;	RC5	Ausgang, frei / SDA in
;	RC6	Ausgang, frei / SCL out
;	RC7	Ausgang, SDO an SDI des Funkmoduls
;
; 4 MHz-Quarz - interner Takt 1 MHz / Tintosc= 1 µs 
;
; Master Rev 0, SPI Mode 0,0
;
; Sendefrequenz 868,55 MHz (F=1710 dez = 6AE hex), 
; SRD 868,0-868,6 MHz: fuer allgem. Nutzung, max. ERP 25mW
; / dc<1%, +-30 KHz Frequenzhub (M=1), 
; moeglichst kleine Sendeleistung -17 dB (P=7)
; verbaut  RFM12B, Version A 1.0
; (PLL Setting Command CC77 hex = default).
; 
; Autor: Dipl.-Ing. Lothar Hiller
;
; ############################################################
;
	list p=16F690
	#include <P16F690.INC>
	errorlevel -302
	radix hex
;
; PIC-Konfiguration:
; ext. Reset an Pin 1 (MCLR) enable, INTOSCIO, sowie 72ms
; Verzoegerung fuer RFM, alle anderen Config-Funktionen OFF:
 __CONFIG  _MCLRE_ON & _INTOSCIO & _PWRTE_ON & _BOR_OFF & _WDT_OFF & _CP_OFF & _FCMEN_OFF & _IESO_OFF
;
; ############################################################
; Register-Adressbereich Bank0 von 0x20 bis 07f
; Zeitverzoegerungen, Modul: quarz_4MHz.inc
miniteil	equ	0x20	
miditeil	equ	0x21	
maxiteil	equ	0x22
time0		equ	0x23
time1		equ	0x24
time2		equ	0x25
;
; RFM12- / UART-Variablen:
rxbyte1		equ	0x27
rxbyte2		equ	0x28
rxbyte3		equ	0x29
rxbyte4		equ	0x2a
rxbyte5		equ	0x2b
rxbyte6		equ	0x2c
;
f0			equ	0x30
f1			equ	0x31
passwort1	equ	0x32
passwort2	equ	0x33
passwort3	equ	0x34
passwort4	equ	0x35
hibyte		equ	0x36
lobyte		equ	0x37
;
; Variablen in software_iic.inc
buf			equ	0x40
count		equ	0x41
;
; Variablen in lcdserbus.inc
LcdByte		equ	0x42
LcdDaten	equ	0x43
LcdCon		equ	0x44
LcdStat		equ	0x45
PcfAdr1		equ	0x46
PcfAdr2		equ	0x47
;
; Variablen in LCD_outputs_2.inc
bin8reg		equ	0x48
bitnum		equ	0x49
hexbyte		equ	0x4a
wert		equ	0x4b
;
; noch frei
;
; Variablen in der ISR:
w_temp		equ	0x60
p_temp		equ	0x61
s_temp		equ	0x62
max_temp	equ	0x63
tim1_temp	equ	0x64
tim2_temp	equ	0x65
zeichen		equ	0x66
;

; Matrix, erste Version für vier Sonden:
; aktuelle Daten von Sonde 1
sonde12		equ	0x70
sonde13		equ	0x71
sonde14		equ	0x72
sonde15		equ	0x73
sonde16         equ	0x6c
; aktuelle Daten von Sonde 2
sonde22		equ	0x74
sonde23		equ	0x75
sonde24		equ	0x76
sonde25		equ	0x77
sonde26         equ	0x6d
; aktuelle Daten von Sonde 3
sonde32		equ	0x78
sonde33		equ	0x79
sonde34		equ	0x7a
sonde35		equ	0x7b
sonde36         equ	0x6e
; aktuelle Daten von Sonde 4
sonde42		equ	0x7c
sonde43		equ	0x7d
sonde44		equ	0x7e
sonde45		equ	0x7f
sonde46         equ	0x6f
; Ende Bank0
;
; ############################################################
; #define - Festlegungen:
; ############################################################
; Definitionen zum RFM12:
#define	nsel	PORTC,2		; Aktivierung RFM12 (nSEL)
#define	rfsdo	PORTB,4		; Bereitmeldeltg. SDO des RFM; muß
							; an SDI des PIC16F690, PortB,4
;
; Definitionen zum Software-I2C des LCD:
; (Konstanten fuer I2C, Pin-Belegung PortC festlegen)
;	RC6	CLK	out
;	RC3	CLK	in
;	RC4	SDA	out
;	RC5	SDA	in
#define	SCLi	PORTC,3		; Takt input
#define	SDAo	PORTC,4		; Daten output
#define	SDAi	PORTC,5		; Daten input
#define	SCLo	PORTC,6		; Takt output
#define	SCL		PORTC,6		; Takt
;
; Schalter fuer Software-I2C aktiv/deaktiv:
#define	I2CENA	PORTA,5		; I2CENA=0 erlaubt I2C an RC3-6
;
; LCD-Controller Ein / Aus:
#define	LC1		LcdCon,5	; LCD-Controller (E/E1)
#define	LC2		LcdCon,6	; Lcd-Controller (E2)
;
;LCD-Steuerbyte zum PCF8574 (IC2), TC1602E-01
#define	LcdSRs	LcdByte,4	; RS
#define	LcdSRw	LcdByte,5	; RW
#define	LcdSE1	LcdByte,6	; E/E1
#define	LcdSE2	LcdByte,7	; P3 (E2), hier unbenutzt
;
; LED-Definitionen in der Testphase
#define	LedGn	PORTC,0		; LED gruen / 1k (Main)
;#define	LedRt	PORTC,1		; LED rot / 1k (ISR)
;
; ############################################################
	org	0				; Beginn Initialisierung des PIC
	goto	InitPic
;
	org	4				; Beginn Interruptroutine fuer UART
IsrUart					; alten Status retten
	movwf	w_temp		; w nach w_temp
	swapf	STATUS,w	; STATUS nach status_temp retten
	clrf	STATUS		; Bank0 (clears IRP, RP1, RP0)
	movwf	s_temp
	movf	PCLATH,w	; PCLATH nach p_temp retten
	movwf	p_temp
	clrf	PCLATH
; Anwenderdaten retten
	movf	maxiteil,w	; UP maxitime
	movwf	max_temp
	movf	time2,w		; UP time250ms
	movwf	tim2_temp
	movf	time1,w		; UP time1ms
	movwf	tim1_temp
;
;
; Wenn das Byte "W" vom Pi am RX-Eingang empfangen wird, 
; Daten an den Pi senden.
;
; UART-Empfang:
	btfss	PIR1,RCIF	; wenn RCIF=1, ueberspringe nae. Bef.
	goto	IntEnd		; Fehler-Int.
						; Pruefen, ob Byte "W" ?
	movfw	RCREG		; Empfangsregister auslesen u.
	movwf	zeichen		; in zeichen speichern
	movlw	"W"			; ASCII-Zeichen "W" nach w
	subwf	zeichen,w	; (f) - (w) -> (d),
						; bei (f) = (w) => Z=1
	btfss	STATUS,Z	; wenn Z=1, ueberspr. nae. Bef.
	goto	IntEnd		; es wurde kein "W" gesendet
						; "W" empfangen, Daten senden
;
; Senden der Sondendaten aus der Matrix  per UART:
	call	txmatrix	; Daten per UART zum Raspi
;
IntEnd
; opt. Kontrolle durch LED rot, wenn ISR aktiv: <=deakt.
;	bcf		LedRt		; LED rot an
;	movlw	d'4'		; 4x 250 ms
;	call	maxitime	; warten
;	bsf		LedRt		; LED rot aus
;	movlw	d'4'		; 4x 250 ms
;	call	maxitime	; warten
;
	clrf	PIR1		; alle Int.-Flags loeschen (Bank0)
	clrf	PIR2
;
; alten Status wiederherstellen:
	movf	p_temp,w
	movwf	PCLATH
;
	movf	max_temp,w
	movwf	maxiteil
	movf	tim2_temp,w
	movwf	time2
	movf	tim1_temp,w
	movwf	time1
;
	swapf	s_temp,w
	movwf	STATUS
	swapf	w_temp,f
	swapf	w_temp,w
	retfie				; Ende ISR, zurueck ins Hauptprog.
;
; ###########################################################
;
; Konfiguration des PIC's:
InitPic
	bcf	STATUS,RP1	; Bank0
	bcf	STATUS,RP0
	clrf	PORTA
	clrf	PORTB
	clrf	PORTC
;
; nach POR stehen alle Pins (ANSEL u. ANSELH=1) auf analog !
	bsf	STATUS,RP1	; Bank2
	clrf	ANSEL		; AN0-7 werden digital
	clrf	ANSELH		; AN8-11 werden digital
	clrf	WPUB		; Port B keine pull-ups (auch Bank2)
	bcf	STATUS,RP1	; Bank0
;
	bsf	STATUS,RP0	; Bank1
	clrf	TRISA		; alle Port-A-Pins Ausgangspins
	bsf	TRISA,5		; RA5 Eingang fuer I2CENA
	clrf	TRISB		; alle Port-B-Pins Ausgangspins
	bsf	TRISB,4		; SDI des PIC, Eingang
	clrf	TRISC		; alle Port-C-Pins Ausgangspins
;
; OPTION_REG (BANK1) pull-up erlauben (nach POR alle Bits 1):
	bcf	OPTION_REG,NOT_RABPU	; NOT_RABPU=0, pull-up 
					; Port A+B erlaubt
;
; pull-ups in Ports A (Bank1), Port B (Bank2) einrichten:
	clrf	WPUA		; alle pull-up Port A gesperrt
	bsf	WPUA,WPUA5	; RA5 pull-up erlaubt
				; WPUB siehe unter ANSELH, Bank2
;	
; USART-Anschluesse (Bank1):
	bsf	TRISB,5		; Bit5=1, Eingang (EUSART)
	bsf	TRISB,7		; BIT7=1, Eingang (EUSART)
;
; USART initialisieren, Baudrate 1200 BPS einstellen:
; Empfaenger (RCSTA):	SPEN=1, CREN=1
; Sender (TXSTA):	TXEN=1
; Baudrate (1200 BPS):	SPBRG=51, BRGH=0, Fosz=4 MHz
;
	bcf	STATUS,RP0	; Bank0
	movlw	0x90		; SPEN=1 (Bit 7), CREN=1 (Bit 4),
	movwf	RCSTA		; alle anderen Bits=0 Empfaenger
;
	bsf	STATUS,RP0	; Bank1
	movlw	0x20		; TXEN=1 (Bit 5), alle anderen Bits=0
	movwf	TXSTA		; Sender
;
	movlw	D'51'		; stelle Baudrate 1,2 KBPS bei 4 MHz
	movwf	SPBRG		; und BRGH=0 ein
	bcf	TXSTA,BRGH	; BRGH=0
;
; SPI fuer RFM einrichten:
; Bank1: SSPSTAT=0C0h: Mode 0,0 (b'11000000')
; Bank0: SSPCON=021h: 
; SPI Master mode, SSP=on, 1/16 Tos (b'00100001')
	movlw	0xc0
	movwf	SSPSTAT
;
	bcf	STATUS,RP0	; Bank0
	movlw	0x21
	movwf	SSPCON
;
; Das RFM benötigt ma. 100ms interne Initialisierungszeit,
; bis es Befehle annimmt (Si4421, Seite 11, Tpor)
; _PWERT_ON bewirkt eine erste Verzoegerung von 72ms,
; es muss nun noch ca. 30ms warten:
	movlw	d'30'
	call	miditime	; noch 30ms warten
;
;
; Adressen zum seriellen LCD mit 2x PCF8574:
; PCF-Adr 1, lsb=0 (schreiben zum Slave):
;	movlw	b'01110000'	; LCD mit TC1602 (2x PCF8574AT)
	movlw	b'01000000'	; LCD mit 1 Controller, TC1602
;	movlw	b'01000110'	; LCD mit 1/2 Controller, außer TC1602
	movwf	PcfAdr1		; IC1 Daten Adr.-Register
;
;	movlw	b'01111110'	; LCD mit TC1602 (2x PCF8574AT)
	movlw	b'01001110'	; LCD mit 1 Controller, TC1602
;	movlw	b'01001000'	; LCD mit 1/2 Controller, außer TC1602
	movwf	PcfAdr2		; IC2 Control Adr.-Register
;
; 8Bit-LED-Modul (LOW-Aktiv) an PortC, alle LEDs aus:
;	movlw	0xFF		; alle Pins=1 an Port C,
;	movwf	PORTC		; alle LEDs u. RFM aus
;
; LEDs an PortC und RFM aus (Pin=1):
	bsf	LedGn		; LED gruen aus
;	bsf	LedRt		; LED rot aus
	bsf	nsel		; RFM aus
;
; Passwortzuweisungen:
	movlw	d'213'		; 0xd5
	movwf	passwort1
	movlw	d'205'		; 0xcd
	movwf	passwort2
	movlw	d'198'		; 0xc6
	movwf	passwort3
	movlw	d'219'		; 0xdb
	movwf	passwort4
;
; ############################################################
	call	testdat
; Funkmodul initialisieren:
; (#include	<rfm12b_rx.inc> erforderlich)
; (RFM-UP'e Init u. Empfang)
	call	InitRfm12B
;
; Interrupts erlauben:
	bsf	STATUS,RP0	; Bank1
	bsf	PIE1,RCIE	; Receiver Int. enable
	bcf	STATUS,RP0	; Bank0
;
	clrf	PIR1		; alle Interruptflags löschen
	clrf	PIR2
	bsf	INTCON,GIE	; Globalen Int. erlauben
	bsf	INTCON,PEIE	; Periphere Int. erlauben
;
main
	clrf	f1
	clrf	f0
	clrf	rxbyte1
	clrf	rxbyte2
	clrf	rxbyte3
	clrf	rxbyte4
	clrf	rxbyte5
;
; LED (gruen) einschalten mit LedGn=0:
	bcf	LedGn		; LED gruen ein
;
	call	empfaenger	; Empfang der Sondendaten (5 Byte) in
						; rxbyte1 bis rxbyte5
;
	call	speichern	; empf. Sondendaten in Matrix speich.
;
; Matrix auf LCD ausgeben, wenn I2CENA=0:
	btfss	I2CENA		; wenn I2CENA=1, ueberspr. nae. Bef.
	call	outmatrix	; I2CENA=0, Matrix auf LCD ausgeben
;
; LED (gruen) ausschalten mit LedGn=1:
	bsf	LedGn		; LED gruen aus
	movlw	d'4'		; 4x 250 ms
	call	maxitime	; warten
;
	goto	main
;
;#############################################################
; INCLUDE's fuer Hilfsprogramme:
	#include <quarz_4MHz.inc>	 ; Zeitverzoeg.-UP'e
	#include <rfm12b_rx.inc>	 ; RFM-UP'e (SPI,Init,Empfang)
	#include <software_iic.inc>	 ; Software-I2C fuer 4MHz
	#include <lcdserbus.inc>	 ; LCD (1/2 Contr.) m.2x PCF
	#include <LCD_outputs_2.inc> ; Ausgabe bin/hex auf LCD
;
; ############################################################
; UP'e :
; ############################################################
; UP outmatrix: aktuelle Daten der Matrix bei I2CENA=0 auf LCD
; ausgeben (in Main). EQU's
; ############################################################
outmatrix
	; I2C init., Matrix auf LCD ausgeben:
	bsf	STATUS,RP0	; Bank1
	bsf	TRISC,3		; SCL in, RC3 auf Eingang
	bsf	TRISC,5		; SDA in, RC5 auf Eingang
	bcf	STATUS,RP0	; Bank0
;
	bsf	LC1		; 1. Controller ein
	call	InitLcdSer	; LCD initialisieren
;
	movlw	0x80		; Cursor auf Zeile 1, Spalte 0
	call	OutLcdCon	; positionieren
;
	movf	sonde12,w	; Sonde 1 aufs LCD
	call	HexByteAscii
	movf	sonde13,w
	call	HexByteAscii
	movf	sonde14,w
	call	HexByteAscii
	movf	sonde15,w
	call	HexByteAscii
;
	movf	sonde22,w	; Sonde 2 aufs LCD
	call	HexByteAscii
	movf	sonde23,w
	call	HexByteAscii
	movf	sonde24,w
	call	HexByteAscii
	movf	sonde25,w
	call	HexByteAscii
;
	movlw	0xc0		; Cursor auf Zeile 2, Spalte 0
	call	OutLcdCon	; positionieren
;
	movf	sonde32,w	; Sonde 3 aufs LCD
	call	HexByteAscii
	movf	sonde33,w
	call	HexByteAscii
	movf	sonde34,w
	call	HexByteAscii
	movf	sonde35,w
	call	HexByteAscii
;
	movf	sonde42,w	; Sonde 4 aufs LCD
	call	HexByteAscii
	movf	sonde43,w
	call	HexByteAscii
	movf	sonde44,w
	call	HexByteAscii
	movf	sonde45,w
	call	HexByteAscii
;
	bcf	LC1		; 1. Controller aus
;
; I2C abschalten, Eingang auf Ausgang umschalten:
	bsf	STATUS,RP0	; Bank1
	bcf	TRISC,3		; SCL in, => Ausgang (inaktiv)
	bcf	TRISC,5		; SDA in, => Ausgang (inaktiv)
	bcf	STATUS,RP0	; Bank0
;
	return
;
; ############################################################
; UP txmatrix: aktuelle Daten von 4 Temperatursonden per UART
; zum Raspi senden (in der ISR). EQU's
; ############################################################
txmatrix
outpw1
	btfss	PIR1,TXIF	; 1. Sonde, Kennwort
	goto	outpw1
	movf	passwort1,w
	movwf	TXREG
	nop
;
out12
	btfss	PIR1,TXIF	; Senderegister leer?
	goto	out12		; nein
	movf	sonde12,w	; ja, Byte nach w
	movwf	TXREG		; w nach TXREG (=> sonde12 senden)
	nop
;
out13
	btfss	PIR1,TXIF
	goto	out13
	movf	sonde13,w
	movwf	TXREG		; Byte sonde13 senden
	nop
;
out14
	btfss	PIR1,TXIF
	goto	out14
	movf	sonde14,w
	movwf	TXREG		; Byte sonde14 senden
	nop
;
out15
	btfss	PIR1,TXIF
	goto	out15
	movf	sonde15,w
	movwf	TXREG		; Byte sonde15 senden
	nop
;
out16
	btfss	PIR1,TXIF
	goto	out16
	movf	sonde16,w
	movwf	TXREG		; Fortschrittszähler senden
	nop
;
; ----------------------
outpw2
	btfss	PIR1,TXIF	; 2. Sonde, Kennwort
	goto	outpw2
	movf	passwort2,w
	movwf	TXREG
	nop
;
out22
	btfss	PIR1,TXIF	; Senderegister leer?
	goto	out22		; nein
	movf	sonde22,w	; ja, Byte nach w
	movwf	TXREG		; w nach TXREG (=> sonde22 senden)
	nop
;
out23
	btfss	PIR1,TXIF
	goto	out23
	movf	sonde23,w
	movwf	TXREG		; Byte sonde23 senden
	nop
;
out24
	btfss	PIR1,TXIF
	goto	out24
	movf	sonde24,w
	movwf	TXREG		; Byte sonde24 senden
	nop
;
out25
	btfss	PIR1,TXIF
	goto	out25
	movf	sonde25,w
	movwf	TXREG		; Byte sonde25 senden
	nop
;
out26
	btfss	PIR1,TXIF
	goto	out26
	movf	sonde26,w
	movwf	TXREG		; Fortschrittszähler senden
	nop
;
; ----------------------
outpw3
	btfss	PIR1,TXIF	; 3. Sonde, Kennwort
	goto	outpw3
	movf	passwort3,w
	movwf	TXREG
	nop
;
out32
	btfss	PIR1,TXIF	; Senderegister leer?
	goto	out32		; nein
	movf	sonde32,w	; ja, Byte nach w
	movwf	TXREG		; w nach TXREG (=> sonde32 senden)
	nop
;
out33
	btfss	PIR1,TXIF
	goto	out33
	movf	sonde33,w
	movwf	TXREG		; Byte sonde33 senden
	nop
;
out34
	btfss	PIR1,TXIF
	goto	out34
	movf	sonde34,w
	movwf	TXREG		; Byte sonde34 senden
	nop
;
out35
	btfss	PIR1,TXIF
	goto	out35
	movf	sonde35,w
	movwf	TXREG		; Byte sonde35 senden
	nop
;
out36
	btfss	PIR1,TXIF
	goto	out36
	movf	sonde36,w
	movwf	TXREG		; Fortschrittszähler senden
	nop
;
; ----------------------
outpw4
	btfss	PIR1,TXIF	; 4. Sonde, Kennwort
	goto	outpw4
	movf	passwort4,w
	movwf	TXREG
	nop
;
out42
	btfss	PIR1,TXIF	; Senderegister leer?
	goto	out42		; nein
	movf	sonde42,w	; ja, Byte nach w
	movwf	TXREG		; w nach TXREG (=> sonde42 senden)
	nop
;
out43
	btfss	PIR1,TXIF
	goto	out43
	movf	sonde43,w
	movwf	TXREG		; Byte sonde43 senden
	nop
;
out44
	btfss	PIR1,TXIF
	goto	out44
	movf	sonde44,w
	movwf	TXREG		; Byte sonde44 senden
	nop
;
out45
	btfss	PIR1,TXIF
	goto	out45
	movf	sonde45,w
	movwf	TXREG		; Byte sonde45 senden
	nop
;
out46
	btfss	PIR1,TXIF
	goto	out46
	movf	sonde46,w
	movwf	TXREG		; Fortschrittszähler senden
	nop
;
	return
;
; ############################################################
; UP speichern: Datenspeicherung von vier Temperatursonden
; im Main. EQU's
; ############################################################
speichern
sonde1		; welche Sonde (rxbyte1=Kennung) hat gesendet?
	movf	passwort1,w
	subwf	rxbyte1,w	; (f)-(w) -> (w) ; wenn f = w => Z=1
	btfsc	STATUS,Z	; wenn Z=0, ueberspringe nae. Bef.
	goto	pw1			; Z=1, also f=w, also speichern
;
sonde2
	movf	passwort2,w
	subwf	rxbyte1,w
	btfsc	STATUS,Z
	goto	pw2
;
sonde3
	movf	passwort3,w
	subwf	rxbyte1,w
	btfsc	STATUS,Z
	goto	pw3
;
sonde4
	movf	passwort4,w
	subwf	rxbyte1,w
	btfsc	STATUS,Z
	goto	pw4
;
	return				; Ende des UP bei falschem Passwort
;
pw1						; Werte der Sonde1 speichern
	movf	rxbyte2,w
	movwf	sonde12
	movf	rxbyte3,w
	movwf	sonde13
	movf	rxbyte4,w
	movwf	sonde14
	movf	rxbyte5,w
	movwf	sonde15
	movf	rxbyte6,w
	movwf	sonde16
	return				; Werte Sonde1 gespeichert.
;
pw2						; Werte der Sonde2 speichern
	movf	rxbyte2,w
	movwf	sonde22
	movf	rxbyte3,w
	movwf	sonde23
	movf	rxbyte4,w
	movwf	sonde24
	movf	rxbyte5,w
	movwf	sonde25
	movf	rxbyte6,w
	movwf	sonde26
	return				; Werte Sonde2 gespeichert.
;
pw3						; Werte der Sonde3 speichern
	movf	rxbyte2,w
	movwf	sonde32
	movf	rxbyte3,w
	movwf	sonde33
	movf	rxbyte4,w
	movwf	sonde34
	movf	rxbyte5,w
	movwf	sonde35
	movf	rxbyte6,w
	movwf	sonde36
	return				; Werte Sonde3 gespeichert.
;
pw4						; Werte der Sonde4 speichern
	movf	rxbyte2,w
	movwf	sonde42
	movf	rxbyte3,w
	movwf	sonde43
	movf	rxbyte4,w
	movwf	sonde44
	movf	rxbyte5,w
	movwf	sonde45
	movf	rxbyte6,w
	movwf	sonde46
	return				; Werte Sonde4 gespeichert.
;
; ############################################################
; UP testdat: speichert Daten von vier Temperatursonden
; in der Matrix (im Main). EQU's
; ############################################################
testdat
; Testdaten: Empfangssimulation, ohne Funkmodul
; Sonde1:
	movlw	0x00
	movwf	sonde12		; => sonde12
	movlw	0x00
	movwf	sonde13		; => sonde13
	movlw	0x00
	movwf	sonde14		; => sonde14
	movlw	0x00
	movwf	sonde15		; => sonde15
	movlw	0x00
	movwf	sonde16		; => sonde16
;
; Sonde2:
	movlw	0x00
	movwf	sonde22		; => sonde22
	movlw	0x00
	movwf	sonde23		; => sonde23
	movlw	0x00
	movwf	sonde24		; => sonde24
	movlw	0x00
	movwf	sonde25		; => sonde25
	movlw	0x00
	movwf	sonde26		; => sonde26
;
; Sonde3:
	movlw	0x00
	movwf	sonde32		; => sonde32
	movlw	0x00
	movwf	sonde33		; => sonde33
	movlw	0x00
	movwf	sonde34		; => sonde34
	movlw	0x00
	movwf	sonde35		; => sonde35
	movlw	0x00
	movwf	sonde36		; => sonde36
;
; Sonde4:
	movlw	0x00
	movwf	sonde42		; => sonde42
	movlw	0x00
	movwf	sonde43		; => sonde43
	movlw	0x00
	movwf	sonde44		; => sonde44
	movlw	0x00
	movwf	sonde45		; => sonde45
	movlw	0x00
	movwf	sonde46		; => sonde46
; Ende Testdaten
	return
;
; ############################################################
	end
; ============= Ende Datei uartw2.asm =============
