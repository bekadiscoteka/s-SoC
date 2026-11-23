`timescale 1ns/1ps

// SoC целиком: загрузчик из fw/boot.hex принимает программу по UART и запускает её.
// Кадры протокола готовит tools/load.py --emit, так что тест проверяет вместе
// загрузчик и скрипт, которым грузится плата.
//
//   1. заголовок с испорченным CRC          -> 'N', снова '>'
//   2. верный заголовок, испорченные данные -> 'Y', 'N', снова '>'
//   3. верный заголовок и данные            -> 'Y', 'Y', программа печатает "OK!"
//
// Запуск: make -C test boot. Волны: vvp -n build/boot.vvp +vcd

module tb_boot;

	localparam real CLK_NS = 1.0e9 / 27_000_000;
	localparam real BIT_NS = 1.0e9 / 115_200;

	logic       clk = 0, reset = 0, uart_rx = 1;
	logic       uart_tx;
	logic [5:0] leds_n;

	picosoc #(.BAUD(115_200), .BOOTFILE(`BOOT_HEX)) soc (.*);

	always #(CLK_NS / 2) clk = ~clk;

	string phase = "старт";

	task automatic fail(input string msg);
		$fatal(1, "FAIL [%s]: %s", phase, msg);
	endtask

	initial begin
		#400ms;
		fail("таймаут");
	end

	// ---------------- кадры от load.py: заголовок 16 байт, затем тело ----------------

	logic [7:0] frames [$];
	int size;   // длина программы, из заголовка

	initial begin
		int fd, b;
		fd = $fopen(`FRAMES, "r");
		if (fd == 0) fail("нет файла кадров");
		while ($fscanf(fd, "%h", b) == 1)
			frames.push_back(8'(b));   // ширина как у очереди: иначе vvp 14 падает
		$fclose(fd);
		size = frames[10] + 256 * frames[11];
	end

	// ---------------- линия ПК -> плата ----------------

	task automatic send_byte(input logic [7:0] b);
		uart_rx = 0;
		#(BIT_NS);
		for (int i = 0; i < 8; i++) begin
			uart_rx = b[i];
			#(BIT_NS);
		end
		uart_rx = 1;
		#(BIT_NS);
	endtask

	// Байты frames[from .. from+n-1] подряд, без пауз; байт с индексом bad инвертируется.
	task automatic send_frames(input int from, input int n, input int bad = -1);
		logic [7:0] b;
		for (int i = from; i < from + n; i++) begin
			b = frames[i];   // через переменную: иначе vvp 14 падает на элементе очереди
			if (i == bad)
				b = ~b;
			send_byte(b);
		end
	endtask

	// ---------------- линия плата -> ПК ----------------

	logic [7:0] rx_q [$];

	initial forever begin : tx_monitor
		logic [7:0] b;
		@(negedge uart_tx);
		#(BIT_NS / 2);
		for (int i = 0; i < 8; i++) begin
			#(BIT_NS);
			b[i] = uart_tx;
		end
		#(BIT_NS);
		if (uart_tx !== 1'b1)
			fail("нет стоп-бита");
		$write("%c", b);
		rx_q.push_back(b);
	end

	task automatic next_byte(output logic [7:0] b);
		while (rx_q.size() == 0) @(posedge clk);   // wait() на .size() в iverilog не просыпается
		b = rx_q.pop_front();
	endtask

	task automatic wait_for(input logic [7:0] want);   // остальные байты пропускаются
		logic [7:0] b;
		do next_byte(b); while (b != want);
	endtask

	task automatic expect_reply(input logic [7:0] want);   // следующий 'Y' или 'N'
		logic [7:0] b;
		do next_byte(b); while (b != "Y" && b != "N");
		if (b != want)
			fail($sformatf("ждали '%c', пришло '%c'", want, b));
	endtask

	// ---------------- сценарий ----------------

	string app_out = "OK!";

	initial begin
		logic [7:0] b;

		if ($test$plusargs("vcd")) begin
			$dumpfile("boot.vcd");
			$dumpvars(0, tb_boot);
		end

		phase = "приглашение после сброса";
		wait_for(">");

		phase = "1: заголовок с плохим CRC";
		send_frames(0, 16, 15);
		expect_reply("N");
		wait_for(">");

		phase = "2: плохие данные";
		send_frames(0, 16);
		expect_reply("Y");
		send_frames(16, size + 4, 16 + size / 2);
		expect_reply("N");
		wait_for(">");

		phase = "3: загрузка";
		send_frames(0, 16);
		expect_reply("Y");
		send_frames(16, size + 4);
		expect_reply("Y");

		phase = "3: вывод программы";
		for (int i = 0; i < app_out.len(); i++) begin
			next_byte(b);
			if (b != app_out[i])
				fail($sformatf("ждали '%c', пришло '%c'", app_out[i], b));
		end

		phase = "итог";
		if (soc.uart_rx_overrun)
			fail("загрузчик не успевал читать байты (переполнение приёма)");

		$display("\nPASS");
		$finish;
	end

endmodule
