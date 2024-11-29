;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Slope sprite
;; by tOaO

; ---------------------------------------------------------------
; Slope Types (from the Slope Sprite Patch by Djief)
; ---------------------------------------------------------------
; The following values represent different slope types:
; 
; #00 - No Slope
; #01 - Left Gradual Slope
; #02 - Left Normal Slope
; #03 - Left Steep Slope
; #04 - Left Very Steep Slope
; #05 - Right Gradual Slope
; #06 - Right Normal Slope
; #07 - Right Steep Slope
; #08 - Right Very Steep Slope
; ---------------------------------------------------------------
; This patch uses a free RAM address to store the slope type.
; The valid values are listed above, and the free RAM address
; for this variable is defined as !SLOPE_SPRITE_PATCH_FREE_RAM.
; Ensure the address in the patch matches the one used here.
; 
; Patch available on SMWCentral: https://smwc.me/s/35555
; ---------------------------------------------------------------
!SLOPE_SPRITE_PATCH_FREE_RAM = $1864|!addr



;=======================================================================================================================
; INIT CODE
;=======================================================================================================================
print "INIT ",pc
;=======================================================================================================================
; MAIN JSL CODE
;=======================================================================================================================
print "MAIN ",pc
PHB : PHK : PLB
JSR MAINCODE
PLB : RTL

;=======================================================================================================================
; MAIN LIFE CODE ROUTINE
;=======================================================================================================================
MAINCODE:

    JSR GRAPHICS           ; Call the graphics routine to draw tiles
    
	LDA #$00
	%SubOffScreen()        ; Check if the sprite is off-screen and handle it accordingly
	
	
    LDA $9D                ; Load sprites/animation locked flag (from $9D)
    ORA $13D4|!addr        ; OR with the "game paused" flag from $13D4 (to check if the game is paused)
    BNE RETURN             ; If the result is not zero (meaning the game is paused), Return

	JSR MOVEMENT

	JSR CONTACT
	
RETURN:
	RTS
	
;=======================================================================================================================
; GRAPHICS ROUTINE
;=======================================================================================================================

GRAPHICS:
	%GetDrawInfo()			; Get the drawing information for the sprite (e.g., position, tiles to draw, etc.)
	
	LDX #$00 				; Initialize loop index (X register) to 0
	TILE_DRAW_LOOP:
			
		
	LDA $00 : CLC : ADC TILEMAP_X_POS_OFFSET,x			; Add X position offset to the current sprite's X position
	STA $0300|!Base2,y      ;
	
	
	LDA $01 : CLC : ADC TILEMAP_Y_POS_OFFSET,x			; Add Y position offset to the current sprite's Y position
	STA $0301|!Base2,y      
	
	; Save the current X value (sprite index) to restore later
	PHX                     ; Push the current value of X to the stack
	LDX $15E9|!Base2		; Restore original X (sprite index)
	LDA !15F6,x             ; Load the tile properties (YXPPCCCT format) for the current tile
	ORA !TILE_PRIORITIES    ; Add tile priority (bit 6) to the tile properties
	STA $0303|!Base2,y      ; Store tile properties 
	PLX						; Restore the value of X from the stack (return to loop index)
	
	
	LDA TILEMAP,x			; Load the tile to be drawn from TILEMAP (using loop index x)
	STA $0302|!Base2,y      ;
	                     

	INX                     ; Increment the loop index (x) to move to the next tile
	INY #4                  ; Increment Y (OAM offset) by 4 for the next tile to be drawn
	
	CPX !NR_OF_TILES        ; Check if we've looped through all the tiles
    BNE TILE_DRAW_LOOP      ; If we haven't, continue the loop to draw the next tile

	
	LDX $15E9|!Base2		; Restore the sprite index again
	LDY #$02                ; Set Y register to 460 = 2 (all 16x16 tiles)
	LDA !NR_OF_TILES-1      ; Load the total number of tiles
	JSL $01B7B3|!BankB      ; Call the off-screen check and rendering function
	
	RTS                     ; return

CONTACT:
	LDA $7D					;if mario is jumping stop
	BMI NO_CONTACT
	
	%SubHorzPos() 			;gets the distance between the player and the sprite. puts it into scratch ram $0E
	
	REP #$20
	
	LDA $0E					;load (player x - sprite x)
	CLC : ADC #$0008		;add 8 pixels for marios offset
	STA $06					;store the x position with the offset for later
	BPL +
		SEP #$20				
		BRA NO_CONTACT		;return if negative, we are to the left of the sprite
	+	
	
	CMP !WIDTH
	BCC +
		SEP #$20
		BRA NO_CONTACT		;return if greater then the width, we are to the right of the sprite
	+
	SEP #$20				

	LDA $06					;mult by 2, because we are dealing with 16bit values
	ASL A
	STA $06

		
	;get sprites y position clip box for the current x position mario is on
	LDA !14D4,x
	XBA
	LDA !D8,x
	REP #$20
	
	LDY $187A|!addr			;\ 
	BEQ +					;| adjust position to marios feet -16pixels, or -32pixels if on yoshi
		SEC : SBC #$0020	;| 
		BRA ++				;|
	+						;|
	SEC : SBC #$0010		;/
	++
	LDX $06
	SEC : SBC SPRITE_CLIPPING_OFFSET, x
	
	STA $0C					; sprite's combined y position
	
	LDX $15E9|!Base2		; Restore the sprite index again

	
	;actual x/y slope contact check
	LDA $96
	SEC : SBC $0C
	BPL +					;\
		EOR #$FFFF			;| clipping offset +8pixels above / -16pixels below
		INC					;|
		CLC					;|
		ADC #$0008			;|
	+						;|
	CMP #$0010				;/
	BCC +
		SEP #$20
		BRA NO_CONTACT
	+

	SEP #$20
	
	BRA STANDONSLOPE 	;we are actually standing on the slope?

NO_CONTACT:
	LDA $1471|!addr								;\
	BNE +										;| reset the slope sprite patch to no slope if we are not standing on any other platform
		LDA #$00								;|
		STA !SLOPE_SPRITE_PATCH_FREE_RAM		;|
	+											;/
	RTS
		
STANDONSLOPE:	
	REP #$20					;\
	LDA $0C						;| set mario to the correct position on the slope
	STA $96						;|
	SEP #$20					;/
	
	LDA !STEEP					;\
	BEQ +						;| very steep slopes need to set this timer to disable the turnaround animation
		LDA #$08				;| 
		STA $14A1|!addr			;|
	+							;/

	LDA #$03					;\ set that we are standing on a solid sprite
	STA $1471|!addr	         	;/
	
	LDA !SLOPE_SPRITE_PATCH_VALUE		;\ set the correct value for the slope sprite patch
	STA !SLOPE_SPRITE_PATCH_FREE_RAM	;/
	
	RTS
	
MOVEMENT:

	LDA !extra_byte_1,x
	
	CMP #$01
	BEQ +
	
	CMP #$02
	BEQ ++
	
	CMP #$03
	BEQ +++
	
	BRA RETURN_MOVEMENT
	
	+					; X and Y speed, with gravity and with object interaction
	JSL $01802A|!bank		
	BRA RETURN_MOVEMENT
	
	
	++					; bullet bill left flying
	LDA #$E8
	STA !B6,x		
	JSL $018022|!bank
	BRA RETURN_MOVEMENT
	
	+++					; bullet bill right flying
	LDA #-$E8
	STA !B6,x		
	JSL $018022|!bank
	BRA RETURN_MOVEMENT
	

RETURN_MOVEMENT:
	RTS