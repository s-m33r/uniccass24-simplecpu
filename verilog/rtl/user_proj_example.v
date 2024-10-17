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
/*
 *-------------------------------------------------------------
 *
 * user_proj_example
 *
 * This is an example of a (trivially simple) user project,
 * showing how the user project can connect to the logic
 * analyzer, the wishbone bus, and the I/O pads.
 *
 * This project generates an integer count, which is output
 * on the user area GPIO pads (digital output only).  The
 * wishbone connection allows the project to be controlled
 * (start and stop) from the management SoC program.
 *
 * See the testbenches in directory "mprj_counter" for the
 * example programs that drive this user project.  The three
 * testbenches are "io_ports", "la_test1", and "la_test2".
 *
 *-------------------------------------------------------------
 */

module user_proj_example #(
    parameter BITS = 16
)(
`ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input         wb_clk_i,
    input         wb_rst_i,

    input         wbs_stb_i,
    input         wbs_cyc_i,
    input         wbs_we_i,
    input   [3:0] wbs_sel_i,
    input  [31:0] wbs_dat_i,
    input  [31:0] wbs_adr_i,
    output        wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [BITS-1:0] io_in,
    output [BITS-1:0] io_out,
    output [BITS-1:0] io_oeb,

    // IRQ
    output [2:0] irq
);

// RAM loading signals
wire load_ram;
wire [3:0] load_addr;
wire [7:0] load_data;

assign load_ram = la_data_in[0];
assign load_addr = la_data_in[4:1];
assign load_data = la_data_in[12:5];

wire cpu_reset;
assign cpu_reset = la_data_in[13];

reg [7:0] ram [0:15];

always @(*) begin
    if (load_ram) begin
	$display("ram[%x] = %x", load_addr, load_data);
	ram[load_addr] = load_data;
    end
end

// CPU registers and flags
reg [3:0] pc_reg;
reg [7:0] a_reg;
reg [7:0] b_reg;
reg [7:0] out_reg;

wire flag_carry;
wire flag_zero;
reg  sub_op;
wire [7:0] alu_out;

alu ALU (
    .a          (a_reg     ),
    .b          (b_reg     ),
    .sub        (sub_op    ),
    .out        (alu_out   ),
    .flag_zero  (flag_zero ),
    .flag_carry (flag_carry)
);

assign la_data_out[7:0] =  a_reg;
assign la_data_out[13:8] = b_reg;
assign la_data_out[15:14] = {flag_carry, flag_zero};
assign la_data_out[23:16] = out_reg;

// helper logic to extract instruction and operand
wire instruction;
wire operand;
assign instruction = ram[pc_reg][7:4];
assign operand = ram[pc_reg][3:0];

// control flow
localparam CYCLE_1 = 1'b0;
localparam CYCLE_2 = 1'b1;
reg cycle_half;
reg [3:0] prev_op;

reg cpu_halt;

always @(posedge wb_clk_i) begin
	if (cpu_reset) begin
	    cpu_halt <= 0;

	    a_reg <= 0;
	    b_reg <= 0;
	    pc_reg <= 0;

	    sub_op <= 0;

	    cycle_half <= 0;
	    prev_op <= 0;
	end

	else if (cpu_halt) begin
	    /* trap state */
	end

	else if ( cycle_half == CYCLE_1 ) begin
		case (instruction)
			4'b0000: begin
			    $display("NOP");
			end

			4'b0001: begin
			    $display("LDA");
			    a_reg <= ram[operand];
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
			end

			4'b0101: begin
			    $display("LDI");
			    a_reg <= operand;
			end

			4'b0110: begin
			    $display("JMP");
			    pc_reg <= operand;
			end

			4'b0111: begin
			    $display("JZ");
			    pc_reg <= (flag_zero) ? operand : pc_reg;
			end

			4'b1000: begin
			    $display("OUT");
			    out_reg <= a_reg;
			end

			4'b1001: begin
			    $display("HLT");
			    cpu_halt <= 1;
			end
		endcase

		cycle_half <= CYCLE_2;
	end

	else if (cycle_half == CYCLE_2) begin

	    case (prev_op)
		4'b0010: begin
		    a_reg <= alu_out;
		end

		4'b0011: begin
		    a_reg <= alu_out;
		end
	    endcase

	    cycle_half <= CYCLE_1;
	end
end

endmodule
`default_nettype wire
