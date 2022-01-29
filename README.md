# Tetris-in-verilog-simulation
Tetris is a retro game where the objective for the player is to move blocks of different shapes to form as many lines as possible which then gets cleared. If the player arranges the block in such a way that the blocks touch the roof the game the game is over. Tetris was one of my favourite games as a toddler and recreating it using verilog sparked interest within me.

Assumptions:
● The original Tetris game has 7 Tetriminos but in the case for this project I have
used only 2 Tetriminos namely Bar and Square.
● The grid size is 160 with 20 rows and 8 columns
● The point of reference for block generation is block 154 , every calculation for
block generation , rotation and movement is based on this block
● The states have been defined in the following way
INITIAL = 8'b0000_0001,
GENERATE_PIECE = 8'b0000_0010,
ROTATE_PIECE = 8'b0000_0100,
COLLISION = 8'b0000_1000,//bottom collision with other blocks
LOSE = 8'b0001_0000,//at the top collision
CLEAR_ROW = 8'b0010_0000,
UNKNOWN = 8'bxxxx_xxxx;
