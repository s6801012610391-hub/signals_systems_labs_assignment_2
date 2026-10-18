
module max10_adc_system (
	adc_command_valid,
	adc_command_channel,
	adc_command_startofpacket,
	adc_command_endofpacket,
	adc_command_ready,
	adc_pll_clock_clk,
	adc_pll_locked_export,
	adc_response_valid,
	adc_response_startofpacket,
	adc_response_endofpacket,
	adc_response_empty,
	adc_response_channel,
	adc_response_data,
	clk_clk,
	reset_reset_n,
	adc_command2_valid,
	adc_command2_channel,
	adc_command2_startofpacket,
	adc_command2_endofpacket,
	adc_command2_ready,
	adc_response2_valid,
	adc_response2_channel,
	adc_response2_data,
	adc_response2_startofpacket,
	adc_response2_endofpacket);	

	input		adc_command_valid;
	input	[4:0]	adc_command_channel;
	input		adc_command_startofpacket;
	input		adc_command_endofpacket;
	output		adc_command_ready;
	input		adc_pll_clock_clk;
	input		adc_pll_locked_export;
	output		adc_response_valid;
	output		adc_response_startofpacket;
	output		adc_response_endofpacket;
	output	[0:0]	adc_response_empty;
	output	[4:0]	adc_response_channel;
	output	[11:0]	adc_response_data;
	input		clk_clk;
	input		reset_reset_n;
	input		adc_command2_valid;
	input	[4:0]	adc_command2_channel;
	input		adc_command2_startofpacket;
	input		adc_command2_endofpacket;
	output		adc_command2_ready;
	output		adc_response2_valid;
	output	[4:0]	adc_response2_channel;
	output	[11:0]	adc_response2_data;
	output		adc_response2_startofpacket;
	output		adc_response2_endofpacket;
endmodule
