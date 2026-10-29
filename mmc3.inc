; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at https://mozilla.org/MPL/2.0/.

.ifndef MMC3_INC
.define MMC3_INC

BankCtrlReg = $9ffc
BankReg = $9ffd
MirrorReg = $bffc
PrgRamProtectReg = $bffd
IrqCounterReg = $dffc
IrqReloadReg = $dffd
IrqDisableReg = $fffc
IrqEnableReg = $fffd

SWITCH_BANK_8 = 6
SWITCH_BANK_A = 7

MIRROR_VERTICAL = 0
MIRROR_HORIZONTAL = 1

DISABLE_PRG_RAM_PROTECTION = $80

.global Switch16kBank

; Must be defined by the host
.globalzp Mmc3BankTemp
.global ResetHdlrEndHook, UpdateSoundHook

.endif ; .ifndef MMC3_INC
