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

module alu (
    input wire [7:0] a,
    input wire [7:0] b,
    input sub,
    
    output wire [7:0] out,
    output flag_zero,
    output flag_carry 
);

    wire [7:0] bTwosComplement;
    wire [7:0] sub8 = {8{sub}};

    assign bTwosComplement = b ^ sub8;

    assign out = a + bTwosComplement + {7'b0, sub};

    assign flag_zero = &out;
    assign flag_carry = (a[7] & b[7] & !out[7]) | (!a[7] & !b[7] & out[7]);
endmodule
`default_nettype wire
