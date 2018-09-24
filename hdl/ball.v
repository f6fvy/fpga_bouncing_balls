module ball(
	input			reset,
	input			tick,
	input	[1:0]	speed,		// Expressed in frame ticks (the lower, the faster)
	input			dir_x,		// 0 = Left, 1 = Right
	input			dir_y,		// 0 = Up, 1 = Down
	input			run,
	
	output reg	[7:0]	x,		// Current X in 4-pixel units : 0 to 159
	output reg	[7:0]	y		// Current Y in 4-pixel units : 0 to 119
);

	reg	[1:0] count;	// Frame cunter (movement speed)

	always @ (posedge tick or posedge reset) begin
		if (reset) begin
			count <= 2'd0;
			x <= 80;	// Center
			y <= 60;	// Center
		end
		else begin
			if (count >= speed) begin	// Time to move the ball
				count <= 2'd0;
				if (run) begin	// Move ball (constant velocity : 1 unit in both directions)
					if (dir_x)
						x <= x + 8'd1;	// Right
					else
						x <= x - 8'd1;	// Left
						
					if (dir_y)
						y <= y + 8'd1;	// Down
					else
						y <= y - 8'd1;	// Up				
				end
			end
			else
				count <= count + 2'd1;
		end
	end

endmodule