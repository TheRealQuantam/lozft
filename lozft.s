; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at https://mozilla.org/MPL/2.0/.

; TODO: Comment this file

.macpack common

.include "nes.inc"
.include "mmc3.inc"
.include "preservesram.inc"
.include "bhop.inc"

.define FT_CODE_BANK "FT_CODE"

NUM_NAT_TRACKS = $12
MAX_TRACKS = $40

.export bhop_music_data

bhop_music_data := $a000

NOT_PLAYING = 0
PLAYING_NAT = 1
PLAYING_FT = 2

NO_FT_TRACK_TO_PLAY = $ff

ZIsPaused := $e0
NatTrackToPlay := $600
Square2SfxToPlay := $602
CurSquare1Sfx := $605
CurNoiseSfx := $606
CurSquare2Sfx := $607
CurNatTrack := $609

UpdateNatSound := $9825


.segment "ZEROPAGE"

.org $4f
Mmc3BankTemp: .byte 0


.segment "FT_RAM"
.reloc

; Track index + 1 or 0 if none
TrackNumToPlay: .byte 0
PrevFtTrack: .byte 0

PrevSfxChanMask: .byte 0

MusicState: .byte 0
NextMusicState: .byte 0

CurFtBank: .byte 0


.segment "BHOP_ZEROPAGE_COPY"

.reloc

Temp: .byte 0

FtTrackToPlay: .byte 0
FtBankToPlay: .byte 0
FtAddrToPlay: .word 0


.segment "HEADER"
.org 4
	.byte $10 ; Number of 16 KB banks


.segment "BANK7"

.reloc
.proc ResetHdlrPart3
	lda #<.bank(CopyGlobalCodeToSram)
	jsr Switch16kBank

	jsr CopyGlobalCodeToSram

	lda #<.bank(ResetHdlrPart4)
	jsr Switch16kBank

	jmp ResetHdlrPart4
.endproc
	

.segment "BANK5"

.reloc
.proc ResetHdlrPart4
	lda #NOT_PLAYING
	sta MusicState
	sta NextMusicState
	
	lda #<.bank(UpdateSoundPart3)
	sta CurFtBank
	
	lda #$0
	sta TrackNumToPlay
	sta PrevFtTrack
	; sta CurSfxChanMask
	sta PrevSfxChanMask
	
	sta ApuStatus_4015

	lda #$f
	sta ApuStatus_4015
	
	rts
.endproc

.segment "BANK7"

.reloc
.proc UpdateSound
	lda #<.bank(UpdateSoundPart2)
	jsr Switch16kBank
	jsr UpdateSoundPart2
	
	rts
.endproc

.segment "BANK0"

.org $8000

TrackMapTable:
	.repeat MAX_TRACKS, i
		.byte 0, i
	.endrepeat
	
TrackAddrTable:
	.repeat MAX_TRACKS
		.word bhop_music_data
	.endrepeat

.org $a000
	
.proc UpdateSoundPart2
	lda #NO_FT_TRACK_TO_PLAY
	sta FtTrackToPlay
	
	lda TrackNumToPlay
	bne @PlayTrack ; A hack might have explicitly set it
	
	jsr DecodeTrackNum

	lda TrackNumToPlay
	beq @Done
	
@PlayTrack:
	ldx #$0
	stx TrackNumToPlay
	
	cmp #$0
	bpl @NewTrack
	
	jsr StopMusic
	
@NoNewTrack:
	ldy #NOT_PLAYING
	sty NextMusicState
	
	rts

@NewTrack:
	cmp PrevFtTrack
	bne @NoResumeFt
	
	ldx MusicState
	cpx #PLAYING_FT
	bne @ResumeFt
	beq @Done
	
@NoResumeFt:
	asl A
	tax

	jsr StopMusic

	ldy TrackMapTable + 1 - 2, X ; TrackNumToPlay is 1 too high
	lda TrackMapTable - 2, X
	bmi @PlayFt
	
	cpy #$ff
	beq @NoNewTrack
	
@PlayNative:	
	jsr Switch16kBank
	
	tya
	asl A
	tay
	ldx NatTrackRegMap, Y
	lda NatTrackRegMap + 1, Y
	sta NatTrackToPlay, X
	
	lda #PLAYING_NAT
	sta NextMusicState
	
	bne @Done
	
@PlayFt:
	eor #$ff
	sta FtBankToPlay
	sty FtTrackToPlay
	
	lda TrackAddrTable - 2, X
	sta FtAddrToPlay
	lda TrackAddrTable - 2 + 1, X
	sta FtAddrToPlay + 1
	
	txa
	lsr a
	sta PrevFtTrack
	
	lda #PLAYING_FT
	sta NextMusicState
	
@Done:
	jsr UpdateNatSound
	
	lda #SWITCH_BANK_8
	sta BankCtrlReg
	lda #<.bank(UpdateSoundPart3)
	sta BankReg
	
	jmp UpdateSoundPart3
	
@ResumeFt:
	jsr StopMusic
	
	lda #$ff
	sta PrevSfxChanMask
	
	lda #PLAYING_FT
	sta NextMusicState
	
	bne @Done
.endproc ; UpdateSoundPart2

StopMusic:
	lda #$0
	sta CurNatTrack
	
	lda $607
	and #$c0
	beq @NoSquare2
	
	lda #$0
	sta $607
	
@NoSquare2:
	lda #NOT_PLAYING
	sta NextMusicState
	
	lda #NO_FT_TRACK_TO_PLAY
	sta FtBankToPlay
	sta FtTrackToPlay

.proc SilenceMusic
	jmp SilenceMusicTail
.endproc ; SilenceMusic

; Tables to quickly decode the track number from the bit masks
MusicLoMaskTracks: ; 600 lo nibble
	.byte $00, $01, $02, $01
	.byte $03, $01, $02, $01
	.byte $04, $01, $02, $01
	.byte $03, $01, $02, $01

MusicHiMaskTracks: ; 600 hi nibble
	.byte $00, $05, $06, $05
	.byte $07, $05, $06, $05
	.byte $08, $05, $06, $05
	.byte $07, $05, $06, $05
	
Square2SfxMaskTracks: ; 602 top 2 bits
	.byte $0, $0a, $0b, $0a

; 0-based map from track number to register/mask values
NatTrackRegMap:
	.byte 0, 1
	.byte 0, 2
	.byte 0, 4
	.byte 0, 8
	.byte 0, $10 ; 4
	.byte 0, $20
	.byte 0, $40
	.byte 0, $80
	.byte 0, $6 ; 8
	.byte 2, $40
	.byte 2, $80
	
	.repeat 7
	.byte 0, $40
	.endrepeat
	
	.repeat MAX_TRACKS - $12
	.byte 0, 0
	.endrepeat
	
; Map of $10 values for dungeons. Already +1.
DungeonTrackMap:
	.byte 7, $c, $d, $e, $f, $10, $11, $12
	
; Returns the track index to play, or < 0 if none
.proc DecodeTrackNum
	lda NatTrackToPlay
	
	beq @CheckSquare2
	
	cmp #$6
	bne @NotFanfare
	
	lda #$9
	
	bne @SetNum
	
@NotFanfare:
	and #$f
	bne @IsMusicLo
	
@IsMusicHi:
	lda NatTrackToPlay
	lsr A
	lsr A
	lsr A
	lsr A
	tax
	lda MusicHiMaskTracks, X
	
	bne @SetNum
	
@IsMusicLo:
	tax
	lda MusicLoMaskTracks, X

	bne @SetNum
	
@CheckSquare2:
	lda Square2SfxToPlay
	and #$c0
	bne @IsSquare2
	
	sta TrackNumToPlay
	
	rts
	
@IsSquare2:
	asl A
	rol A
	rol A
	tax
	lda Square2SfxMaskTracks, X
	
@SetNum:
	cmp #(6 + 1)
	bne @NotDungeon
	
	lda $10
	tax
	lda DungeonTrackMap - 1, X
	
@NotDungeon:
	sta TrackNumToPlay
	
	lda #$0
	sta NatTrackToPlay
	sta Square2SfxToPlay
	
	rts
.endproc ; DecodeTrackNum
	
.org $9d42

	; Convert to a callable function
.proc StopMusicStub
	jmp StopMusic
.endproc ; StopMusicStub
	
.proc SilenceMusicTail
  LDA #$00
  ; STA CurNatTrack
  STA ApuStatus_4015
  LDA #$0F
  STA ApuStatus_4015
  RTS
.endproc ; SilenceMusicTail

.segment FT_CODE_BANK
.reloc

.proc UpdateSoundPart3
SfxChanMask := Temp

	lda #SWITCH_BANK_A
	sta BankCtrlReg

	; Start an FT track if any
	lda FtTrackToPlay
	bmi @NoNewTrack
	
	lda FtBankToPlay
	sta CurFtBank
	sta BankReg

	lda FtTrackToPlay
	ldx FtAddrToPlay
	ldy FtAddrToPlay + 1
	jsr bhop_init
	
	lda #$4
	jsr bhop_mute_channel
	
	lda #NO_FT_TRACK_TO_PLAY
	sta FtTrackToPlay
	sta FtBankToPlay
	
@NoNewTrack:
	ldx MusicState
	lda NextMusicState
	sta MusicState

	cmp #PLAYING_FT
	bne @Done
	
	lda PrevSfxChanMask
	bpl @NotResumingFt
	
@ResumingFt:
	lda #$f
	sta PrevSfxChanMask
	
	jsr bhop_mute_channels

@NotResumingFt:
	lda ZIsPaused
	beq @NotPaused
	
@Paused:
	lda #$f
	sta SfxChanMask

	bne @CheckMuteUnmutes
	
@NotPaused:
	lda #$0
	sta SfxChanMask
	
	lda CurNoiseSfx
	cmp #$1
	rol SfxChanMask
	rol SfxChanMask
	
	lda CurSquare2Sfx
	cmp #$1
	rol SfxChanMask
	
	lda CurSquare1Sfx
	cmp #$1
	rol SfxChanMask
	
	lda SfxChanMask

@CheckMuteUnmutes:
	; If necessary mute/unmute bhop channels for SFX. Also used during pause/unpause.
	cmp PrevSfxChanMask
	beq @ChanMaskChecked
	
@MuteUnmuteChans:
	lda PrevSfxChanMask
	eor #$f
	and SfxChanMask
	beq @NoNewMutes
	
	jsr bhop_mute_channels
	
@NoNewMutes:
	lda SfxChanMask
	eor #$f
	and PrevSfxChanMask
	beq @NoNewUnmutes
	
	jsr bhop_unmute_channels
	
@NoNewUnmutes:
	lda SfxChanMask
	sta PrevSfxChanMask
	
@ChanMaskChecked:
	lda ZIsPaused
	bne @Done
	
	lda CurFtBank
	sta BankReg
	
	jsr bhop_play

@Done:	
	rts
.endproc ; UpdateSoundPart3
