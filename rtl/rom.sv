
module rom #(
	parameter int WORDS     = 2048,
	parameter     BOOTFILE = "fw/test.hex"
) (
	input  logic                     clk,

	input  logic [$clog2(WORDS)-1:0] addr,   // индекс слова, а не байтовый адрес
	output logic [31:0]              rdata
);

	logic [31:0] mem [0:WORDS-1];

	/* logic [3:0][7:0] mem [0:WORDS-1]; */

	initial $readmemh(BOOTFILE, mem);

	always_ff @(posedge clk) 
		rdata <= mem[addr];

endmodule
