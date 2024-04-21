// ----------------------------------------------------------------------
//  A Verilog module for a simple divider
//
//  Written by Gandhi Puvvada  Date: 7/17/98, 2/15/2008
//
//  File name:  divider_timing_part1.v
//  Ported to Nexys 4: Yue (Julien) Niu, Gandhi Puvvada
//  Date: Mar 29, 2020 (changed 4-bit divider to 8-bit divider, added SCEN signle step control)
// ------------------------------------------------------------------------
module divider_timing (Xin, Yin, Start, Ack, Clk, Reset,  SCEN,  // Notice SCEN
                Done, Quotient, Remainder, Q5card, Q4card, Q3card, Qhand, Qstart);

input Start, Ack, Clk, Reset;
output Done;
input SCEN;
output [3:0] card1, card2, card3, card4, card5, player1card1, player1card2, player2card1, player2card2;
output playerTurn;
output dispCards;

reg [3:0] card1, card2, card3, card4, card5, player1card1, player1card2, player2card1, player2card2;
reg [5:0] gamestate;
reg [4:0] player1state;
reg [4:0] player2state;
reg [0] flag;
reg playerTurn;
reg dispCards;
reg [3:0] player1_data [0:6]
reg [3:0] player2_data [0:6]
reg [3:0] i, j;
reg [3:0] temp;
reg player1sorted;
reg player2sorted;

localparam
START = 5'b00001,
HAND	= 5'b00010,
3CARD	= 5'b00100;
4CARD = 5'b01000;
5CARD = 5'b10000;

NOMOVE = 6'b000001,
CHECK	= 6'b000010,
BET	= 6'b000100;
CALL = 6'b001000;
FOLD = 6'b010000;
WINNER = 6'b100000

assign {Q5card, Q4card, Q3card, Qhand, Qstart} = state;

assign NEXT_TURN = player1state != NOMOVE && player2state != NOMOVE;
assign END_GAME = player1state == FOLD || player2state == FOLD;
always @(posedge Clk, posedge Reset) 

  begin  : CU_n_DU
    if (Reset)
       begin
           state <= START;
           playerTurn <= 0;
           card1 <= 0; 
           card2<= 0; 
           card3<= 0; 
           card4<= 0; 
           card5<= 0; 
           player1card1<= 0; 
           player1card2<= 0; 
           player2card1<= 0; 
           player2card2<= 0;
           player1state <= NOMOVE;
           player2state <= NOMOVE;
           flag <= 0;
           dispCards <= 0;
           player1sorted <= 0;
           player2sorted <= 0;
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
    else
       begin
         (* full_case, parallel_case *)
         case (state)
            START : 
              begin
                  // state transitions in the control unit
                  if (Start)
                  begin
                      state <= HAND;
                  // RTL operations in the Data Path 
                    playerTurn <= 0;
                     card1 <= 0; 
                     card2<= 0; 
                      card3<= 0; 
                      card4<= 0; 
                      card5<= 0; 
                      player1card1<= 0; 
                      player1card2<= 0; 
                      player2card1<= 0; 
                      player2card2<= 0;
                      player1state <= NOMOVE;
                      player2state <= NOMOVE;
                      flag <= 0;
                      dispCards <= 0;
                      player1sorted <= 0;
                      player2sorted <= 0;
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
              end
            HAND :
			  if (SCEN)  // Notice SCEN
              begin
                 // state transitions in the control unit
                 if(flag == 0)
                 begin
                  flag <= 1;
                  player1card1 <= $random % 13 + 1;
                  player1card2 <= $random % 13 + 1;
                  player2card1 <= $random % 13 + 1;
                  player2card2 <= $random % 13 + 1;
                 end
                  if (NEXT_TURN )
                  begin
                      state <= 3CARD;
                      flag <= 0;
                       player1state <= NOMOVE;
                      player2state <= NOMOVE;
                  end
                  else if(END_GAME)
                  begin
                    state <= WINNER;
                    flag <= 0;
                  end
                  // RTL operations in the Data Path 
                  else if(playerTurn == 0)
                  begin
                    if(Ack) //changes card visibility
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
                    if(Call)
                    begin
                      playerTurn <= 1;
                      dispCards <= 0;
                      player1state <= CALL;
                    end
                    if(Bet)
                    begin
                      playerTurn <= 1;
                      dispCards <= 0;
                      player1state <= BET;
                    end
                    if(Check)
                    begin
                      playerTurn <= 1;
                      dispCards <= 0;
                      player1state <= CHECK;
                    end
                    if(Fold)
                    begin
                      playerTurn <= 1;
                      dispCards <= 0;
                      player1state <= FOLD;
                    end
                    //player1 makes there move
                  end
                  else if (playerTurn == 1)
                  begin //remember player turn goes to 0 here when da button is pressed
                    if(Ack) //changes card visibility
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
                    if(Call)
                    begin
                      playerTurn <= 0;
                      dispCards <= 0;
                      player1state <= CALL;
                    end
                    if(Bet)
                    begin
                      playerTurn <= 0;
                      dispCards <= 0;
                      player1state <= BET;
                    end
                    if(Check)
                    begin
                      playerTurn <= 0;
                      dispCards <= 0;
                      player1state <= CHECK;
                    end
                    if(Fold)
                    begin
                      playerTurn <= 0;
                      dispCards <= 0;
                      player1state <= FOLD;
                    end
                  end
                 
              end 
            3CARD  :
              begin  
                  // state transitions in the control unit
                  if (Ack)
                      state <= INITIAL;
                      if(flag == 0)
                 begin
                  flag <= 1;
                  card1 <= $random % 13 + 1;
                  card2 <= $random % 13 + 1;
                  card3 <= $random % 13 + 1;
                 end
                  if (NEXT_TURN)
                  begin
                      state <= 4CARD;
                       player1state <= NOMOVE;
                      player2state <= NOMOVE;
                      flag <= 0;
                  end
                  else if(END_GAME)
                  begin
                      state <= WINNER;
                      flag <= 0;
                  end
                  // RTL operations in the Data Path 
                  else if(playerTurn == 0)
                  begin
                    if(Ack) //changes card visibility
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
                    if(Call)
                    begin
                      playerTurn <= 1;
                      dispCards <= 0;
                      player1state <= CALL;
                    end
                    if(Bet)
                    begin
                      playerTurn <= 1;
                      dispCards <= 0;
                      player1state <= BET;
                    end
                    if(Check)
                    begin
                      playerTurn <= 1;
                      dispCards <= 0;
                      player1state <= CHECK;
                    end
                    if(Fold)
                    begin
                      playerTurn <= 1;
                      dispCards <= 0;
                      player1state <= FOLD;
                    end
                    //player1 makes there move
                  end
                  else if (playerTurn == 1)
                  begin //remember player turn goes to 0 here when da button is pressed
                    if(Ack) //changes card visibility
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
                    if(Call)
                    begin
                      playerTurn <= 0;
                      dispCards <= 0;
                      player1state <= CALL;
                    end
                    if(Bet)
                    begin
                      playerTurn <= 0;
                      dispCards <= 0;
                      player1state <= BET;
                    end
                    if(Check)
                    begin
                      playerTurn <= 0;
                      dispCards <= 0;
                      player1state <= CHECK;
                    end
                    if(Fold)
                    begin
                      playerTurn <= 0;
                      dispCards <= 0;
                      player1state <= FOLD;
                    end
                  end
              end   
              4CARD :
              begin
                if(flag == 0)
                 begin
                  flag <= 1;
                  card4 <= $random % 13 + 1;
                 end
                  if (NEXT_TURN )
                  begin
                      state <= 5CARD;
                      player1state <= NOMOVE;
                      player2state <= NOMOVE;
                      flag <= 0;
                  end
                  else if(END_GAME)
                  begin
                    state <= WINNER;
                      flag <= 0;
                  end
                  // RTL operations in the Data Path 
                 else if(playerTurn == 0)
                  begin
                    if(Ack) //changes card visibility
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
                    if(Call)
                    begin
                      playerTurn <= 1;
                      dispCards <= 0;
                      player1state <= CALL;
                    end
                    if(Bet)
                    begin
                      playerTurn <= 1;
                      dispCards <= 0;
                      player1state <= BET;
                    end
                    if(Check)
                    begin
                      playerTurn <= 1;
                      dispCards <= 0;
                      player1state <= CHECK;
                    end
                    if(Fold)
                    begin
                      playerTurn <= 1;
                      dispCards <= 0;
                      player1state <= FOLD;
                    end
                    //player1 makes there move
                  end
                  else if (playerTurn == 1)
                  begin //remember player turn goes to 0 here when da button is pressed
                    if(Ack) //changes card visibility
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
                    if(Call)
                    begin
                      playerTurn <= 0;
                      dispCards <= 0;
                      player1state <= CALL;
                    end
                    if(Bet)
                    begin
                      playerTurn <= 0;
                      dispCards <= 0;
                      player1state <= BET;
                    end
                    if(Check)
                    begin
                      playerTurn <= 0;
                      dispCards <= 0;
                      player1state <= CHECK;
                    end
                    if(Fold)
                    begin
                      playerTurn <= 0;
                      dispCards <= 0;
                      player1state <= FOLD;
                    end
                  end
              end
              5CARD :
              begin
                if(flag == 0)
                 begin
                  flag <= 1;
                  card5 <= $random % 13 + 1;
                 end
                  if (NEXT_TURN )
                  begin
                      state <= WINNER;
                      player1state <= NOMOVE;
                      player2state <= NOMOVE;
                      flag <= 0;
                  end
                  else if(END_GAME)
                  begin
                    state <= WINNER;
                      flag <= 0;
                  end
                  // RTL operations in the Data Path 
                  else if(playerTurn == 0)
                  begin
                    if(Ack) //changes card visibility
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
                    if(Call)
                    begin
                      playerTurn <= 1;
                      dispCards <= 0;
                      player1state <= CALL;
                    end
                    if(Bet)
                    begin
                      playerTurn <= 1;
                      dispCards <= 0;
                      player1state <= BET;
                    end
                    if(Check)
                    begin
                      playerTurn <= 1;
                      dispCards <= 0;
                      player1state <= CHECK;
                    end
                    if(Fold)
                    begin
                      playerTurn <= 1;
                      dispCards <= 0;
                      player1state <= FOLD;
                    end
                    //player1 makes there move
                  end
                  else if (playerTurn == 1)
                  begin //remember player turn goes to 0 here when da button is pressed
                    if(Ack) //changes card visibility
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
                    if(Call)
                    begin
                      playerTurn <= 0;
                      dispCards <= 0;
                      player1state <= CALL;
                    end
                    if(Bet)
                    begin
                      playerTurn <= 0;
                      dispCards <= 0;
                      player1state <= BET;
                    end
                    if(Check)
                    begin
                      playerTurn <= 0;
                      dispCards <= 0;
                      player1state <= CHECK;
                    end
                    if(Fold)
                    begin
                      playerTurn <= 0;
                      dispCards <= 0;
                      player1state <= FOLD;
                    end
                  end
              end 
              WINNER :
              begin
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
                  //player2 wins
                end
                else if(player2state == FOLD)
                begin
                  //player1 wins
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
              end
      endcase
    end 
  end
 
assign Remainder = x;
assign Done = (state == DONE_S) ;

endmodule  // divider_timing
