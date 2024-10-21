// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0
`default_nettype none

module simplecpu (
	input       clk,
	input       reset,
	
	input       load_ram,
	input [3:0] load_addr,
	input [7:0] load_data,

	output [7:0] out_port,
	output [7:0] io_oeb
);

reg [7:0] ram [0:15];

always @(posedge clk) begin
    if (~reset & load_ram) begin
		$display("ram[%b] = %b", load_addr, load_data);
		ram[load_addr] <= load_data;
    end
end

// CPU registers and flags
reg [3:0] pc_reg;
reg [7:0] a_reg;
reg [7:0] b_reg;

reg [7:0] out_reg;
assign out_port = out_reg;
assign io_oeb = 7'd0; // enable given output lines

reg flag_carry;
reg flag_zero;

wire flag_carry_w;
wire flag_zero_w;
reg  sub_op;
wire [7:0] alu_out;

alu ALU (
    .a          (a_reg       ),
    .b          (b_reg       ),
    .sub        (sub_op      ),
    .out        (alu_out     ),
    .flag_zero  (flag_zero_w ),
    .flag_carry (flag_carry_w)
);

// helper logic to extract instruction and operand
reg [7:0] mem_pc_data;
wire [3:0] instruction;
wire [3:0] operand;
assign instruction = mem_pc_data[7:4];
assign operand     = mem_pc_data[3:0];

// control flow
localparam CYCLE_FETCH   = 4'b0000;
localparam CYCLE_DECODE  = 4'b0001;
localparam CYCLE_EXECUTE = 4'b0010;

localparam CYCLE_1 = 1'b0;
localparam CYCLE_2 = 1'b1;
reg [3:0] cycle;
reg [3:0] prev_op;

reg cpu_halt;

always @(posedge clk) begin
	if (~reset) begin
	    cpu_halt <= 0;

	    a_reg <= 0;
	    b_reg <= 0;
	    pc_reg <= 0;

		flag_carry <= 0;
		flag_zero <= 0;

	    sub_op <= 0;

	    cycle <= CYCLE_FETCH;
	    prev_op <= 0;
	end

	else if (cpu_halt) begin
	    /* trap state */
	end

	else if ( cycle == CYCLE_FETCH ) begin
	    mem_pc_data <= ram[pc_reg];
	    cycle <= CYCLE_DECODE;
	end

	else if ( cycle == CYCLE_DECODE ) begin
		case (instruction)
			4'b0000: begin
			    $display("NOP");
				pc_reg <= pc_reg + 1;
			end

			4'b0001: begin
			    $display("LDA");
			    a_reg <= ram[operand];
			    pc_reg <= pc_reg + 1;
			end

			4'b0010: begin // { a_reg <= alu_out } handled in 2nd cycle
			    $display("ADD");
			    b_reg <= ram[operand];
			end

			4'b0011: begin
			    $display("SUB"); // { a_reg <= alu_out } handled in 2nd cycle
			    b_reg <= ram[operand];
			    sub_op <= 1;
			end

			4'b0100: begin
			    $display("STA");
			    ram[operand] <= a_reg;
			    pc_reg <= pc_reg + 1;
			end

			4'b0101: begin
			    $display("LDI");
			    a_reg <= 8'h0 ^ operand;
			    pc_reg <= pc_reg + 1;
			end

			4'b0110: begin
			    $display("JMP");
			    pc_reg <= operand;
			end

			4'b0111: begin
			    $display("JC");
			    pc_reg <= (flag_carry) ? operand : pc_reg + 1;
			end

			4'b1000: begin
			    $display("JZ");
			    pc_reg <= (flag_zero) ? operand : pc_reg + 1;
			end

			4'b1110: begin
			    $display("OUT");
			    out_reg <= a_reg;
			    pc_reg <= pc_reg + 1;
			end

			4'b1111: begin
			    $display("HLT");
			    cpu_halt <= 1;
			end
		endcase

		prev_op <= instruction;
		cycle <= CYCLE_EXECUTE;
	end

	else if (cycle == CYCLE_EXECUTE) begin

	    if (prev_op == 4'b0010) begin
	    	a_reg <= alu_out;
	    	pc_reg <= pc_reg + 1;

			flag_zero <= flag_zero_w;
			flag_carry <= flag_carry_w;
	    end
	    else if (prev_op == 4'b0011) begin
	    	a_reg <= alu_out;
	    	sub_op <= 0;
	    	pc_reg <= pc_reg + 1;

			flag_zero <= flag_zero_w;
			flag_carry <= flag_carry_w;
	    end

	    cycle <= CYCLE_FETCH;

	    // print CPU state at end of cycle
	    $display("PC: %x | A: %x | B: %x | O: %x | z: %b | c: %b", pc_reg, a_reg, b_reg, out_reg, flag_zero, flag_carry);
	end
end

endmodule
`default_nettype wire
