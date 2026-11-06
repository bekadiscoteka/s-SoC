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
		
		// Байт i занимает биты [8*i +: 8]; we[0] — младший байт (адрес 4k+0).
		for (int i = 0; i < 4; i++)
			if (we[i])
				mem[addr][8*i +: 8] <= wdata[8*i +: 8];
		
	end

endmodule
