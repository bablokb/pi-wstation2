; ####################################################################
; UP bin8_out_ascii: wandelt ein Byte (8bit),Übergabe an UP in W,
; in 8 einzelne Bits um und gibt jedes einzeln als ASCII-Zeichen
; auf LCD aus ! ;EQU: bin8reg, bitnum
; ####################################################################
bin8_out_ascii
	movwf	bin8reg		; ein Byte aus W laden
	movlw	d'8'		; Anzahl umzuwandelnder Bits
	movwf	bitnum
top1	bcf	STATUS,C	; C=0
	rlf	bin8reg,F	; mit Bit 0 beginnend
	btfss	STATUS,C
	goto	null_out	; C=0
eins_out			; C=1
	movlw	'1'		; ascii 1 
	call	OutLcdDat	; ausgeben
	goto	bit_stelle
null_out
	movlw	'0'		; ascii 0
	call	OutLcdDat	; ausgeben
bit_stelle
	decfsz	bitnum,F	; bitnum dekrementieren
	goto	top1		; nächste Bitstelle
	return			; alle 8 Bits ausgegeben; fertig!
;
; ####################################################################
; UP HexByteAscii: wandelt ein Hex-Byte in 2 ASCII-Zeichen um und
; gibt diese mit UP AscOut auf LCD aus. EQU hexbyte
; ####################################################################
HexByteAscii
	movwf	hexbyte
	swapf	hexbyte,W	; oberes Halbbyte zuerst
	andlw	0x0f		; die vorderen 4 Bit in W löschen
	call	AscOut		; Hex in W umwandeln in Ascii-Code
				; und an LCD ausgeben
	movf	hexbyte,W	; unteres Halbyte
	andlw	0x0f		; die vorderen 4 Bit in W löschen
	call	AscOut
;	movlw	' '		; Leerzeichen ausgeben
;	call	OutLcdDat
	return
;
; ####################################################################
; UP AscOut: wandelt (W) (also oberes oder unteres Halbbyte von 
; HexByteAscii) in ASCII um und gibt es auf dem LCD aus. EQU wert
; ####################################################################
AscOut
	movwf	wert
	movlw	0x0a
	subwf	wert,W
	btfsc	STATUS,C	; wenn C=0, überspr. nä. Bef.
	goto	A_F
	movlw	0x30		;
	addwf	wert,W
	call	OutLcdDat
	return
A_F
	movlw	0x37		; =movlw '7' Ausgabe A-F oder 0x??
	addwf	wert,W		; für Ausgabe a-f
	call	OutLcdDat
	return
;
;Ende Datei lcdoutputs-2.asm
