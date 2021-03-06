; Author)  "Lyall Jonathan Di Trapani <lj.ditrapani@gmail.com>" ----------------
.aasc "NES", $1A    ; Static NES\n in header
.byt 1              ; PRG ROM data 1 X 16,384 bytes
.byt 1              ; CHR ROM data 1 X  8,192 bytes
; Flags 6
; bit  0)   0 vertical scroll  --  1 horizontal scroll
; bits 1)   Set battery backeg PRG RAM ($6000-7FFF)
; bits 2)   Set 512-byte trainer at $7000-$71FF (stored before PRG data)
; bit  3)   Set 4-screen VRAM (ignor bits 0-2)
; bits 4-7) mapper number
.byt %00000001      ; Flags 6, NROM mapper
                    ;          horizontal scroll (vertical mirroring, bit 0)
.byt %00000000      ; Flags 7
.byt 1              ; PRG RAM 1 X 8,192 bytes
.byt %00000000      ; Flags 9
.byt %00000000      ; Flags 10
.dsb 5,0            ; Bytes 11-15 zero filled

; Set PC to $8000
; $8000 = 32,768 = 32 KB = start of NES PRG ROM
* = $8000

; Data -------------------------------------------------------------------------

; strings

score_string:
    .aasc 5,"score"
top_score_string:
    .aasc 9,"top score"
you_win_string:
    .aasc 7,"you win"
you_loose_string:
    .aasc 8,"you lose"
play_again_string:
    .aasc 21,"press a to play again"

palette:
    ; Global background  light-light-blue
    ; $0D = black

    ; Background
    .byte $31,$0D,$02,$1C   ; Blue, dark cyan
    .byte $31,$0D,$0B,$03   ; Green, purple
    .byte $31,$0D,$04,$15   ; fusia, hot pink
    .byte $31,$0D,$16,$07   ; Orange, dark red

    ; Sprites
    .byte $31,$0D,$0C,$1C   ; Cyan
    .byte $31,$0D,$19,$29   ; Green + yellow-green
    .byte $31,$0D,$17,$27   ; Orrange
    .byte $31,$01,$12,$21   ; Blue

sprite_data:
    .byte $80,$00,%00000000,$80
    .byte $80,$00,%00000001,$88
    .byte $80,$00,%00000010,$90
    .byte $80,$00,%00000011,$98
    .byte $90,$20,%00000000,$80
    .byte $90,$21,%00000001,$88
    .byte $98,$30,%00000010,$80
    .byte $98,$31,%00000011,$88

cell_x_column_name_table_address_data:
    .byte $08,$0C,$10,$14


; Subroutines ------------------------------------------------------------------

wait_on_vblank:
    LDA $2002
    BPL wait_on_vblank
    RTS

; Expects two paramters, data address and screen location
;
; Data adress: address of string to draw
; the first byte of data is the length of string (1-255) and the rest are the
; actual ASCII characters of the string (a-z and <space>).
; found in tmp var $00 (low byte) $01 (high byte)
;
; Screen location:  position in nametable where drawing should begin
; found in X (low byte) Y (high byte)
draw_string:
    LDA $2002           ; read PPU status to reset the high/low latch to high
    STY $2006
    STX $2006

    LDX #$00            ; X will count down the size of the string
    LDA ($00, x)
    TAX                 ; X has length of string
    DEX                 ; Account for offset
    LDY #$01            ; Y is index into string
    write_char:
        LDA ($00), y
        STA $2007
        INY
        DEX
        BPL write_char
    RTS

; Expects one parameter in the accumulator
; The index into the pattern table of the boarder tile
draw_horizontal_boarder:
    LDX #0
    draw_one_boarder_segment:
        STA $2007
        INX
        CPX #16
        BNE draw_one_boarder_segment
    RTS

; No parameters; uses A X Y $00 $01
draw_vertical_boarders:
    LDA #$07
    STA $00
    LDA #$21
    STA $01
    LDY #$98
    LDX #0
    ; Y    The index into the pattern table of the left boarder tile
    ; X    Iteration counter
    ; $00  Low byte pointer to next boarder address in name table
    ; $01  High byte pointer to next boarder address in name table
    draw_one_side_boarder_segment_pair:
        JSR load_name_table_position
        ; write tile index of left boarder to name table
        STY $2007

        ; add 17 to pointer (never sets carry bit, does not effect high byte)
        LDA $00
        CLC
        ADC #17
        STA $00

        JSR load_name_table_position
        ; write tile index of right boarder to name table
        LDA #$96
        STA $2007

        ; add 15 to pointer (may set carry bit and effect high byte)
        LDA $00
        CLC
        ADC #15
        STA $00
        LDA $01
        ADC #0
        STA $01

        INX
        CPX #16         ; 16 rows
        BNE draw_one_side_boarder_segment_pair
    RTS


load_name_table_position:
    LDA $2002
    LDA $01
    STA $2006
    LDA $00
    STA $2006
    RTS


; X cell type 0-11
; Y cell position 0-15
draw_cell:
    ; $00   low byte of name table address
    ; $01   high byte of name table address
    ; $02   type of cell
    ; $03   cell position
    ; $04   chr cell boarder offset
    ; $05   chr cell boarder index
    ; $06   address of tile attr color index
    ; $07   attr color index 0-3
    ; $08   pointer to inner 4 chr tile label indices - low byte
    ; $09   pointer to inner 4 chr tile label indices - high byte
    STX $02
    STY $03
    TYA
    AND #%00001000
    CMP #%00001000
    BEQ load_22
    LDA #$21
    JMP store_high_byte_of_name_table_address
load_22:
    LDA #$22
store_high_byte_of_name_table_address:
    STA $01
    TYA
    AND #%00000100
    CMP #%00000100
    BEQ load_80
    LDA #0
    JMP move_base_low_byte_of_name_table_address
load_80:
    LDA #$80
move_base_low_byte_of_name_table_address:
    STA $00
    TYA
    AND #%00000011
    TAX
    LDA $00
    CLC
    ADC cell_x_column_name_table_address_data, x
    STA $00
    JSR load_name_table_position

    LDA $02
    STA $2007

    RTS




; RESET ------------------------------------------------------------------------

RESET:
    SEI                 ; SEt Interrupt disable; I flag = 1; disable IRQs
    CLD                 ; CLear Decimal mode; D flag = 0; Disable decimal mode
    LDX #%01000000      ; MI-- ---- IRQ inhib flag (I)
    STX $4017           ; disable APU frame IRQ (APU Frame Counter Register)
    LDX #$FF
    TXS                 ; Set up stack; Transfer Index X to Stack Register
    INX                 ; X = 255 + 1 = 0
    ; Now store 0 to the following 3 address to clear flags.
    STX $2000           ; disable NMI
    STX $2001           ; disable rendering
    STX $4010           ; Set APU DMC register to 0; disable DMC IRQs IL-- RRRR

; Apparently we have to wait for 2 frames before the PPU is ready...
; it was in bunnyboy's nerdy nights tutorial
    JSR wait_on_vblank        ; First wait for vblank to make sure PPU is ready

; Clear work ram
    LDX #$00
    LDA #$02
    STA $00
    LDA #$00
    STA $01
clear_work_ram:
    LDA #$CC
    STA ($00, x)
    INC $00
    LDA $00
    BNE clear_work_ram
    INC $01
    LDA $01
    CMP #$08
    BNE clear_work_ram
    LDA #$00
    STA $00
    STA $01

    JSR wait_on_vblank        ; Second wait for vblank, PPU is ready after this

; PALETTE
    LDA $2002           ; read PPU status to reset the high/low latch to high
    ; Set palette colors
    ; $3F00 - $3F0F )  Background palette
    ; $3F10 - $3F1F )  Sprite palette
    ; Set main background color at $3F00
    LDA #$3F
    STA $2006
    LDA #$00
    STA $2006
    LDX #$00
fill_palette:
    LDA palette, x
    STA $2007
    INX
    CPX #$20            ; Write 32 colors; 16 bg & 16 sprite
    BNE fill_palette

; nametable
    LDA $2002           ; read PPU status to reset the high/low latch to high
    LDA #$20
    STA $2006
    LDA #$00
    STA $2006

; Set entire screen to blank tile
    LDY #$00
; 256 tiles = 8 rows of blank tiles
draw_8_rows_of_blank_tiles:
    LDX #$00
    LDA #$20
draw_a_blank_tile:
    STA $2007
    INX
    CPX #$00
    BNE draw_a_blank_tile
    INY
    CPY #4
    BNE draw_8_rows_of_blank_tiles

; Show Score
    LDY #$20
    LDX #$68
    LDA #<score_string  ; low byte
    STA $00
    LDA #>score_string  ; high byte
    STA $01
    JSR draw_string
; Show Top Score
    LDY #$20
    LDX #$88
    LDA #<top_score_string  ; low byte
    STA $00
    LDA #>top_score_string  ; high byte
    STA $01
    JSR draw_string

; Draw grid

; draw top boarder
    LDA $2002
    LDA #$20
    STA $2006
    LDA #$E8
    STA $2006

    LDA #$A7
    JSR draw_horizontal_boarder

; draw bottom boarder
    LDA $2002
    LDA #$23
    STA $2006
    LDA #$08
    STA $2006

    LDA #$87
    JSR draw_horizontal_boarder

; draw left and right boarders
    JSR draw_vertical_boarders

; draw row of cells
    LDA $2002
    LDA #$21
    STA $2006
    LDA #$08
    STA $2006

    LDA #$86
    STA $2007
    LDA #$87
    STA $2007
    STA $2007
    LDA #$88
    STA $2007

    LDA #$86
    STA $2007
    LDA #$87
    STA $2007
    STA $2007
    LDA #$88
    STA $2007

    LDA #$86
    STA $2007
    LDA #$87
    STA $2007
    STA $2007
    LDA #$88
    STA $2007

    LDA #$86
    STA $2007
    LDA #$87
    STA $2007
    STA $2007
    LDA #$88
    STA $2007

; draw blank cells in grid

    LDX #5               ; X cell type 0-11
    LDY #3              ; Y cell position 0-15
    JSR draw_cell
    LDX #6               ; X cell type 0-11
    LDY #9              ; Y cell position 0-15
    JSR draw_cell
    LDX #9               ; X cell type 0-11
    LDY #15              ; Y cell position 0-15
    JSR draw_cell




; Enable PPU
    LDA #%00011110      ; D4 Sprites visible
                        ; D3 BG visible
                        ; D2 No sprite clipping
                        ; D1 No BG clipping
                        ; D0 Color display
    STA $2001

; Enable NMI (VBLANK)
    LDA #%10001000      ; D7    enable NMI (VBLANK), 
                        ; D3-4  BG patterns $0000; Sprite patterns $1000
    STA $2000           ; enable NMI

; variables
    ; addresses $0000-$000F used as temporary registers
    pointer_low = $00
    pointer_high = $01
    frame_counter = $10
    LDA #$00
    STA frame_counter
    y_pos = $11
    LDA #$AB
    STA y_pos
    score_low = $12
    score_high = $13
    board = $20         ; $0010 - $001F contain the board values
    ; enum tile state
    tile_empty = 0
    tile_2 = 1
    tile_4 = 2
    tile_8 = 3
    tile_16 = 4
    tile_32 = 5
    tile_64 = 6
    tile_128 = 7
    tile_256 = 8
    tile_512 = 9
    tile_1024 = 10
    tile_2048 = 11


; Main -------------------------------------------------------------------------

main:
; TODO  determine if inside animation sequence
animating:
; TODO  do next step in animation
waiting_on_input:
; Input
    ; Set bit 0 of $4016 high and then low (strobe)
    LDA #$01            ; Reset controller/reload button A
    STA $4016
    LDA #$00            ; Latch all values
    STA $4016
    LDA $4016           ; Player 1 - A
    LDA $4016           ; Player 1 - B
    LDA $4016           ; Player 1 - Select
    LDA $4016           ; Player 1 - Start
    LDA $4016           ; Player 1 - Up
    AND #$01
    BNE up_pressed
    LDA $4016           ; Player 1 - Down
    AND #$01
    BNE down_pressed
    LDA $4016           ; Player 1 - Left
    AND #$01
    BNE left_pressed
    LDA $4016           ; Player 1 - Right
    AND #$01
    BNE right_pressed

update_sprites:
; Sprites
    ; Set sprite data to be transfered to PPU
    LDX #$00
fill_sprites_loop:
    LDA sprite_data, x
    STA $0200, x
    INX
    CPX #$20            ; 8 sprites * 4 bytes = 32
    BNE fill_sprites_loop

    LDA y_pos           ; Y index
    STA $0220
    LDA #$00            ; Tile
    STA $0221
    LDA #%00000011      ; color
    STA $0222
    LDA #$00            ; X index
    CLC
    ADC frame_counter
    STA $0223

empty_loop:             ; kill time until next frame
    JMP empty_loop      ; infinite loop

up_pressed:
    DEC y_pos
    JMP update_sprites

down_pressed:
    INC y_pos
    JMP update_sprites

left_pressed:
    LDA #$00
    STA frame_counter
    JMP update_sprites

right_pressed:
    LDA #$F0
    STA frame_counter
    JMP update_sprites

; VBlank -----------------------------------------------------------------------

; When vblank interrupt, DMA sprite data and modify nametable
VBLANK:
    PLA                 ; pop proc status word off stack & throw away
    PLA                 ; pop PC off stack & throw away
; Copy sprites from work RAM to VRAM OAM
    ; Set automatic transfer of work RAM $0200 - $02FF
    LDA #$02
    STA $4014           ; OAM DMA address high byte
    LDA #$00
    STA $2003           ; OAM DMA address low byte

    INC frame_counter

; put name table changes here

; Reset PPU scroll since writes to PPU addr ($2006) overite this register
    LDA $2002
    LDA #$00
    STA $2005
    STA $2005

    JMP main

; When irqbrk interrupts are triggered,
; just immediately return from the  interrupt
IRQ:
    RTI


; Fill with zeros from current PC to $bffa
; (from end of program to end of rom)
; $8000 = 32,768 = 32 KB
; $BFFA = 49,146 = 48 KB
; * = end of program (current PC)
; 16 = size of iNES header in bytes
.dsb $BFFA-*, 0

.word VBLANK, RESET, IRQ

.bin 0,8192,"char.bin"
