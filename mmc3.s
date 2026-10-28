; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at https://mozilla.org/MPL/2.0/.

; Convert from MMC1 to MMC3, and relocate as much of the reset and NMI handlers as possible to other banks to save space in the common bank. The banks chosen are not arbitrary, and correspond to banks the moved code calls anyway.

.macpack common

.include "nes.inc"
.include "mmc3.inc"

.macro PATCH_ADDR patch_addr, new_addr
	.org patch_addr
		.word new_addr
.endmacro

ObjState := $ac

ReadCtlrs := $e62d


.segment "HEADER"

.org 6
	.byte $40 ; MMC3


; For some reason every bank has its own copy of the bank switching functions. Even worse, a couple functions in bank 1 call them. Get rid of the calls so the space can be reclaimed.
.segment "BANK1"

PATCH_ADDR $aab6, Switch16kBank
PATCH_ADDR $aac9, Switch16kBank
PATCH_ADDR $aace, SetMirroring
PATCH_ADDR $acef, Switch16kBank

FREE "BANK0" [$bfc0, $c000]
FREE "BANK1" [$bfc0, $c000]
FREE "BANK2" [$bfc0, $c000]
FREE "BANK3" [$bfc0, $c000]
FREE "BANK4" [$bfc0, $c000]
FREE "BANK5" [$bfc0, $c000]
FREE "BANK6" [$bfc0, $c000]


; Relocate part of the reset handler to bank 5 as some of the functions it calls are in bank 5 anyway.
.segment "BANK5"

.reloc
.proc ResetHdlrPart2
	sta IrqDisableReg

-
	lda PpuStatus_2002
	bpl -
	
-
	lda PpuStatus_2002
	bpl -
	
	ldx #(SWITCH_BANK_8 - 1)

-:
	stx BankCtrlReg
	lda @InitialChrBanks, x
	sta BankReg
	
	dex
	bpl -
	
	lda #MIRROR_HORIZONTAL
	sta MirrorReg
	
	lda #DISABLE_PRG_RAM_PROTECTION
	sta PrgRamProtectReg

	LDA #$00
	STA $F4

	;LDA #$05
	;JSR $FFAC

	JSR $B4AC
	JSR $B4E8

	JSR $E45E
	
	rts
	
@InitialChrBanks:
	.byte 0, 2, 4, 5, 6, 7
.endproc ; ResetHdlrPart2
	
; Relocate the half of the NMI handler that only uses banks 5 and 7 to bank 5
.reloc
.proc NmiHdlrPart2
  LDA $E3                  ;Wait for Sprite 0 hit, if needed.
  BEQ @CheckScroll
  
  ;LDA #$05
  ;JSR SwitchBank
  JSR $8521
  
;If updating a game mode instead of initializing one,
@CheckScroll:
  LDA $11
  BEQ @UpdateTimers
  
  LDA $12
  BEQ @SetScroll
  CMP #$05
  BEQ @SetScroll
  CMP #$09
  BEQ @SetScroll
  CMP #$0B
  BEQ @SetScroll
  CMP #$0C
  BEQ @SetScroll
  CMP #$13
  BNE @UpdateTimers
  
@SetScroll:
  LDA PpuStatus_2002
  LDA $FD
  STA PpuScroll_2005
  LDA $FC
  STA PpuScroll_2005
  LDA $FF
  STA PpuControl_2000
  
@UpdateTimers:
  LDA $E1                  ;If paused or in menu, then don't decrement timers.
  ORA $E0
  BNE @CheckInput
  
  LDX #$26                 ;Advance the stun cycle.
  LDA #$3C
  LDY #$4E
  STX $00
  DEC $00,X
  BPL @DecTimers
  LDA #$09
  STA $00,X
  TYA
  
@DecTimers:
  TAX                      ;Decrement timers (object and optionally stun timers).
  
@LoopTimer:
  LDA $00,X
  BEQ @L1E536
  DEC $00,X
  
@L1E536:
  DEX
  CPX $00
  BNE @LoopTimer
  
@CheckInput:
  LDA $E3                  ;Sprite 0 is used for scrolling. Input isn't checked while scrolling.
  BNE @ScrambleRandom
  
  JSR ReadCtlrs
  
@ScrambleRandom:
  LDX #$18                 ;Scramble the random array.
  LDY #$0D
  LDA $00,X
  AND #$02
  STA $00
  LDA $01,X
  AND #$02
  EOR $00
  CLC
  BEQ @LoopRandom
  
  SEC
  
@LoopRandom:
  ROR $00,X
  INX
  DEY
  BNE @LoopRandom
  
	rts
.endproc ; NmiHdlrPart2


; Relocate the half of the NMI handler that only uses banks 6 and 7 to bank 6
.segment "BANK6"

.reloc
.proc NmiHdlrPart1
IsrNmi:
	LDA $FF
	LDX $5C
	BEQ @L1E48C               ;If need to switch name tables,
	
	EOR #$02                 ;Switch to the other name table ($2000 <-> $2800).
	
@L1E48C:
	AND #$7F                 ;Disable NMI.
	STA $FF
	AND #$7E                 ;Make sure table is 0 or 2.
	STA PpuControl_2000
;Set PPUMASK.
	LDA $FE
	LDY $E3                  ;If checking for sprite 0,
	BNE @EnableAllVideo
	
	LDY $14                  ;TODO: or TileBufSelector = 0 and [$17] = 0,
	BNE @SetPpuMask
	
	LDY $17
	BNE @SetPpuMask
	
@EnableAllVideo:
	ORA #$1E                 ;then make sure all video is on.
	
@SetPpuMask:
	STA PpuMask_2001
	STA $FE
	LDA #$00                 ;Copy all our sprites to OAM.
	STA OamAddr_2003
	LDA #$02
	STA SpriteDma_4014
	LDA #$00                 ;Reset scroll register.
	STA PpuScroll_2005
	STA PpuScroll_2005
	;LDA #$06
	;JSR SwitchBank
	JSR $A080
;Reset PPUADDR.
	LDA #$3F
	STA PpuAddr_2006
	LDA #$00
	STA PpuAddr_2006
	STA PpuAddr_2006
	STA PpuAddr_2006
	
;If Sprite 0 Hit is set,
@WaitVBlankEnd:
	LDA PpuStatus_2002
	AND #$40
	BNE @WaitVBlankEnd
	
	LDA PpuStatus_2002       ;Clear shift register.

	rts
.endproc ; NmiHdlrPart1


.segment "BANK7"

.org $e484

.proc NmiHdlr ; $2f bytes
	lda #<.bank(NmiHdlrPart1)
	jsr Switch16kBank
	jsr NmiHdlrPart1
	
	lda #<.bank(NmiHdlrPart2)
	jsr Switch16kBank
	jsr NmiHdlrPart2
	
	jsr UpdateSound
	
	INC $15
	LDA $11
	BNE @LE570

	JSR $E8F8
	JMP @LE573

@LE570:
	JSR $EB30
	
@LE573:
	LDA PpuStatus_2002
	LDA $FF
	ORA #$80
	STA PpuControl_2000
	STA $FF

	RTI
.endproc ; NmiHdlr

FREE_UNTIL $e580

.org $ff50

.proc ResetHdlr
	sei
	ldx #$0
	stx PpuControl_2000
	stx BankCtrlReg
	
	dex
	txs
	
	lda #<.bank(ResetHdlrPart2)
	jsr Switch16kBank
	
	jsr ResetHdlrPart2

	jsr ResetHdlrPart3

	LDA $FF
	ORA #$A0
	STA PpuControl_2000
	STA $FF
	
@GameLoop:
	jmp @GameLoop
.endproc ; ResetHdlr
	
FREE_UNTIL $ff98
FREE "BANK7" [$e440, $e45e]

.org $ff98

; While it's possible to get rid of this function entirely and just inline it, there are so many calls to it that it was easier to just leave it.
.proc SetMirroring
	sta MirrorReg
	rts
.endproc
	
FREE_UNTIL $ffac

.org $ffac

; Fastest possible implementation that takes a 16 KB bank in A and does not clobber X or Y
.proc Switch16kBank
	stx Mmc3BankTemp
	
	ldx #SWITCH_BANK_8
	stx BankCtrlReg
	asl a
	sta BankReg

	inx
	stx BankCtrlReg
	ora #$1
	sta BankReg
	
	ldx Mmc3BankTemp
	
	rts
.endproc ; Switch16kBank
		
FREE_UNTIL $ffe0
