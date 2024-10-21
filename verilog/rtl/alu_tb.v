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
`timescale 1ns/1ps

module alu_tb();

reg [7:0] a;
reg [7:0] b;
reg sub;


wire [7:0] out;
wire flag_zero;
wire flag_carry;

alu dut (
	.a(a),
	.b(b),
	.sub(sub),

	.out(out),
	.flag_zero(flag_zero),
	.flag_carry(flag_carry)
);

initial begin
	a = 1;
	b = 2;
	sub = 1;
	#10
	$display(out);
	$display(flag_carry);
	$display(flag_zero);
end

endmodule
