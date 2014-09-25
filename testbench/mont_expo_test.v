`timescale 1ns / 1ps

module mont_expo_test;

	// Inputs
	reg [191:0] x, y;
	reg clk, reset, start;
	wire [191:0] z;
	wire done;

	// Instantiate the Unit Under Test (UUT)
	mont_expo instance_name (
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
		  
		x = 192'h6543210fedcba9876543210fedcba9876543210fedcba987;
		y = 192'hfedcba9876543210fedcba9876543210fedcba9876543210;
//		x = 192'h3;
//		y = 192'h3;
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
		start = 1;
		#100000;
		@(posedge done) #100 $finish;
		
	end
	      
endmodule
