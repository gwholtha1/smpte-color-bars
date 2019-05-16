`include "hvsync_generator.v"

module smpte_color_bars(
  input clk,
  input reset,
  output hsync,
  output vsync,
  output [2:0] rgb
);

wire display_on; // Indicates when we are in the visible portion of the display
wire [8:0] hpos; // Horizontal position of the electron beam
wire [8:0] vpos; // Vertical position of the electron beam

reg [5:0] b_clk; // Clock signal to determine blue gun timing
wire r_on; // signal to drive red gun
wire g_on; // signal to drive green gun
wire b_on; // signal to drive blue gun

hvsync_generator hvsync_gen (
  .clk(clk),
  .reset(reset),
  .hsync(hsync),
  .vsync(vsync),
  .display_on(display_on),
  .hpos(hpos),
  .vpos(vpos)
);

// For SMPTE color bars, divide the visible screen into 7 vertical bars
// White, yellow, cyan, green, magenta, red, blue
// Table below shows when red, green, and blue guns should be on (1) or off (0)
//
// This simple one-bit setup can be translated to 75% luminosity in hardware,
// which is a typical level for these color bars
//
// Bar:   0 1 2 3 4 5 6
//
// Red:   1 1 0 0 1 1 0
// Green: 1 1 1 1 0 0 0
// Blue:  1 0 1 0 1 0 1
//
// RGB signals can be controlled by three levels of divided clocks
  
// Consider switching the blue gun every 32 clocks. This makes it easy to pick off
// bits of hpos to determine the r_on, g_on, and b_on signals.
  
  assign b_on = ~hpos[5] && display_on;
  assign r_on = ~hpos[6] && display_on;
  assign g_on = ~hpos[7] && display_on;
  
assign rgb = {r_on, g_on, b_on};
