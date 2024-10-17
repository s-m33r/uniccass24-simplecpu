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
