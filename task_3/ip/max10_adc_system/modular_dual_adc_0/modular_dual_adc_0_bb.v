
module modular_dual_adc_0 (
	clock_clk,
	reset_sink_reset_n,
	adc_pll_clock_clk,
	adc_pll_locked_export,
	command_valid,
	command_channel,
	command_startofpacket,
	command_endofpacket,
	command_ready,
	command_2_valid,
	command_2_channel,
	command_2_startofpacket,
	command_2_endofpacket,
	command_2_ready,
	response_valid,
	response_startofpacket,
	response_endofpacket,
	response_empty,
	response_channel,
	response_data,
	response_2_valid,
	response_2_channel,
	response_2_data,
	response_2_startofpacket,
	response_2_endofpacket);	

	input		clock_clk;
	input		reset_sink_reset_n;
	input		adc_pll_clock_clk;
	input		adc_pll_locked_export;
	input		command_valid;
	input	[4:0]	command_channel;
	input		command_startofpacket;
	input		command_endofpacket;
	output		command_ready;
	input		command_2_valid;
	input	[4:0]	command_2_channel;
	input		command_2_startofpacket;
	input		command_2_endofpacket;
	output		command_2_ready;
	output		response_valid;
	output		response_startofpacket;
	output		response_endofpacket;
	output	[0:0]	response_empty;
	output	[4:0]	response_channel;
	output	[11:0]	response_data;
	output		response_2_valid;
	output	[4:0]	response_2_channel;
	output	[11:0]	response_2_data;
	output		response_2_startofpacket;
	output		response_2_endofpacket;
endmodule
