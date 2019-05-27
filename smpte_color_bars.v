`include "hvsync_generator.v"

module smpte_color_bars(
  input clk,
  output hsync_out,
  output vsync_out,
  output [2:0] rgb,
  output reg frame_led,
  output cbl_gnd1,
  output cbl_gnd2,
  output cbl_gnd3
);

  // 12MHZ iCEstick FPGA clock is too fast for signal generation, need to divide
  // by 2
  reg clk2; // 6MHz clock
  always @(posedge clk) begin
    clk2 <= ~clk2;
  end

  reg [4:0] frame_cnt; // Frame counter to drive LED
  
  always @(posedge vsync_out) begin
    if (frame_cnt == 30) begin // Toggle LED every 30 frames = 1Hz at 60 frames per second
      frame_led <= ~frame_led;
      frame_cnt <= 0;
    end else begin
      frame_cnt <= frame_cnt + 1;
    end
  end
  
  wire display_on; // Indicates when we are in the visible portion of the display
  wire [8:0] hpos; // Horizontal position of the electron beam
  wire [8:0] vpos; // Vertical position of the electron beam
  wire r_on; // signal to drive red gun
  wire g_on; // signal to drive green gun
  wire b_on; // signal to drive blue gun
  wire reset;

  assign reset = 0;
  assign cbl_gnd1 = 0; // Ground unused wires in cable
  assign cbl_gnd2 = 0; // Ground unused wires in cable
  assign cbl_gnd3 = 0; // Ground unused wires in cable
  
  // Need to change default hvsync_generator scan line clock counts for clk2
  hvsync_generator #(
    .H_DISPLAY(256), // Horizontal display width
    .H_BACK(60), // Horizontal back porch
    .H_FRONT(40), // Horizontal front porch
    .H_SYNC(25) // Horizontal sync width
  )
  hvsync_gen (
    .clk(clk2), // Use divided clock
    .reset(reset),
    .hsync(hsync_out),
    .vsync(vsync_out),
    .display_on(display_on),
    .hpos(hpos),
    .vpos(vpos)
  );

  // For SMPTE color bars, divide the visible screen into 7 vertical bars
  // White, yellow, cyan, green, magenta, red, blue
  // Table below shows when red, green, and blue guns should be on (1) or off (0)
  //
  // This simple one-bit setup for RGB output can be translated to 75% luminosity
  // in hardware, which is a typical level for these color bars
  //
  // Bar:   0 1 2 3 4 5 6
  //
  // Red:   1 1 0 0 1 1 0
  // Green: 1 1 1 1 0 0 0
  // Blue:  1 0 1 0 1 0 1
  //
  // RGB signals can be controlled by three levels of divided clocks  
  // Switch the blue gun every 32 clocks. This makes it easy to pick off
  // bits of hpos to determine the r_on, g_on, and b_on signals.
  
  assign b_on = ~hpos[5] && display_on;
  assign r_on = ~hpos[6] && display_on;
  assign g_on = ~hpos[7] && display_on;
  assign rgb = {r_on, g_on, b_on};

endmodule
