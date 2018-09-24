module gameplay(
	input					tick,
	input					reset,
	input		[9:0]		xpos,				// Current pixel xpos
	input		[9:0]		ypos,				// Current pixel ypos
	input					active,
	
	output	[2:0]		pixel_rgb		// Current pixel rgb output
);

	localparam
	HPIXELS_4		= 8'd160,			// Screen width in 4-pixel units
	VPIXELS_4		= 8'd120,			// Screen height in 4-pixel units

	COLOR_BLACK		= 3'b000,

	COLOR_RED		= 3'b100,
	COLOR_GREEN		= 3'b010,
	COLOR_BLUE		= 3'b001,
	
	COLOR_CYAN		= 3'b110,
	COLOR_YELLOW	= 3'b011,
	COLOR_MAGENTA	= 3'b101,
	
	COLOR_WHITE		= 3'b111;

	// Countdown startup counter
	// To get the monitor synchronised before starting
	
	reg	[7:0]	startup_counter = 255;	// In frames (1 frame = 16.6 ms)
	
	wire	game_run;

	assign game_run = (startup_counter <= 0);

	always @ (posedge tick) begin
		if (~game_run)
			startup_counter <= startup_counter - 8'd1;
	end
	
	// Current pixel position expressed in 4 x 4 squares

	wire	[7:0] xpos_4;
	wire	[7:0] ypos_4;

	assign xpos_4 = xpos[9:2];
	assign ypos_4 = ypos[9:2];
	
	// Walls registers

	localparam
	WALL_THICKNESS_4_MIN	= 6'd1,		// In 4-pixel units 
	WALL_THICKNESS_4_MAX	= 6'd31;		// In 4-pixel units

	reg	[5:0] wall_thickness_4;		// Current wall thickness
	reg			wall_thickness_dir;	// 0 increase / 1 decrease
	reg	[4:0]	wall_counter;			// Inc / dec every 32 frames (around 500 ms)

	// Ball registers

	localparam
	BALLS = 4;		// 1 - 4 ball(s)

	wire	[7:0] ball_x[0:BALLS - 1], ball_y[0:BALLS - 1];
	reg	[1:0] ball_speed[0:BALLS - 1];			// 0 to 3 (refresh every 16 ms to 64 ms)
	reg			ball_x_dir[0:BALLS - 1];			// 0 = Left, 1 = Right
	reg			ball_y_dir[0:BALLS - 1];         // 0 = Up, 1 = Down
	reg			ball_run[0:BALLS - 1];				// 0 = No mvt, 1 : mvt

	// Balls

	genvar i;
	generate
		for (i = 0; i < BALLS; i = i + 1)
			begin: balls_generation
			
				// Instantation of BALLS balls

				ball ball_inst(
					.reset(reset),
					.tick(tick),
					.speed(ball_speed[i]),
					.dir_x(ball_x_dir[i]),
					.dir_y(ball_y_dir[i]),
					.run(ball_run[i]),

					.x(ball_x[i]),
					.y(ball_y[i])
				);
				
				// Balls init
				
				always @ (posedge reset) begin
					ball_speed[i] <= i[1:0];	// Depends on i to get different speed on start
				end
				
				always @(*) begin
					ball_run[i] <= game_run;	// Set instance run bit for every ball
				end

				// Check for ball - walls collisions

				always @ (posedge tick or posedge reset) begin
					if (reset) begin
						ball_y_dir[i] <= i[0];	// Depends on i to get different directions on start
						ball_x_dir[i] <= i[1];	// Depends on i to get different directions on start
					end
					else
					begin
						if (game_run) begin	// Check collisions only if the game is running	
							if ((ball_y[i] < wall_thickness_4 + 1) && (!ball_y_dir[i]))	// Banging on the top wall
									ball_y_dir[i] <= 1'b1;	// Go Down
									
							if ((ball_y[i] >= VPIXELS_4 - wall_thickness_4 - 1) && (ball_y_dir[i]))	// Banging on the bottom wall
									ball_y_dir[i] <= 1'b0;	// Go Up
									
							if ((ball_x[i] < wall_thickness_4 + 1) && (!ball_x_dir[i]))	// Banging on the left wall
									ball_x_dir[i] <= 1'b1;	// Go Right
									
							if ((ball_x[i] >= HPIXELS_4 - wall_thickness_4 - 1) && (ball_x_dir[i]))	// Banging on the right wall
									ball_x_dir[i] <= 1'b0; 	// Go Left
						end
					end
				end	
			end
	endgenerate
	
	// Walls expansion / contraction
	
	always @ (posedge tick or posedge reset) begin
		if (reset) begin
			wall_thickness_4 <= WALL_THICKNESS_4_MIN;
			wall_counter <= 5'd0;
			wall_thickness_dir <= 1'b0;
		end
		else if (game_run) begin
			wall_counter = wall_counter + 5'd1;
			if (wall_counter == 0) begin	// Every time the counter rolls, modify thickness
				if (wall_thickness_dir) begin	// Decrease thickness
					if (wall_thickness_4 > WALL_THICKNESS_4_MIN)
						wall_thickness_4 <= wall_thickness_4 - 6'd1;
					else begin
						wall_thickness_4 <= wall_thickness_4 + 6'd1;
						wall_thickness_dir <= 1'b0;	// Now increase
					end
				end
				else begin	// Increase thickness
					if (wall_thickness_4 < WALL_THICKNESS_4_MAX)
						wall_thickness_4 <= wall_thickness_4 + 6'd1;
					else begin
						wall_thickness_4 <= wall_thickness_4 - 6'd1;
						wall_thickness_dir <= 1'b1;	// Now decrease
					end
				end	
			end
		end
	end
	
	// Wall painting

	wire	wall_on;		// Set to 1 if the current pixel is a wall, 0 otherwise
	
	assign wall_on = (xpos_4 < wall_thickness_4) || (xpos_4 >= HPIXELS_4 - wall_thickness_4) || (ypos_4 < wall_thickness_4) || (ypos_4 >= VPIXELS_4 - wall_thickness_4);

	// Balls painting
	
	wire	[BALLS - 1:0]	ball_on;	// Set to 1 if the current pixel is a ball, 0 otherwise - 1 bit par ball
	
	generate
		for (i = 0; i < BALLS; i = i + 1) begin: balls_painting
			assign ball_on[i] = (xpos_4 == ball_x[i]) && (ypos_4 == ball_y[i]);
		end
	endgenerate

	// Colors assignment for the current pixel
	
	reg [2:0]	pixel_rgb_r;

	always @(*) begin
		if (active == 0)	// Not in the active area of the screen
			pixel_rgb_r = COLOR_BLACK;
		else begin
			if (ball_on & 4'b0001)
				pixel_rgb_r = COLOR_WHITE;	// White ball
			else if (ball_on & 4'b0010)
				pixel_rgb_r = COLOR_BLUE;	// Blue ball
			else if (ball_on & 4'b0100)
				pixel_rgb_r = COLOR_GREEN;	// Green ball
			else if (ball_on & 4'b1000)
				pixel_rgb_r = COLOR_RED;	// Red ball

			else if (wall_on)
				pixel_rgb_r = COLOR_CYAN;	// Cyan walls

			else
				pixel_rgb_r = COLOR_BLACK;	// Black background
		end
	end
	
	assign pixel_rgb = pixel_rgb_r;
	
endmodule
