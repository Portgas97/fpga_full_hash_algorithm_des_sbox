// This file contains the full_hash_des_sbox front-end RTL description in SystemVerilog for
// the "Hardware and Embedded Security" course project of the University of Pisa
// Students: Venturini Francesco, Bigliazzi Pierfrancesco
// Professors: Saponara Sergio, Crocetti Luca
// repo: https://github.com/Portgas97/fpga_full_hash_algorithm_des_sbox


// Main module that implements the FSM and instantiates the submodules
module full_hash_des_box(
	input rst_n,					// active-low asynchronous reset
	input clk,						// clock
	input M_valid,					// input port that signals input validity
	input [7:0] message,			// message byte intput
	input [63:0] counter,			// real byte length of the overall message
	output reg [31:0] digest_out,	// hash value
	output reg hash_ready			// output port that signals output validity
);

	// nibbles initialization values for the H[i] variables 
	localparam h_0 = 4'h4;
	localparam h_1 = 4'hB;
	localparam h_2 = 4'h7;
	localparam h_3 = 4'h1;
	localparam h_4 = 4'hD;
	localparam h_5 = 4'hF;
	localparam h_6 = 4'h0;
	localparam h_7 = 4'h3;

	// useful names for the states of the FSM
	localparam S0 = 2'b00;
	localparam S1 = 2'b01;
	localparam S2 = 2'b10;

	reg [7:0] MSG; 			 // input character
	reg [63:0] C_COUNT; 	 // remaining bytes
	reg [63:0] COUNTER;		 // real byte length
	reg [7:0] [3:0] H_MAIN;  // used for the main computation
	reg [7:0] [3:0] H_LAST;  // used for the last computation
	reg [1:0] STAR;			 // status register for the FSM
	reg M_VALID_R;			 // to sample M_valid input


	// Store partial results, between different characters of the same message
	wire [7:0] [3:0] half_hash;	


	// main module instantiation
	H_main_computation main(
		.m(MSG),
		.h_main(H_MAIN),
		.h_main_out(half_hash)
	);
	

	// last computation instantiation
	H_last_computation final_op(
		.H_main(H_MAIN), 
		.counter(COUNTER), 
		.H_last(H_LAST)
	);


	// Finite State Machine, see documentation
	always @(posedge clk or negedge rst_n) begin

		if(!rst_n) begin

			// initialization 
			STAR <= S0;
			hash_ready <= 0;

		end else begin

			case(STAR)

				// input sampling
				S0: begin

					// state transfer if inputs are valid
					STAR <= (M_valid == 1) ? ((counter > 0) ? S1: S2) : S0;

					// input sampling
					MSG <= message;
					
					// sampling the M_valid value
					M_VALID_R <= M_valid;

					// sampling the real length of the message
					C_COUNT <= counter;
					
					// sampling the real length of the message
					COUNTER <= counter;

					// initialize the main register
					H_MAIN <= {h_0, h_1, h_2, h_3, h_4, h_5, h_6, h_7};

					// in case of a new character elaboration
					hash_ready <= (M_valid == 1'b1) ? 1'b0 : hash_ready;
				end

				// main computation
				S1: begin 
					
					// result of the elaboration of the 4 rounds
					H_MAIN <= (M_VALID_R == 1) ? half_hash : H_MAIN;
					
					// count the number of elaborated bytes
					C_COUNT <= (M_valid == 1) ? C_COUNT - 1 : C_COUNT;
					
					// continuing to sample the M_valid value
					M_VALID_R <= M_valid;

					// state transfer
					STAR <= (C_COUNT == 1) ? S2 : S1;

					// needed for the consecutive input sampling
					MSG <= (M_valid == 1) ? message : MSG;
				end

				// last transformation signalling and digest output, return to S0
				S2: begin
					
					// digest assigned with the final result of the last computation
					digest_out <= H_LAST;

					// signal the output
					hash_ready <= 1;
					
					// continuing to sample the M_valid value
					M_VALID_R <= M_valid;
					
					// unconditional state trasfer
					STAR <= S0;
				end

				default: STAR <= S0;
			endcase
		end
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
    assign m6 = {m[3]^m[2], m[1], m[0], m[7], m[6], m[5]^m[4]};

	// DES S-Box value computation
	wire [3:0] s_value;
	S_Box SBox(
		.in(m6),
		.out(s_value)
		);

	// first round
	wire [7:0] [3:0] h_main_1;
	Hash_Round Round_1(
		.S_Box_value(s_value),
		.h_main(h_main),
		.h_out(h_main_1)
		);

	// second round
	wire [7:0] [3:0] h_main_2;
	Hash_Round Round_2(
		.S_Box_value(s_value),
		.h_main(h_main_1),
		.h_out(h_main_2)
		);

	// third round
	wire [7:0] [3:0] h_main_3;
	Hash_Round Round_3(
		.S_Box_value(s_value),
		.h_main(h_main_2),
		.h_out(h_main_3)
		);

	// fourth round
	Hash_Round Round_4(
		.S_Box_value(s_value),
		.h_main(h_main_3),
		.h_out(h_main_out)
		);

endmodule



// It performs one round of the main hash algorithm
// According to: H[i] = (H[(i+1) mod 8] ^ S(M6)) << |_ i/2 _|
module Hash_Round(
	input [3:0] S_Box_value, // output of the DES S-Box LUT table
	input [7:0] [3:0] h_main, // previous hash values
    output reg [7:0] [3:0] h_out // new hash values
);

	always @(*) begin

		// 0
		h_out[0] = h_main[1] ^ S_Box_value;

		// 1
		h_out[1] = h_main[2] ^ S_Box_value;

		// 2
		h_out[2] = {h_main[3][2:0] ^ S_Box_value[2:0], h_main[3][3] ^ S_Box_value[3]};

		// 3
		h_out[3] = {h_main[4][2:0] ^ S_Box_value[2:0], h_main[4][3] ^ S_Box_value[3]};

		// 4
		h_out[4] = {h_main[5][1:0] ^ S_Box_value[1:0], h_main[5][3:2] ^ S_Box_value[3:2]};

		// 5
		h_out[5] = {h_main[6][1:0] ^ S_Box_value[1:0], h_main[6][3:2] ^ S_Box_value[3:2]};

		// 6
		h_out[6] = {h_main[7][0] ^ S_Box_value[0], h_main[7][3:1] ^ S_Box_value[3:1]}; 

		// 7
		h_out[7] = {h_main[0][0] ^ S_Box_value[0], h_main[0][3:1] ^ S_Box_value[3:1]};
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
	reg [7:0] [3:0] h_out;

	// 0
	Counter_to_C_6 C6_0(
		.in_c(counter[63:56]), 
		.out_c(idx[0])
		);
	S_Box Sbox0(
		.in(idx[0]), 
		.out(S_value[7])	
		);
	
	// 1
	Counter_to_C_6 C6_1(
		.in_c(counter[55:48]),
		.out_c(idx[1])
		);
	S_Box Sbox1(
		.in(idx[1]),
		.out(S_value[6])
		);
	
	// 2
	Counter_to_C_6 C6_2(
		.in_c(counter[47:40]),
		.out_c(idx[2])
		);
	S_Box Sbox2(
		.in(idx[2]),
		.out(S_value[5])
		);
	
	// 3
	Counter_to_C_6 C6_3(
		.in_c(counter[39:32]),
		.out_c(idx[3])
		);
	S_Box Sbox3(
		.in(idx[3]),
		.out(S_value[4])
		);
	
	// 4
	Counter_to_C_6 C6_4(
		.in_c(counter[31:24]),
		.out_c(idx[4])
		);
	S_Box Sbox4(
		.in(idx[4]),
		.out(S_value[3])
		);
	
	// 5
	Counter_to_C_6 C6_5(
		.in_c(counter[23:16]),
		.out_c(idx[5])
		);
	S_Box Sbox5(
		.in(idx[5]),
		.out(S_value[2])
		);
	
	// 6
	Counter_to_C_6 C6_6(
		.in_c(counter[15:8]),
		.out_c(idx[6])
		);
	S_Box Sbox6(
		.in(idx[6]),
		.out(S_value[1])
		);

	// 7
	Counter_to_C_6 C6_7(
		.in_c(counter[7:0]),
		.out_c(idx[7])
		);
	S_Box Sbox7(
		.in(idx[7]),
		.out(S_value[0])
		);
	

	always @(*) begin
		
		h_out[0] = H_main[1] ^ S_value[0];

		h_out[1] = H_main[2] ^ S_value[1];

		h_out[2] = {H_main[3][2:0] ^ S_value[2][2:0], H_main[3][3] ^ S_value[2][3]};
		
		h_out[3] = {H_main[4][2:0] ^ S_value[3][2:0], H_main[4][3] ^ S_value[3][3]};

		h_out[4] = {H_main[5][1:0] ^ S_value[4][1:0], H_main[5][3:2] ^ S_value[4][3:2]};
	
		h_out[5] = {H_main[6][1:0] ^ S_value[5][1:0], H_main[6][3:2] ^ S_value[5][3:2]};

		h_out[6] = {H_main[7][0] ^ S_value[6][0], H_main[7][3:1] ^ S_value[6][3:1]};

		h_out[7] = {H_main[0][0] ^ S_value[7][0], H_main[0][3:1] ^ S_value[7][3:1]};
		
		H_last = {h_out[7], h_out[6], h_out[5], h_out[4], h_out[3], h_out[2], h_out[1], h_out[0]};
	end

endmodule





/************************************** UTILITY FUNCTIONS **************************************/


//Final operation, it trasnforms one byte of the message length counter into a 6-bit value 
module Counter_to_C_6(input [7:0] in_c, output reg [5:0] out_c);
	always @(*) begin
		out_c = {in_c[7] ^ in_c[1], in_c[3], in_c[2], in_c[5] ^ in_c[0], in_c[4], in_c[6]};
	end
endmodule


// This module implements a LUT version of the DES S-box
// The first and the last bits of the input select the row of the S-Box
// The 4 central bits select the column of the S-box
module S_Box (input [5 : 0] in, output reg [3 : 0] out);

    reg [1 : 0] row ;
    reg [3 : 0] colum;

    always @(*) begin

        row = {in[5], in[0]};
        colum = in[4:1];
		
        case(colum)
            4'b0000: case(row) 2'b00: out = 4'b0010; 2'b01: out = 4'b1110; 2'b10: out = 4'b0100; 2'b11: out = 4'b1011; endcase
            4'b0001: case(row) 2'b00: out = 4'b1100; 2'b01: out = 4'b1011; 2'b10: out = 4'b0010; 2'b11: out = 4'b1000; endcase
            4'b0010: case(row) 2'b00: out = 4'b0100; 2'b01: out = 4'b0010; 2'b10: out = 4'b0001; 2'b11: out = 4'b1100; endcase
            4'b0011: case(row) 2'b00: out = 4'b0001; 2'b01: out = 4'b1100; 2'b10: out = 4'b1011; 2'b11: out = 4'b0111; endcase
            4'b0100: case(row) 2'b00: out = 4'b0111; 2'b01: out = 4'b0100; 2'b10: out = 4'b1100; 2'b11: out = 4'b0001; endcase
            4'b0101: case(row) 2'b00: out = 4'b1010; 2'b01: out = 4'b0111; 2'b10: out = 4'b1101; 2'b11: out = 4'b1110; endcase
            4'b0110: case(row) 2'b00: out = 4'b1011; 2'b01: out = 4'b1101; 2'b10: out = 4'b0111; 2'b11: out = 4'b0010; endcase
            4'b0111: case(row) 2'b00: out = 4'b0110; 2'b01: out = 4'b0001; 2'b10: out = 4'b1000; 2'b11: out = 4'b1101; endcase
            4'b1000: case(row) 2'b00: out = 4'b1000; 2'b01: out = 4'b0101; 2'b10: out = 4'b1111; 2'b11: out = 4'b0110; endcase
            4'b1001: case(row) 2'b00: out = 4'b0101; 2'b01: out = 4'b0000; 2'b10: out = 4'b1001; 2'b11: out = 4'b1111; endcase
            4'b1010: case(row) 2'b00: out = 4'b0011; 2'b01: out = 4'b1111; 2'b10: out = 4'b1100; 2'b11: out = 4'b0000; endcase
            4'b1011: case(row) 2'b00: out = 4'b1111; 2'b01: out = 4'b1100; 2'b10: out = 4'b0101; 2'b11: out = 4'b1001; endcase
            4'b1100: case(row) 2'b00: out = 4'b1101; 2'b01: out = 4'b0011; 2'b10: out = 4'b0110; 2'b11: out = 4'b1100; endcase
            4'b1101: case(row) 2'b00: out = 4'b0000; 2'b01: out = 4'b1001; 2'b10: out = 4'b0011; 2'b11: out = 4'b0100; endcase
            4'b1110: case(row) 2'b00: out = 4'b1110; 2'b01: out = 4'b1000; 2'b10: out = 4'b0000; 2'b11: out = 4'b0101; endcase
            4'b1111: case(row) 2'b00: out = 4'b1001; 2'b01: out = 4'b0110; 2'b10: out = 4'b1110; 2'b11: out = 4'b0011; endcase 
        endcase
    end
endmodule