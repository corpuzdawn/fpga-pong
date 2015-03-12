module pong(CLK50, LEDR, LEDG, HEX0, HEX1, HEX2, HEX3, PB, SW);
	output [9:0] LEDR;
	output [7:0] LEDG;
	output [6:0] HEX0, HEX1, HEX2, HEX3;
	input [3:0] PB;
	input [9:0] SW;
	input CLK50;
	
	
	reg [4:0] pos;
	reg player1Pressed;
	reg player2Pressed;
	reg gameStarted;
	reg playerServed;
	reg enable;
	reg [7:0] score1, score2;
	reg direction;
	reg [1:0] ballSpeed;
	reg [1:0] savedBallSpeed;
	reg [25:0] N;

	//parameter N = 25_000_000;
//-------function bcdto7seg ------
function [6:0] bcdto7seg; //(bcd -> g,f,e,d,c,b,a);
input [4:0] bcd;
	
  case (bcd)
  0 :  bcdto7seg = 7'b1000000; 
  1 :  bcdto7seg = 7'b1111001; 
  2 :  bcdto7seg = 7'b0100100; 
  3 :  bcdto7seg = 7'b0110000; 
  4 :  bcdto7seg = 7'b0011001; 
  5 :  bcdto7seg = 7'b0010010; 
  6 :  bcdto7seg = 7'b0000011; 
  7 :  bcdto7seg = 7'b1111000; 
  8 :  bcdto7seg = 7'b0000000; 
  9 :  bcdto7seg = 7'b0010000; 
  default:  bcdto7seg = 7'b1111111; 						
 endcase
endfunction

initial begin
	ballSpeed = 0;
	pos = 1;
	direction = 0;
	enable = 0;
	gameStarted = 0;
	playerServed = 0;
	player1Pressed = 0;
	player2Pressed = 0;
	score1 = 0;
	score2 = 0;
end


wire [25:0] cnt1M;
mycnter #26 M1(CLK50, PB[1], 1, N, cnt1M); //(CLK, RESTE, N, q)

always @(posedge CLK50)
	if( SW[3] == 0 ) begin
	//reset 
		pos <= 1;
		direction <= 0;
		score1 <= 0;
		score2 <= 0;
		playerServed <= 0;
		gameStarted <= 0;
	end
	else if (SW[3] == 1) begin
		//Store ball speed on first run
		if (gameStarted == 0) begin
			ballSpeed <= SW[1:0]; // ballSpeed change
			savedBallSpeed <= SW[1:0];
			gameStarted <=1; 
		end
		
		else if (gameStarted == 1 && playerServed == 0) begin
		//Reset ball Speed
		ballSpeed <=savedBallSpeed;
		
		//Player 1 serve		
		if (PB[0]) player1Pressed <= 0;
		else if (!PB[0]) begin
			if (player1Pressed == 0) begin
				playerServed <= 1-playerServed;
				player1Pressed <= 1;
			end
		end
		
		//Player 2 serve
		if (PB[3]) player2Pressed <= 0;
		else if (!PB[3]) begin
			if (player2Pressed == 0) begin
				playerServed <=1-playerServed;
				player2Pressed <= 1;
			end
		end
	end
	
	else if (gameStarted == 1 && playerServed == 1) begin
		//Update ball position on direction and speed
		if (cnt1M == N) begin
			if (direction == 0) pos <= pos + 1; //Ball to Player 2
			else if (direction == 1) pos <= pos - 1; //Ball to Player 1
		end
		
		//Always reset player1/2Pressed to zero if not pressed
		//So that when the game starts, the paddle workss
		if (PB[0]) player1Pressed <= 0;
		if (PB[3]) player2Pressed <= 0;
		
		
		//Check for player input at certain positions 
		//For change of directions and ballSpeed
		//Player 1
		if (pos == 1 && direction == 1)begin //outside
			if(!PB[0]) begin
				if (player1Pressed == 0) begin
					direction <= 1 - direction;
					player1Pressed <= 1;
				end
			end
		end
		if (pos == 2 && direction == 1) begin //inside
			if(!PB[0]) begin
				if(player1Pressed == 0) begin
					if (ballSpeed < 3) ballSpeed <= ballSpeed + 1;
					direction <= 1 - direction;
					player1Pressed <= 1;
				end
			end
		end
		
		//Player 2
		if (pos == 18 && direction == 0) begin //outside
			if (!PB[3]) begin
				if (player2Pressed == 0) begin
				direction <= 1-direction;
				player2Pressed <= 1;
				end
			end
		end
		if (pos == 17 && direction == 0) begin //inside
			if (!PB[3]) begin
				if (player2Pressed == 0) begin
				if (ballSpeed < 3) ballSpeed <= ballSpeed + 1;
				direction <= 1-direction;
				player2Pressed <= 1;
				end
			end
		end
		
		//Check for win conditions
		if (pos == 0) begin //Player 1 missed, Player 2 scores
				pos <= 1; // loser serves
				direction <= 0;
				score2 <= score2 +1;
				playerServed <= 0; //To make the player2 serve again
		end
		if (pos == 19) begin //Player 2 missed, Player 1 scores
				pos <= 18; // loser serves
				direction <= 1;
				score1 <= score1 +1;
				playerServed <= 0; //To make the player2 serve again
		end
	end
end

//Ball Speed
always @(posedge CLK50)
	if(ballSpeed == 0) N <= 30_000_000; //Slow
	else if (ballSpeed == 1) N <=15_000_000; //Normal
	else if (ballSpeed == 2) N <=8_000_000; //Fast
	else if (ballSpeed == 3) N <=2_000_000; //Fastest
	
//Display scores
assign HEX0 = bcdto7seg(score1 % 10);
assign HEX1 = bcdto7seg(score1 / 10);
assign HEX2 = bcdto7seg(score2 % 10);
assign HEX3 = bcdto7seg(score2 / 10);
 
/*//Serve direction
always @(posedge CLK50)
	if(gameStarted==1 && playerServed==1) begin
		//update ball position on direction and speed
		if (cnt1M == N) begin
			if (direction == 0) pos <= pos + 1; //ball to Player2
			else if (direction ==1) pos <= pos -1; //ball to Player1
			else if (pos == 19) begin // P2 missed, P1 scores
				pos <= 18;
				direction <= 1;
				score1 <= score1 + 1;
				playerServed <= 0; // make sure this is last
			end
			else if (pos == 0) begin // P1 missed, P2 scores
				pos <= 1;
				direction <= 0;
				score2 <= score2 + 1;
				playerServed <= 0; // make sure this is last
			end
		end
	
		//Check for player input
		if(player1Pressed == 1) begin
			//Inner position
			if (pos == 2) begin
				direction <= 1 - direction; // reverse
				if (ballSpeed < 4) ballSpeed <= ballSpeed + 1; // and increase ball speed
			end
			//Outer position
			if (pos == 1) begin
				direction <= 1 - direction; // reverse only
			end
		end
	
		else if (player2Pressed ==1) begin	
			//Inner position
			if (pos == 17) begin
				direction <= 1 - direction; // reverse
				if (ballSpeed < 4) ballSpeed <= ballSpeed + 1; // and increase ball speed
			end
			//Outer position
			if (pos == 18) begin
				direction <= 1 - direction; // reverse only
			end
		end	
	end	

always @(posedge CLK50)
  case (ballSpeed)
	 0 : N = 50_000_000;
	 1 : N = 25_000_000;
	 2 : N = 10_000_000;
	 3 : N =  2_500_000;
   endcase 
   */


  
  
//Ball Position
function [17:0] display; 
input [4:0] pos;
	
  case (pos)
  1 : display = 18'b000000000000000001;
  2 : display = 18'b000000000000000010;
  3 : display = 18'b000000000000000100;
  4 : display = 18'b000000000000001000;
  5 : display = 18'b000000000000010000;
  6 : display = 18'b000000000000100000;
  7 : display = 18'b000000000001000000;
  8 : display = 18'b000000000010000000;
  9 : display = 18'b000000000100000000;
  10 : display = 18'b000000001000000000;
  11 : display = 18'b000000010000000000;
  12 : display = 18'b000000100000000000;
  13 : display = 18'b000001000000000000;
  14 : display = 18'b000010000000000000;
  15 : display = 18'b000100000000000000;
  16 : display = 18'b001000000000000000;
  17 : display = 18'b010000000000000000;
  186r : display = 18'b100000000000000000;  
  default:  display = 18'b000000000000000000; 						
 endcase
endfunction

//Lights LEDs

wire[17:0] displayoutput;
assign displayoutput = display(pos);

assign LEDG = displayoutput[7:0];
assign LEDR = displayoutput[17:8];

endmodule

module mycnter(clk, rst, startn, stopn, q);
parameter N = 3;
input clk, rst;
input [N-1:0] startn, stopn;
output [N-1:0] q;
reg [N-1:0] q;

initial q = startn;
always @(posedge clk)
  if (!rst) q <= startn;
  else 
	begin
	  if (q == stopn) q <= startn;
	  else			q <= q + 1;
	end
	  
endmodule





