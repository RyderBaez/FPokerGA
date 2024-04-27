// ----------------------------------------------------------------------
//  A Verilog module for Poker
//
//  Written by Ryder Baez and Eric Chen
//
//  Date: Apr 24, 2024
// ------------------------------------------------------------------------
module poker (	Switches, Start, Ack, 
					Check, Bet, Call, Fold,
					Clk, Reset,  SCEN,  // Notice SCEN
					Done, Card1, Card2, Card3, Card4, Card5,
					Player1card1, Player1card2, Player2card1, Player2card2,
					Player1balance, Player2balance,
					PlayerTurn, DispCards, Winner, Gameover,
					Player1state, Player2state, Betting);

		
input Start, Ack, Clk, Reset, Check, Bet, Call, Fold;
input [7:0] Switches;

output Done;
input SCEN;


reg [5:0] state;

//DO WE MAKE THESE OUTPUTS? ans yes think so
output [3:0] Card1, Card2, Card3, Card4, Card5, Player1card1, Player1card2, Player2card1, Player2card2;
output [7:0] Player1balance, Player2balance;
output PlayerTurn;
output DispCards;
output Winner;
output Gameover;
output Player1state;
output Player2state;
output Betting;

//need registers for inner state machine logic
reg [3:0] card1, card2, card3, card4, card5, player1card1, player1card2, player2card1, player2card2;
reg playerTurn;
reg dispCards;
reg gameover;
reg winner;
reg betting;

//reg [3:0] card1, card2, card3, card4, card5, player1card1, player1card2, player2card1, player2card2;
//reg [6:0] gamestate;

//Add registers for balance
reg [7:0] player1balance, player2balance, betLimit, bet, pot;

reg [5:0] player1state;     //Check localparams
reg [5:0] player2state;     //Check localparams
reg flag;
reg [3:0] player1_data [0:6];
reg [3:0] player2_data [0:6];
reg [3:0] i, j;
reg [3:0] temp;
reg [3:0] player1highcard;
reg [3:0] player2highcard;
reg [2:0] player1hand;
reg [2:0] player2hand;
reg player1sorted;
reg player2sorted;
reg player1High;
reg player2High;
reg [2:0] numpairs;

reg [12:0] randomNum;

localparam
START   = 6'b000001,
HAND	= 6'b000010,
THREE	= 6'b000100,
FOUR    = 6'b001000,
FIVE    = 6'b010000,
WINNER  = 6'b100000,

NOMOVE  =   6'b000001,
CHECK   =   6'b000010,
BET	    =   6'b000100,
CALL    =   6'b001000,
FOLD    =   6'b010000,
IN 		=	6'b100000,

HIGHCARD    =   3'b000,
PAIR        =   3'b001,
TWOPAIR     =   3'b010,
TRIPLE      =   3'b011,
STRAIGHT    =   3'b100,
FULLHOUSE   =   3'b101,
QUAD        =   3'b110;

assign {Qwinner, Q5card, Q4card, Q3card, Qhand, Qstart} = state;

assign NEXT_TURN = player1state == CALL || player2state == CALL || (player1state == CHECK && player2state == CHECK);
assign END_GAME = player1state == FOLD || player2state == FOLD;
			
always @(posedge Clk, posedge Reset) 
  
  begin  : CU_n_DU
    randomNum = {randomNum[8:0], state[9] ^ state[4]};

    if (Reset)
       begin
           state <= START;
           playerTurn <= 0;
           card1 <= 0; 
           card2 <= 0; 
           card3 <= 0; 
           card4 <= 0; 
           card5 <= 0; 
           player1card1 <= 0; 
           player1card2 <= 0; 
           player2card1 <= 0; 
           player2card2 <= 0;
           player1state <= NOMOVE;
           player2state <= NOMOVE;
           flag <= 0;
           dispCards <= 0;
           player1sorted <= 0;
           player2sorted <= 0;
           player1High <= 0;
           player2High <= 0;
           gameover <= 0;
            player1_data[0] <= 0;
            player1_data[1] <= 0;
            player1_data[2] <= 0;
            player1_data[3] <= 0;
            player1_data[4] <= 0;
            player1_data[5] <= 0;
            player1_data[6] <= 0;

            player2_data[0] <= 0;
            player2_data[1] <= 0;
            player2_data[2] <= 0;
            player2_data[3] <= 0;
            player2_data[4] <= 0;
            player2_data[5] <= 0;
            player2_data[6] <= 0;
			
			//ASSIGN BALANCES AT START OF GAME
			player1balance 		<= 		255; //start at 255
			player2balance 		<= 		255;
			betLimit 			<= 		8'b00000000;
			bet 				<= 		8'b00000000;
			pot 				<= 		8'b00000000;
			
            randomNum           <=      13'b1111010110101;
       end
    else
       begin
         (* full_case, parallel_case *)
         case (state)
            START : 
              begin
                randomNum = {randomNum[8:0], state[9] ^ state[4]};
                  // state transitions in the control unit
                  if (SCEN && Ack)
                  begin
                     state <= HAND;
                  end
                  
                  // RTL operations in the Data Path 
                    playerTurn <= 0;
                    card1 <= 0; 
                    card2 <= 0; 
                    card3 <= 0; 
                    card4 <= 0; 
                    card5 <= 0; 
                    player1card1 <= 0; 
                    player1card2 <= 0; 
                    player2card1 <= 0; 
                    player2card2 <= 0;
                    player1state <= NOMOVE;
                    player2state <= NOMOVE;
                    flag <= 0;
                    dispCards <= 0;
                    player1sorted <= 0;
                    player2sorted <= 0;
                    player1High <= 0;
                    player2High <= 0;
                    gameover <= 0;
                    betting <= 0;
                    player1_data[0] <= 0;
                    player1_data[1] <= 0;
                    player1_data[2] <= 0;
                    player1_data[3] <= 0;
                    player1_data[4] <= 0;
                    player1_data[5] <= 0;
                    player1_data[6] <= 0;
                    
                    player2_data[0] <= 0;
                    player2_data[1] <= 0;
                    player2_data[2] <= 0;
                    player2_data[3] <= 0;
                    player2_data[4] <= 0;
                    player2_data[5] <= 0;
                    player2_data[6] <= 0;
				    
					pot 		<= 8'b00000000;
					betLimit 	<= 8'b00000000;
					randomNum = {randomNum[8:0], state[9] ^ state[4]};
            end
            HAND :
            begin
			// state transitions in the control unit
			if(flag == 0)
			begin 
				//NOTE: MAYBE FIX LATER, this is not real poker b/c so many repeat cards exist
				flag <= 1;
				player1card1 = randomNum % 13 + 2;
				randomNum = {randomNum[8:0], state[9] ^ state[4]};
				player1card2 = randomNum % 13 + 2;
				randomNum = {randomNum[8:0], state[9] ^ state[4]};
				player2card1 = randomNum % 13 + 2;
				randomNum = {randomNum[8:0], state[9] ^ state[4]};
				player2card2 = randomNum % 13 + 2;
			end
			else if (NEXT_TURN )
			begin
				state <= THREE;
				flag <= 0;
				player1state <= NOMOVE;
				player2state <= NOMOVE;
				betLimit <= 0;
				playerTurn <= 0;
			end
			else if(END_GAME)
			begin
				state <= WINNER;
				flag <= 0;
				betLimit <= 0;
				betting <= 0;
			end
			// RTL operations in the Data Path 
			else if(playerTurn == 0)
			begin
				if(player1state == BET)
				begin
					bet <= Switches;
					if(Bet && SCEN)
					begin
						player1state <= NOMOVE;	//pressing BET again cancels the bet
						betting <= 0;
					end
					else if(bet <= player1balance && bet > betLimit && Ack  && SCEN) //press middle button to submit bet
					begin
						playerTurn <= 1;
						player1balance <= player1balance - bet;
						pot <= pot + bet;
						player1state <= IN;
						betLimit <= bet;
						betting <= 0;
					end
				end
				else
				begin
					if(Ack && SCEN) //changes card visibility
					begin
						if(dispCards == 1)
						begin
							dispCards <= 0;
						end 
						else
						begin
							dispCards <= 1;
						end
					end 
					if(player2state != NOMOVE && player2state != CHECK && Call && SCEN)
					begin
						playerTurn <= 1;
						dispCards <= 0;
						pot 			<= 	(player1balance > betLimit)	? pot + betLimit : pot + player1balance;
						player1balance 	<= 	(player1balance > betLimit)	? player1balance - betLimit : 0;
						player1state <= CALL; //After call, round ends (2 player implementation)
					end 
					if(player1state != IN && Bet && SCEN)
					begin
						dispCards <= 0;
						player1state <= BET; //Players cannot re-raise (can only bet once)
						betting <= 1;
					end
					if((player2state == NOMOVE || player2state == CHECK) && player1state == NOMOVE && Check && SCEN)
					begin
						playerTurn <= 1;
						dispCards <= 0;
						player1state <= CHECK; //Check can only happen if nobody has bet
					end
					if(Fold && SCEN)
					begin
						playerTurn <= 1;
						dispCards <= 0;
						player1state <= FOLD; //After fold, game ends (2 player implementation)
					end
				end
				// ^ player1 makes their move
			end
			else if(playerTurn == 1)
			begin
				if(player2state == BET)
				begin
				    bet <= Switches;
					if(Bet && SCEN)
					begin
						player2state <= NOMOVE;	//pressing BET again cancels the bet
						betting <= 0;
					end
					else if(bet <= player2balance && bet > betLimit && Ack && SCEN) //press middle button to submit bet
					begin
						playerTurn <= 0;
						player2balance <= player2balance - bet;
						pot <= pot + bet;
						player2state <= IN;
						betLimit <= bet;
						betting <= 0;
					end
				end
				else
				begin
					if(Ack && SCEN) //changes card visibility
					begin
						if(dispCards == 1)
						begin
							dispCards <= 0;
						end 
						else
						begin
							dispCards <= 1;
						end
					end 
					if(player1state != NOMOVE && player1state != CHECK && Call && SCEN) //P2 CALL
					begin
						playerTurn <= 0;
						dispCards <= 0;
						pot 			<= 	(player2balance > betLimit)	? pot + betLimit : pot + player2balance;
						player2balance 	<= 	(player2balance > betLimit)	? player2balance - betLimit : 0;
						player2state <= CALL; //After call, round ends (2 player implementation)
					end 
					if(player2state != IN && Bet && SCEN) //P2 BET
					begin
						dispCards <= 0;
						player2state <= BET; //Players cannot re-raise (can only bet once)
						betting <= 1;
					end
					if((player1state == NOMOVE || player1state == CHECK) && player2state == NOMOVE && Check && SCEN) //P2 CHECK
					begin
						playerTurn <= 0;
						dispCards <= 0;
						player2state <= CHECK; //Check can only happen if nobody has bet
					end
					if(Fold && SCEN) //P2 FOLD
					begin
						playerTurn <= 0;
						dispCards <= 0;
						player2state <= FOLD; //After fold, game ends (2 player implementation)
					end
				end
				// ^ player 2 makes their move
			end            
			end      
            THREE  :
            begin           
			if(flag == 0)
				begin
					flag <= 1;
					card1 = randomNum % 13 + 2;
					randomNum = {randomNum[8:0], state[9] ^ state[4]};
					card2 = randomNum % 13 + 2;
					randomNum = {randomNum[8:0], state[9] ^ state[4]};
					card3 = randomNum % 13 + 2;
					randomNum = {randomNum[8:0], state[9] ^ state[4]};
				end
			else if (NEXT_TURN)
				begin
					state <= FOUR;
					player1state <= NOMOVE;
					player2state <= NOMOVE;
					flag <= 0;
					betLimit <= 0;
					playerTurn <= 0;
				end
			else if(END_GAME)
				begin
					state <= WINNER;
					flag <= 0;
					betLimit <= 0;
				end
			// RTL operations in the Data Path 
			else if(playerTurn == 0)
			begin
				if(player1state == BET)
				begin
					bet <= Switches;
					if(Bet && SCEN)
					begin
						player1state <= NOMOVE;	//pressing BET again cancels the bet
						betting <= 0;
					end
					else if(bet <= player1balance && bet > betLimit && Ack  && SCEN) //press middle button to submit bet
					begin
						playerTurn <= 1;
						player1balance <= player1balance - bet;
						pot <= pot + bet;
						player1state <= IN;
						betLimit <= bet;
						betting <= 0;
					end
				end
				else
				begin
					if(Ack && SCEN) //changes card visibility
					begin
						if(dispCards == 1)
						begin
							dispCards <= 0;
						end 
						else
						begin
							dispCards <= 1;
						end
					end 
					if(player2state != NOMOVE && player2state != CHECK && Call && SCEN)
					begin
						playerTurn <= 1;
						dispCards <= 0;
						pot 			<= 	(player1balance > betLimit)	? pot + betLimit : pot + player1balance;
						player1balance 	<= 	(player1balance > betLimit)	? player1balance - betLimit : 0;
						player1state <= CALL; //After call, round ends (2 player implementation)
					end 
					if(player1state != IN && Bet && SCEN)
					begin
						dispCards <= 0;
						player1state <= BET; //Players cannot re-raise (can only bet once)
						betting <= 1;
					end
					if((player2state == NOMOVE || player2state == CHECK) && player1state == NOMOVE && Check && SCEN)
					begin
						playerTurn <= 1;
						dispCards <= 0;
						player1state <= CHECK; //Check can only happen if nobody has bet
					end
					if(Fold && SCEN)
					begin
						playerTurn <= 1;
						dispCards <= 0;
						player1state <= FOLD; //After fold, game ends (2 player implementation)
					end
				end
				// ^ player1 makes their move
			end
			else if(playerTurn == 1)
			begin
				if(player2state == BET)
				begin
	                bet <= Switches;
					if(Bet && SCEN)
					begin
						player2state <= NOMOVE;	//pressing BET again cancels the bet
						betting <= 0;
					end
					else if(bet <= player2balance && bet > betLimit && Ack && SCEN) //press middle button to submit bet
					begin
						playerTurn <= 0;
						player2balance <= player2balance - bet;
						pot <= pot + bet;
						player2state <= IN;
						betLimit <= bet;
						betting <= 0;
					end
				end
				else
				begin
					if(Ack && SCEN) //changes card visibility
					begin
						if(dispCards == 1)
						begin
							dispCards <= 0;
						end 
						else
						begin
							dispCards <= 1;
						end
					end 
					if(player1state != NOMOVE && player1state != CHECK && Call && SCEN) //P2 CALL
					begin
						playerTurn <= 0;
						dispCards <= 0;
						pot 			<= 	(player2balance > betLimit)	? pot + betLimit : pot + player2balance;
						player2balance 	<= 	(player2balance > betLimit)	? player2balance - betLimit : 0;
						player2state <= CALL; //After call, round ends (2 player implementation)
					end 
					if(player2state != IN && Bet && SCEN) //P2 BET
					begin
						dispCards <= 0;
						player2state <= BET; //Players cannot re-raise (can only bet once)
						betting <= 1;
					end
					if((player1state == NOMOVE || player1state == CHECK) && player2state == NOMOVE && Check && SCEN) //P2 CHECK
					begin
						playerTurn <= 0;
						dispCards <= 0;
						player2state <= CHECK; //Check can only happen if nobody has bet
					end
					if(Fold && SCEN) //P2 FOLD
					begin
						playerTurn <= 0;
						dispCards <= 0;
						player2state <= FOLD; //After fold, game ends (2 player implementation)
					end
				end
				// ^ player 2 makes their move
			end            
			end   
            FOUR :
            begin
                if(flag == 0)
                begin
                    flag <= 1;
                    card4 <= randomNum % 13 + 2;
                    randomNum = {randomNum[8:0], state[9] ^ state[4]};
                end
                else if (NEXT_TURN )
                begin
                    state <= FIVE;
                    player1state <= NOMOVE;
                    player2state <= NOMOVE;
                    flag <= 0;
					betLimit <= 0;
					playerTurn <= 0;
                end
                else if(END_GAME)
                begin
                    state <= WINNER;
                    flag <= 0;
					betLimit <= 0;
                end 
			// RTL operations in the Data Path 
			else if(playerTurn == 0)
			begin
				if(player1state == BET)
				begin
					bet <= Switches;
					if(Bet && SCEN)
					begin
						player1state <= NOMOVE;	//pressing BET again cancels the bet
						betting <= 0;
					end
					else if(bet <= player1balance && bet > betLimit && Ack  && SCEN) //press middle button to submit bet
					begin
						playerTurn <= 1;
						player1balance <= player1balance - bet;
						pot <= pot + bet;
						player1state <= IN;
						betLimit <= bet;
						betting <= 0;
					end
				end
				else
				begin
					if(Ack && SCEN) //changes card visibility
					begin
						if(dispCards == 1)
						begin
							dispCards <= 0;
						end 
						else
						begin
							dispCards <= 1;
						end
					end 
					if(player2state != NOMOVE && player2state != CHECK && Call && SCEN)
					begin
						playerTurn <= 1;
						dispCards <= 0;
						pot 			<= 	(player1balance > betLimit)	? pot + betLimit : pot + player1balance;
						player1balance 	<= 	(player1balance > betLimit)	? player1balance - betLimit : 0;
						player1state <= CALL; //After call, round ends (2 player implementation)
					end 
					if(player1state != IN && Bet && SCEN)
					begin
						dispCards <= 0;
						player1state <= BET; //Players cannot re-raise (can only bet once)
						betting <= 1;
					end
					if((player2state == NOMOVE || player2state == CHECK) && player1state == NOMOVE && Check && SCEN)
					begin
						playerTurn <= 1;
						dispCards <= 0;
						player1state <= CHECK; //Check can only happen if nobody has bet
					end
					if(Fold && SCEN)
					begin
						playerTurn <= 1;
						dispCards <= 0;
						player1state <= FOLD; //After fold, game ends (2 player implementation)
					end
				end
				// ^ player1 makes their move
			end
			else if(playerTurn == 1)
			begin
				if(player2state == BET)
				begin
				    bet <= Switches;
					if(Bet && SCEN)
					begin
						player2state <= NOMOVE;	//pressing BET again cancels the bet
						betting <= 0;
					end
					else if(bet <= player2balance && bet > betLimit && Ack && SCEN) //press middle button to submit bet
					begin
						playerTurn <= 0;
						player2balance <= player2balance - bet;
						pot <= pot + bet;
						player2state <= IN;
						betLimit <= bet;
						betting <= 0;
					end
				end
				else
				begin
					if(Ack && SCEN) //changes card visibility
					begin
						if(dispCards == 1)
						begin
							dispCards <= 0;
						end 
						else
						begin
							dispCards <= 1;
						end
					end 
					if(player1state != NOMOVE && player1state != CHECK && Call && SCEN) //P2 CALL
					begin
						playerTurn <= 0;
						dispCards <= 0;
						pot 			<= 	(player2balance > betLimit)	? pot + betLimit : pot + player2balance;
						player2balance 	<= 	(player2balance > betLimit)	? player2balance - betLimit : 0;
						player2state <= CALL; //After call, round ends (2 player implementation)
					end 
					if(player2state != IN && Bet && SCEN) //P2 BET
					begin
						dispCards <= 0;
						player2state <= BET; //Players cannot re-raise (can only bet once)
						betting <= 1;
					end
					if((player1state == NOMOVE || player1state == CHECK) && player2state == NOMOVE && Check && SCEN) //P2 CHECK
					begin
						playerTurn <= 0;
						dispCards <= 0;
						player2state <= CHECK; //Check can only happen if nobody has bet
					end
					if(Fold && SCEN) //P2 FOLD
					begin
						playerTurn <= 0;
						dispCards <= 0;
						player2state <= FOLD; //After fold, game ends (2 player implementation)
					end
				end
				// ^ player 2 makes their move
			end            
			end   
            FIVE :
            begin
				if(flag == 0)
					begin
						flag <= 1;
						card5 = randomNum % 13 + 2;
						randomNum = {randomNum[8:0], state[9] ^ state[4]};
					end
				else if (NEXT_TURN)
					begin
						state <= WINNER;
						player1state <= NOMOVE;
						player2state <= NOMOVE;
						flag <= 0;
						betLimit <= 0;
					    playerTurn <= 0;
					end
				else if(END_GAME)
					begin
						state <= WINNER;
						flag <= 0;
						betLimit <= 0;
					end 
			// RTL operations in the Data Path 
			else if(playerTurn == 0)
			begin
				if(player1state == BET)
				begin
					bet <= Switches;
					if(Bet && SCEN)
					begin
						player1state <= NOMOVE;	//pressing BET again cancels the bet
						betting <= 0;
					end
					else if(bet <= player1balance && bet > betLimit && Ack  && SCEN) //press middle button to submit bet
					begin
						playerTurn <= 1;
						player1balance <= player1balance - bet;
						pot <= pot + bet;
						player1state <= IN;
						betLimit <= bet;
						betting <= 0;
					end
				end
				else
				begin
					if(Ack && SCEN) //changes card visibility
					begin
						if(dispCards == 1)
						begin
							dispCards <= 0;
						end 
						else
						begin
							dispCards <= 1;
						end
					end 
					if(player2state != NOMOVE && player2state != CHECK && Call && SCEN)
					begin
						playerTurn <= 1;
						dispCards <= 0;
						pot 			<= 	(player1balance > betLimit)	? pot + betLimit : pot + player1balance;
						player1balance 	<= 	(player1balance > betLimit)	? player1balance - betLimit : 0;
						player1state <= CALL; //After call, round ends (2 player implementation)
					end 
					if(player1state != IN && Bet && SCEN)
					begin
						dispCards <= 0;
						player1state <= BET; //Players cannot re-raise (can only bet once)
						betting <= 1;
					end
					if((player2state == NOMOVE || player2state == CHECK) && player1state == NOMOVE && Check && SCEN)
					begin
						playerTurn <= 1;
						dispCards <= 0;
						player1state <= CHECK; //Check can only happen if nobody has bet
					end
					if(Fold && SCEN)
					begin
						playerTurn <= 1;
						dispCards <= 0;
						player1state <= FOLD; //After fold, game ends (2 player implementation)
					end
				end
				// ^ player1 makes their move
			end
			else if(playerTurn == 1)
			begin
				if(player2state == BET)
				begin
                bet <= Switches;
					if(Bet && SCEN)
					begin
						player2state <= NOMOVE;	//pressing BET again cancels the bet
						betting <= 0;
					end
					else if(bet <= player2balance && bet > betLimit && Ack && SCEN) //press middle button to submit bet
					begin
						playerTurn <= 0;
						player2balance <= player2balance - bet;
						pot <= pot + bet;
						player2state <= IN;
						betLimit <= bet;
						betting <= 0;
					end
				end
				else
				begin
					if(Ack && SCEN) //changes card visibility
					begin
						if(dispCards == 1)
						begin
							dispCards <= 0;
						end 
						else
						begin
							dispCards <= 1;
						end
					end 
					if(player1state != NOMOVE && player1state != CHECK && Call && SCEN) //P2 CALL
					begin
						playerTurn <= 0;
						dispCards <= 0;
						pot 			<= 	(player2balance > betLimit)	? pot + betLimit : pot + player2balance;
						player2balance 	<= 	(player2balance > betLimit)	? player2balance - betLimit : 0;
						player2state <= CALL; //After call, round ends (2 player implementation)
					end 
					if(player2state != IN && Bet && SCEN) //P2 BET
					begin
						dispCards <= 0;
						player2state <= BET; //Players cannot re-raise (can only bet once)
						betting <= 1;
					end
					if((player1state == NOMOVE || player1state == CHECK) && player2state == NOMOVE && Check && SCEN) //P2 CHECK
					begin
						playerTurn <= 0;
						dispCards <= 0;
						player2state <= CHECK; //Check can only happen if nobody has bet
					end
					if(Fold && SCEN) //P2 FOLD
					begin
						playerTurn <= 0;
						dispCards <= 0;
						player2state <= FOLD; //After fold, game ends (2 player implementation)
					end
				end
				// ^ player 2 makes their move
			end            
			end   
            WINNER :
            begin
                if(SCEN && Ack && gameover == 1)
                begin
					if(player1balance != 0 && player2balance != 0)	//When one player's balance is 0, then the game is OVER OVER.
					begin
                        player1state <= NOMOVE;
                        player2state <= NOMOVE;
						state <= START;
					end
                end
                if(flag == 0)
                begin
                    flag <= 1;
                    player1_data[0] <= card1;
                    player1_data[1] <= card2;
                    player1_data[2] <= card3;
                    player1_data[3] <= card4;
                    player1_data[4] <= card5;
                    player1_data[5] <= player1card1;
                    player1_data[6] <= player1card2;
                    
                    player2_data[0] <= card1;
                    player2_data[1] <= card2;
                    player2_data[2] <= card3;
                    player2_data[3] <= card4;
                    player2_data[4] <= card5;
                    player2_data[5] <= player2card1;
                    player2_data[6] <= player2card2;
                end
                if(player1state == FOLD)
                begin
					player2balance <= player2balance + pot;
					pot <= 0;
					winner <= 1;
					gameover <= 1;	//set gameover flag, to display winner info (eg: P2  [P2BAL])
                end
                else if(player2state == FOLD)
                begin
					player1balance <= player1balance + pot;
					pot <= 0;
					winner <= 0;
					gameover <= 1; //set gameover flag, to display winner info (eg: P1  [P1BAL])
				end
                else if (player1sorted == 0)
                begin
                    for (i = 0; i < 7; i = i + 1) 
                    begin
                        for (j = 0; j < 7 - i; j = j + 1) 
                        begin
                            if (player1_data[j] > player1_data[j + 1]) 
                            begin
                                // Swap elements if they are out of order
                                temp = player1_data[j];
                                player1_data[j] = player1_data[j + 1];
                                player1_data[j + 1] = temp;
                            end
                        end
                    end
                    player1sorted <= 1;
                end
                else if (player2sorted == 0)
                begin
                    for (i = 0; i < 7; i = i + 1) 
                    begin
                        for (j = 0; j < 7 - i; j = j + 1) 
                        begin
                            if (player2_data[j] > player2_data[j + 1]) 
                                begin
                                    // Swap elements if they are out of order
                                    temp = player2_data[j];
                                    player2_data[j] = player2_data[j + 1];
                                    player2_data[j + 1] = temp;
                                end
                        end
                    end
                    player2sorted <= 1;
                end
                
                
                else if(player1High == 0) //where we find the actual winner :)
                begin // 0 1 2 3 4 5 6
                    //player1 best hand
                    if(player1_data[0] == player1_data[3] || player1_data[1] == player1_data[4] ||
                    player1_data[2] == player1_data[5] || player1_data[3] == player1_data[6])
                        begin
                            player1hand <= FOUR;
                            player1highcard <= player1_data[6];
                        end
                    else if((player1_data[6] == player1_data[4] && (player1_data[3] == player1_data[2] || player1_data[2] == player1_data[1] || player1_data[1] == player1_data[0]))
                    || (player1_data[5] == player1_data[3] && (player1_data[2] == player1_data[1] || player1_data[1] == player1_data[0]))
                    )
                        begin
                            player1hand <= FULLHOUSE;
                            player1highcard <= player1_data[6];
                        end
                     else if((player1_data[4] == player1_data[2] && (player1_data[6] == player1_data[5] || player1_data[1] == player1_data[0]))
                    || (player1_data[3] == player1_data[1] && (player1_data[6] == player1_data[5] || player1_data[5] == player1_data[4]))
                    || (player1_data[2] == player1_data[0] && (player1_data[6] == player1_data[5] || player1_data[5] == player1_data[4] || player1_data[4] == player1_data[3]))
                    )
                        begin
                            player1hand <= FULLHOUSE;
                            if(player1_data[6] == player1_data[5])
                            begin
                                player1highcard <= player1_data[6];
                            end
                            else if(player1_data[5] == player1_data[4])
                            begin
                                player1highcard <= player1_data[5];
                            end
                            else
                            begin
                                player1highcard <= player1_data[4];
                            end
                        end
                    else if(player1_data[5] + 1 == player1_data[6] && player1_data[4] + 1 == player1_data[5] && player1_data[2] + 1 == player1_data[3]
                    && player1_data[3] + 1 == player1_data[4])
                        begin
                            player1hand <= STRAIGHT;
                            player1highcard <= player1_data[6];
                        end
                    else if(player1_data[4] + 1 == player1_data[5] && player1_data[1] + 1 == player1_data[2] && player1_data[2] + 1 == player1_data[3]
                    && player1_data[3] + 1 == player1_data[4])
                        begin
                            player1hand <= STRAIGHT;
                            player1highcard <= player1_data[5];
                        end
                    else if(player1_data[0] + 1 == player1_data[1] && player1_data[1] + 1 == player1_data[2] && player1_data[2] + 1 == player1_data[3]
                    && player1_data[3] + 1 == player1_data[4])
                        begin
                            player1hand <= STRAIGHT;
                            player1highcard <= player1_data[4];
                        end
                    else if(player1_data[0] == player1_data[2] || player1_data[1] == player1_data[3] ||
                    player1_data[2] == player1_data[4] || player1_data[3] == player1_data[5] || player1_data[4] == player1_data[6])
                        begin
                            player1hand <= THREE;
                            player1highcard <= player1_data[6];
                        end
                    else if(player1_data[0] == player1_data[1] || player1_data[1] == player1_data[2] ||
                    player1_data[2] == player1_data[3] || player1_data[3] == player1_data[4] || player1_data[4] == player1_data[5] || player1_data[6] == player1_data[5])
                        begin
                            numpairs = 0;
                            for (i = 1; i < 7; i = i + 1) 
                            begin
                                if(player1_data[i] == player1_data[i-1])
                                begin
                                    numpairs = numpairs + 1;
                                end
                            end
                            if(numpairs > 1)
                            begin
                                player1hand <= TWOPAIR;
                                player1highcard <= player1_data[6];
                            end
                            else
                            begin
                                player1hand <= PAIR;
                                player1highcard <= player1_data[6];
                            end
                        end
                    else
                        begin
                            player1hand <= HIGHCARD;
                            player1highcard <= player1_data[6];
                        end
                    player1High <= 1;
                end

                else if(player2High == 0)//where we find the actual winner :)
                begin // 0 1 2 3 4 5 6
                    //player1 best hand
                    if(player2_data[0] == player2_data[3] || player2_data[1] == player2_data[4] ||
                    player2_data[2] == player2_data[5] || player2_data[3] == player2_data[6])
                    begin
                      player2hand <= FOUR;
                      player2highcard <= player2_data[6];
                    end
                    else if((player2_data[6] == player2_data[4] && (player2_data[3] == player2_data[2] || player2_data[2] == player2_data[1] || player2_data[1] == player2_data[0]))
                    || (player2_data[5] == player2_data[3] && (player2_data[2] == player2_data[1] || player2_data[1] == player2_data[0]))
                   )
                    begin
                      player2hand <= FULLHOUSE;
                      player2highcard <= player2_data[6];
                    end
                    else if((player2_data[4] == player2_data[2] && (player2_data[6] == player2_data[5] || player2_data[1] == player2_data[0]))
                    || (player2_data[3] == player2_data[1] && (player2_data[6] == player2_data[5] || player2_data[5] == player2_data[4]))
                    || (player2_data[2] == player2_data[0] && (player2_data[6] == player2_data[5] || player2_data[5] == player2_data[4] || player2_data[4] == player2_data[3]))
                    )
                    begin
                      player2hand <= FULLHOUSE;
                      if(player2_data[6] == player2_data[5])
                      begin
                        player2highcard <= player2_data[6];
                      end
                      else if(player2_data[5] == player2_data[4])
                      begin
                        player2highcard <= player2_data[5];
                      end
                      else
                      begin
                        player2highcard <= player2_data[4];
                      end
                    end
                    else if(player2_data[5] + 1 == player2_data[6] && player2_data[4] + 1 == player2_data[5] && player2_data[2] + 1 == player2_data[3]
                     && player2_data[3] + 1 == player2_data[4])
                    begin
                      player2hand <= STRAIGHT;
                      player2highcard <= player2_data[6];
                    end
                    else if(player2_data[4] + 1 == player2_data[5] && player2_data[1] + 1 == player2_data[2] && player2_data[2] + 1 == player2_data[3]
                     && player2_data[3] + 1 == player2_data[4])
                    begin
                      player2hand <= STRAIGHT;
                      player2highcard <= player2_data[5];
                    end
                    else if(player2_data[0] + 1 == player2_data[1] && player2_data[1] + 1 == player2_data[2] && player2_data[2] + 1 == player2_data[3]
                     && player2_data[3] + 1 == player2_data[4])
                    begin
                      player2hand <= STRAIGHT;
                      player2highcard <= player2_data[4];
                    end
                    else if(player2_data[0] == player2_data[2] || player2_data[1] == player2_data[3] ||
                    player2_data[2] == player2_data[4] || player2_data[3] == player2_data[5] || player2_data[4] == player2_data[6])
                    begin
                      player2hand <= THREE;
                      player2highcard <= player2_data[6];
                    end
                    else if(player2_data[0] == player2_data[1] || player2_data[1] == player2_data[2] ||
                    player2_data[2] == player2_data[3] || player2_data[3] == player2_data[4] || player2_data[4] == player2_data[5] || player2_data[6] == player2_data[5])
                    begin
                      numpairs = 0;
                       for (i = 1; i < 7; i = i + 1) 
                    begin
                      if(player2_data[i] == player2_data[i-1])
                      begin
                        numpairs = numpairs + 1;
                      end
                    end
                      if(numpairs > 1)
                      begin
                      player2hand <= TWOPAIR;
                      player2highcard <= player2_data[6];
                      end
                      else
                      begin
                      player2hand <= PAIR;
                      player2highcard <= player2_data[6];
                      end
                    end
                    else
                    begin
                      player2hand <= HIGHCARD;
                      player2highcard <= player2_data[6];
                    end
                    player2High <= 1;
                end
              else
              begin
                  gameover <= 1;
                  if(player1hand > player2hand)
                  begin
                    winner <= 0; //0 is player1 wins
					player1balance <= player1balance + pot;
					pot <= 0;
                  end
                  else if(player1hand < player2hand)
                  begin
                    winner <= 1; //1 is player2 wins
					player2balance <= player2balance + pot;
					pot <= 0;
                  end
                  else
                  begin
                    if(player1highcard >= player2highcard) //currently ties go to player 1 ummm yeah
                    begin
                      winner <= 0;					
					  player1balance <= player1balance + pot;
					  pot <= 0;
                    end
                    else
                    begin
                      winner <= 1;
					  player2balance <= player2balance + pot;
					  pot <= 0;
                    end
                  end
              end
            end
        endcase
    end 
  end

// DISPLAY THE WINNER ON SSDS
assign Card1 = card1;
assign Card2 = card2; 
assign Card3 = card3; 
assign Card4 = card4; 
assign Card5 = card5; 
assign Player1card1 = player1card1; 
assign Player1card2 = player1card2; 
assign Player2card1 = player2card1; 
assign Player2card2 = player2card2;
assign Player1balance = player1balance; //Player1balance
assign Player2balance = player2balance; //Player2balance
assign PlayerTurn = playerTurn;
assign DispCards = dispCards;
assign Winner = winner;
assign Gameover = gameover;
assign Player1state = player1state;
assign Player2state = player2state;
assign Betting = betting;

endmodule  // poker
