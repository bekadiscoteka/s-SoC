
module picosoc #(
	parameter int BAUD = 9600
) (
	output logic [5:0] leds, 

	output logic uart_tx,
	
	input clk, resetn, uart_rx

); 

	

	/*======== PicoRV32 cpu ============== */

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

	/* =========== MMIO decoder ============== */

	logic ram_sel;
	logic led_sel;
	logic uart_sel;
	wire uart_reg_sel = mem_addr[2];

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

	/* ======== RAM module ============= */

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

	/* ======== LED register ======== */

	always_ff @(posedge clk) begin
		if (!resetn) 
			leds <= '0;
		else if ( mem_wstrb[0] && led_sel )
			leds <= mem_wdata;
	end

	/* ======== UART module ======== */

	logic       uart_tx_start;   
        logic       uart_tx_busy;

	logic [7:0] uart_status;
	logic [7:0] rx_data;
	
        logic       uart_rx_valid;
        logic       uart_rx_ack;	

	assign uart_status = { 6'b0, uart_tx_busy, uart_rx_valid };

        uart #(
                .CLK_HZ(27_000_000),
                .BAUD  (BAUD)
        ) uart0 (
                .clk     (clk),
                .resetn  (resetn),

                .tx_data (mem_wdata[7:0]),
                .tx_start(uart_tx_start),
                .tx_busy (uart_tx_busy),
                .tx      (uart_tx),    

                .rx      (uart_rx),   
                .rx_data (rx_data),
                .rx_valid(uart_rx_valid),
                .rx_ack  (uart_rx_ack)
        );

	/*
		it is CPU's responsibility to check uart_status, 
		otherwise uart_tx data will be ignored
	*/

	assign uart_tx_start	=  mem_wstrb[0] && uart_sel && !uart_reg_sel && !mem_ready;	
	assign uart_rx_ack	= !mem_wstrb[0] && uart_sel && !uart_reg_sel &&  mem_ready;


	/* ======= mem_rdata bus controller ========= */

	always_comb begin
		mem_rdata = 32'h0;
		if (ram_sel)
			mem_rdata = ram_rdata;
		else if (led_sel)
			mem_rdata = { 26'd0, leds };
		else if (uart_sel) 
			if (uart_reg_sel) 
				mem_rdata = { 24'd0, uart_status };
			else 
				mem_rdata = { 24'd0, rx_data };
	end

	/* ======== test log ==========*/


endmodule
