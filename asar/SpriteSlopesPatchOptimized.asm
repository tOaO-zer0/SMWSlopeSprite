!dp = $0000
!addr = $0000
!bank = $800000
!sa1 = 0
!gsu = 0

if read1($00FFD6) == $15
	sfxrom
	!dp = $6000
	!addr = !dp
	!bank = $000000
	!gsu = 1
elseif read1($00FFD5) == $23
	sa1rom
	!dp = $3000
	!addr = $6000
	!bank = $000000
	!sa1 = 1
endif

!SpriteSlopeType = $1864|!addr ;FreeRam address which sprites need to store to to act as slopes

;Values
;No Slope 0
;Left Gradual Slope 1
;Left Normal Slope 2
;Left Steep Slope 3
;Left Very Steep Slope 4
;Right Gradual Slope 5
;Right Normal Slope 6
;Right Steep Slope 7
;Right Very Steep Slope 8

;Set the same address to those value when you set $1471 (mario is on sprite platform)

org $00EE28
	autoclean JML SetSlopeY
	NOP

freedata

SlopeY:
db $20
db $01,$08,$0C,$1D
db $06,$0B,$0D,$1F

SetSlopeY:

	LDX !SpriteSlopeType
	LDA.l SlopeY,x
	TAY
	JML $00EEE1|!bank