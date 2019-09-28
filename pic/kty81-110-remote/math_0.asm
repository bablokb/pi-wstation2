;math_0.asm
;####################################################################
;Unterprogramme für Mathe-Routinen
;####################################################################
;Einfügen mit:
;   #include <D:\MPLAB-Projekte\Bibliothek\math_0.asm>	     ;Mathematik-UP'e
;
;Definitionen/EQU's:
;f0		equ
;f1		equ
;f2		equ
;f3		equ
;xw0		equ
;xw1		equ
;xw2		equ
;xw3		equ
;g0		equ
;g1		equ
;Fehler		equ
;
;####################################################################
;UP Sub16: 16 Bit Subtraktion, C-Flag bei Überlauf gesetzt
;####################################################################
Sub16				;16 bit f:=f-xw   calc=xw cnt=f
	clrf	Fehler		;bcf	Fehler,C   ;extraflags löschen
	movf	xw0,W		;f0=f0-xw0
	subwf	f0,F
	btfsc	STATUS,C
	goto	sub16A
	movlw	0x01		;borgen von f1
	subwf	f1,F
	btfss	STATUS,C
	bsf	Fehler,C		;Unterlauf
sub16A
	movf	xw1,w		;f1=f1-xw1
	subwf	f1,F
	btfss	STATUS,C
 	bsf	Fehler,C		;Unterlauf
	bcf	STATUS,C
	btfsc	Fehler,C
	bsf	STATUS,C
	return
;
;####################################################################
; 32 Bit Subtraktion, bei Überlauf (neg. Ergebnis) ist C gesetzt
;####################################################################
Sub32		; 32 bit f:=f-xw   calc=xw cnt=f
		; extraflags löschen    
	bcf	Fehler,C		;Fehler,C=0
	movf	xw0,W		; f0=f0-xw0
	subwf	f0,F

	btfsc	STATUS,C
	goto	sb0
	movlw	0x01		; borgen von f1
	subwf	f1,F

	btfsc	STATUS,C
	goto	sb0
	subwf	f2,F		; borgen von f2

	btfsc	STATUS,C
	goto	sb0
	subwf	f3,F		; borgen von f3
	btfss	STATUS,C
	bsf	Fehler,C		; unterlauf

sb0	movf	xw1,W		; f1=f1-xw1
	subwf	f1,F

	btfsc	STATUS,C
	goto	sb1
	movlw	0x01		; borgen von f2
	subwf	f2,F

	btfsc	STATUS,C
	goto	sb1
	subwf	f3,F		; borgen von f3

	btfss	STATUS,C
	bsf	Fehler,C		; Unterlauf

sb1	movf	xw2,W		; f2=f2-xw2
	subwf	f2,F

	btfsc	STATUS,C
	goto	sb2
	movlw	0x01
	subwf	f3,F		; borgen von f3

	btfss	STATUS,C
	bsf	Fehler,C		; Unterlauf

sb2	movf	xw3,W		; f3=f3-xw3
	subwf	f3,F

	btfss	STATUS,C
 	bsf	Fehler,C		; Unterlauf

	bcf	STATUS,C
	btfsc	Fehler,C
	bsf	STATUS,C
	return
;
;####################################################################
;UP Add16: 16 bit Adition, C-Flag bei Überlauf gesetzt
;####################################################################
Add16 		; 16-bit add: f = f + xw
	movf	xw0,W		;low byte
	addwf	f0,F 		;low byte add
;
	movf	xw1,W 		;next byte
	btfsc	STATUS,C 	;skip to simple add if C was reset
	incfsz	xw1,W 		;add C if it was set
	addwf	f1,F 		;high byte add if NZ
	return
;
;####################################################################
;UP Mal2: Multiplikation mit 2 wird w-mal ausgeführt,
;die zu multiplizierende Zahl steht in xw
;####################################################################
Mal2 
	movwf	counter		;Anzahl der Multiplikationen speichern
Mal2a				;16 bit xw:=xw*2
	bcf	STATUS,C	; carry löschen
	rlf	xw1,F
	rlf	xw0,F
	decfsz	counter,F	;fertig?
	goto	Mal2a		;nein: noch mal
	return
;
;####################################################################
;UP Div2: Division durch 2 wird w-mal ausgeführt,
;die zu dividierende Zahl steht in xw
;####################################################################
Div2 
	movwf	counter		;Anzahl der Divisionen speichern
Div2a				;16 bit xw:=xw/2
	bcf	STATUS,C	; carry löschen
	rrf	xw1,F
	rrf	xw0,F
	decfsz	counter,F		;fertig?
	goto	Div2a		;nein: noch mal
	return
;
;Anwendung:
;	movf	f0,W	;f ==> W ==> xw
;	movwf	xw0
;	movf	f1,W
;	movwf	xw1		;
;			;z.B. xw durch 64 dividieren (6 mal durch 2),also:
;			;W=6
;	movlw	0x06
;	call	Div2
;
;####################################################################
;primitive 16 bit Division 	f:= f / xw
;####################################################################
Div16
	clrf	g0
	decf	g0,F
	clrf	g1
	decf	g1,F
div16Loop
	incf	g0,F
	btfsc	STATUS, Z
	incf	g1,F
	call	Sub16		;
	btfss	STATUS, C	;Überlauf
	goto	div16Loop		;Stelle 1 mehr
	movf	g0,W
	movwf	f0
	movf	g1,W
	movwf	f1
	return
;
;####################################################################
;primitive 32 Bit Division	f:= f / xw	(Ergebnis nur 16-Bittig wegen g1,g0 !!! )
;####################################################################
Div32
	clrf	g0
	decf	g0,F
	clrf	g1
	decf	g1,F
div32Loop
	incf	g0,F
	btfsc	STATUS,Z
	incf	g1,F
	call	Sub32		;f:= f - xw (32-Bit-Subtraktion)
;
	btfss	STATUS,C	;Überlauf
	goto	div32Loop		;Stelle 1 mehr
;
;Div-Ergebnis umspeichern, gx nach fx (max 16-Bit):
	movf	g0,W
	movwf	f0
	movf	g1,W
	movwf	f1
	return
;
;####################################################################
;Ende der Datei math_0.asm

