; This Source Code Form is subject to the terms of the Mozilla Public
; License, v. 2.0. If a copy of the MPL was not distributed with this
; file, You can obtain one at https://mozilla.org/MPL/2.0/.

.ifndef NES_INC
.define NES_INC

Sq0Duty_4000 := $4000
Sq0Sweep_4001 := $4001
Sq0Timer_4002 := $4002
Sq0Length_4003 := $4003
Sq1Duty_4004 := $4004
Sq1Sweep_4005 := $4005
Sq1Timer_4006 := $4006
Sq1Length_4007 := $4007
TriLinear_4008 := $4008
TriTimer_400A := $400a
TriLength_400B := $400b
NoiseVolume_400C := $400c
NoisePeriod_400E := $400e
NoiseLength_400F := $400f
DmcFreq_4010 := $4010
DmcCounter_4011 := $4011
DmcAddress_4012 := $4012
DmcLength_4013 := $4013
ApuStatus_4015 := $4015

PpuControl_2000 := $2000
PpuMask_2001 := $2001
PpuStatus_2002 := $2002
OamAddr_2003 := $2003
PpuScroll_2005 := $2005
PpuAddr_2006 := $2006

SpriteDma_4014 := $4014
Ctrl1_4016 := $4016
Ctrl2_FrameCtr_4017 := $4017

.endif ; .ifndef NES_INC
