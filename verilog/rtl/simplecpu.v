module simplecpu (
	input clock,
	input reset,
	
	input load_ram,
	input [3:0] load_addr,
	input [7:0] load_data
);

reg [7:0] ram [0:15];

always @(*) begin
    if (load_ram) begin
	$display("ram[%b] = %b", load_addr, load_data);
	ram[load_addr] <= load_data;
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

//assign la_data_out[7:0] =  a_reg;
//assign la_data_out[13:8] = b_reg;
//assign la_data_out[15:14] = {flag_carry, flag_zero};
//assign la_data_out[23:16] = out_reg;

// helper logic to extract instruction and operand
wire [3:0] instruction;
wire [3:0] operand;
assign instruction = ram[pc_reg][7:4];
assign operand = ram[pc_reg][3:0];

// control flow
localparam CYCLE_1 = 1'b0;
localparam CYCLE_2 = 1'b1;
reg cycle_half;
reg [3:0] prev_op;

reg cpu_halt;

always @(posedge clock) begin
	if (~reset) begin
	    cpu_halt <= 0;

	    a_reg <= 0;
	    b_reg <= 0;
	    pc_reg <= 0;

	    sub_op <= 0;

	    cycle_half <= CYCLE_1;
	    prev_op <= 0;
	end

	else if (cpu_halt) begin
	    /* trap state */
	end

	else if ( cycle_half == CYCLE_1 ) begin
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
			    a_reg <= operand;
				pc_reg <= pc_reg + 1;
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
				pc_reg <= pc_reg + 1;
			end

			4'b1001: begin
			    $display("HLT");
			    cpu_halt <= 1;
			end
		endcase

		prev_op <= instruction;
		cycle_half <= CYCLE_2;
	end

	else if (cycle_half == CYCLE_2) begin

	    case (prev_op)
			4'b0010: begin
			    a_reg <= alu_out;
				pc_reg <= pc_reg + 1;
			end

			4'b0011: begin
			    a_reg <= alu_out;
				sub_op <= 0;
				pc_reg <= pc_reg + 1;
			end
	    endcase

	    cycle_half <= CYCLE_1;

		// print cpu state at end of cycle
		$display("| PC: %x | A: %x | B: %x | O: %x | z: %b | c: %b", pc_reg, a_reg, b_reg, out_reg, flag_zero, flag_carry);
	end
end

endmodule
