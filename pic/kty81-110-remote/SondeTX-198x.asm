; Datei: SondeTX-198, mit RFM12B	 Version 1.0 		01.07.2012
; (Ursprung 2TX)
; ###############################################################
; Kennungen:				Strom (Sleep 4,2V) / µA:
; 213dez	Garage			(1Kfz)	1,3
; 205dez	Harald			(2Har)	
; 198dez	Balkon			(3Bal)	1,68
; 219dez	Vorratskammer	(4Vor)
; usw.
; ###############################################################
; am 30.06.2012 o.k. Stromaufnahme im Sleep-Zustand 1,3-1,7 µA.
; Sleep-Zeit unterschiedlich.
; 
; Ausgabe an LCD's mit 2x PCF u. 1 Controller, z.B. 2x16,
; TC1602E: Daten: 0100000 Control: 0100111 O.K. 05.07.2012
; ###############################################################
; Aufgabe:	funktioniert, O.K.
; Ermittlung der Temperatur (16 bit) und "Bordspannung" (16 bit) 
; und senden dieser beiden 16 bit-Werte an die Basisstation in
; der Wohnstube, zur Anzeige beider Werte auf einem LCD-Display. 
; Verwendung einer Kennung (8 bit) zur Erhöhung der Übertragungs-
; sicherheit sowie zur Unterscheidung bei Verwendung mehrerer
; Temperatursonden auf der gleichen Frequenz.
; Sleep-Befehl zum Stromsparen
; WDT weckt den PIC in vorgegeb. Zeitabstand (ca. 5 min ? ) auf:
; T0-Vorteiler dem WDT zuweisen mit 1:128 und WDTCON-Vorteiler
; auf 1:65536 einstellen. WDT= 128*65536/31000 = 271 sec 
; (= 4,5 min Schlafzeit je Zyklus)oder kürzer:
; zB. den WDT-Vorteiler kleiner wählen.
; Betriebsspannung Lipo 1s = 3,0-4,2V,
; für Spannungsmessungen steht eine Uref=2,5V zur Verfügung,
; die über Mosfet für die Messung dazugeschaltet wird. 
; Akkuspannungsmessung über Spannungsteiler 1:2, keine Pegel-
; anpassung PIC RFM, da Betrieb mit 1 Lipozelle (3,0-4,2V).
; ###############################################################
; Bestückung:
; Pull-up-Widerstände ein für Portpin RB7, 
; kein I-O-C für Port A und B.
;
; Port A:
; 	RA0	AN0, ADC-Eingang, halbierte Betriebs-U messen
;	RA1	AN1, Eingang für Uref=2,5V
;	RA2	AN2, ADC-Eingang, Umgebungstemperatur messen
;	RA3	MCLR\
;	RA4	MOSEA, Digital-Ausg.mit 10K an G v. P-Ch.Mosfet *)
;	RA5	Digitalausg., frei
;
;   *) RA4=1, MOSFET aus (gesperrt), RA4=0, MOSFET ein (leitend)
;
; Port B:	Funkmodul, siehe auch RC7
;	RB4	Eingang SDI an SDO des Funkmoduls
;	RB5	Ausgang nSEL
;	RB6	Ausgang SCK
;	RB7	Eingang I2CENA: RB7=0 erlaubt an RC0-3 Software-I2C
;
; Port C:
;  Software-I2C-Modul für Prüfzwecke über ext. Adapter
;  (Wenn RB7=1, Modul deaktiviert, RC0-3 nicht beschaltet u.
;  wegen Aufladungsgefahr alles als Ausgänge geschaltet ! )
;		RB7=1   / RB7=0, I2C aktiv :
;	RC0	Ausgang, frei
;	RC1	Ausgang, frei
;	RC2	Ausgang, frei 
;	RC3	Ausgang, frei / SCL in
;	RC4	Ausgang, frei / SDA out
;	RC5	Ausgang, frei / SDA in
;	RC6	Ausgang, frei / SCL out
;	RC7	Ausgang SDO an SDI des Funkmoduls
;
; 4 MHz-Quarz - interner Takt 1 MHz / Tintosc= 1 µs 
;
; Master Rev 0, SPI Mode 0,0
;
; Sendefrequenz 868,55 MHz (F=1710 dez = 6AE hex), 
; SRD 868,0-868,6 MHz: für allgem. Nutzung, max. ERP 25mW / dc<1%,
; +-30 KHz Frequenzhub (M=1), 
; möglichst kleine Sendeleistung -17 dB (P=7)
; verbaut  RFM12B, Version A 1.0
; (PLL Setting Command CC77 hex = default).
; 
; Autor: Dipl.-Ing. Lothar Hiller
;#################################################################
;
	list p=16F690
	#include <p16F690.inc>
	errorlevel -302
	radix hex
;
; PIC-Konfiguration:
; ext. Reset über Pin 1 (MCLR) enable, INTOSCIO, sowie 72ms Verzögerung
; für RFM, WDT einschalten, alle anderen Config-Funktionen OFF:
 __CONFIG  _MCLRE_ON & _INTOSCIO & _PWRTE_ON & _BOR_OFF & _WDT_ON & _CP_OFF & _FCMEN_OFF & _IESO_OFF
;
;#################################################################
; UP-Variablen für Zeitverzögerungen, Modul: quarz_xMHz.asm
miniteil	equ	0x20	
miditeil	equ	0x21	
maxiteil	equ	0x22
time0		equ	0x23
time1		equ	0x24
time2		equ	0x25
;
; Registerdefinitionen für SPI/Funkmodul:
hibyte		equ	0x26	;high byte - sent to SPI
lobyte		equ	0x27	;low byte - sent to SPI
;
; Sendebytex (txbytex):
; für Schaltbefehle zum Empfänger:
txbyte1		equ	0x28	;Kennung
txbyte2		equ	0x29	;Bordspannung, high-Teil
txbyte3		equ	0x2a	;Bordspannung, low-Teil
txbyte4		equ	0x2b	;Temperatur, high-Teil
txbyte5		equ	0x2c	;Temperatur, low-Teil
txbyte6		equ	0x5c	;Fortschrittszähler
; Messungen:
OffsetTemp	equ	0x2d	;Korrekturwert für Akku-U-Messung
NrMessung	equ	0x2e	;Zähler für die 64 Temp.-Messungen
Flags		equ	0x2f	;Negativ-Temp.
;
; Registerdefinitionen für Matheroutinen UP math_0.asm:
f0			equ	0x30
f1			equ	0x31
f2			equ	0x32
f3			equ	0x33
xw0			equ	0x34
xw1			equ	0x35
xw2			equ	0x36
xw3			equ	0x37
g0			equ	0x38
g1			equ	0x39
Fehler		equ	0x3a
counter		equ	0x3b
sw0			equ	0x3c
sw1			equ	0x3d
;
;
; Registerdefinitionen für I2C
buf			equ	0x41	; I2C-UP'e
count		equ	0x42	; I2C-UP'e
BcdDaten	equ	0x43	; UP Bcd4Bit
LcdByte		equ 0x44
LcdCon		equ	0x45
LcdDaten	equ	0x46
LcdStat		equ	0x47
;
; I2C-Adressen,  seriell mit 2x PCF8574:
PcfAdr1		equ	0x48	;
PcfAdr2		equ	0x49	;
;
;Register für UP Hex2Dez16 und 8:
HdZT		equ	0x4a
HdT			equ	0x4b
HdH			equ	0x4c
HdZ			equ	0x4d
HdE			equ	0x4e
HdX			equ	0x4f
;
; Definitionen fuer RFM12B:
#define	nsel	PORTB,5	; Aktivierung RFM über nSEL
#define	rfsdo	PORTB,4	; Bereit-Melde-Leitung SDO des Funk-
						; moduls, liegt an SDI des PIC's,
						; also an Port B,4 (Eingang)!
;
; Portpinzuweisung für MOSFET-Gate
#define	MOSEA	PORTA,4
;
;Definitionen für Software-I2C-Portpin's:
;(Konstanten für I2C festlegen, Pinbelegung, für Port C)
; 	RC6	CLK out
;	RC3	CLK in
;	RC4	SDA out	
;	RC5 SDA in
#define	SCLi	PORTC,3		; Takt input
#define	SDAo	PORTC,4		; Daten output
#define	SDAi	PORTC,5		; Daten input
#define	SCLo	PORTC,6		; Takt output
#define	SCL	PORTC,6		; Takt
;
;LCD-Controller-Aktivierung/-Deaktivierung
#define	LC1	LcdCon,5	; 1. LCD-Controller (E/E1)
#define LC2	LcdCon,6	; 2. LCD-Controller (E2), unbenutzt
;
;LCD-Steuerbyte zum PCF8574 (IC2)
#define	LcdSRs	LcdByte,4	; RS
#define	LcdSRw	LcdByte,5	; RW
#define	LcdSE1	LcdByte,6	; E/E1
#define	LcdSE2	LcdByte,6	; E2 hier unbenutzt
#define	LcdBel	LcdByte,7	; Beleuchtung
;
;Schalter fuer Software-I2C-Aktivierung/-Deaktivierung
#define	I2CEN	PORTB,7	; I2CEN=0 erlaubt I2C an RC0-3
;
; Definitionen fÃ¼r die Messungen:
#define	Negativ		Flags,6	; Flags,6 = 1, Temperatur negativ
#define	TempVorz	f1,7	; Temperaturvorz. der Sonde
;
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
; der Wert offset dient zur Kalibrierung der Temperaturmessung,
; der Standardwert ist 150 dezimal;
; zeigt der PIC eine um xÂ°C zu hohe Temperatur an,
; muss offset um x erhÃ¶ht werden.
;
; der Wert OffsetUx dient der Kalibrierung der Spannungsmessung,
; der Standard ist 40 (mV);
; zeigt der PIC eine um x mV zu kleine Spannung an, 
; muÃ Offset um x erhÃ¶ht werden.
;
; OFFSETs der Sonde Nr. 198:
#define	OffsetT1	d'151'	; Offset des PTC
#define	OffsetU1	d'35'	; 16+19 Offset in mV U-Messung
;
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;
; Hauptprogramm:
	org	0x00
	goto	InitPic
;
	org	0x04
; Platz für ISR-Sprungbefehl
;
	org	0x06
; Platz für Sprungtabellen
;
; Konfiguration der PIC-Ports:
InitPic
	; Bank0
	bcf		STATUS,RP1
	bcf		STATUS,RP0
	clrf	PORTA
;
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
; Kennungen der Sonden:
	movlw	d'198'			; Dez. Sonden Nr. 198
	movwf	txbyte1			; Kennung
;
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
; Bank2, Register ANSEL, ANSELH: 
	; nach POR stehen alle Bits auf 1 (1 = analog, 0 = digital)
	bsf		STATUS,RP1
	clrf	ANSEL		; AN0-7 digital I/O => RA0-7
	bsf		ANSEL,ANS0	; RA0 => AN0 (U-Mess.)
	bsf		ANSEL,ANS1	; RA1 => AN1 (Uref)
	bsf		ANSEL,ANS2	; RA2 => AN2 (Temp.mess.)
	clrf	ANSELH		; AN8-11 digital I/O
	; Bank1
	bcf		STATUS,RP1
	bsf		STATUS,RP0
	movlw	b'00000111'	; (Analog-) Eingaenge fuer AN0-2,
                                ; (Digital-) siehe ANSEL) Eing. RA5,
	movwf	TRISA		; der Rest Ausgänge
	movlw	b'00010000'	; RB4/SDI ist Eingang, für RFM
	movwf	TRISB
	clrf	TRISC		; alles Ausgänge
; Bank1, OPTION_REG
	; nach POR stehen alle bits des OPTION-Registers auf 1
	bcf		OPTION_REG,NOT_RABPU
                       ; bit 7 = 0, NOT_RABPU=0, PortA-B-pullups enable,
				; Achtung: gilt für beide Ports !
				; bit 3 = 1, Vorteilerzuweisung zum WDT (PSA)
				; bit  2:0 = 111, WDT-Vorteiler 1:128
; Interrupt on change an PortA
	; NOT_RABPU im OPTION_REG muß erlaubt sein !
	; pull-up-Widerstände einschalten, 1=enable
	; alle Bits des Registers WPUA sind nach POR gesetzt !
	clrf	WPUA		; alle pull-ups disabled
;
; Int.-On-Change für Portpin auswählen, 1=enable
	; Register IOCA ist nach POR gelöscht
;
; für PortB für RB7 ein pull-up aktivieren u. keine I-O-C:
	; Bank2
	bsf		STATUS,RP1
	bcf		STATUS,RP0
	; alle Bits von WPUB sind nach POR gesetzt!
	clrf	WPUB		; keine pull-ups für PortB
	bsf	WPUB,WPUB7	; nur RB7 pull-up
	;  IOCB ist nach POR gelöscht, also kein I-O-C
;
; Konfiguration des ADC an AN0 Meßeingang, AN1 Ref.-U-Eingang:
	;Bank0
	bcf		STATUS,RP1
	movlw	b'11000000' ; Daten rechtsbünd., Vref, AN0, ADC aus
	movwf	ADCON0
	; Bank1
	bsf		STATUS,RP0
	; nach POR sind alle bits von ADCON1 gelöscht
	bsf		ADCON1,ADCS0 ; ADC-Takt Fosz/8
	; kein ADC-Interrupt, weil Bit ADIE in Reg. PIE1 
	; nach POR gelöscht ist.
;
; WDT= 128*4096/31000 = 17 sec  /
; = 4,5 min Schlafzeit je Zyklus):
; WDT= 128*("WDT-Tf")/31000 = in sec Schlafzeit je Zyklus
;  WDTPS	WDT-Tf          Zyklus	WDTPS	WDT-Tf	Zyklus
;  <3:0>                        sec	<3:0>		sec
;  0000 1:32                    0,13	0110	1:2048	8,5
;  0001 1:64                    0,26	0111	1:4096	17
;  0010 1:128                   0,53	1000	1:8192	34
;  0011 1:256                   1,1	1001	1:16384	68
;  0100 1:512 (nach Reset)      2,1	1010	1:32768	135
;  0101 1:1024			4,2	1011	1:65536	271
; Die Zeiten sind von PIC zu PIC unterschiedlich (Toleranzen):
       movlw   b'00010111'     ; WDT-Teilerfaktor 1:65536 (=271Sek)
;        movlw   b'00001011'     ; WDT-Teilerfaktor 1:1024 (=4,2 Sek)
	movwf	WDTCON          ; SWDTEN (Bit 0) = 1
;
; Konfiguration MSSP für SPI-Mode 0,0
	movlw	0xc0		; SPI-Mode 0,0
	movwf	SSPSTAT
	; Bank0
	bcf	STATUS,RP0
	movlw	0xff		; alle Ausgangspins auf high
	movwf	PORTB		; 
	movwf	PORTC		; nSEL=1, RFM deaktiviert
;
; Konfiguration SPI als Master, Takt Fosz/16, SSP einschalten
	movlw	0x21		; SPI Master mode, Takt=1: Fosz/16
						; (oder =0: Fosz/4)
	movwf	SSPCON		; SSP ist on
;
; Funkmodul aktivieren:
	movlw	d'30'		; 100-72=28 ms, also noch ca. 30 ms
	call	miditime	; warten wegen RFM12B (gesamt 100ms!)
	call	InitRfm12B	; Sendefrequenz fo= 868,25 MHz
	;Funkmodul bereit
;
; I2C-Adressen des LCD-Moduls mit 2x PCF8574:
; PCF-Adr. 1, lsb=0 (schreiben zum Slave):
	movlw	b'01000000'	; LCD mit 1 Controller
;	movlw	b'01000110'	; LCD mit 2 Controllern 
	movwf	PcfAdr1		; IC1 Daten Adr.-Register
;
	movlw	b'01001110'	; LCD mit 1 Controller
;	movlw	b'01001000'	; LCD mit 2 Controllern
	movwf	PcfAdr2		; IC2 Control Adr.-Register
;
;
; Power Management Command 0x8201 an RFM, Sleep-Modus einnehmen
	movlw	0x82
	movwf	hibyte
	movlw	0x01
	movwf	lobyte
	call	spi16		; RFM im Sleep-Modus
        clrf    txbyte6         ; Fortschrittszähler zurücksetzen
;
; Schalter für I2C Ein/Aus:
	btfss	I2CEN		; wenn I2CEN=1, überspringe nä. Bef.
	goto	Wartung		; I2CEN=0, Jumper gesteckt, also Wartung
						; I2CEN=1, keine Wartung

; Spannungsmodul abschalten (Uref und U-Meß-Teiler)
	bsf	MOSEA			; MOSEA=1, P-CH. MOSFET aus
;
;################################################################
loop
	clrwdt
; PIC in den Sleep-Modus versetzen	
	sleep
; wecken durch WDT nach der vorprogrammierten Zeit in WDTCON,
; dann weiter bei Pkt. 1.
;
loopW
; 1. an AN0 (RA0) Akkuspannung überprüfen:
	; Spannungsmodul einschalten
	bcf		MOSEA		; MOSEA=0, P-CH. MOSFET ein
	; ADC einschalten
	bsf		ADCON0,ADON	; ADC ein
	; Messung durchführen:
	clrf	f1
	clrf	f0
	clrf	xw1
	clrf	xw0
	call	UMessen1 	; ADC mißt Spannung, wandeln nach xw1, xw0
;
	movf	xw1,w
	movwf	f1
	movf	xw0,W
	movwf	f0
	call	mv			; Startwert und Ergebnis in  in f1, f0
;
; Spannungsteiler- und Meßfühlerkorrektur:
	clrf	xw1
	movlw	OffsetU1
	movwf	xw0
	call	Add16
;	call	Sub16		; 16 bit-Subtraktion: f = f-xw
;
; Umspeichern zum Senden:
	movf	f0,w
	movwf	txbyte2
	movf	f1,w
	movwf	txbyte3		; Meßwert steht nun in txbyte2,3
;
; 2. an AN2 (RA2) Umgebungstemperatur messen:
	bsf		ADCON0,CHS1	; Auswahl Analogkanalbit CHS1=1
	; Messung durchführen:
	clrf	f1
	clrf	f0
	clrf	xw1
	clrf	xw0
	call	TemperaturX1 ; Mehrfach-Temperaturmessung
        incf    txbyte6,f         ; Fortschrittszähler
;
; f1, f0 beinhalten nun die gemessene Temp. (64 Messungen),
; Umrechnung der Messwerte unter Berücksichtigung des
; Meßfühler-Offsets:
	movlw	OffsetT1	; Offsetwert vom Meßfühler nach w
	movwf	OffsetTemp	; umspeichern
	call	TemperaturXS ; Umrechnung Spannung in Sonden-Temp.
;
; umspeichern zum Senden:
	movf	f0,W
	movwf	txbyte4
	movf	f1,W
	movwf	txbyte5		; Meßwert steht nun in txbyte4,5
;
; ADC wieder auf AN0 umschalten, ADC ausschalten
; und Spannungsmodul abschalten:
	bcf	ADCON0,CHS1		; Auswahl Analogkanalbit CHS1=0
	bcf	ADCON0,ADON 	; ADC aus
	bsf	MOSEA			; MOSEA=1, P-CH. MOSFET aus
;
; ################################################################
	btfss	I2CEN		; wenn I2CEN=1, überspringe nä. Bef.
	goto	LcdAusgabe	;I2CEN=0
						;I2CEN=1
rfm_wecken
; RFM aufwecken:
	; Power Management Command 0x8258 weckt das RFM auf
	movlw	0x82
	movwf	hibyte
	movlw	0x58		; ex, ebb, es einschalten
	movwf	lobyte
	call	spi16
	; Wartezeit (lt. Si4421, S. 11, Tsxmax=7ms),
	; bis RFM bereit ist:
	movlw	d'7'
	call	miditime	; 7 ms warten
; Daten senden
	call	senden		; Übertragung von txbyte1-5
;
; Funkmodul schlafen legen
	; Power Management Command 0x8201 an RFM
	movlw	0x82
	movwf	hibyte
	movlw	0x01
	movwf	lobyte
	call	spi16		; RFM im Sleep-Modus
;
	goto	loop		; PIC schlafen legen
;
; ################################################################
Wartung
	bsf		STATUS,RP0	; Bank1
	movlw	b'00101000'	; PortC, Pin 3 u. 5 
	movwf	TRISC		; auf Eingang schalten
	bcf		STATUS,RP0	; Bank0
;
	bsf		LC1			; 1. Controller
	call	InitLcdSer	; initialisieren
	bcf		LC1
;
	bsf		LC1			; 1. Controller ein
	movlw	0x80		; Cursor auf Zeile 1, Spalte 0
	call	OutLcdCon	; einstellen
	movlw	'S'			; Text "Sonde Nr. xxx" ausgeben
	call	OutLcdDat
	movlw	'o'
	call	OutLcdDat
	movlw	'n'
	call	OutLcdDat
	movlw	'd'
	call	OutLcdDat
	movlw	'e'
	call	OutLcdDat
	movlw	' '
	call	OutLcdDat
	movlw	'N'
	call	OutLcdDat
	movlw	'r'
	call	OutLcdDat
	movlw	'.'
	call	OutLcdDat
	movlw	' '
	call	OutLcdDat
; Sondennummer ausgeben (Kennung):
	movf	txbyte1,w
	movwf	f0
	clrf	f1
	call	OutDez3
	bcf		LC1			; 1. Controller aus
;
	goto	loopW
;
; ################################################################
LcdAusgabe
	bsf	LC1				; Controller1 ein
	movlw	0xc0		; Ausgabe in Zeile 2, ab Spalte 0:
	call	OutLcdCon
;
; Textvorspann:
	movlw	'T'
	call	OutLcdDat
;
; Temperaturausgabe
	movf	txbyte4,w	; Sondentemperaturwert nach f0
	movwf	f0
	movf	txbyte5,w	; Vorzeichen nach f1
	movwf	f1
	call	Vorzeichen	; wenn Minus-Temp. wird Negativ=1 gesetzt
						; (für UP OutMinus) 
	call	OutMinus	; Ausgabe '-', wenn negative Temp.
	call	OutDez3		; 'xxx' - Ausgabe (Umr. in BCD)
	call	OutCelsius	; '°C'
;
;Lipospannung von Sonde1:
	movlw	0xc9		; Zeile 2, ab Spalte 9
	call	OutLcdCon	
	movf	txbyte2,w
	movwf	f0
	movf	txbyte3,w
	movwf	f1
	call	OutDez4		; Daten für UP über f1, f0
	movlw	' '
	call	OutLcdDat
	movlw	'm'
	call	OutLcdDat
	movlw	'V'
	call	OutLcdDat
	bcf	LC1				; Controller1 aus
;
	goto	loopW
;
;################################################################
; INCLUDE für Hilfsprogramme:
	#include <quarz_4MHz.asm>	;Zeitverzög.-UP'e
	#include <math_0.asm>		;Mathematik-UP'e
	#include <software-iic.asm>	;Software-I2C für PIC16Fxxx
	#include <lcdserbus.asm>	;LCD (1/2 Contr.) mit 2x PCF8574
;
;################################################################
; UP'e :
;################################################################
;
;#################################################################
;UP UMessen1: ADC misst Spannung, wandeln nach xw1, xw0 
; >>>>>>>  Messzyklusstart hier mit bsf ADCON0,1  (PIC16F690)  !!
;#################################################################
UMessen1
	clrf	counter
UM_aqui				; 0,3 ms ADC Aquisitionszeit nach Eingangswahl
	decfsz	counter,f
	goto	UM_aqui
;
	bsf	ADCON0,1	; ADC starten
UM_loop
	btfsc	ADCON0,1 ; ist der ADC fertig?
	goto	UM_loop	; nein, weiter warten
	movfw	ADRESH	; obere  2 Bit auslesen
	movwf	xw1		; obere  2-Bit nach xw1
	bsf	STATUS,RP0	; Bank1
	movfw	ADRESL	; untere 8 Bit auslesen
	bcf	STATUS,RP0 	; Bank0
	movwf	xw0		; untere 8-Bit nach xw0
;
	clrf	counter	; warten, damit der ADC sich erholen kann
UM_warten
	decfsz	counter,f
	goto	UM_warten
	return
;
;###############################################################
;UP mv: Wandlung des ADC-Wert in Millivolt (binär)
; Der ADC-Wert steht in f1,f0
; Ergebnis steht in f1,f0
;###############################################################
mv	; zunächst die Multiplikation mal 5
	movf	f0,W
	movwf	xw0
	movf	f1,W
	movwf	xw1
	call	Add16		; f := 2xADC
	call	Add16		; f := 3xADC
	call	Add16		; f := 4xADC
	call	Add16		; f := 5xADC
	; ADC * 5 nach xw kopieren
	movf	f0,W
	movwf	xw0
	movf	f1,W
	movwf	xw1		; xw := 5xADC
	; xw durch 64 dividieren (6 mal durch 2)
	; dann ist xw = 5xADC/64
	movlw	0x06
	call	Div2
	call	Sub16		; f := 5xADC - 5xADC/64
	; xw auf 5xADC/128 verringern
	movlw	0x01
	call	Div2
	call	Sub16		; f := 5xADC - 5xADC/64 - 5xADC/128 
	return
;
;################################################################
;UP'e TemperaturX1,S: Mehrfach-Spannungsmessung am KTY81-110
;1. Temperaturregister (16-Bit) auf 82 setzen (32+50)
;2. 64 mal ADC abfragen, ADC-Wert jeweils zum Temperaturregister
;    addieren (16 Bit Addition)
;3. Temperaturregister durch 101 dividieren (16 Bit Division)
;4. Vom Temperaturregister 150 subtrahieren (16 Bit Subtraktion)
;5. Temperaturregister in BCD umrechen (3-st.), Vorzeichen beacht.
;################################################################
TemperaturX1
	; Startwert für korrektes Runden (32+50)
	clrf	f1
	movlw	D'82'
	movwf	f0
;
	; 64 Messungen
	movlw	D'64'
	movwf	NrMessung
UMessung
	call	UMessen1	; ANx nach xw1,xw0
	call	Add16 		; 16-bit add: f = f + xw
	decfsz	NrMessung,F
	goto	UMessung
	return				; Meßwert steht in f
;
; ################################################################
TemperaturXS			; nur für die Sonden (Vorzeichen)
; Meßwert wird in f übernommen
	; Division durch 101
	movlw	0x00		; 101 = 00 65 h
	movwf	xw1
	movlw	0x65
	movwf	xw0
	call	Div16		; Division f:= f / xw
;
; 150°C Offset entfernen
; (f1)=0, bei Temp.werten bis 255°C ist nur f0 belegt
						; angenommen: positive Temperatur
	clrf	xw1
	movf	OffsetTemp,W
	movwf	xw0
	call	Sub16		; 16 bit f:=f-xw   calc=xw cnt=f;  neg=C
	btfss	STATUS,C
	goto	Positiv
;
	movf	f1,W
	movwf	xw1
	movf	f0,W
	movwf	xw0
	clrf	f1
	clrf	f0	
	call	Sub16		; 16 bit f:=f-xw   calc=xw cnt=f;  neg=C
	bsf	f1,7		; Negatives Vorzeichen senden
Positiv
	return				; Endergebnis in f
;
;###############################################################
; UP Vorzeichen: 
; setzt voraus, das vor UP-Aufruf rxbyte5 (Vorzeichen) 
; nach f1 umgespeichert wurde.
; Je nach Temperatur-Vorzeichen wird Negativ gesetzt (Minuswert)
; oder gelöscht (Plustemperatur).
; #define TempVorz
;###############################################################
Vorzeichen
	btfsc	TempVorz	; wenn TempVorz=0, überspringe nä. Bef.
	goto	minusV		; TempVorz=1: springe zu minusT
	bcf	Negativ		; TempVorz=0: Negativ=0, Temp. positiv
	return
;
minusV		 			; TempVorz=1
	bsf	Negativ 		; Negativ=1, Temp. negativ
	clrf	f1			; muß gelöscht werden, da es im folgenden
					; Ausgabe-UP sonst die Werte verfälscht.
	return
;
;###############################################################
; UP OutMinus,
; Ausgabe eines Minuszeichens, wenn Temperatur negativ ist: 
; Negativ=0, Temp. ist positiv (Leerzeichen ausgeben),
; Negativ=1, Temp. ist negativ (Minuszeichen ausgeben).
;###############################################################
OutMinus	;Flags,6 = Negativ = 1, Temp. ist negativ
	btfsc	Negativ		;wenn Negativ=0, überspringe nä. Bef.
	goto	minusT		; Negativ=1, (Minustemp.)
	movlw	' '			;gebe ein Leerzeichen (Plustemp.)
	call	OutLcdDat	;am LCD aus
	return
;
minusT
	movlw	'-'			;gebe ein Minuszeichen
	call	OutLcdDat	;am LCD aus
	return
;
;==================================
; String '°C' am LCD ausgeben
;==================================
OutCelsius
	movlw	0xdf
	call	OutLcdDat
	movlw	'C'
	call	OutLcdDat
	return
;
;###############################################################
;16 Bit Wert (f1,f0) auf LCD dezimal 4-stellig anzeigen mit Vornullen-Unterdrückung
;###############################################################
OutDez4				;16-bit (f0,f1) als 4-st. Dez (BCD) zum Lcd
	call	Hex2Dez16	;Wandlung
	clrf	Fehler
	movfw	HdT		;1.000er Ausgabe
	call	Vornull		;
	movfw	HdH		;100er Ausgabe
	call	Vornull
	movfw	HdZ		;10er Ausgabe
	call	Vornull
	movfw	HdE		;1er Ausgabe
	Call	Bcd4Bit
	return
;
;################################################################
; 16 Bit Wert (f1,f0) auf LCD dezimal 3-stellig anzeigen mit Vornullen-Unterdrückung
;################################################################
OutDez3				;16-bit (f0,f1) als 3-st. Dez (BCD) zum Lcd
	call	Hex2Dez8	;Wandlung
	clrf	Fehler
	movfw	HdH		;100er Ausgabe
	call	Vornull
	movfw	HdZ		;10er Ausgabe
	call	Vornull
	movfw	HdE		;1er Ausgabe
	Call	Bcd4Bit
	return
;
Vornull
	iorwf	Fehler,F
	movf	Fehler,F	;Test auf 0
	btfss	STATUS,Z	;bisher alles 0 ?
	goto	Bcd4Bit		;nein, UP sichert Rücksprungadr.
	movlw	' '			;ja, Leerzeichen ausgeben
	goto	OutLcdDat	;UP sichert Rücksprungadr.
	;Das return fehlt hier absichtlich, weil die beiden goto-Sprünge zu je
	;einemUP führen, das mit der gespeicherten Rückkehradress. des
	;UP Vornull den Rücksprung sichert.
;
;##############################################################
;UP Bcd4Bit: low-4-Bit als BCD-Zahl (Dez. 0-9) ausgeben
;##############################################################
Bcd4Bit				;low-4 Bit als BCD ausgeben
	movwf	BcdDaten
	movlw	B'00110000'
	ADDwf	BcdDaten,F	;ASCII-wandeln (+48)
	movlw	B'00111010'
	subwf	BcdDaten,W
	btfss	STATUS,C	;Test auf A ... F
	goto	BcdOk
	movlw	.7
	addwf	BcdDaten,F	;korrigiere A...F (+7)
BcdOk
	movfw	BcdDaten
	call	OutLcdDat
	return
;
;###############################################################
; UP Hex2Dez16 und 8: wandelt 16 o. 8-bit (f1, f0)
; in einstell. Dez.zahl. (BCD) um.
;###############################################################
; 16-bit(f1,f0) in 5-stellen Bcd (ZT,T,H,Z,E):
;     10 000 = 0000 2710 h
;      1 000 = 0000 03E8 h
;        100 = 0000 0064 h
;         10 = 0000 000A h
;          1 = 0000 0001 h
;###############################################################
Hex2Dez16			; 16-bit(f1,f0) in 5-stellen Bcd (ZT,T,H,Z,E)				
	movlw	0x27		; 10 000 = 00 00 27 10 h
	movwf	xw1
	clrf	xw2
	movlw	0x10
	movwf	xw0
	call	Hex2Dez1	; 10 000er
	movfw	HdX
	movwf	HdZT
;
	movlw	0x03		; 1 000 = 00 00 03 E8 h
	movwf	xw1
	clrf	xw2
	movlw	0xE8
	movwf	xw0
	call	Hex2Dez1	; 1000er
	movfw	HdX
	movwf	HdT
Hex2Dez8
	movlw	0x00		; 100 = 00 00 00 64 h
	movwf	xw2
	movwf	xw1
	movlw	0x64
	movwf	xw0
	call	Hex2Dez1	; 100er
	movfw	HdX
	movwf	HdH
;
	movlw	0x00		; 10 = 00 00 00 0A h
	movwf	xw2
	movwf	xw1
	movlw	0x0A
	movwf	xw0
	call	Hex2Dez1	; 10er
	movfw	HdX
	movwf	HdZ
;
	movfw	f0
	movwf	HdE
	return
;
Hex2Dez1
	clrf	HdX
	decf	HdX,F
HdLoop
	incf	HdX,F
	call	Sub16		;
	btfss	STATUS,C	;Überlauf
	goto	HdLoop		;Stelle 1 mehr
	call	Add16
	return
;
;################################################################
; UP waitrfm: vor jedem übertragenen Byte muß die Bereitschaft
; des RFM-Moduls abgewartet werden. 
; Def.: #define rfsdo PORTX,4 (PIC-SPI-Eingang SDI) !!
;################################################################
waitrfm
	bcf		nsel		;Modul aktivieren
RfmTest
	nop
	btfss	rfsdo		;wenn rfsdo=1, überspr. nä. Bef.
	goto	RfmTest		;rfsdo=0, weiter warten und testen
	return				;Modul meldet Bereitschaft
;
;################################################################
; UP sendbyte: überträgt ein Byte über die SPI-Schnittstelle
; zum RFM12. Das Sende/Empfangs-Byte in W. 
; keine EQU's!!
;################################################################
sendbyte
	movwf	SSPBUF		;W nach SSPBUF
	bsf		STATUS,RP0	;Bank1
Char0	
	btfss	SSPSTAT,BF	;Data transfer complete? (Buffer full?)
	goto	Char0		;if not, check again
	bcf		STATUS,RP0	;Bank0
	movf	SSPBUF,W	;SSPBUF nach W
	return
;
;################################################################
; UP spi16: 16-bit-Transfer per SPI zum RFM12-Funkmodul.
; Die Bytes müssen vorher in hibyte u. lobyte geladen werden.
; EQU's hibyte, lobyte
;################################################################
spi16
	bcf		nsel		;nSEL=0, Modul aktivieren
	movf	hibyte,W	;highbyte zum Modul
	call	sendbyte
	movf	lobyte,W	;lowbyte zum Modul
	call	sendbyte
	bsf		nsel		;nSEL=1, Modul deaktivieren
	return
;
;################################################################
;UP senden:
; sendet 5 Byte Daten (Meßwerte, Kennung) zur Gegenstelle
;################################################################
;1. Sender Ein 8278h:
senden
	movlw	0x82		;high byte laden
	movwf	hibyte		;W => hibyte
	movlw	0x78		;low byte laden
	movwf	lobyte		;W ==> lobyte
	call	spi16		;hibyte u. lobyte ==> RFM
;
;2. synchronisieren der ALC (3x B8AAh):
	movlw	0xb8		;high byte laden
	movwf	hibyte		;W => hibyte
	movlw	0xaa		;low byte laden
	movwf	lobyte		;W ==> lobyte
;
	call	waitrfm		;auf RFM-Bereitschaft warten
	call	spi16		;hibyte u. lobyte ==> RFM
;
	call	waitrfm		;auf RFM-Bereitschaft warten
	call	spi16		;hibyte u. lobyte ==> RFM
;
	call	waitrfm		;auf RFM-Bereitschaft warten
	call	spi16		;hibyte u. lobyte ==> RFM
;
;2. synchron pattern (2Dh u. D4h):
	movlw	0xb8		;high byte laden
	movwf	hibyte		;W => hibyte
	movlw	0x2d		;low byte laden
	movwf	lobyte		;W ==> lobyte
	call	waitrfm		;auf RFM-Bereitschaft warten
	call	spi16		;hibyte u. lobyte ==> RFM
;
	movlw	0xd4		;low byte laden
	movwf	lobyte		;W ==> lobyte
	call	waitrfm		;auf RFM-Bereitschaft warten
	call	spi16		;hibyte u. lobyte ==> RFM
;
;3. fünf Datenbyte senden:
	movlw	0xb8		;high byte laden
	movwf	hibyte		;W => hibyte
	movf	txbyte1,W	;Sendebyte1 => W		;
	movwf	lobyte		;W ==> lobyte
	call	waitrfm		;auf RFM-Bereitschaft warten
	call	spi16			;hibyte u. lobyte ==> RFM
;
	movf	txbyte2,W	;Sendebyte2 => W		;
	movwf	lobyte		;W ==> lobyte
	call	waitrfm		;auf RFM-Bereitschaft warten
	call	spi16		;hibyte u. lobyte ==> RFM
;
	movf	txbyte3,W	;Sendebyte3 => W		;
	movwf	lobyte		;W ==> lobyte
	call	waitrfm		;auf RFM-Bereitschaft warten
	call	spi16		;hibyte u. lobyte ==> RFM
;
	movf	txbyte4,W	;Sendebyte4 => W		;
	movwf	lobyte		;W ==> lobyte
	call	waitrfm		;auf RFM-Bereitschaft warten
	call	spi16		;hibyte u. lobyte ==> RFM
;
	movf	txbyte5,W	;Sendebyte5 => W		;
	movwf	lobyte		;W ==> lobyte
	call	waitrfm		;auf RFM-Bereitschaft warten
	call	spi16		;hibyte u. lobyte ==> RFM
;
	movf	txbyte6,W	;Sendebyte6 => W		;
	movwf	lobyte		;W ==> lobyte
	call	waitrfm		;auf RFM-Bereitschaft warten
	call	spi16		;hibyte u. lobyte ==> RFM
;
;4. Abspann (2x B8AAh) senden:
	movlw	0xb8		;high byte laden
	movwf	hibyte		;W => hibyte
	movlw	0xaa		;low byte laden
	movwf	lobyte		;W ==> lobyte
	call	waitrfm		;auf RFM-Bereitschaft warten
	call	spi16		;hibyte u. lobyte ==> RFM
;
	call	waitrfm		;auf RFM-Bereitschaft warten
	call	spi16		;hibyte u. lobyte ==> RFM
;
;5. Sender aus 8258h:
	movlw	0x82		;high byte laden
	movwf	hibyte		;W => hibyte
	movlw	0x58		;low byte laden
	movwf	lobyte		;W ==> lobyte
	call	waitrfm		;auf RFM-Bereitschaft warten
	call	spi16		;hibyte u. lobyte ==> RFM
	return
;
;#################################################################
;UP InitRfm12B: überträgt alle Commands Grundeinstellungen über
;SPI zum Funkmodul RFM12B, 868 MHz-Band. EQU's hibyte, lobyte.
;Erst high-Teil (obere 8 bits), dann low-Teil (untere 8 bits)send.
;#################################################################
InitRfm12B
;1. Configuration Setting: 80E7h 
					;el=ef=1 (FSK-Pin mit 10K an +), 868-MHz-Band,
					;erlaubt intern. Data Register u. FIFO-Mode:
	movlw	0x80		;high byte laden
	movwf	hibyte		;W => hibyte
	movlw	0xe7		;low byte laden
	movwf	lobyte		;W ==> lobyte
	call	spi16
;
;2. Power Management: 8258h	
						;ebb=es=ex=1
	movlw	0x82
	movwf	hibyte
	movlw	0x58
	movwf	lobyte
	call	spi16
;
;3. Frequency Setting: A6AEh	
						;Frequenzeinstellung Axxx (hex):
	movlw	0xa6		;fo= 868,55 MHz, Fdez=1710,
	movwf	hibyte		;Fhex=6AE
	movlw	0xae
	movwf	lobyte
	call	spi16
;
;4. Data Rate: C647h
	movlw	0xc6
	movwf	hibyte
	movlw	0x47
	movwf	lobyte
	call	spi16
;
;5. Receiver Control: 94xxh
	movlw	0x94		;Empfaenger-BW 94xx (hex):
	movwf	hibyte		;BW=67KHz: i2:i0=110, g1:g0=00, r2:r0=000
	movlw	0xc0
	movwf	lobyte
	call	spi16
;
;6. Data Filter: C2ACh
	movlw	0xc2
	movwf	hibyte
	movlw	0xac
	movwf	lobyte
	call	spi16
;
;7. FIFO and Reset Mode: CA81h
	movlw	0xca
	movwf	hibyte
	movlw	0x81
	movwf	lobyte
	call	spi16
;
;9. AFC: C483h
	movlw	0xc4
	movwf	hibyte
	movlw	0x83
	movwf	lobyte
	call	spi16
;
;10. TX Configuration Control: 98xxh
	movlw	0x98		;TX Configuration 98MP (hex):
	movwf	hibyte		;Frequ.hub +-30KHz => M=1,
	movlw	0x17		;Psende = -17,5 dB (9 mW) => 111 => P=7
	movwf	lobyte
	call	spi16
;
;12. Wake-Up Timer: E000h
	movlw	0xe0
	movwf	hibyte
	movlw	0x00
	movwf	lobyte
	call	spi16
;
;13. Low Duty-Cycle: C800h
	movlw	0xc8
	movwf	hibyte
	movlw	0x00
	movwf	lobyte
	call	spi16
;
;14. Low Battery Detector...: C0C0h (c0h = 5 MHz am Taktausg.)
	movlw	0xc0
	movwf	hibyte
	movlw	0xc0
	movwf	lobyte
	call	spi16
;
	return
;
;#################################################################
	end
;=============Ende Datei SondeTX-198.asm=============
