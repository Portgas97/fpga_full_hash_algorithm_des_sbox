// This file contains the full_hash_des_sbox front-end RTL description in SystemVerilog for
// the "Hardware and Embedded Security" course project of the University of Pisa
// Students: Venturini Francesco, Bigliazzi Pierfrancesco
// Professors: Saponara Sergio, Crocetti Luca
// repo: https://github.com/Portgas97/fpga_full_hash_algorithm_des_sbox

// TODO: check on the validity of the input (ASCII range) ???


// Main module that implements the FSM and instantiates the submodules
module full_hash_des_box(
	input rst_n,
	input clk,
	input M_valid,
	input [7:0] message,
	input [63:0] counter,
	output reg [31:0] digest_out,
	output reg hash_ready
);

	// nibbles initialization value for the H[i] variables 
	localparam h_0 = 4'h4;
	localparam h_1 = 4'hB;
	localparam h_2 = 4'h7;
	localparam h_3 = 4'h1;
	localparam h_4 = 4'hD;
	localparam h_5 = 4'hF;
	localparam h_6 = 4'h0;
	localparam h_7 = 4'h3;

	// useful names for the states of the FSM
	localparam S0 = 3'b00;
	localparam S1 = 3'b01;
	localparam S2 = 3'b10;
	localparam S3 = 3'b11;

	reg [7:0] MSG; 			// input character
	reg [63:0] C_COUNT; 	// remaining bytes
	reg [5:0] M_6; 			// result of the compression operation on the message character
	reg [7:0][5:0] C_6; 	// For the result of the final operation on the message character
	// unused reg [3:0] S_M_6; 		// SBox result for M6
	// unused reg [3:0] S_C_6; 		// SBox result for C6
	reg [7:0]  [3:0] H_MAIN; // Used for the main computation
	reg [7:0] [3:0] H_LAST; // Used for the last computation
	reg HASH_READY; 		// Used to hold hash_ready value
	reg [31:0] DIGEST; 		// Final digest output
	reg [1:0] STAR, NEXT_STATE;			// Status register for the FSM

	// Store partial results, between different characters of the same message
	wire [7:0] [3:0] half_hash;	


	H_main_computation main(
		.m(MSG),
		.h_main(H_MAIN),
		.H_MAIN_OUT(half_hash)
	);
	

	H_last_computation final_op(
		.H_main(H_MAIN), 
		.counter(C_COUNT), 
		.H_last(DIGEST)
	);


	// Finite State Machine, see documentation
	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			// initialization 
			STAR <= S0;
			HASH_READY <= 0;
		end else
			STAR <= NEXT_STATE;
	end


	always @(*) begin 
		case(STAR)

				// initialization and sampling
				S0: begin 

					// input sampling
					MSG <= message; 

					// input sampling or hold previous value
					C_COUNT <= (C_COUNT != 0) ? C_COUNT : counter; 

					// first case: another character of the same message to compute yet,
					//			   "transfer" of the computed value
					// second case: inizialization 
					H_MAIN <= (C_COUNT != 0) ? half_hash : {h_0,h_1,h_2,h_3,h_4,h_5,h_6,h_7};

					// conditional state transfer
					NEXT_STATE <= (M_valid == 1) ? S1 : S0; 
				end 

				// DALLA MACCHINA A STATI QUI VENGONO CALCOLATI S(M6) E S(C6), è davvero così??? /////////////////////////////////////
				S1: begin 

					// in case of a new character elaboration
					HASH_READY <= 0;

					// unconditional state transfer
					NEXT_STATE <= S2;
				end

				// 4 main algorithm rounds
				S2: begin 

					// state transfer
					NEXT_STATE <= (C_COUNT == 0) ? S3 : S0;

					// count the number of elaborated bytes
					C_COUNT <= C_COUNT - 1;

				end

				// last transformation (digest) signalling and output, and return to S0
				S3: begin 

					// unconditional state trasfer
					NEXT_STATE <= S0;

					// set the output
					digest_out <= DIGEST;

					// signal the output
					hash_ready <= 1;
				end

				default: NEXT_STATE <= S0;
			endcase
	end
			
	

endmodule



// Main hash algorithm, 4 rounds
module H_main_computation(
	input [7:0] m,
	input [7:0] [3:0] h_main,
	output [7:0] [3:0] h_main_out
);

	// message byte character compression
	wire [5:0] m6;
	Message_To_M_6 M_to_M6(
		.in(m),
		.out(m6)
		);

	// DES S-Box value computation
	wire [3:0] s_value;
	S_Box SBox(
		.in(m6),
		.out(s_value)
		);

	// first round
	wire [7:0] [3:0] h_main_1;
	Hash_Round Round_1(
		.S_box_value(s_value),
		.h_main(h_main),
		.h_out(h_main_1)
		);

	// second round
	wire [7:0] [3:0] h_main_2;
	Hash_Round Round_2(
		.S_box_value(s_value),
		.h_main(h_main_1),
		.h_out(h_main_2)
		);

	// third round
	wire [7:0] [3:0] h_main_3;
	Hash_Round Round_3(
		.S_box_value(s_value),
		.h_main(h_main_2),
		.h_out(h_main_3)
		);

	// fourth round
	Hash_Round Round_4(
		.S_box_value(s_value),
		.h_main(h_main_3),
		.h_out(h_main_out)
		);

endmodule



// It performs one round of the main hash algorithm
// According to: H[i] = (H[(i+1) mod 8] ^ S(M6)) << |_ i/2 _|
module Hash_Round(
	input [3:0] SBox_value, // output of the DES S-Box LUT table
	input [7:0] [3:0] h_main, // previous hash values
    output reg [7:0] [3:0] h_out // new hash values
);

	reg [3:0] tmp;	
	always @(*) begin

		// 0
		tmp = h_main[1] ^ SBox_value; 
		h_out[0] = tmp;

		// 1
		tmp = h_main[2] ^ SBox_value; 
		h_out[1] = tmp;

		// 2
		tmp = h_main[3] ^ SBox_value; 
		h_out[2] = {tmp[2:0], tmp[3]};

		// 3
		tmp = h_main[4] ^ SBox_value; 
		h_out[3] = {tmp[2:0], tmp[3]};

		// 4
		tmp = h_main[5] ^ SBox_value; 
		h_out[4] = {tmp[1:0], tmp[3:2]};

		// 5
		tmp = h_main[6] ^ SBox_value; 
		h_out[5] = {tmp[1:0], tmp[3:2]};

		// 6
		tmp = h_main[7] ^ SBox_value; 
		h_out[6] = {tmp[0], tmp[3:1]};

		// 7
		tmp = h_main[0] ^ SBox_value; 
		h_out[7] = {tmp[0], tmp[3:1]};
	end

endmodule



// It performs the last operation of the algorithm
// According to: H[i] = (H[(i+1) mod 8] ^ S(C6[i])) << |_ i/2 _|
module H_last_computation(
	input [7:0] [3:0] H_main, 		// Results from the main 4 rounds
	input [63:0] counter, 			// Message length counter
	output reg [7:0] [3:0] H_last	// Digest
);

	reg [7:0] [5:0] idx;
	reg [7:0] [3:0] S_value;
	reg [7:0] [3:0] tmp;
	reg [7:0] [3:0] h_out;

	// 0
	Counter_to_C_6 C6_0(
		.in_c(counter[63:56]), 
		.out_c(idx[0])
		);
	S_Box Sbox0(
		.in(idx[0]), 
		.out(S_value[0])
		);
	
	// 1
	Counter_to_C_6 C6_1(
		.in_c(counter[55:48]),
		.out_c(idx[1])
		);
	S_Box Sbox1(
		.in(idx[1]),
		.out(S_value[1])
		);
	

	// 2
	Counter_to_C_6 C6_2(
		.in_c(counter[47:40]),
		.out_c(idx[2])
		);
	S_Box Sbox2(
		.in(idx[2]),
		.out(S_value[2])
		);
	

	// 3
	Counter_to_C_6 C6_3(
		.in_c(counter[39:32]),
		.out_c(idx[3])
		);
	S_Box Sbox3(
		.in(idx[3]),
		.out(S_value[3])
		);
	

	// 4
	Counter_to_C_6 C6_4(
		.in_c(counter[31:24]),
		.out_c(idx[4])
		);
	S_Box Sbox4(
		.in(idx[4]),
		.out(S_value[4])
		);
	

	// 5
	Counter_to_C_6 C6_5(
		.in_c(counter[23:16]),
		.out_c(idx[5])
		);
	S_Box Sbox5(
		.in(idx[5]),
		.out(S_value[5])
		);
	

	// 6
	Counter_to_C_6 C6_6(
		.in_c(counter[15:8]),
		.out_c(idx[6])
		);
	S_Box Sbox6(
		.in(idx[6]),
		.out(S_value[6])
		);
	

	// 7
	Counter_to_C_6 C6_7(
		.in_c(counter[7:0]),
		.out_c(idx[7])
		);
	S_Box Sbox7(
		.in(idx[7]),
		.out(S_value[7])
		);
	

	always @(*) begin
		tmp[1] = H_main[2] ^ S_value[1];
		h_out[1] = tmp[1];
		tmp[2] = H_main[3] ^ S_value[2];
		h_out[2] = {tmp[2][2:0], tmp[2][3]};
		tmp[3] = H_main[4] ^ S_value[3];
		h_out[3] = {tmp[3][2:0], tmp[3][3]};
		tmp[4] = H_main[5] ^ S_value[4];
		h_out[4] = {tmp[4][1:0], tmp[4][3:2]};
		tmp[5] = H_main[6] ^ S_value[5];
		h_out[5] = {tmp[5][1:0], tmp[5][3:2]};
		tmp[6] = H_main[7] ^ S_value[6];
		h_out[6] = {tmp[6][0], tmp[6][3:1]};
		tmp[7] = H_main[0] ^ S_value[7];
		h_out[7] = {tmp[7][0], tmp[7][3:1]};
		
		H_last = {h_out[0], h_out[1], h_out[2], h_out[3], h_out[4], h_out[5], h_out[6], h_out[7]};
	end

	
endmodule





/************************************** UTILITY FUNCTIONS **************************************/


// Compression function, it transforms an 8-bit character into a 6-bit character
module Message_To_M_6(input [7:0] in, output [5:0] out);
	assign out = {in[3]^in[2], in[1], in[0], in[7], in[6], in[5]^in[4]};
endmodule


//Final operation, it trasnforms one byte of the message length counter into a 6-bit value 
module Counter_to_C_6( input [7:0] in_c, output reg [5:0] out_c);
	always @(*) begin
		out_c = {in_c[7] ^ in_c[1], in_c[3], in_c[2], in_c[5] ^ in_c[0], in_c[4], in_c[6]};
	end
endmodule


// This module implements a LUT version of the DES S-box
//The first and last bits of the input select the row of the S-Box
//The 4 central bits select the column of the S-box
module S_Box(input [5:0] in, output reg [3:0] out);

  	reg [1:0] row;
  	reg [3:0] column;
   
   	always @(*) begin

    	row = {in[5], in[0]};
    	column = in[4:1];
	
    	case(row)
			2'b00: 
				case(column)
					4'b0000: out = 4'b0010; 4'b0001: out = 4'b1100;
					4'b0010: out = 4'b0100; 4'b0011: out = 4'b0001;
					4'b0100: out = 4'b0111; 4'b0101: out = 4'b1010;
					4'b0110: out = 4'b1011; 4'b0111: out = 4'b0110;
					4'b1000: out = 4'b1000; 4'b1001: out = 4'b0101;
					4'b1010: out = 4'b0011; 4'b1011: out = 4'b1111;
					4'b1100: out = 4'b1101; 4'b1101: out = 4'b0000;
					4'b1110: out = 4'b1110; 4'b1111: out = 4'b1001;
				endcase
			2'b01: 
				case(column)
					4'b0000: out = 4'b1110; 4'b0001: out = 4'b1011;
					4'b0010: out = 4'b0010; 4'b0011: out = 4'b1100;
					4'b0100: out = 4'b0100; 4'b0101: out = 4'b0111;
					4'b0110: out = 4'b1101; 4'b0111: out = 4'b0001;
					4'b1000: out = 4'b0101; 4'b1001: out = 4'b0000;
					4'b1010: out = 4'b1111; 4'b1011: out = 4'b1100;
					4'b1100: out = 4'b0011; 4'b1101: out = 4'b1001;
					4'b1110: out = 4'b1000; 4'b1111: out = 4'b0110;
				endcase
			2'b10: 
				case(column)
					4'b0000: out = 4'b0100; 4'b0001: out = 4'b0010;
					4'b0010: out = 4'b0001; 4'b0011: out = 4'b1011;
					4'b0100: out = 4'b1100; 4'b0101: out = 4'b1101;
					4'b0110: out = 4'b0111; 4'b0111: out = 4'b1000;
					4'b1000: out = 4'b1111; 4'b1001: out = 4'b1001;
					4'b1010: out = 4'b1100; 4'b1011: out = 4'b0101;
					4'b1100: out = 4'b0110; 4'b1101: out = 4'b0011;
					4'b1110: out = 4'b0000; 4'b1111: out = 4'b1110;
				endcase	
			2'b11: 
				case(column)
					4'b0000: out = 4'b1011; 4'b0001: out = 4'b1000;
					4'b0010: out = 4'b1100; 4'b0011: out = 4'b0111;
					4'b0100: out = 4'b0001; 4'b0101: out = 4'b1110;
					4'b0110: out = 4'b0010; 4'b0111: out = 4'b1101;
					4'b1000: out = 4'b0110; 4'b1001: out = 4'b1111;
					4'b1010: out = 4'b0000; 4'b1011: out = 4'b1001;
					4'b1100: out = 4'b1100; 4'b1101: out = 4'b0100;
					4'b1110: out = 4'b0101; 4'b1111: out = 4'b0011;
				endcase

			default: out = 4'bXXXX;
		endcase
   	end
endmodule
