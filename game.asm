; Author)  "Lyall Jonathan Di Trapani <lj.ditrapani@gmail.com>" ----------------
.aasc "NES", $1A    ; Static NES\n in header
.byt 1              ; PRG ROM data 1 X 16,384 bytes
.byt 1              ; CHR ROM data 1 X  8,192 bytes
.byt %00000001      ; Flags 6, horizontal scroll (vertical mirroring)
.byt %00000000      ; Flags 7
.byt 1              ; PRG RAM 1 X 8,192 bytes
.byt %00000000      ; Flags 9
.byt %00000000      ; Flags 10
.dsb 5,0            ; Bytes 11-15 zero filled
; Flags 6
; bit  0)   0 vertical scroll  --  1 horizontal scroll
; bits 1)   Set battery backeg PRG RAM ($6000-7FFF)
; bits 2)   Set 512-byte trainer at $7000-$71FF (stored before PRG data)
; bit  3)   Set 4-screen VRAM (ignor bits 0-2)
; bits 4-7) mapper number

; Set PC to $8000
* = $8000

int_reset:
    LDA #$FF

; When vblank or irqbrk interrupts are triggered,
; just immediately return from the  interrupt
int_vblank:
int_irqbrk:
    rti


; Fill with zeros from current PC to $bffa
; (from end of program to end of rom)
.dsb $bffa-*-16, 0

.word int_vblank, int_reset, int_irqbrk
