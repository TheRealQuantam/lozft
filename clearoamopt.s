; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at https://mozilla.org/MPL/2.0/.

; ClearGameOamBuff clears part of the OAM sprite buffer each frame. The very standard normal version takes ~750 cycles. Unrolling can save ~430 cycles, or 1.4% of the CPU. Because of the way Z1 swizzles its sprite indices, it's not possible to only fill in sprite slots that were used the previous frame but not this frame, like in Mega Man 2.

.macpack common

.include "nes.inc"

.segment "BANK1_HIRAM2"

.org $6e1d ; $1:a68d
.proc ClearGameOamBuff 
	lda #$ff
	ldx #$28
	
@Loop:
	sta $260, X
	sta $288, X
	sta $2b0, X
	sta $2d8, X
	
	axs #$4 ; X = (A & X) - 4
	bpl @Loop
	
	jmp +

FREE_UNTIL $6e36

.segment "BANK1_HIRAM2", "BANK7"
.reloc
+
	LDA $0342
	JSR $6E39
	STA $0342

	RTS
.endproc ; ClearGameOamBuff
