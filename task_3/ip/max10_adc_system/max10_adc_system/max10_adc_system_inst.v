	max10_adc_system u0 (
		.adc_command_valid           (<connected-to-adc_command_valid>),           //    adc_command.valid
		.adc_command_channel         (<connected-to-adc_command_channel>),         //               .channel
		.adc_command_startofpacket   (<connected-to-adc_command_startofpacket>),   //               .startofpacket
		.adc_command_endofpacket     (<connected-to-adc_command_endofpacket>),     //               .endofpacket
		.adc_command_ready           (<connected-to-adc_command_ready>),           //               .ready
		.adc_pll_clock_clk           (<connected-to-adc_pll_clock_clk>),           //  adc_pll_clock.clk
		.adc_pll_locked_export       (<connected-to-adc_pll_locked_export>),       // adc_pll_locked.export
		.adc_response_valid          (<connected-to-adc_response_valid>),          //   adc_response.valid
		.adc_response_startofpacket  (<connected-to-adc_response_startofpacket>),  //               .startofpacket
		.adc_response_endofpacket    (<connected-to-adc_response_endofpacket>),    //               .endofpacket
		.adc_response_empty          (<connected-to-adc_response_empty>),          //               .empty
		.adc_response_channel        (<connected-to-adc_response_channel>),        //               .channel
		.adc_response_data           (<connected-to-adc_response_data>),           //               .data
		.clk_clk                     (<connected-to-clk_clk>),                     //            clk.clk
		.reset_reset_n               (<connected-to-reset_reset_n>),               //          reset.reset_n
		.adc_command2_valid          (<connected-to-adc_command2_valid>),          //   adc_command2.valid
		.adc_command2_channel        (<connected-to-adc_command2_channel>),        //               .channel
		.adc_command2_startofpacket  (<connected-to-adc_command2_startofpacket>),  //               .startofpacket
		.adc_command2_endofpacket    (<connected-to-adc_command2_endofpacket>),    //               .endofpacket
		.adc_command2_ready          (<connected-to-adc_command2_ready>),          //               .ready
		.adc_response2_valid         (<connected-to-adc_response2_valid>),         //  adc_response2.valid
		.adc_response2_channel       (<connected-to-adc_response2_channel>),       //               .channel
		.adc_response2_data          (<connected-to-adc_response2_data>),          //               .data
		.adc_response2_startofpacket (<connected-to-adc_response2_startofpacket>), //               .startofpacket
		.adc_response2_endofpacket   (<connected-to-adc_response2_endofpacket>)    //               .endofpacket
	);

