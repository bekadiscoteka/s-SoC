// UART 8N1: передатчик и приёмник. К шине не привязан, подключается в soc.sv.
module uart #(
	parameter int CLK_HZ = 27_000_000,
	parameter int BAUD   = 115_200
) (
	input  logic       clk,
	input  logic       resetn,

	// Передача
	input  logic [7:0] tx_data,
	input  logic       tx_start,   // импульс на один такт; пока tx_busy, игнорируется
	output logic       tx_busy,
	output logic       tx,

	// Приём
	input  logic       rx,
	output logic [7:0] rx_data,
	output logic       rx_valid,   // держится, пока не придёт rx_ack
	input  logic       rx_ack      // импульс на один такт: байт прочитан
);

	// Тактов на бит, с округлением: 27 МГц / 115200 = 234,375 -> 234, ошибка 0,16 %.
	localparam int DIV = (CLK_HZ + BAUD / 2) / BAUD;
	localparam int CW  = $clog2(DIV);

	localparam logic [CW-1:0] BIT_LAST  = CW'(DIV - 1);
	localparam logic [CW-1:0] HALF_LAST = CW'(DIV / 2 - 1);

	// ================= TX =================
	// Кадр {стоп, данные, старт} уходит младшим битом вперёд.
	// Сдвиг заполняет регистр единицами, поэтому в покое линия остаётся в 1.

	logic [9:0]    tx_shift;
	logic [3:0]    tx_left;    // сколько битов кадра ещё не отправлено
	logic [CW-1:0] tx_cnt;

	assign tx      = tx_shift[0];
	assign tx_busy = (tx_left != 0);

	always_ff @(posedge clk) begin
		if (!resetn) begin
			tx_shift <= '1;
			tx_left  <= '0;
			tx_cnt   <= '0;
		end else if (!tx_busy) begin
			if (tx_start) begin
				tx_shift <= {1'b1, tx_data, 1'b0};
				tx_left  <= 4'd10;
				tx_cnt   <= BIT_LAST;
			end
		end else if (tx_cnt != 0) begin
			tx_cnt <= tx_cnt - 1'b1;
		end else begin
			tx_shift <= {1'b1, tx_shift[9:1]};
			tx_left  <= tx_left - 1'b1;
			tx_cnt   <= BIT_LAST;
		end
	end

	// ================= RX =================
	// Вход асинхронный, поэтому сначала идёт двойной синхронизатор.
	// Старт ловится по спаду 1 -> 0, выборка берётся в середине каждого бита.
	// Именно спад, а не уровень: после битого кадра линия может ещё держать 0.

	logic rx_meta = 1'b1;
	logic rx_s    = 1'b1;
	logic rx_prev = 1'b1;

	always_ff @(posedge clk) begin
		rx_meta <= rx;
		rx_s    <= rx_meta;
		rx_prev <= rx_s;
	end

	typedef enum logic [1:0] { RX_IDLE, RX_START, RX_DATA, RX_STOP } rx_state_t;

	rx_state_t     rx_state;
	logic [CW-1:0] rx_cnt;
	logic [2:0]    rx_bit;
	logic [7:0]    rx_shift;

	always_ff @(posedge clk) begin
		if (!resetn) begin
			rx_state <= RX_IDLE;
			rx_cnt   <= '0;
			rx_bit   <= '0;
			rx_shift <= '0;
			rx_data  <= '0;
			rx_valid <= 1'b0;
		end else begin
			// Подтверждение чтения. Новый байт ниже в том же такте важнее.
			if (rx_ack)
				rx_valid <= 1'b0;

			unique case (rx_state)
				RX_IDLE:
					if (rx_prev && !rx_s) begin
						rx_state <= RX_START;
						rx_cnt   <= HALF_LAST;
					end

				RX_START:   // середина старт-бита: если линия снова 1, это была помеха
					if (rx_cnt != 0)
						rx_cnt <= rx_cnt - 1'b1;
					else if (rx_s)
						rx_state <= RX_IDLE;
					else begin
						rx_state <= RX_DATA;
						rx_cnt   <= BIT_LAST;
						rx_bit   <= '0;
					end

				RX_DATA:
					if (rx_cnt != 0)
						rx_cnt <= rx_cnt - 1'b1;
					else begin
						rx_shift <= {rx_s, rx_shift[7:1]};
						rx_cnt   <= BIT_LAST;
						if (rx_bit == 3'd7)
							rx_state <= RX_STOP;
						else
							rx_bit <= rx_bit + 1'b1;
					end

				RX_STOP:    // середина стоп-бита: 0 здесь значит битый кадр, байт отбрасывается
					if (rx_cnt != 0)
						rx_cnt <= rx_cnt - 1'b1;
					else begin
						rx_state <= RX_IDLE;
						if (rx_s) begin
							rx_data  <= rx_shift;   // непрочитанный старый байт заменяется
							rx_valid <= 1'b1;
						end
					end
			endcase
		end
	end

endmodule
