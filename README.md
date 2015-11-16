Yet another 2048 on the Nintendo Entertainment System (NES)
===========================================================

My first romp into NES programming.

Assemble program & run program

    ./run.sh

Just assemble program

    ./asm.sh

hex dump game

    xxd 2048.nes | less

States
------

- Rendering
    - animating (ignore input)
        - step of animation
    - waiting for input
        - receive up
        - receive down
        - receive left
        - receive right
- end of game
    - win: press a to play again
    - lose: press a to play again
        - waiting for input
            - receive a
- VBlank:  make changes to name table; DMA copy sprites


TODO
-----
Finish setting initial background
- grid
    - make draw_cell(x,y,type)
- draw_cell(x,y,type)
    - make better use of labels in subroutine
        - use scopes to make local labels .( .)
    - used to draw initial background
    - used to change individual cells during game
    - parameters:  cell_pos: 0-15, type: 0-11
    - type

```
        0  blank
        1      1
        2      2
        3      8
        4     16
        5     32
        6     64
        7    128
        8    256
        9    512
        10  1024
        11  2048
```


Author:  Lyall Jonathan Di Trapani
