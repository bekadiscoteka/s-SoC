// Синхронная RAM с побайтовой записью: данные чтения появляются на следующем такте.
module ram #(
	parameter int WORDS     = 2048,
	parameter     INIT_FILE = "fw/test.hex"
) (
	input  logic                     clk,

	input  logic [$clog2(WORDS)-1:0] addr,   // индекс слова, а не байтовый адрес
	input  logic [3:0]               we,     // разрешение записи на каждый байт
	input  logic [31:0]              wdata,
	output logic [31:0]              rdata
);

	logic [31:0] mem [0:WORDS-1];

	/* logic [3:0][7:0] mem [0:WORDS-1]; */

	initial $readmemh(INIT_FILE, mem);

	always_ff @(posedge clk) begin
		
		rdata <= mem[addr];
		
		if (we[3])
			mem[addr][31-:8] <= wdata[31-:8];
		if (we[2])
			mem[addr][31-8-:8] <= wdata[31-8-:8];
		if (we[1])
			mem[addr][31-16-:8] <= wdata[31-16-:8];
		if (we[0])
			mem[addr][31-24-:8] <= wdata[31-24-:8];
		
	end

endmodule
