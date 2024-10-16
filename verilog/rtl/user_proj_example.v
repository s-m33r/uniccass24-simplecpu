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

wire [7:0] o_ram_data;

reg [7:0] pc_reg;
reg [7:0] a_reg;
reg [7:0] b_reg;
reg [7:0] alu_out;
reg [7:0] io_reg;
reg flag_carry;
wire flag_zero = (alu_out == 8'b0);

wb_ram RAM (
	.i_clk    (wb_clk_i),
	.i_reset  (wb_rst_i),

	.i_wb_adr (wbs_adr_i),
	.i_wb_dat (wbs_dat_i),
	.i_wb_sel (wbs_sel_i),
	.i_wb_we  (wbs_we_i ),
	.i_wb_cyc (wbs_cyc_i),
	.i_wb_stb (wbs_stb_i),

	.o_wb_dat (wbs_dat_o),
	.o_wb_ack (wbs_ack_o),

	.o_ram_data(o_ram_data),
	.o_ram_addr(pc_reg    )
);

assign la_data_out[7:0] =  a_reg;
assign la_data_out[13:8] = b_reg;
assign la_data_out[15:14] = {flag_carry, flag_zero};
assign la_data_out[23:16] = io_reg;

always @(posedge wb_clk_i) begin
	if (wb_rst_i) begin
		a_reg = 0;
		b_reg = 0;
		pc_reg = 0;
	end
	else begin
		case (o_ram_data)
			8'b0: begin
				$display("NOP");
				pc_reg <= pc_reg + 1;
			end
		endcase
	end
end

endmodule

`default_nettype wire

module wb_ram(
    // RCC
    input wire i_clk,
    input wire i_reset,
    // Wishbone
    input  wire [31:0] i_wb_adr,
    input  wire [31:0] i_wb_dat,
    input  wire  [3:0] i_wb_sel,
    input  wire        i_wb_we,
    input  wire        i_wb_cyc,
    input  wire        i_wb_stb,
    output reg  [31:0] o_wb_dat,
    output reg         o_wb_ack,

	output [7:0]       o_ram_data,
	input  [7:0]       o_ram_addr
);

// Number of 8-bit words to store
localparam SIZE = 16;

// Data storage
reg [7:0] data [SIZE];

assign o_ram_data = data[o_ram_addr];

// Each data entry is 32 bits wide, so right shift the input address
//localparam addr_width = $clog2(SIZE);
localparam addr_width = 8;
wire [addr_width-1:0] data_addr = i_wb_adr[addr_width+1:2];

integer i;
always @(posedge i_clk) begin

    if (i_reset) begin
        o_wb_ack <= 1'b0;
    end else begin
        o_wb_ack <= 1'b0;

        if (i_wb_cyc & i_wb_stb & ~o_wb_ack) begin
            // Always ack
            o_wb_ack <= 1'b1;

            // Reads
            o_wb_dat <= data[data_addr];

            // Writes
            if (i_wb_we) begin
                for (i = 0; i < 4; i++) begin
                    if (i_wb_sel[i])
                        data[data_addr][i*8 +: 8] <= i_wb_dat[i*8 +: 8];
                end
            end
        end
    end

end

endmodule
