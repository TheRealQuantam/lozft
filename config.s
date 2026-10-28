; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at https://mozilla.org/MPL/2.0/.

;;; TODO: See if there's a cleaner way of doing some of this stuff in js65

.macpack common

.segment "ZEROPAGE"      :size $0100 :mem $0000 :zp
.segment "BHOP_ZEROPAGE" :size $0006 :mem $0000 :zp
.segment "BHOP_ZEROPAGE_COPY" :size $0006 :mem $0000 :zp
.segment "RAM"           :size $0700 :mem $0100
.segment "FREE_RAM"      :size $0090 :mem $0150
.segment "HIRAM"         :size $2000 :mem $6000
.segment "CODE_HIRAM1"   :size $8d :mem $67f0
.segment "CODE_HIRAM2"   :size $1270 :mem $6c90
.segment "BHOP_RAM"      :size $00be :mem $7f40

.segment "FT_RAM" :load "FREE_RAM"
.segment "BHOP_RAM2" :load "FREE_RAM"

.segment "HEADER" :size $0010 :mem $0000 :out

.segment "BANK0"  :bank $00 :size $4000 :mem $8000 :out
.segment "BANK1"  :bank $01 :size $4000 :mem $8000 :out
.segment "BANK2"  :bank $02 :size $4000 :mem $8000 :out
.segment "BANK3"  :bank $03 :size $4000 :mem $8000 :out
.segment "BANK4"  :bank $04 :size $4000 :mem $8000 :out
.segment "BANK5"  :bank $05 :size $4000 :mem $8000 :out
.segment "BANK6"  :bank $06 :size $4000 :mem $8000 :out

.segment "BANK1_HIRAM2"  :size $1270 :mem $6c90 :off $6510

.ifdef ROM_256KB

.segment "BANKE"  :bank $0e :size $2000 :mem $8000 :out :fill $00
.segment "BANKF"  :bank $0f :size $2000 :mem $8000 :out :fill $00
.segment "BANK10" :bank $10 :size $2000 :mem $8000 :out :fill $00
.segment "BANK11" :bank $11 :size $2000 :mem $8000 :out :fill $00
.segment "BANK12" :bank $12 :size $2000 :mem $8000 :out :fill $00
.segment "BANK13" :bank $13 :size $2000 :mem $8000 :out :fill $00
.segment "BANK14" :bank $14 :size $2000 :mem $8000 :out :fill $00
.segment "BANK15" :bank $15 :size $2000 :mem $8000 :out :fill $00
.segment "BANK16" :bank $16 :size $2000 :mem $8000 :out :fill $00
.segment "BANK17" :bank $17 :size $2000 :mem $8000 :out :fill $00
.segment "BANK18" :bank $18 :size $2000 :mem $8000 :out :fill $00
.segment "BANK19" :bank $19 :size $2000 :mem $8000 :out :fill $00
.segment "BANK1A" :bank $1a :size $2000 :mem $8000 :out :fill $00
.segment "BANK1B" :bank $1b :size $2000 :mem $8000 :out :fill $00
.segment "BANK1C" :bank $1c :size $2000 :mem $8000 :out :fill $00
.segment "BANK1D" :bank $1d :size $2000 :mem $8000 :out :fill $00

.segment "FT_CODE" :load "BANKE"
.segment "BHOP_PRG" :load "BANKE"

.endif ; defined(ROM_256KB)

.segment "BANK7"  :bank $07 :size $4000 :mem $c000 :out

FREE "ZEROPAGE" [$4f, $4f)
FREE "ZEROPAGE" [$e4, $e4)

;FREE "RAM" [$110, $1e9]

FREE "BANK0" [$8000, $8d60]
FREE "BANK0" [$9ff9, $bf50]

FREE "BANK1" [$8cb0, $8d00]
FREE "BANK1" [$9ec4, $a000]
FREE "BANK1" [$a423, $a500]
FREE "BANK1" [$b751, $bf50]

FREE "BANK5" [$859d, $8600]
FREE "BANK5" [$935c, $9400]
FREE "BANK5" [$ac2a, $b000]
FREE "BANK5" [$b8a0, $bf50]

FREE "BANK6" [$83c0, $8400]
FREE "BANK6" [$935f, $93dc]
FREE "BANK6" [$9d66, $a000]
FREE "BANK6" [$ad54, $bf50]

FREE "BANK7" [$ffc0, $ffe0]