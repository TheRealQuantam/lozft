; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at https://mozilla.org/MPL/2.0/.

; Reading the controllers is expensive on the NES, especially when DMC is used and may require rereading them. One optimization that can be done is to only read the second controller at the status screen, where up+A may be entered. This saves ~700 cycles (2.3% CPU), and moving it to a different bank saves common bank space.

.macpack common

.include "nes.inc"

IsMenuScreen := $e1
CtlrReadTemp := 2


.segment "BANK7"

; Relocate to save space
.org $e62d
    jmp ReadCtlrs

FREE_UNTIL $e679

.segment "BANK5"

.reloc
.proc ReadCtlrs
	; Allowed to clobber everything
	ldx #$0
	jsr ReadCtlr
	
	lda IsMenuScreen
	beq @NotStatusScreen
	
	inx
	jmp ReadCtlr
	
@NotStatusScreen:
	stx $f8 + 1
	stx $fa + 1
	
	rts
.endproc ; ReadCtlrs

.reloc
.proc ReadCtlrOnce
	lda #$1
	sta Ctrl1_4016
	sta CtlrReadTemp

	lsr A
	sta Ctrl1_4016
	
@Loop:
	lda Ctrl1_4016, X
	and #$3
	cmp #$1
	rol CtlrReadTemp
	bcc @Loop
	
	rts
.endproc ; ReadCtlrOnce

.reloc
.proc ReadCtlr
	jsr ReadCtlrOnce
	
@Loop:
	ldy CtlrReadTemp

	jsr ReadCtlrOnce
	
	cpy CtlrReadTemp
	bne @Loop
	
	tya
	eor $fa, X
	and CtlrReadTemp
	sta $f8, X
	sty $fa, X
	
	rts
.endproc ; ReadCtlr	
