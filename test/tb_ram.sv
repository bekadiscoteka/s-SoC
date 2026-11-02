`timescale 1ns/1ns

module ram_tb;

	logic	tb_rx, tb_tx,
		clk=0, resetn=1;	

	logic [5:0] leds;

	picosoc #(.MEM_LOG(1)) soc(
		.clk(clk),
		.resetn(resetn),
		.leds(leds),
		.uart_rx(tb_tx),
		.uart_tx(tb_rx)
	);


	initial forever #5 clk <= ~clk;	

	initial begin
		$dumpfile("sim.vcd");
		$dumpvars(0, ram_tb);

		resetn = 0;
		#3us;
		resetn = 1;

		#100us;
		$finish;
	end
	
	initial wait(soc.cpu.trap)
			$fatal(1, "CPU is in trap!");
	
	


endmodule
