`timescale 10 ns / 100 ps

module boucing_balls_tb();
	reg	clk;						// 50 MHz 20 ns

	wire	red, green, blue;		// VGA outputs
	wire	hsync, vsync;

	bouncing_balls dut(
	.clk(clk),
	
	.vga_red(red),
	.vga_green(green),
	.vga_blue(blue),
	.vga_hsync(hsync),
	.vga_vsync(vsync)
	);
	
	initial begin
		clk = 1'b0;
		forever begin
			#1 clk = ~clk;		// 20 ns period
		end
	end

endmodule