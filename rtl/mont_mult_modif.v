`timescale 1ns / 1ps


module mont_mult_modif(
	x, y,
	clk, reset, start,
	z,
	done1
    );
parameter m =192'hfffffffffffffffffffffffffffffffeffffffffffffffff,
k = 192, logk = 8, zero = { logk {1'b0}},
minus_m = {1'b0,192'h000000000000000000000000000000010000000000000001},
delay = 8'b01100000, COUNT = 8'b10111111; //(k-1,logk)

parameter S0 = 3'd0, S1 = 3'd1, S2 = 3'd2, S3 = 3'd3, S4 = 3'd4;

input [k-1:0] x;
input [k-1:0] y;
input clk, reset, start;
output [k-1:0] z;
output done1;

reg [logk-1:0] count;
reg [logk-1:0] timer_state;
reg [k:0] pc, psa;
reg [k-1:0] int_x;
wire equal_zero, time_out;
wire [k:0] y_by_xi, half_ac, half_as, half_bc, half_bs, next_pc, next_psa, p, p_minus_m;
wire [k+1:0] ac, as, bc, bs, long_m;
wire xi;
reg load, ce_p, load_timer;
reg [2:0] current_state;
reg [2:0] next_state;
reg done;

assign done1 = done;
genvar i;
generate for(i=0;i<k;i=i+1) 
	begin:and_gates
		and a(y_by_xi[i],y[i],xi);
	end
endgenerate

assign y_by_xi[k] = 1'b0;
generate for(i=0;i<=k;i=i+1) 
	begin:first_csa
		xor x(as[i],pc[i],psa[i],y_by_xi[i]);
		wire w1,w2,w3;
		and a1(w1,pc[i],psa[i]);
		and a2(w2,pc[i],y_by_xi[i]);
		and a3(w3,psa[i],y_by_xi[i]);
		or o(ac[i+1],w1,w2,w3);
	end
endgenerate
assign ac[0] = 1'b0, as[k+1] = 1'b0, long_m = {{2'b00},m};
generate for(i=0;i<=k;i=i+1) 
	begin:second_csa
		xor x(bs[i],ac[i],as[i],long_m[i]);
		wire w1,w2,w3;
		and a1(w1,ac[i],as[i]);
		and a2(w2,ac[i],long_m[i]);
		and a3(w3,as[i],long_m[i]);
		or o(bc[i+1],w1,w2,w3);
	end
endgenerate

assign bc[0] = 1'b0, bs[k+1] = ac[k+1],
	half_as = as[k+1:1], half_ac = ac[k+1:1],
	half_bs = bs[k+1:1], half_bc = bc[k+1:1];

assign next_pc = (as[0]==1'b0)? half_ac:half_bc;
assign next_psa = (as[0]==1'b0)? half_as:half_bs;

always@(posedge(clk)) 
	begin:parallel_register
		if (load==1'b1) begin
			pc = { k+1 {1'b0} }; psa = { k+1 {1'b0} }; end
		else if (ce_p==1'b1) begin
			pc = next_pc; psa = next_psa; end
	end 
assign equal_zero = (count==zero)? 1'b1:1'b0;
assign p = psa + pc, p_minus_m = p + minus_m;
assign z = (p_minus_m[k]==1'b0)? p[k-1:0]:p_minus_m[k-1:0];

always@(posedge(clk))
	begin:shift_register
		integer i;
		if (load==1'b1) int_x = x; 
		else if (ce_p==1'b1) begin
			for(i=0;i<=k-2;i=i+1) int_x[i] = int_x[i+1];
			int_x[k-1] = 1'b0; end
	end 
assign xi = int_x[0];

always@(posedge(clk)) 
	begin:counter
		if (load==1'b1) count <= COUNT;  
		else if (ce_p==1'b1) count <= count - 1'b1;
	end 
	
	always@(clk, current_state) begin
			case(current_state) 
				S0: begin ce_p = 1'b0; load = 1'b0; load_timer = 1'b1; done = 1'b1; end
				S1: begin ce_p = 1'b0; load = 1'b0; load_timer = 1'b1; done = 1'b1; end
				S2: begin ce_p = 1'b0; load = 1'b1; load_timer = 1'b1; done = 1'b0; end
				S3: begin ce_p = 1'b1; load = 1'b0; load_timer = 1'b1; done = 1'b0; end
				S4: begin ce_p = 1'b0; load = 1'b0; load_timer = 1'b0; done = 1'b0; end
				default: begin ce_p = 1'b0; load = 1'b0; load_timer = 1'b1; done = 1'b1; end
			endcase
	end
	
	always@(posedge clk) begin	
		if(reset) current_state = S0;
		else current_state = next_state;
	end
	
	always@(*) begin
		next_state = current_state;
		if (reset==1'b1) next_state = S0; 
		else if (clk==1'b1) begin
			case(next_state)
				S0: if(start==1'b0) next_state = S1;
				S1: if(start==1'b1) next_state = S2;
				S2: next_state = S3;
				S3: if(equal_zero==1'b1) next_state = S4;
				S4: if(time_out==1'b1) next_state = S0;
				default: next_state = S0;
			endcase
		end
	end

always@(posedge clk)
	begin:timer
		if (clk==1'b1) begin
			if (load_timer==1'b1) timer_state = delay; 
			else timer_state = timer_state - 1'b1;
		end
	end
	
assign time_out = (timer_state==zero)? 1'b1:1'b0;

endmodule



