`timescale 1ns / 1ps

module mont_expo(
	x, y, clk, reset, start,
	z,
	done1
    );
	 
parameter m =192'hfffffffffffffffffffffffffffffffeffffffffffffffff,  //2^192-2^16-1
k = 192, logk = 8, one = {{ k-1 {1'b0} }, 1'b1},
minus_m = {1'b0,192'h000000000000000000000000000000010000000000000001},
exp_k = 192'h000000000000000000000000000000010000000000000001, 
exp_2k = 192'h000000000000000100000000000000020000000000000001;

input [k-1:0] x;
input [k-1:0] y;
input clk, reset, start;
output [k-1:0] z;
output done1;

reg done;
wire [k-1:0] operand1, operand2;
reg [k-1:0] e, ty, int_x;
reg [logk-1:0] count;
wire [k-1:0] result;
reg ce_e, ce_ty, update, load, start_mp;
wire mp_done;
reg [1:0] control;
wire equal_zero, xkminusi;
reg [4:0] current_state;
reg [4:0] next_state;


mont_mult_modif f(operand1, operand2, clk, reset, start_mp, result, mp_done);
assign done1 = done;
assign operand1 = (control==2'b00)? y:e;
assign operand2 = (control==2'b00)? exp_2k:(control==2'b01)? e:(control==2'b10)? ty: one;
assign z = result;

always@(posedge(clk)) 
	begin:register_e
		if (load==1'b1) e = exp_k; 
		else if (ce_e==1'b1) e = result; 
	end 

always@(posedge(clk)) 
	begin:register_ty
		if (ce_ty==1'b1) ty = result; 
	end 
	
always@(posedge(clk))
	begin:shift_register
		integer i;
		if (load==1'b1) int_x = x; 
		else if (update==1'b1) int_x = {int_x[k-2:0],1'b0};
	end 
assign xkminusi = int_x[k-1];
	
always@(posedge(clk)) 
	begin:counter
		if (load==1'b1) count <= 8'b11000000; 
		else if (update==1'b1) count <= count - 1'b1; 
	end 
assign equal_zero = (count == {logk {1'b0}})? 1'b1:1'b0;

always@(clk, current_state) 
	begin:control_unit
		case(current_state) 
			5'h0: begin ce_e = 1'b0; ce_ty = 1'b0; load = 1'b0; update = 0; start_mp = 0; control = 2'b0; done = 1'b1; end
			5'h1: begin ce_e = 1'b0; ce_ty = 1'b0; load = 1'b0; update = 0; start_mp = 0; control = 2'b0; done = 1'b1; end
			5'h2: begin ce_e = 1'b0; ce_ty = 1'b0; load = 1'b1; update = 0; start_mp = 0; control = 2'b0; done = 1'b0; end
			5'h3: begin ce_e = 1'b0; ce_ty = 1'b0; load = 1'b0; update = 0; start_mp = 1; control = 2'b0; done = 1'b0; end
			5'h4: begin ce_e = 1'b0; ce_ty = 1'b0; load = 1'b0; update = 0; start_mp = 0; control = 2'b0; done = 1'b0; end
			5'h5: begin ce_e = 1'b0; ce_ty = 1'b1; load = 1'b0; update = 0; start_mp = 0; control = 2'b0; done = 1'b0; end
			5'h6: begin ce_e = 1'b0; ce_ty = 1'b0; load = 1'b0; update = 0; start_mp = 1; control = 2'b1; done = 1'b0; end
			5'h7: begin ce_e = 1'b0; ce_ty = 1'b0; load = 1'b0; update = 0; start_mp = 0; control = 2'b1; done = 1'b0; end
			5'h8: begin ce_e = 1'b1; ce_ty = 1'b0; load = 1'b0; update = 0; start_mp = 0; control = 2'b1; done = 1'b0; end
			5'h9: begin ce_e = 1'b0; ce_ty = 1'b0; load = 1'b0; update = 0; start_mp = 1; control = 2'b10; done = 1'b0; end
			5'hA: begin ce_e = 1'b0; ce_ty = 1'b0; load = 1'b0; update = 0; start_mp = 0; control = 2'b10; done = 1'b0; end
			5'hB: begin ce_e = 1'b1; ce_ty = 1'b0; load = 1'b0; update = 0; start_mp = 0; control = 2'b10; done = 1'b0; end
			5'hC: begin ce_e = 1'b0; ce_ty = 1'b0; load = 1'b0; update = 1; start_mp = 0; control = 2'b0; done = 1'b0; end
			5'hD: begin ce_e = 1'b0; ce_ty = 1'b0; load = 1'b0; update = 0; start_mp = 0; control = 2'b0; done = 1'b0; end
			5'hE: begin ce_e = 1'b0; ce_ty = 1'b0; load = 1'b0; update = 0; start_mp = 1; control = 2'b11; done = 1'b0; end
			5'hF: begin ce_e = 1'b0; ce_ty = 1'b0; load = 1'b0; update = 0; start_mp = 0; control = 2'b11; done = 1'b0; end
			5'h10: begin ce_e = 1'b0; ce_ty = 1'b0; load = 1'b0; update = 0; start_mp = 0; control = 2'b11; done = 1'b0; end
			default: begin ce_e = 1'b0; ce_ty = 1'b0; load = 1'b0; update = 0; start_mp = 0; control = 2'b0; done = 1'b1; end
		endcase
	end
	
	always@(posedge clk) begin	
		if(reset) current_state = 5'b0;
		else current_state = next_state;
	end
	
	always@(*) begin		
		next_state = current_state;
		if (reset==1'b1) begin
			next_state = 5'b0; end
		else if (clk==1'b1) begin
			case(next_state)
				5'h0: if(start==1'b0) next_state = 5'h1;
				5'h1: if(start==1'b1) next_state = 5'h2;
				5'h2: next_state = 5'h3;
				5'h3: next_state = 5'h4;
				5'h4: if(mp_done==1'b1) next_state = 5'h5;
				5'h5: next_state = 5'h6;
				5'h6: next_state = 5'h7;
				5'h7: if(mp_done==1'b1) next_state = 5'h8;
				5'h8: next_state = (xkminusi==1'b1)? 5'h9:5'hC;
				5'h9: next_state = 5'hA;
				5'hA: if(mp_done==1'b1) next_state = 5'hB;
				5'hB: next_state = 5'hC;
				5'hC: next_state = 5'hD;
				5'hD: next_state = (equal_zero==1'b1)? 5'hE:5'h6;
				5'hE: next_state = 5'hF;
				5'hF: if(mp_done==1'b1) next_state = 5'h10;
				5'h10: next_state = 5'h0;
				default: if(start==1'b0) next_state = 5'h0;
			endcase
		end
	end
	
endmodule
