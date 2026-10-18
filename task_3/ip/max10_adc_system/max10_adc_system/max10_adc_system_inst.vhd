	component max10_adc_system is
		port (
			adc_command_valid           : in  std_logic                     := 'X';             -- valid
			adc_command_channel         : in  std_logic_vector(4 downto 0)  := (others => 'X'); -- channel
			adc_command_startofpacket   : in  std_logic                     := 'X';             -- startofpacket
			adc_command_endofpacket     : in  std_logic                     := 'X';             -- endofpacket
			adc_command_ready           : out std_logic;                                        -- ready
			adc_pll_clock_clk           : in  std_logic                     := 'X';             -- clk
			adc_pll_locked_export       : in  std_logic                     := 'X';             -- export
			adc_response_valid          : out std_logic;                                        -- valid
			adc_response_startofpacket  : out std_logic;                                        -- startofpacket
			adc_response_endofpacket    : out std_logic;                                        -- endofpacket
			adc_response_empty          : out std_logic_vector(0 downto 0);                     -- empty
			adc_response_channel        : out std_logic_vector(4 downto 0);                     -- channel
			adc_response_data           : out std_logic_vector(11 downto 0);                    -- data
			clk_clk                     : in  std_logic                     := 'X';             -- clk
			reset_reset_n               : in  std_logic                     := 'X';             -- reset_n
			adc_command2_valid          : in  std_logic                     := 'X';             -- valid
			adc_command2_channel        : in  std_logic_vector(4 downto 0)  := (others => 'X'); -- channel
			adc_command2_startofpacket  : in  std_logic                     := 'X';             -- startofpacket
			adc_command2_endofpacket    : in  std_logic                     := 'X';             -- endofpacket
			adc_command2_ready          : out std_logic;                                        -- ready
			adc_response2_valid         : out std_logic;                                        -- valid
			adc_response2_channel       : out std_logic_vector(4 downto 0);                     -- channel
			adc_response2_data          : out std_logic_vector(11 downto 0);                    -- data
			adc_response2_startofpacket : out std_logic;                                        -- startofpacket
			adc_response2_endofpacket   : out std_logic                                         -- endofpacket
		);
	end component max10_adc_system;

	u0 : component max10_adc_system
		port map (
			adc_command_valid           => CONNECTED_TO_adc_command_valid,           --    adc_command.valid
			adc_command_channel         => CONNECTED_TO_adc_command_channel,         --               .channel
			adc_command_startofpacket   => CONNECTED_TO_adc_command_startofpacket,   --               .startofpacket
			adc_command_endofpacket     => CONNECTED_TO_adc_command_endofpacket,     --               .endofpacket
			adc_command_ready           => CONNECTED_TO_adc_command_ready,           --               .ready
			adc_pll_clock_clk           => CONNECTED_TO_adc_pll_clock_clk,           --  adc_pll_clock.clk
			adc_pll_locked_export       => CONNECTED_TO_adc_pll_locked_export,       -- adc_pll_locked.export
			adc_response_valid          => CONNECTED_TO_adc_response_valid,          --   adc_response.valid
			adc_response_startofpacket  => CONNECTED_TO_adc_response_startofpacket,  --               .startofpacket
			adc_response_endofpacket    => CONNECTED_TO_adc_response_endofpacket,    --               .endofpacket
			adc_response_empty          => CONNECTED_TO_adc_response_empty,          --               .empty
			adc_response_channel        => CONNECTED_TO_adc_response_channel,        --               .channel
			adc_response_data           => CONNECTED_TO_adc_response_data,           --               .data
			clk_clk                     => CONNECTED_TO_clk_clk,                     --            clk.clk
			reset_reset_n               => CONNECTED_TO_reset_reset_n,               --          reset.reset_n
			adc_command2_valid          => CONNECTED_TO_adc_command2_valid,          --   adc_command2.valid
			adc_command2_channel        => CONNECTED_TO_adc_command2_channel,        --               .channel
			adc_command2_startofpacket  => CONNECTED_TO_adc_command2_startofpacket,  --               .startofpacket
			adc_command2_endofpacket    => CONNECTED_TO_adc_command2_endofpacket,    --               .endofpacket
			adc_command2_ready          => CONNECTED_TO_adc_command2_ready,          --               .ready
			adc_response2_valid         => CONNECTED_TO_adc_response2_valid,         --  adc_response2.valid
			adc_response2_channel       => CONNECTED_TO_adc_response2_channel,       --               .channel
			adc_response2_data          => CONNECTED_TO_adc_response2_data,          --               .data
			adc_response2_startofpacket => CONNECTED_TO_adc_response2_startofpacket, --               .startofpacket
			adc_response2_endofpacket   => CONNECTED_TO_adc_response2_endofpacket    --               .endofpacket
		);

