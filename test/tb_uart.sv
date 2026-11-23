`timescale 1ns/1ps

// Testbench для rtl/uart.sv отдельно от SoC.
// Запуск: iverilog -g2012 -s uart_tb -o uart.vvp test/tb_uart.sv rtl/uart.sv && vvp uart.vvp
//
// Идея: testbench знает только протокол 8N1 и время бита в наносекундах.
// Он не использует DIV из модуля, поэтому ошибка в делителе будет видна.

module uart_tb;

	localparam int  CLK_HZ = 27_000_000;
	localparam int  BAUD   = 115_200;
	localparam real CLK_NS = 1.0e9 / CLK_HZ;   // 37,037 нс
	localparam real BIT_NS = 1.0e9 / BAUD;     // 8680,6 нс

	logic       clk = 0, resetn = 0;
	logic [7:0] tx_data = 0;
	logic       tx_start = 0;
	logic       tx_busy, tx;
	logic       rx = 1;                       // линия в покое: 1
	logic [7:0] rx_data;
	logic       rx_valid;
	logic       rx_overrun;
	logic       rx_overrun_clr = 0;
	logic       rx_ack = 0;

	int errors = 0;
	uart #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) dut (.*);

	always #(CLK_NS / 2) clk = ~clk;

	// Стимулы меняем по спаду clk: DUT защёлкивает их по фронту,
	// и порядок событий внутри одного фронта не играет роли.

	// ---------------- TX: отправка и декодер линии ----------------

	task automatic send_byte(input logic [7:0] b, input logic wait_tx_busy = 1'b1);
		@(negedge clk);
		if (wait_tx_busy) 
			while (tx_busy) @(negedge clk);
		tx_data  = b;
		tx_start = 1;
		@(negedge clk);
		tx_start = 0;
	endtask

	// Что ожидаем увидеть на tx, по порядку.
	logic [7:0] tx_expect [$];
	int         tx_seen = 0;

	// Монитор: ловит спад, встаёт в середину старт-бита и шагает по битам.
	initial forever begin : tx_monitor
		logic [7:0] got;
		@(negedge tx);
		#(BIT_NS / 2);
		if (tx !== 1'b0) begin
			$display("[%0t] TX: старт-бит не держится до середины", $time);
			errors++;
		end
		for (int i = 0; i < 8; i++) begin
			#(BIT_NS);
			got[i] = tx;
		end
		#(BIT_NS);
		if (tx !== 1'b1) begin
			$display("[%0t] TX: нет стоп-бита", $time);
			errors++;
		end

		if (tx_expect.size() == 0) begin
			$display("[%0t] TX: лишний байт %02h", $time, got);
			errors++;
		end else begin
			logic [7:0] exp;
			exp = tx_expect.pop_front();
			if (got !== exp) begin
				$display("[%0t] TX: ждали %02h, пришло %02h", $time, exp, got);
				errors++;
			end else
				$display("[%0t] TX: %02h '%c'", $time, got, got);
		end
		tx_seen++;
	end

	// ---------------- RX: драйвер линии и чтение ----------------

	// bit_ns отдельным аргументом: можно проверить чужой baud (например, +2 %).
	task automatic drive_byte(input logic [7:0] b, input real bit_ns);
		rx = 0;
		#(bit_ns);
		for (int i = 0; i < 8; i++) begin
			rx = b[i];
			#(bit_ns);
		end
		rx = 1;
		#(bit_ns);
	endtask

	// Дождаться байта, сверить данные и флаг переполнения,
	// подтвердить чтение импульсом rx_ack.
	task automatic read_byte(input logic [7:0] exp, input logic exp_overrun = 1'b0);
		@(negedge clk);
		while (!rx_valid) @(negedge clk);
		if (rx_data !== exp) begin
			$display("[%0t] RX: ждали %02h, пришло %02h", $time, exp, rx_data);
			errors++;
		end else
			$display("[%0t] RX: %02h '%c'", $time, rx_data, rx_data);
		if (rx_overrun !== exp_overrun) begin
			$display("[%0t] RX: rx_overrun = %b, ждали %b", $time, rx_overrun, exp_overrun);
			errors++;
		end
		rx_ack = 1;
		@(negedge clk);
		rx_ack = 0;
		if (rx_valid) begin
			$display("[%0t] RX: rx_valid не снялся после rx_ack", $time);
			errors++;
		end
		if (rx_overrun !== exp_overrun) begin
			$display("[%0t] RX: rx_ack изменил rx_overrun", $time);
			errors++;
		end
	endtask

	task automatic check_overrun(input logic exp, input string what);
		if (rx_overrun !== exp) begin
			$display("[%0t] RX: %s: rx_overrun = %b, ждали %b", $time, what, rx_overrun, exp);
			errors++;
		end
	endtask

	task automatic clear_overrun();
		@(negedge clk);
		rx_overrun_clr = 1;
		@(negedge clk);
		rx_overrun_clr = 0;
		check_overrun(1'b0, "после явного сброса");
	endtask

	// ---------------- Сценарий ----------------

	string MSG = "Hello";   // localparam string роняет iverilog 12


	initial begin
		$dumpfile("uart.vcd");
		$dumpvars(0, uart_tb);

		repeat (5) @(negedge clk);
		resetn = 1;
		repeat (5) @(negedge clk);

		if (tx !== 1'b1) begin
			$display("TX: после сброса линия не в 1");
			errors++;
		end

		// 1. TX: «Hello» подряд, send_byte сам ждёт !tx_busy.
		$display("--- TX: Hello ---");
		for (int i = 0; i < MSG.len(); i++) begin
			tx_expect.push_back(MSG[i]);
			send_byte(MSG[i]);
		end
		while (tx_expect.size() != 0) @(negedge clk);   // wait() на .size() в iverilog не просыпается
		#(BIT_NS);

		// 2. RX: «Hello» без пауз между кадрами, как при вставке текста.
		//    Драйвер и читатель работают параллельно.
		$display("--- RX: Hello подряд ---");
		fork
			for (int i = 0; i < MSG.len(); i++) drive_byte(MSG[i], BIT_NS);
			for (int i = 0; i < MSG.len(); i++) read_byte(MSG[i]);
		join

		// 3. RX: два байта без чтения. По задумке модуля старый заменяется новым,
		//    и это видно по rx_overrun. В сценарии 2 read_byte проверяет, что флага нет.
		$display("--- RX: переполнение ---");
		drive_byte(8'hA5, BIT_NS);
		drive_byte(8'h3C, BIT_NS);
		read_byte(8'h3C, 1'b1);

		// Чтение флаг не снимает: следующий байт читается ещё с ним.
		drive_byte(8'h5A, BIT_NS);
		read_byte(8'h5A, 1'b1);
		clear_overrun();

		// 3а. Байт теряется между чтением статуса и чтением данных.
		$display("--- RX: потеря между статусом и данными ---");
		drive_byte(8'h11, BIT_NS);
		@(negedge clk);
		check_overrun(1'b0, "статус до потери");
		drive_byte(8'h22, BIT_NS);
		read_byte(8'h22, 1'b1);
		clear_overrun();

		// 3б. Сброс в том же такте, что и новая потеря: потеря важнее.
		//     clr держим всё время, поэтому флаг обязан появиться ровно на такт.
		$display("--- RX: сброс одновременно с потерей ---");
		drive_byte(8'h33, BIT_NS);
		begin: clear_vs_set
			logic seen;
			logic done;
			seen = 0;
			done = 0;
			@(negedge clk);
			rx_overrun_clr = 1;
			fork
				begin drive_byte(8'h44, BIT_NS); done = 1; end
				while (!done) begin @(negedge clk); if (rx_overrun) seen = 1; end
			join
			rx_overrun_clr = 0;
			if (!seen) begin
				$display("[%0t] RX: сброс затёр одновременную потерю", $time);
				errors++;
			end
		end
		read_byte(8'h44);

		// TODO 4. TX: tx_start, пока tx_busy, должен игнорироваться.
		//         Что именно проверить: какой байт и сколько байт увидит монитор?
	
		$display("-- TX: tx_busy ignore ----");

		begin: ignore
			byte value = "A";
			byte value_ignored = "B";

			tx_expect.push_back(value);
			send_byte(value);		
			send_byte(value_ignored, 0);
			wait(!tx_busy);
		end

		
		#(BIT_NS);
		if (errors == 0) $display("PASS");
		else             $fatal(1, "FAIL: %0d ошибок", errors);
		$finish;
	end

	// Сторож: если что-то зависло, не ждать вечно.
	initial begin
		#20ms;
		$fatal(1, "TIMEOUT");
	end

endmodule
