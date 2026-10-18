	component modular_dual_adc_0 is
		port (
			clock_clk                : in  std_logic                     := 'X';             -- clk
			reset_sink_reset_n       : in  std_logic                     := 'X';             -- reset_n
			adc_pll_clock_clk        : in  std_logic                     := 'X';             -- clk
			adc_pll_locked_export    : in  std_logic                     := 'X';             -- export
			command_valid            : in  std_logic                     := 'X';             -- valid
			command_channel          : in  std_logic_vector(4 downto 0)  := (others => 'X'); -- channel
			command_startofpacket    : in  std_logic                     := 'X';             -- startofpacket
			command_endofpacket      : in  std_logic                     := 'X';             -- endofpacket
			command_ready            : out std_logic;                                        -- ready
			command_2_valid          : in  std_logic                     := 'X';             -- valid
			command_2_channel        : in  std_logic_vector(4 downto 0)  := (others => 'X'); -- channel
			command_2_startofpacket  : in  std_logic                     := 'X';             -- startofpacket
			command_2_endofpacket    : in  std_logic                     := 'X';             -- endofpacket
			command_2_ready          : out std_logic;                                        -- ready
			response_valid           : out std_logic;                                        -- valid
			response_startofpacket   : out std_logic;                                        -- startofpacket
			response_endofpacket     : out std_logic;                                        -- endofpacket
			response_empty           : out std_logic_vector(0 downto 0);                     -- empty
			response_channel         : out std_logic_vector(4 downto 0);                     -- channel
			response_data            : out std_logic_vector(11 downto 0);                    -- data
			response_2_valid         : out std_logic;                                        -- valid
			response_2_channel       : out std_logic_vector(4 downto 0);                     -- channel
			response_2_data          : out std_logic_vector(11 downto 0);                    -- data
			response_2_startofpacket : out std_logic;                                        -- startofpacket
			response_2_endofpacket   : out std_logic                                         -- endofpacket
		);
	end component modular_dual_adc_0;

	u0 : component modular_dual_adc_0
		port map (
			clock_clk                => CONNECTED_TO_clock_clk,                --          clock.clk
			reset_sink_reset_n       => CONNECTED_TO_reset_sink_reset_n,       --     reset_sink.reset_n
			adc_pll_clock_clk        => CONNECTED_TO_adc_pll_clock_clk,        --  adc_pll_clock.clk
			adc_pll_locked_export    => CONNECTED_TO_adc_pll_locked_export,    -- adc_pll_locked.export
			command_valid            => CONNECTED_TO_command_valid,            --        command.valid
			command_channel          => CONNECTED_TO_command_channel,          --               .channel
			command_startofpacket    => CONNECTED_TO_command_startofpacket,    --               .startofpacket
			command_endofpacket      => CONNECTED_TO_command_endofpacket,      --               .endofpacket
			command_ready            => CONNECTED_TO_command_ready,            --               .ready
			command_2_valid          => CONNECTED_TO_command_2_valid,          --      command_2.valid
			command_2_channel        => CONNECTED_TO_command_2_channel,        --               .channel
			command_2_startofpacket  => CONNECTED_TO_command_2_startofpacket,  --               .startofpacket
			command_2_endofpacket    => CONNECTED_TO_command_2_endofpacket,    --               .endofpacket
			command_2_ready          => CONNECTED_TO_command_2_ready,          --               .ready
			response_valid           => CONNECTED_TO_response_valid,           --       response.valid
			response_startofpacket   => CONNECTED_TO_response_startofpacket,   --               .startofpacket
			response_endofpacket     => CONNECTED_TO_response_endofpacket,     --               .endofpacket
			response_empty           => CONNECTED_TO_response_empty,           --               .empty
			response_channel         => CONNECTED_TO_response_channel,         --               .channel
			response_data            => CONNECTED_TO_response_data,            --               .data
			response_2_valid         => CONNECTED_TO_response_2_valid,         --     response_2.valid
			response_2_channel       => CONNECTED_TO_response_2_channel,       --               .channel
			response_2_data          => CONNECTED_TO_response_2_data,          --               .data
			response_2_startofpacket => CONNECTED_TO_response_2_startofpacket, --               .startofpacket
			response_2_endofpacket   => CONNECTED_TO_response_2_endofpacket    --               .endofpacket
		);

