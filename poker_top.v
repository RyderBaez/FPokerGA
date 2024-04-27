/*
File     : divider_timing_top_with_single_step.v (based on divider_top_with_single_step.v) 
Author   : Gandhi Puvvada
Revision  : 1.2, 2.0, 3.0 (to suit Nexys 4)
Date : Feb 15, 2008, 10/14/08, 2/22/2010, 2/12/2012, 2/17/2020
//  Revised: Yue (Julien) Niu, Gandhi Puvvada
//  Date: Mar 29, 2020 (changed 4-bit divider to 8-bit divider, added SCEN signle step control)
*/
module poker_top
       (ClkPort,                                    // System Clock
        //MemOE, MemWR, RamCS, QuadSpiFlashCS,
        QuadSpiFlashCS,
        BtnL, BtnU, BtnR, BtnD, BtnC,	             // the Left, Up, Right, Down, and Center buttons
        Sw0, Sw1, Sw2, Sw3, Sw4, Sw5, Sw6, Sw7,      // 16 Switches
		Sw8, Sw9, Sw10, Sw11, Sw12, Sw13, Sw14, Sw15,  
        Ld0, Ld1, Ld2, Ld3, Ld4, Ld5, Ld6, Ld7,      // 16 LEDs
		Ld8, Ld9, Ld10, Ld11, Ld12, Ld13, Ld14, Ld15, 
		An0, An1, An2, An3, An4, An5, An6, An7,      // 8 seven-LEDs
		Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp
		  );
                                    
	input    ClkPort;
	input    BtnL, BtnU, BtnD, BtnR, BtnC;
	input    Sw0, Sw1, Sw2, Sw3, Sw4, Sw5, Sw6, Sw7;
	input    Sw8, Sw9, Sw10, Sw11, Sw12, Sw13, Sw14, Sw15;
	output   Ld0, Ld1, Ld2, Ld3, Ld4,Ld5, Ld6, Ld7;
	output   Ld8, Ld9, Ld10, Ld11, Ld12,Ld13, Ld14, Ld15;
	output   An0, An1, An2, An3, An4, An5, An6, An7;
	output   Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp;
	
	// ROM drivers: Control signals on Memory chips (to disable them) 	
	//output 	MemOE, MemWR, RamCS, QuadSpiFlashCS;  
    output QuadSpiFlashCS;
	// local signal declaration
	wire [7:0] Switches, Xin, Yin;
	wire Start, Ack, SCEN;
	wire Done;
	
	wire[3:0] card1, card2, card3, card4, card5, player1card2, player2card2, player1card1, player2card1;
    wire playerTurn;
    wire dispCards;
    wire gameover;
    wire winner;
    wire betting;
    wire[5:0] player1state, player2state;
	wire [7:0] player1balance, player2balance;

	/*  LOCAL SIGNALS */
	wire		Reset, ClkPort;
	wire		board_clk, sys_clk;
	wire [2:0] 	ssdscan_clk;
	

// to produce divided clock
	reg [26:0]	DIV_CLK;
// SSD (Seven Segment Display)
	reg [3:0]	SSD;
	reg [3:0]	SSD7, SSD6, SSD5, SSD4, SSD3, SSD2, SSD1, SSD0;
	reg [6:0]  	SSD_CATHODES;
	
	
//------------	
// Disable the three memories so that they do not interfere with the rest of the design.
	assign {MemOE, MemWR, RamCS, QuadSpiFlashCS} = 4'b1111;
	
	
//------------
// CLOCK DIVISION

	// The clock division circuitary works like this:
	//
	// ClkPort ---> [BUFGP2] ---> board_clk
	// board_clk ---> [clock dividing counter] ---> DIV_CLK
	// DIV_CLK ---> [constant assignment] ---> sys_clk;
	
	BUFGP BUFGP1 (board_clk, ClkPort); 	

// As the ClkPort signal travels throughout our design,
// it is necessary to provide global routing to this signal. 
// The BUFGPs buffer these input ports and connect them to the global 
// routing resources in the FPGA.

	// BUFGP BUFGP2 (Reset, BtnC); In the case of Spartan 3E (on Nexys-2 board), we were using BUFGP to provide global routing for the reset signal. But Spartan 6 (on Nexys-3) does not allow this.
	assign Reset = Sw15;
	
//------------
	// Our clock is too fast (100MHz) for SSD scanning
	// create a series of slower "divided" clocks
	// each successive bit is 1/2 frequency
  always @(posedge board_clk, posedge Reset) 	
    begin							
        if (Reset)
		DIV_CLK <= 0;
        else
		DIV_CLK <= DIV_CLK + 1'b1;
    end
//------------	
	// In this design, we run the core design at full 50MHz clock!
	assign	sys_clk = board_clk;
	// assign	sys_clk = DIV_CLK[25];


	//------------         


	// The Switch values are the values of the X and Y inputs
	// Buttons are used to indicate start and ack signals
	
	// NO. SWITCHES ARE FOR BALANCES. Make a new state machine.
	// assign Xin   =  {Sw15, Sw14, Sw13, Sw12, Sw11, Sw10, Sw9, Sw8};
	assign Switches   =  {Sw7,  Sw6,  Sw5,  Sw4,  Sw3,  Sw2,  Sw1, Sw0}; //up to 254 balance
	
	assign Start = BtnL; 
	assign Ack = BtnC; 
	assign Check = BtnL; 
	assign Bet = BtnD; 
	assign Call = BtnR; 
	assign Fold = BtnU;
	
	// Unlike in the divider_simple, here we use one button BtnU to represent SCEN
	// Instantiate the debouncer	// module ee201_debouncer(CLK, RESET, PB, DPB, SCEN, MCEN, CCEN);
	// notice the "SCEN" is produced here and is sent into the divider core further below
    ee201_debouncer #(.N_dc(25)) ee201_debouncer_1 
            (.CLK(sys_clk), .RESET(Reset), .PB(BtnU), .DPB( ), .SCEN(SCEN1), .MCEN( ), .CCEN( ));
    ee201_debouncer #(.N_dc(25)) ee201_debouncer_2 
            (.CLK(sys_clk), .RESET(Reset), .PB(BtnR), .DPB( ), .SCEN(SCEN2), .MCEN( ), .CCEN( ));
     ee201_debouncer #(.N_dc(25)) ee201_debouncer_3 
            (.CLK(sys_clk), .RESET(Reset), .PB(BtnC), .DPB( ), .SCEN(SCEN3), .MCEN( ), .CCEN( ));
    ee201_debouncer #(.N_dc(25)) ee201_debouncer_4 
            (.CLK(sys_clk), .RESET(Reset), .PB(BtnL), .DPB( ), .SCEN(SCEN4), .MCEN( ), .CCEN( ));
    ee201_debouncer #(.N_dc(25)) ee201_debouncer_5 
            (.CLK(sys_clk), .RESET(Reset), .PB(BtnD), .DPB( ), .SCEN(SCEN5), .MCEN( ), .CCEN( )); 
    assign SCEN = SCEN1 || SCEN2 ||  SCEN3 ||  SCEN4 ||  SCEN5;
    
	// instantiate the core divider design. Note the .SCEN(SCEN)
	poker poker (   .Switches(Switches), 
						.Start(Start), .Ack(Ack), 
						.Check(Check), .Bet(Bet), .Call(Call), .Fold(Fold),
						.Clk(sys_clk), .Reset(Reset), .SCEN(SCEN), 
						.Done(Done),  .Card1(card1), .Card2(card2), .Card3(card3), .Card4(card4), .Card5(card5), 
						.Player1card1(player1card1), .Player1card2(player1card2), .Player2card1(player2card1), 
						.Player2card2(player2card2), .Player1balance(player1balance), .Player2balance(player2balance),
						.PlayerTurn(playerTurn), .DispCards(dispCards), .Winner(winner), .Gameover(gameover),
						 .Player1state(player1state), .Player2state(player2state), .Betting(betting));	
													

//------------
// OUTPUT: LEDS
	
	//assign {Ld7, Ld6, Ld5, Ld4} = {Qi, Qc, Qd, Done};
	//assign {Ld3, Ld2, Ld1, Ld0} = {Start, BtnU, Ack, BtnD}; // We do not want to put SCEN in place of BtnU here as the Ld2 will be on for just 10ns!

//------------
// SSD (Seven Segment Display)
	// reg [3:0]	SSD;
	// wire [3:0]	SSD3, SSD2, SSD1, SSD0;
	
	// The 8 SSDs display [playerTurn][card 5, 4, 3, 2, 1] [playerCard 2, 1] 
	
	assign winner = winner;
	assign gameover = gameover;
	assign player1balance = player1balance;
	assign player2balance = player2balance;
	assign betting = betting;

	//TODO: if we are in done state, put the winner on the SSDs
	reg [7:0] tempBal, tempSwitches;
	always @ *
	begin	
		if(betting == 0 && gameover == 0 )
		begin
			SSD7 <= (playerTurn == 0) ? 4'b0001 : 4'b0010; //if playerturn is 0, display 1; else display 2
			SSD6 <= card5;	
			SSD5 <= card4;
			SSD4 <= card3;
            SSD3 <= card2;
			SSD2 <= card1;
			SSD1 <= (dispCards == 0) ? 4'b0000 : (playerTurn == 0) ? player1card2 : player2card2; //display nothing OR card2
			SSD0 <= (dispCards == 0) ? 4'b0000 : (playerTurn == 0) ? player1card1 : player2card1; //display nothing OR card1
		end
		else if ( betting == 1 )
		begin
			tempBal = (player1state == 6'b000100)? player1balance : player2balance;
			tempSwitches = Switches;

			SSD4 <= tempBal % 10 == 0?  4'b1010: tempBal % 10;
			tempBal = tempBal / 10;		
			SSD5 <= tempBal % 10 == 0?  4'b1010: tempBal % 10;
			tempBal = tempBal / 10; // Divide tempBal by 10
            SSD6 <= tempBal % 10 == 0?  4'b1010: tempBal % 10; // Calculate SSD6 from remainder of tempBal divided by 10
            tempBal = tempBal / 10; // Divide tempBal by 10
            SSD7 <= tempBal % 10 == 0?  4'b1010: tempBal % 10; // Calculate SSD6 from remainder of tempBal divided by 10
            
            SSD0 <= tempSwitches % 10 == 0? 4'b1010: tempSwitches % 10; // Calculate SSD0 from remainder of tempSwitches divided by 10
            tempSwitches = tempSwitches / 10; // Divide tempSwitches by 10
            SSD1 <= tempSwitches % 10 == 0? 4'b1010: tempSwitches % 10; // Calculate SSD1 from remainder of tempSwitches divided by 10
            tempSwitches = tempSwitches / 10; // Divide tempSwitches by 10
            SSD2 <= tempSwitches % 10 == 0? 4'b1010: tempSwitches % 10; // Calculate SSD2 from remainder of tempSwitches divided by 10
            tempSwitches = tempSwitches / 10; // Divide tempSwitches by 10
            SSD3 <= tempSwitches % 10 == 0? 4'b1010: tempSwitches % 10; // Calculate SSD3 from remainder of tempSwitches divided by 10
		end
		else	//on game over
		begin
            SSD7 <= 4'b1111;
            SSD6 <= (winner == 0) ? 4'b0001 : 4'b0010;
            SSD5 <= 4'b0000;
            SSD4 <= 4'b0000;
        
            // Calculate tempBal based on player state
            tempBal = (winner == 0) ? player1balance : player2balance;
        
            SSD0 <= tempBal % 10 == 0?  4'b1010: tempBal % 10;
            tempBal = tempBal / 10;
            SSD1 <= tempBal % 10 == 0?  4'b1010: tempBal % 10;
            tempBal = tempBal / 10;
            SSD2 <= tempBal % 10 == 0?  4'b1010: tempBal % 10;
            tempBal = tempBal / 10;
            SSD3 <= tempBal % 10 == 0?  4'b1010: tempBal % 10;
		end
	end
	// need a scan clk for the seven segment display 
	
	// 100 MHz / 2^18 = 381.5 cycles/sec ==> frequency of DIV_CLK[17]
	// 100 MHz / 2^19 = 190.7 cycles/sec ==> frequency of DIV_CLK[18]
	// 100 MHz / 2^20 =  95.4 cycles/sec ==> frequency of DIV_CLK[19]
	
	// 381.5 cycles/sec (2.62 ms per digit) [which means all 4 digits are lit once every 10.5 ms (reciprocal of 95.4 cycles/sec)] works well.
	
	//                  --|  |--|  |--|  |--|  |--|  |--|  |--|  |--|  |   
    //                    |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | 
	//  DIV_CLK[17]       |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|
	//
	//               -----|     |-----|     |-----|     |-----|     |
    //                    |  0  |  1  |  0  |  1  |     |     |     |     
	//  DIV_CLK[18]       |_____|     |_____|     |_____|     |_____|
	//
	//         -----------|           |-----------|           |
    //                    |  0     0  |  1     1  |           |           
	//  DIV_CLK[19]       |___________|           |___________|
	//
	
	assign ssdscan_clk = DIV_CLK[20:18];

	assign An0	=  !(~(ssdscan_clk[2]) && ~(ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 000
	assign An1	=  !(~(ssdscan_clk[2]) && ~(ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 001
	assign An2	=  !(~(ssdscan_clk[2]) &&  (ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 010
	assign An3	=  !(~(ssdscan_clk[2]) &&  (ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 011
	
	assign An4	=  !( (ssdscan_clk[2]) && ~(ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 100
	assign An5	=  !( (ssdscan_clk[2]) && ~(ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 101
	assign An6	=  !( (ssdscan_clk[2]) &&  (ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 110
	assign An7	=  !( (ssdscan_clk[2]) &&  (ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 111
	
	
	always @ (ssdscan_clk, SSD0, SSD1, SSD2, SSD3, SSD4, SSD5, SSD6, SSD7)
	begin : SSD_SCAN_OUT
		case (ssdscan_clk) 
				  3'b000: SSD = SSD0;
				  3'b001: SSD = SSD1;
				  3'b010: SSD = SSD2;
				  3'b011: SSD = SSD3;
				  3'b100: SSD = SSD4;
				  3'b101: SSD = SSD5;
				  3'b110: SSD = SSD6;
				  3'b111: SSD = SSD7;
		endcase 
	end

	// Following is Hex-to-SSD conversion
	always @ (SSD) 
	begin : HEX_TO_SSD
		case (SSD) // in this solution file the dot points are made to glow by making Dp = 0
		    //                                                                abcdefg,Dp
			4'b0000: SSD_CATHODES = 7'b1111111; // 0 (default empty)
			4'b0001: SSD_CATHODES = 7'b1001111; // 1
			4'b0010: SSD_CATHODES = 7'b0010010; // 2
			4'b0011: SSD_CATHODES = 7'b0000110; // 3
			4'b0100: SSD_CATHODES = 7'b1001100; // 4
			4'b0101: SSD_CATHODES = 7'b0100100; // 5
			4'b0110: SSD_CATHODES = 7'b0100000; // 6
			4'b0111: SSD_CATHODES = 7'b0001111; // 7
			4'b1000: SSD_CATHODES = 7'b0000000; // 8
			4'b1001: SSD_CATHODES = 7'b0000100; // 9
			4'b1010: SSD_CATHODES = 7'b0000001; // 10 (displays as 0)
			4'b1011: SSD_CATHODES = 7'b1000111; // Jack
			4'b1100: SSD_CATHODES = 7'b0001100; // Queen
			4'b1101: SSD_CATHODES = 7'b1001000; // King (looks like H)
			4'b1110: SSD_CATHODES = 7'b0001000; // A (for player)
			4'b1111: SSD_CATHODES = 7'b0011000; // P (when you need to type player 1)   
			default: SSD_CATHODES = 7'bXXXXXXX; // default is not needed as we covered all cases
		endcase
	end	
	
	// reg [6:0]  SSD_CATHODES;
	assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg} = {SSD_CATHODES}; 
	// assign Dp = 1'b0; // For TA's solution
	assign Dp = 1'b1; // For Student's exercise
	
endmodule