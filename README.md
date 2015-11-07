Yet another 2048 on the NES
===========================

My first romp into NES programming.

Assemble program & run program

    ./run.sh

Just assemble program

    ./asm.sh

hex dump game

    xxd game.o65 | less

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
- VBlank:  make changes to name table; DMA copy sprites

Author:  Lyall Jonathan Di Trapani
