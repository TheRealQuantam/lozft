; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at https://mozilla.org/MPL/2.0/.

; The SRAM region $6c90-7eff is copied from 1:a500 at 1:8d00 during startup and when a new map is loaded (when entering the game and when transitioning between overworld and dugneons). This is necessary because $6c90-6da1 is used as a buffer when saving the game, overwriting the copied data. While the copied region is code in the original game, the constant overwriting prevents any of it from being repurposed as variables in the future. Rewrite the copy mechanism so that only $6c90-6da1 is overwritten every time a map transition occurs, allowing variables to be stored in the rest of the region.

.macpack common

.include "preservesram.inc"

CopySrcBase := $a500
CopyTgtBase := $6c90
TotalCopySize = $1270
AlwaysCopySize = $112
RgnEntrySize  = 6

TempTgtAddr := 0
TempSrcAddr := 2
TempCopySize := 4
TempCopyTblAddr := 6


.segment "BANK1"

.reloc

GlobalSramCopyRegions:
	.word CopyTgtBase, CopySrcBase, TotalCopySize 
	.word 0

; Should only be called once, during boot
CopyGlobalCodeToSram: 
	lda #<GlobalSramCopyRegions
	sta TempCopyTblAddr
	lda #>GlobalSramCopyRegions
	sta TempCopyTblAddr + 1
	
.proc CopyRegionsToSram
	jmp @CheckPtr
	
.reloc

@RegionLoop:
	ldy #(RgnEntrySize - 1)
	
@Loop:
	lda (TempCopyTblAddr), Y
	sta TempTgtAddr, Y
	
	dey
	bpl @Loop
	
	jsr memcpy_long_bank1

	lda TempCopyTblAddr
	clc
	adc #RgnEntrySize
	sta TempCopyTblAddr
	lda TempCopyTblAddr + 1
	adc #$0
	sta TempCopyTblAddr + 1
	
@CheckPtr:
	ldy #$1
	lda (TempCopyTblAddr), Y
	
	bne @RegionLoop
	
	rts
.endproc ; CopyRegionsToSram

.org $8d00

; Called every time a map is loaded
.proc CopyCommonCodeToRam ; $14 bytes
	lda #<@RegionTable
	sta TempCopyTblAddr
	lda #>@RegionTable
	sta TempCopyTblAddr + 1
	
	jsr CopyRegionsToSram
	
	rts
	
@RegionTable:
	.word CopyTgtBase, CopySrcBase, AlwaysCopySize
	.word 0
.endproc ; CopyCommonCodeToRam

memcpy_long_bank1: ; $15 bytes
	; Takes target in $0, source in $2, length in $4. Clobbers X, Y.
	ldy #$0
	lda TempCopySize + 1
	beq memcpy_short_bank1
	
@BlockLoop:
	lda (TempSrcAddr), Y
	sta (TempTgtAddr), Y
	
	iny
	bne @BlockLoop
	
	inc TempSrcAddr + 1
	inc TempTgtAddr + 1
	
	dec TempCopySize + 1
	bne @BlockLoop
	
.proc memcpy_short_bank1 ; $d bytes
	; Takes target in $0, source in $2, length in $4 (<= $ff). Clobbers X, Y.
	ldx TempCopySize
	beq @Done
	
@TailLoop:
	lda (TempSrcAddr), Y
	sta (TempTgtAddr), Y
	
	iny
	dex
	bne @TailLoop
	
@Done:
	rts
.endproc ; memcpy_short_bank1

FREE_UNTIL $8d3b
