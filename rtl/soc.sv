
module picosoc #(
	parameter MEM_LOG = 1'b0
) (
	output logic [5:0] leds, 

	output logic uart_tx,
	
	input clk, resetn, uart_rx

); 

	logic        trap;      
	logic        mem_valid;
	logic        mem_instr;
	logic        mem_ready;
	logic [31:0] mem_addr;
	logic [31:0] mem_wdata;
	logic [ 3:0] mem_wstrb;
	logic [31:0] mem_rdata;


	picorv32 cpu(
		.clk(clk),
		.resetn(resetn),
		.trap(trap),

		.mem_valid(mem_valid),
		.mem_instr(mem_instr),
		.mem_ready(mem_ready),

		.mem_addr(mem_addr),
		.mem_wdata(mem_wdata),
		.mem_wstrb(mem_wstrb),
		.mem_rdata(mem_rdata)
	);


	logic ram_sel;
	logic led_sel;
	logic uart_sel;

	always_comb begin
		ram_sel  = 1'b0;
		led_sel  = 1'b0;
		uart_sel = 1'b0;
		
		if (mem_valid) 
			unique case( mem_addr[31-:4] )
				4'h0: ram_sel = 1;
				4'h1: led_sel = 1;
				4'h2: uart_sel = 1;
				default: assert(0) else $fatal(0, "memory segment: %h is invalid\n", mem_addr[31-:4]);
			endcase
	end

	always_ff @(posedge clk) begin

		if ( !resetn ) 
			mem_ready <= 1'b0;

		else if ( mem_valid && !mem_ready )
			mem_ready <= 1'b1;
		else 
			mem_ready <= 1'b0;

	end

	localparam int RAM_WORDS = 2048;

	logic [$clog2(RAM_WORDS)-1:0] ram_addr;
	logic [3:0]                   ram_we;
	logic [31:0]                  ram_rdata;

	assign ram_addr = mem_addr >> 2;

	assign ram_we = (ram_sel && !mem_ready) ? mem_wstrb : '0;

	ram #(.WORDS(RAM_WORDS), .INIT_FILE("fw/test.hex")) ram0(
		.clk(clk),
		.addr(ram_addr),
		.we(ram_we),
		.wdata(mem_wdata),
		.rdata(ram_rdata)
	);

	always_comb begin
		mem_rdata = 32'h0;
		if (ram_sel)
			mem_rdata = ram_rdata;
	end

	generate if (MEM_LOG) 
		always @(posedge mem_valid) 
			if (mem_wstrb)
				$display("addr=%h wstrb=%b wdata=%b\n", mem_addr, mem_wstrb, mem_wdata);

	endgenerate

endmodule
