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
reg [7:0] data [SIZE:0];

assign o_ram_data = data[o_ram_addr];

// // If we have been given an initial file parameter, load that
// parameter INITIAL_HEX = "";
// initial begin
//     /* verilator lint_off WIDTH */
//     if (INITIAL_HEX != "")
//         $readmemh(INITIAL_HEX, data);
//     /* verilator lint_on WIDTH */
// end

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
