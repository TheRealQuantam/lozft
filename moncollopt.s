; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at https://mozilla.org/MPL/2.0/.

; The original version of CheckMonsterCollisions calls a series of functions to check for collisions with different things, totalling ~800 cycles/enemy even when no collision is possible with a given object. This requires the overhead of an unnecessary function call multiple times per enemy, as well as many of the functions being quite inefficient. Additionally, there is an unnecesary call to GetObjectMiddle for each enemy, costing ~55 cycles/enemy. Optimizing these things saves up to ~500 cycles (1.7% CPU) per enemy.

.macpack common

.include "nes.inc"

ObjState := $ac


.segment "BANK1_HIRAM2"

.org $79d0 ; 1:b240
.proc CheckMonsterCollisions
	JSR $7A2D
	LDA $04BF,X
	AND #$20
	BNE @L79FD

	LDA $04F0,X
	;BNE @L7A1C
	beq @CheckBoomerangFood

	rts

@CheckBoomerangFood:
	lda ObjState + $f
	beq @CheckBeam
	bmi @CheckBeam
	
	LDY #$0F
	JSR $7BC2
	
@CheckBeam:
	lda ObjState + $e
	beq @CheckBomb1
	lsr A
	bcs @CheckBomb1
	
	LDY #$0E
	JSR $7C9D
	
@CheckBomb1:
	lda ObjState + $10
	beq @CheckBomb2
	
	LDY #$10
	JSR $7CDC
	
@CheckBomb2:
	lda ObjState + $11
	beq @CheckSword
	
	LDY #$11
	JSR $7CDC
	
@CheckSword:
	lda ObjState + $d
	cmp #$2
	bne @CheckArrowRod
	
	LDY #$0D
	JSR $7D29
	
@CheckArrowRod:
	lda ObjState + $12
	beq @L79FD
	
	LDY #$12
	JSR $7D5F

@L79FD:
	; JSR $7AA7
	
	jsr $7aaa ; Skip redundant call to $7a2d
	
	LDA $034F,X
	LDY $0405,X

	jmp CheckMonsterCollisionsCont
.endproc ; CheckMonsterCollisions

FREE_UNTIL $7a2d

.segment "BANK1_HIRAM2", "BANK7"

.reloc
.proc CheckMonsterCollisionsCont
	BEQ @L7A1D

	CMP #$05
	BEQ @L7A10

	CMP #$06
	BNE @L7A1C

@L7A10:
	LDA $AC,X
	BPL @L7A1C

	LDY $042C,X
	LDA #$00
	STA $034F,Y

@L7A1C:
	RTS

@L7A1D:
	CMP #$27
	BEQ @L7A25

	CMP #$17
	BNE @L7A2C

@L7A25:
	LDA $0C
	BEQ @L7A2C

	INC $042C,X

@L7A2C:
	RTS
.endproc ; CheckMonsterCollisions
