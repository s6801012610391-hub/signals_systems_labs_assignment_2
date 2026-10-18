// Simulation/syntax stubs only. DO NOT add this file to Quartus synthesis.
module adc_pll(input inclk0, output c0, output locked);
assign c0 = inclk0;
assign locked = 1'b1;
endmodule

module max10_adc_system(
    input clk_clk,
    input reset_reset_n,
    input adc_pll_clock_clk,
    input adc_pll_locked_export,
    input adc_command_valid,
    input [4:0] adc_command_channel,
    input adc_command_startofpacket,
    input adc_command_endofpacket,
    output adc_command_ready,
    output adc_response_valid,
    output [4:0] adc_response_channel,
    output [11:0] adc_response_data,
    output adc_response_startofpacket,
    output adc_response_endofpacket
);
assign adc_command_ready = 1'b1;
assign adc_response_valid = 1'b0;
assign adc_response_channel = 5'd0;
assign adc_response_data = 12'd0;
assign adc_response_startofpacket = 1'b0;
assign adc_response_endofpacket = 1'b0;
endmodule
