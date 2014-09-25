`timescale 1ns / 1ps

module modif_mult_test;

	// Inputs
	reg [191:0] x, y;
	reg clk, reset, start;
	wire [191:0] z;
	wire done;
	// Instantiate the Unit Under Test (UUT)
	mont_mult_modif uut (
    .x(x), 
    .y(y), 
    .clk(clk), 
    .reset(reset), 
    .start(start), 
    .z(z), 
    .done1(done)
    );

	always
		#50 clk = ~clk;

	initial begin
		// Initialize Inputs
		x = 0;
		y = 0;		
		clk = 1;
		// Wait 100 ns for global reset to finish
		#100;
		  
		x = {1'b1,191'b0};
		y = 192'd48;
		reset = 1;
		start = 1;
		#100
		reset = 0;
		#100
		start = 0;
		#100
		start = 1;

		start = 0;
		#100
		x = 8'Hf7;
		y = 8'H0a;
		#100
		start = 1;
		#3000

		start = 0;
		#100
		x = 8'Hd4;
		y = 8'H30;
		#100
		start = 1;
		#3000

		start = 0;
		#100
		x = 8'Hf7;
		y = 8'H30;
		#100
		start = 1;
		#3000;
	end
	
	initial 
		#100000 $finish;
      
endmodule

