`timescale 1ns/1ps

`ifndef TX_EXP 
`define TX_EXP "Hello"
`endif

module tb_soc;
	parameter LOG = 1;

	localparam int BAUD = 9600;
	localparam real BIT_NS = 1.0e9 / BAUD;     // 8680,6 нс

	int errors = 0;

	logic	uart_rx, uart_tx,
		clk=0, resetn=1;	

	logic [5:0] leds;

	picosoc #( .BAUD(BAUD) ) soc(.*);



	initial forever #18.5 clk <= ~clk;	

	initial begin
		//$dumpfile("sim.vcd");
		//$dumpvars(0, tb_soc);

		resetn = 0;
		#3us;
		resetn = 1;

		#30ms;

		// Программа должна закончиться ebreak; дошли сюда, значит CPU завис.
		$display("[%0t] Таймаут: trap так и не сработал", $time);
		errors++;
		finish_test();
	end

	initial @(posedge soc.trap) begin
		$info("Trap activated");
		finish_test();
	end
	
	/* uart TX verifier */	

	string tx_exp = `TX_EXP;
	int tx_expi = 0;

	// Единый итог для любого конца теста: trap или таймаут.
	// Ранний trap без ошибок не должен давать PASS, поэтому сверяем число байтов.
	task automatic finish_test();
		if (tx_expi != tx_exp.len()) begin
			$display("TX: принято %0d байт из %0d", tx_expi, tx_exp.len());
			errors++;
		end
		if (errors == 0)
			$display("PASS");
		else
			$display("FAIL, errors: %0d", errors);
		$finish;
	endtask

	initial forever begin : tx_monitor

		logic [7:0] got;
		logic [7:0] exp;

		@(negedge uart_tx);
		#(BIT_NS / 2);
		if (uart_tx !== 1'b0) begin
			$display("[%0t] TX: старт-бит не держится до середины", $time);
			errors++;
		end
		for (int i = 0; i < 8; i++) begin
			#(BIT_NS);
			got[i] = uart_tx;
		end
		#(BIT_NS);
		if (uart_tx !== 1'b1) begin
			$display("[%0t] TX: нет стоп-бита", $time);
			errors++;
		end


		exp = tx_exp[tx_expi]; 
		tx_expi++;

		if (got !== exp) begin
			$display("[%0t] TX: ждали %02h, пришло %02h", $time, exp, got);
			errors++;
		end else
			$display("[%0t] TX: %02h '%c'", $time, got, got);
	end

	initial begin
		@(posedge resetn);

		errors++;  /*in advance if there won't be any write for LED*/
		@(leds);
		errors--;  
		
		if (leds !== 6'b11_0000) 
			errors++;

		$info("LED: expected: %b, got: %b", 6'b11_0000, leds);
	end
	
	
endmodule
