`timescale 1ns/1ps

// Проверка crt0 загрузчика вместе с fw/crt0_test.c: globals после включения
// и после сброса посреди работы. Протокол описан в fw/crt0_test.c.

`ifndef BOOTFILE
`define BOOTFILE "fw/crt0_test.hex"
`endif

module tb_crt0;

	localparam int  BAUD   = 9600;
	localparam real BIT_NS = 1.0e9 / BAUD;
	string EXP = "1010";   // "10" до сброса, "10" после (переменная: iverilog не индексирует localparam string)

	logic clk = 0, reset = 0, uart_rx = 1;
	logic uart_tx;
	logic [5:0] leds_n;

	picosoc #( .BAUD(BAUD), .BOOTFILE(`BOOTFILE) ) soc(.*);

	initial forever #18.5 clk <= ~clk;   // 27 МГц

	int errors = 0;
	int nrx = 0;
	logic [7:0] rx [0:15];

	/* UART-приёмник: складывает байты в rx[] */
	initial forever begin : tx_monitor
		logic [7:0] got;

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

		$display("[%0t] TX: '%c'", $time, got);
		if (nrx < 16)
			rx[nrx] = got;
		nrx++;
	end

	/* Сценарий */
	initial begin
		$dumpfile("crt0.vcd");
		$dumpvars(0, tb_crt0);

		// Первый запуск: ждём оба байта. После второго globals уже испорчены,
		// а программа крутится в for(;;).
		wait (nrx == 2);

		// Сброс посреди работы. reset меняется на negedge, чтобы не было
		// гонки с posedge, на котором sys_reset его читает.
		@(negedge clk) reset = 1;
		repeat (10) @(negedge clk);
		reset = 0;
		$display("[%0t] reset отпущен", $time);

		wait (nrx == 4);

		// Лишних байтов быть не должно.
		#(BIT_NS * 20);
		finish_test();
	end

	/* Ранний конец: trap (main не должна возвращаться) или таймаут */
	initial begin
		@(posedge soc.trap);
		$display("[%0t] Неожиданный trap", $time);
		errors++;
		finish_test();
	end

	initial begin
		#20ms;
		$display("[%0t] Таймаут: принято %0d байт из %0d", $time, nrx, EXP.len());
		errors++;
		finish_test();
	end

	task automatic finish_test();
		if (nrx != EXP.len()) begin
			$display("Принято %0d байт, ждали %0d", nrx, EXP.len());
			errors++;
		end
		for (int i = 0; i < EXP.len() && i < nrx; i++)
			if (rx[i] !== EXP[i]) begin
				errors++;
				case (i)
					0: $display("Байт 0: globals неверны после включения (crt0 не скопировал .data или не обнулил .bss)");
					1: $display("Байт 1: проверка не заметила порчу globals (тест слепой)");
					2: $display("Байт 2: globals не восстановились после сброса");
					3: $display("Байт 3: проверка после сброса не заметила порчу globals");
				endcase
			end
		if (errors == 0)
			$display("PASS");
		else
			$display("FAIL, errors: %0d", errors);
		$finish;
	endtask

endmodule
