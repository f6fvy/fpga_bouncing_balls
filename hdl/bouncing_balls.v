// Bouncing balls

// Laurent Haas - F6FVY
// Sept 2018

// Up to 4 (square) balls bouncing on the screen.
// Free space is constantly contracting and expanding.

// Requirement : VGA 640 x 480 / 50 Hz screen

// FPGA Hardware used : Low cost Chinese board A-C4E6E10

module bouncing_balls(
	input			clk,
	
	output		vga_red, vga_green, vga_blue,
	output		vga_hsync, vga_vsync
);

	// Reset pulse generation

	reg			counter_reset = 0;
	reg			reset = 0;

	always @ (posedge clk) begin
		if (~counter_reset) begin
			counter_reset <= 1'b1;
			reset <= 1'b1;
		end
		else
			reset <= 0;
	end

	// Wires between instances

	wire	[2:0] pixel_rgb_tmp;
	wire			active_tmp;
	wire			ftick_tmp;
	wire	[9:0]	xpos_tmp;
	wire	[9:0]	ypos_tmp;
	wire			ptick_tmp;
	
	// VGA generator instantation

	vga vga_inst(
		.clk(clk),
		.reset(reset),
		.pixel_rgb(pixel_rgb_tmp),

		.hsync(vga_hsync),
		.vsync(vga_vsync),
		.red(vga_red),
		.green(vga_green),
		.blue(vga_blue),
		.active(active_tmp),
		.ptick(ptick_tmp),
		.xpos(xpos_tmp),
		.ypos(ypos_tmp),
		.ftick(ftick_tmp)
	);

	// Gameplay instantation

	gameplay gameplay_inst(
		.tick(ftick_tmp),
		.reset(reset),
		.xpos(xpos_tmp),
		.ypos(ypos_tmp),
		.active(active_tmp),

		.pixel_rgb(pixel_rgb_tmp)
	);

endmodule
