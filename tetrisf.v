`timescale 1ns / 1ns
module tetris1( Reset, Clk, Start, try_again, Left, Right, Down, Rotate,
	O_Initial, O_Generate, O_Rotate, O_Collision, O_Lose, blocks, score, orientation, position, next_block
    );

input Reset, Clk;
input Start, try_again;	
input Left, Right, Down;
input Rotate;
	
output O_Initial, O_Generate;
output O_Rotate, O_Collision, O_Lose;


output reg [159:0] blocks;
output reg [7:0] score;
reg [7:0] state;

// Current Block Information
output reg [7:0] position;
integer i;
reg [2:0] block_type;
output reg [1:0] orientation;
output reg [2:0] next_block;

// Number of Loops for Rotate and Move
reg [24:0] loop;
reg [2:0] random_count;
wire [19:0] full_rows;
reg [151:0] block_update ;

// Check if space is avaliable for a rotate or move down Wire
// Square
wire square_left, square_right, square_down;
assign square_left = !blocks[position-2] && !blocks[position -10] && ((position-1)%8);//left movement
assign square_right = !blocks[position+1] && !blocks[position-7] && ((position+1)%8);//right movement
assign square_down = !blocks[position-16] && !blocks[position-17] && (position > 15) ;//down movement
//Bar
wire bar0_l, bar0_r, bar0_d, bar0_rot, bar1_l, bar1_r, bar1_d, bar1_rot;  // Two orientations  
assign bar0_l = !blocks[position-3] && ((position-2)%8);
assign bar0_r = !blocks[position+2] && ((position+2)%8);
assign bar0_d = !blocks[position-7] && !blocks[position-8] && !blocks[position-9] && !blocks[position-10] && position > 7; 
assign bar0_rot = (position/8 != 19) && !blocks[position+8] && !blocks[position-8] && !blocks[position-16] && (position >15);
assign bar1_l = !blocks[position-1] && !blocks[position-9] && !blocks[position-17] && !blocks[position+7] && position%8;
assign bar1_r = !blocks[position+1] && !blocks[position+9] && !blocks[position-7] && !blocks[position -15] && (position+1)%8;
assign bar1_d = !blocks[position-24] && (position > 23);
assign bar1_rot = !blocks[position +1] && !blocks[position-1] && !blocks[position-2] && (position+1)%8 && position%8;



//for Row clear condition
wire above_row, position_row, below_row, double_below_row;
assign above_row = blocks[(position/8 +1)*8] && blocks[(position/8+1)*8 + 1]
					&& blocks[(position/8+1)*8 + 2]&& blocks[(position/8+1)*8 + 3]
					&& blocks[(position/8+1)*8 + 4]&& blocks[(position/8+1)*8 + 5]
					&& blocks[(position/8+1)*8 + 6]&& blocks[(position/8+1)*8 + 7]; 
assign position_row = blocks[(position/8)*8] && blocks[(position/8)*8 + 1]
					&& blocks[(position/8)*8 + 2]&& blocks[(position/8)*8 + 3]
					&& blocks[(position/8)*8 + 4]&& blocks[(position/8)*8 + 5]
					&& blocks[(position/8)*8 + 6]&& blocks[(position/8)*8 + 7]; 
assign below_row = blocks[(position/8-1)*8] && blocks[(position/8-1)*8 + 1]
					&& blocks[(position/8-1)*8 + 2]&& blocks[(position/8-1)*8 + 3]
					&& blocks[(position/8-1)*8 + 4]&& blocks[(position/8-1)*8 + 5]
					&& blocks[(position/8-1)*8 + 6]&& blocks[(position/8-1)*8 + 7]; 
assign double_below_row = blocks[(position/8-2)*8] && blocks[(position/8-2)*8 + 1]
					&& blocks[(position/8-2)*8 + 2]&& blocks[(position/8-2)*8 + 3]
					&& blocks[(position/8-2)*8 + 4]&& blocks[(position/8-2)*8 + 5]
					&& blocks[(position/8-2)*8 + 6]&& blocks[(position/8-2)*8 + 7]; 


assign { O_Lose, O_Collision, O_Rotate, O_Generate, O_Initial} = state[4:0] ;//lose is 1 bit I is LSB
	

localparam
	INITIAL = 8'b0000_0001,
	GENERATE_PIECE = 8'b0000_0010,
	ROTATE_PIECE = 8'b0000_0100,
	COLLISION = 8'b0000_1000,//bottom collison with other blocks
	LOSE = 8'b0001_0000,//at the top collioson
	CLEAR_ROW = 8'b0010_0000,
	UNKNOWN = 8'bxxxx_xxxx;
	
//temp
localparam
	empty_row = 8'b0000_0000,
	full_row = 8'b1111_1111,
	loop_max =  25'd1; //25'b11111_11111_11111_11111_11111 (25'd1,max extreme case 24 +1)
	

//pieces	
localparam
	SQUARE = 3'b000,
	BAR = 3'b001;
/*	S = 3'b010,
	Z = 3'b011,
	L = 3'b100,
	J = 3'b101,
	T = 3'b110;*/

initial begin
	random_count = $random;
end
	
always @ (posedge Clk )
	begin
		if(random_count >= 3'b001)
			random_count <= 0;  
		else
			random_count <= random_count+ 1'b1;
	end
	
	
	
always @ (posedge Clk, posedge Reset)
	begin
		if(Reset)
			begin 
			state <= INITIAL;
			loop <= 25'd0;
			for(i=0; i<160; i = i+1)
				begin
				blocks[i] <= 0;
				end
			score <= 0;
			position <= 0;
			end
		else
			begin
			case(state)
				INITIAL : 
					begin
					if(Start)
						state <= GENERATE_PIECE;
					else
						state <= INITIAL;
					
					loop <= 25'd0;
					for(i=0; i<160; i = i+1)
					begin
					blocks[i] <= 0;
					end
					score <= 0;
					position <= 0;
					block_type <= random_count%2 ; 
					next_block <= random_count%2;
					orientation <= 2'b00;
					
					end
				GENERATE_PIECE :
					begin
					case(next_block)
					SQUARE :
						begin
						if(blocks[154] || blocks[153] || blocks[146] || blocks[145]	)
							state <= LOSE;
						else
							state <= ROTATE_PIECE;
						end
					BAR :
						begin
						if(blocks[152] || blocks[153] || blocks[154] || blocks[155])
							state <= LOSE;
						else 
							state <= ROTATE_PIECE;
						end
					endcase
					
					
					//State Actions
					block_type <= next_block;//next block to current block
					next_block <= random_count %2; //change for all blocks
					orientation <= 2'b00;
					position <= 8'd154;
					loop <= 25'b0;
					case( next_block)
					SQUARE:
						begin
						blocks [154] <= 1;
						blocks[153] <= 1;
						blocks[146]<= 1;
						blocks[145] <= 1;
						end
					BAR:
						begin 
						blocks[152] <= 1;
						blocks[153] <= 1;
						blocks[154] <= 1;
						blocks[155] <= 1;
						end
					endcase
					end
				ROTATE_PIECE :
					begin
					if( loop < loop_max)
						state <= ROTATE_PIECE;
					else if(loop == loop_max)
						state <= COLLISION;
						
					loop<= loop+ 1'b1;
					
					if(block_type == SQUARE)
						begin					
						if(Left && square_left )//Move towards left
							begin
							blocks[position] <= 0;
							blocks[position-8] <= 0;
							blocks[position-10] <= 1;
							blocks[position -2] <= 1;
							position <= position - 1'b1;
							
							end
						else if( Right && square_right)//Move towards right
							begin
							blocks[position-1] <= 0;
							blocks[position-9] <=0;							
							blocks[position +1] <= 1;
							blocks[position - 7] <= 1;
							position <= position + 1'b1;
						 
							end
						else if( Down && square_down)//Move downwards
							begin
							blocks[position] <= 0;
							blocks[position-1] <= 0;							
							blocks[position-16] <= 1;
							blocks[position-17] <= 1;
							position <= position - 4'd8;
							loop<= 25'd0;
							end
						end						
					else if(block_type == BAR)
						begin
						if(Left && !orientation[0] && bar0_l)
							begin
							blocks[position +1] <= 0;
							blocks[position -3] <= 1;
							position <= position - 1'b1;
							end							
						else if(Right && !orientation[0] && bar0_r)
							begin
							blocks[position +2] <= 1;
							blocks[position -2] <= 0;
							position <= position+1'b1;
							end
						else if(Down && !orientation[0] && bar0_d)
							begin
							blocks[position] <= 0;
							blocks[position+1] <= 0;
							blocks[position-1] <= 0;
							blocks[position-2] <= 0;
							blocks[position-7] <= 1;
							blocks[position-8] <= 1;
							blocks[position-9] <= 1;
							blocks[position-10] <= 1;
							position <= position -4'd8;
							loop<= 25'd0;
							end
						else if(Rotate && !orientation[0] && bar0_rot)
							begin
							blocks[position+8] <= 1;
							blocks[position-8] <= 1;
							blocks[position-16] <= 1;
							blocks[position-2] <= 0;
							blocks[position-1] <= 0;
							blocks[position +1] <= 0;
							orientation <= 2'b01;
							end
						else if(Left && orientation[0] && bar1_l)
							begin
							blocks[position +8] <= 0; 
							blocks[position] <= 0; 
							blocks[position -8] <= 0; 
							blocks[position -16] <= 0;
							blocks[position +7] <= 1; 
							blocks[position-1] <= 1; 
							blocks[position -9] <= 1; 
							blocks[position -17] <= 1;
							position <= position - 1'b1;
							end
						else if(Right && orientation[0] && bar1_r)
							begin
							blocks[position +8] <= 0; 
							blocks[position] <= 0; 
							blocks[position -8] <= 0; 
							blocks[position -16] <= 0;
							blocks[position +9] <= 1; 
							blocks[position+1] <= 1; 
							blocks[position -7] <= 1; 
							blocks[position -15] <= 1;
							position <= position +1'b1;
							end
						else if(Down && orientation[0]  && bar1_d)
							begin
							blocks[position +8] <= 0;
							blocks[position -24] <= 1;
							position <= position -4'd8;
							loop<= 25'd0;
							end
						else if(Rotate && orientation[0] && bar1_rot)
							begin
							blocks[position+8] <= 0;
							blocks[position-8] <= 0;
							blocks[position-16] <= 0;
							blocks[position+1] <= 1;
							blocks[position-1] <= 1;
							blocks[position-2] <= 1;
							orientation <= 2'b00;
							end
						end		
					end
				COLLISION :
					begin
					if( (block_type == SQUARE && !square_down && (position_row + below_row) ==2 )  //current and below row full 
						|| (block_type == BAR && !(orientation[0] ? bar1_d : bar0_d) && 
							(orientation[0] ? (above_row + position_row + below_row + double_below_row) >1 : position_row)))
						state <= CLEAR_ROW;
					else if( (block_type == SQUARE && !square_down)
							|| block_type == BAR && !(orientation[0] ? bar1_d : bar0_d))
						state <= GENERATE_PIECE;
					else 
						state <= ROTATE_PIECE;
					
					
					if(block_type == SQUARE)
						begin
						if(square_down)
							begin
							blocks[position] <= 0;
							blocks[position-1] <= 0;							
							blocks[position-16] <= 1;
							blocks[position-17] <= 1;
							position <= position - 4'd8;//down movement of player
							loop<= 25'd0;
							end
						end
					else if(block_type == BAR)
						begin
						if( !orientation[0])
							begin
							if(bar0_d)
								begin
								blocks[position] <= 0;
								blocks[position+1] <= 0;
								blocks[position-1] <= 0;
								blocks[position-2] <= 0;
								blocks[position-7] <= 1;
								blocks[position-8] <= 1;
								blocks[position-9] <= 1;
								blocks[position-10] <= 1;
								position <= position -4'd8;
								loop <= 25'd0;
								end
							end	
						else if(orientation[0])
							begin
							if(bar1_d)
								begin
								blocks[position+8] <= 0;
								blocks[position-24] <= 1;
								position <= position - 4'd8;
								loop <= 25'd0;
								end					
							end
						end	
					end // end of the Collision State
				CLEAR_ROW:
					begin
					if( (block_type == SQUARE && !square_down && (position_row + below_row) ==2 )   
						|| (block_type == BAR && !(orientation[0] ? bar1_d : bar0_d) && 
							(orientation[0] ? (above_row + position_row + below_row + double_below_row) >1 : position_row)))
						begin
						state <= CLEAR_ROW;
						block_update<=blocks[159:8];
						blocks[151:0]<=block_update;
						blocks[159:152]<=8'b00000000;
						end
					else
						state <= GENERATE_PIECE;
					
					
					
					end
				LOSE: 
					begin
					if(try_again)//try again
						state<= INITIAL;
					else
						state<= LOSE;							
					end
				default : state <= UNKNOWN;
				endcase
			end
	end
endmodule
