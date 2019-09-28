; ############################################################
; Datei: rfm12b_rx.asm		        		Steinau, 07.07.19
; ############################################################
; ############################################################
; RFM12B-Datei, Init u. Empfaenger
; 
; ############################################################
; ############################################################
;
; fosc = 4 MHz (default), mit internem Oscillator
; ############################################################
;
; Anschluß RFM an PIC-"Motherboard" 16F690:
;
; RFM12B-Pins		PIC-Pins
; Vdd=+3,3V			Vdd=+3,3V
; GNG				GND
; SDO				SDI		RB4
; SDI				SDO		RC7
; CLK				CLK		RB6
; nSEL				RC2
;
; PIC 16F690 muß mit 4MHz laufen
; Autor: Dipl.-Ing. Lothar Hiller
;
; ############################################################
; Initialisierung des Funkmoduls u. Hilfsprogramme
; ############################################################
; Definitionen:
; hibyte, lobyte equ	; RFM benötigt 2 Byte (Commands)
; #define nsel	PORTX,x	; belieb. freies PIC-Portpin,
						; nSEL für RFM12
; #define rfsdo	PORTC,4	; PIC-SDI an RFM12-SDO (PIC16F872)
; oder
; #define rfsdo PORTB,4	; PIC-SDI an RFM12-SDO (PIC16F690)
;
; UP'e:
; ############################################################
; UP waitrfm: vor jedem übertragenen Byte muß die Bereitschaft
; des RFM-Moduls abgewartet werden. 
; Def.: #define rfsdo PORTX,4 (PIC-SPI-Eingang SDI) !!
;#############################################################
waitrfm
	bcf		nsel		; Modul aktivieren
RfmTest	
	nop
	btfss	rfsdo		; wenn rfsdo=1, überspr. nä. Bef.
	goto	RfmTest		; rfsdo=0, weiter warten und testen
	return				; Modul meldet Bereitschaft
;
; ############################################################
; UP sendbyte: uebertraegt 1 Byte per SPI-Schnittstelle zum
; RFM12, das Byte muß in W an das UP uebergeben werden. 
; Nach dem return kann das empf. Byte in W gespeichert werden. 
; keine EQU's!!
; ############################################################
sendbyte
	movwf	SSPBUF		; W nach SSPBUF
	bsf		STATUS,RP0	; Bank1
Char0	
	btfss	SSPSTAT,BF	; Data transfer complete?
	goto	Char0		; if not, check again
	bcf		STATUS,RP0	; Bank0
	movf	SSPBUF,W	; SSPBUF nach W
	return
;
; ############################################################
;UP spi16: 16-bit-Transfer per SPI zum RFM12-Funkmodul,
;Die Bytes vorher in hibyte u. lobyte laden.  EQU's!!
; ############################################################
spi16
	bcf		nsel		; nSEL=0, Modul aktivieren
	movf	hibyte,W	; highbyte zum Modul
	call	sendbyte
	movf	lobyte,W	; lowbyte zum Modul
	call	sendbyte
	bsf		nsel		; nSEL=1, Modul deaktivieren
	return
;
; ############################################################
; UP InitRfm12B: übertraegt alle Commands Grundeinstellungen
; ueber SPI zum Funkmodul RFM12B, 868 MHz-Band. Keine EQU's!!
; Erst high- (obere 8 bits), 
; dann low-Teil senden (untere 8 bits):
; ############################################################
InitRfm12B
;1. Configuration Setting: 80E7h
			; el=ef=1 (FSK-Pin mit 10K an +), 868 MHz-Band
			; erlaubt die internen Data Register u. FIFO-Mode
	movlw	0x80		; high byte laden
	movwf	hibyte		; W => hibyte
	movlw	0xe7		; low byte laden
	movwf	lobyte		; W ==> lobyte
	call	spi16
;
;2. Power Management: 8258h	; ebb=es=ex=1
	movlw	0x82
	movwf	hibyte
	movlw	0x58
	movwf	lobyte
	call	spi16
;
;3. Frequency Setting: A6AEh
			; F = 1710 dez = 6AE hex , (fo = 868,55 MHz)
	movlw	0xa6
	movwf	hibyte
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
;5. Receiver Control: 94C0h
	movlw	0x94		; Empfänger-BW 94xx (hex):
	movwf	hibyte		; BW=67KHz: i2:i0=110, g1:g0=00,
	movlw	0xc0		; r2:r0=000
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
;10. TX Configuration Control: 9814h
	movlw	0x98		; TX Configuration 98MP (hex):
	movwf	hibyte		; Frequ.hub +-30KHz => M=1,
	movlw	0x14		; Psende = -12 dB => 100 => P=4
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
;14. Low Battery Detector..: C0C0h (c0h = 5 MHz am Taktausg.)
	movlw	0xc0
	movwf	hibyte
	movlw	0xc0
	movwf	lobyte
	call	spi16
;
	return
;
; ############################################################
; UP Empfaenger
; ############################################################
empfaenger
;1. Empfänger Ein  82c8h
	movlw	0x82		;high byte laden
	movwf	hibyte		;W => hibyte
	movlw	0xc8		;low byte laden
	movwf	lobyte		;W ==> lobyte
	call	spi16		;hibyte u. lobyte an RFM übertragen
;
;2. Synchron Pattern, FIFO fill, Resetmode normal CA83h:
	movlw	0xca
	movwf	hibyte
	movlw	0x83
	movwf	lobyte
	call	spi16
;
;3. Empfang von fuenf Bytes und speichern:
	;1. Byte:
	movlw	0xb0		;high byte laden
	movwf	hibyte
	movlw	0x00		;low byte laden
	movwf	lobyte
	call	waitrfm		;Warten auf Bereitsch. d. Moduls
	call	spi16		;hibyte u. lobyte an RFM übertragen
	;empf. Byte aus W weiterverarbeiten
	movwf	rxbyte1		;erstes empf. Byte speichern
;
	;2. Byte:
	movlw	0xb0		;high byte laden
	movwf	hibyte
	movlw	0x00		;low byte laden
	movwf	lobyte
	call	waitrfm		;Warten auf Bereitsch. d. Moduls
	call	spi16		;hibyte u. lobyte an RFM übertragen
	;empf. Byte aus W weiterverarbeiten
	movwf	rxbyte2		;zweites empf. Byte speichern
;
	;3. Byte:
	movlw	0xb0		;high byte laden
	movwf	hibyte
	movlw	0x00		;low byte laden
	movwf	lobyte
	call	waitrfm		;Warten auf Bereitsch. d. Moduls
	call	spi16		;hibyte u. lobyte an RFM übertragen
	;empf. Byte aus W weiterverarbeiten
	movwf	rxbyte3		;drittes empf. Byte speichern
;
	;4. Byte:
	movlw	0xb0		;high byte laden
	movwf	hibyte
	movlw	0x00		;low byte laden
	movwf	lobyte
	call	waitrfm		;Warten auf Bereitsch. d. Moduls
	call	spi16		;hibyte u. lobyte an RFM übertragen
	;empf. Byte aus W weiterverarbeiten
	movwf	rxbyte4		;viertes empf. Byte speichern
;
	;5. Byte:
	movlw	0xb0		;high byte laden
	movwf	hibyte
	movlw	0x00		;low byte laden
	movwf	lobyte
	call	waitrfm		;Warten auf Bereitsch. d. Moduls
	call	spi16		;hibyte u. lobyte an RFM übertragen
	;empf. Byte aus W weiterverarbeiten
	movwf	rxbyte5		;fünftes empf. Byte speichern
;
;4. Empfaenger abschalten 8258h:
	movlw	0x82		;high byte laden
	movwf	hibyte		;W => hibyte
	movlw	0x58		;low byte laden
	movwf	lobyte		;W ==> lobyte
	call	spi16		;hibyte u. lobyte an RFM übertragen
;
	return
;
; ############################################################

; =============Ende Datei rfm12b_rx.asm=============
