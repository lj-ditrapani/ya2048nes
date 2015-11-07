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

    LDA #%00001000      ; BG patterns $0000; Sprite patterns $1000
    STA $2000

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

;wait_on_vblank:
;    LDA $2002
;    BPL wait_on_vblank

nametable:
    LDA #$20
    STA $2006
    LDA #$00
    STA $2006

; Fill first 2 rows of nametable with C
    LDX #$00
    LDA #$02
first_2_rows_of_nametable:
    STA $2007
    INX
    CPX #$40
    BNE first_2_rows_of_nametable

; Show entire nametable on screen
    LDA #$00    ; CHR index
    LDY #$00    ; row counter
fill_nametable_loop:
    LDX #$00    ; column counter
write_a_chr:
    STA $2007
    CLC
    ADC #$1
    INX
    CPX #$10
    BNE write_a_chr

write_a_blank:
    STA $2007
    INX
    CPX #$20
    BNE write_a_blank

    INY
    CPY #$10
    BNE fill_nametable_loop

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

; frame_counter
    frame_counter = $0000
    LDA #$00
    STA frame_counter

loop:
    JMP loop            ; infinite loop


; When vblank or irqbrk interrupts are triggered,
; just immediately return from the  interrupt
VBLANK:

; Sprites
    ; Set sprit data to be transfered to PPU
    LDX #$00
fill_sprites_loop:
    LDA sprite_data, x
    STA $0200, x
    INX
    CPX #$20            ; 8 sprites * 4 bytes = 32
    BNE fill_sprites_loop

    LDA #$A8            ; Y index
    STA $0220
    LDA #$00            ; Tile
    STA $0221
    LDA #%00000000      ; color
    STA $0222
    LDA #$80            ; X index
    CLC
    ADC frame_counter
    STA $0223

    ; Set automatic transfer of work RAM $0200 - $02FF
    LDA #$02
    STA $4014           ; OAM DMA address high byte
    LDA #$00
    STA $2003           ; OAM DMA address low byte

    INC frame_counter

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
