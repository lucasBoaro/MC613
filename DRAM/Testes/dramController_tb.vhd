library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use work.dram_pkg.all;

entity dramController_tb is
end dramController_tb;

architecture behavior of dramController_tb is

    signal tb_clk_143   : std_logic := '0';
    signal tb_rst       : std_logic := '0';
    signal tb_address   : std_logic_vector(25 downto 0) := (others => '0');
    signal tb_data_in   : std_logic_vector(7 downto 0) := (others => '0');
    signal tb_data_out  : std_logic_vector(7 downto 0);
    signal tb_req       : std_logic := '0';
    signal tb_ready     : std_logic;
    signal tb_write_in  : std_logic := '0';
    signal tb_read_in   : std_logic := '0';

    signal tb_dram_cs_n  : std_logic;
    signal tb_dram_ras_n : std_logic;
    signal tb_dram_cas_n : std_logic;
    signal tb_dram_we_n  : std_logic;
    signal tb_dram_addr  : std_logic_vector(12 downto 0);
    signal tb_dram_cke   : std_logic;
    signal tb_dram_ldqm  : std_logic;
    signal tb_dram_udqm  : std_logic;
    signal tb_dram_ba    : std_logic_vector(1 downto 0);
    signal tb_dram_dq    : std_logic_vector(15 downto 0) := (others => 'Z');
    signal tb_state_debug : state_type;
    constant CLK_PERIOD : time := 7 ns; -- clock period used in this TB (7ns high + 7ns low)

begin

    uut: entity work.dramController
        port map(
            clk_143   => tb_clk_143,
            rst       => tb_rst,
            address   => tb_address,
            data_in   => tb_data_in,
            data_out  => tb_data_out,
            req       => tb_req,
            ready     => tb_ready,
            write_in  => tb_write_in,
            read_in   => tb_read_in,

            DRAM_CS_N => tb_dram_cs_n,
            DRAM_RAS_N => tb_dram_ras_n,
            DRAM_CAS_N => tb_dram_cas_n,
            DRAM_WE_N => tb_dram_we_n,
            DRAM_ADDR => tb_dram_addr,
            DRAM_CKE  => tb_dram_cke,
            DRAM_LDQM => tb_dram_ldqm,
            DRAM_UDQM => tb_dram_udqm,
            DRAM_BA   => tb_dram_ba,
            DRAM_DQ   => tb_dram_dq,

            state_debug => tb_state_debug
        );

    clk_process : process
    begin
        while true loop
            tb_clk_143 <= '0';
            wait for 3.5 ns;
            tb_clk_143 <= '1';
            wait for 3.5 ns;
        end loop;
    end process;
	
fake_dram_chip_proc: process
        type mem_array is array (0 to 3) of std_logic_vector(15 downto 0);
        variable fake_mem : mem_array := (others => (others => '0'));
        variable bank_idx : integer := 0;
    begin
        wait until falling_edge(tb_clk_143);
        
        case tb_dram_ba is
            when "00" => bank_idx := 0;
            when "01" => bank_idx := 1;
            when "10" => bank_idx := 2;
            when "11" => bank_idx := 3;
            when others => bank_idx := 0;
        end case;

        -- Escrita
        if tb_dram_cs_n = '0' and tb_dram_ras_n = '1' and tb_dram_cas_n = '0' and tb_dram_we_n = '0' then
            fake_mem(bank_idx) := tb_dram_dq;
        end if;

        -- Leitura com CAS Latency
        if tb_dram_cs_n = '0' and tb_dram_ras_n = '1' and tb_dram_cas_n = '0' and tb_dram_we_n = '1' then
            wait for CLK_PERIOD * 2;
            tb_dram_dq <= fake_mem(bank_idx);
            wait for CLK_PERIOD * 2;
            tb_dram_dq <= (others => 'Z');
        else
            tb_dram_dq <= (others => 'Z');
        end if;
    end process;

	test_input_process: process
        variable line_out : line;
    begin
        tb_rst <= '1';
        wait for 20 ns;
        tb_rst <= '0';

        wait until tb_state_debug = idle;
        wait for 10 ns;

        -- Teste A: Grava 10 no banco 0
        tb_write_in <= '1'; tb_read_in <= '0';
        tb_address <= "00000000000000000000000000";
        tb_data_in <= "00001010";
        tb_req <= '1';
        wait until tb_state_debug = write_st;
        wait until tb_state_debug = precharge;
        tb_req <= '0'; tb_write_in <= '0';
        wait until tb_state_debug = idle;
        wait for 10 ns;

        -- Teste B: Grava 99 no banco 3
        tb_write_in <= '1';
        tb_address <= "11111111111111111111111111";
        tb_data_in <= "01100011";
        tb_req <= '1';
        wait until tb_state_debug = write_st;
        wait until tb_state_debug = precharge;
        tb_req <= '0'; tb_write_in <= '0';
        wait until tb_state_debug = idle;
        wait for 10 ns;

        -- Leitura A:
        tb_read_in <= '1';
        tb_address <= "00000000000000000000000000";
        tb_req <= '1';
        wait until tb_state_debug = read_st;
        wait until tb_state_debug = precharge;
        wait for 1 ns;
		  write(line_out, string("Espera-se '00001010'. Lido: "));
		  write(line_out, tb_data_out);
		  writeline(output, lineout);
        assert (tb_data_out = "00001010") report "ERRO GRAVE: Leu errado do banco 0" severity failure;
        tb_req <= '0'; tb_read_in <= '0';
        wait until tb_state_debug = idle;
        wait for 10 ns;

        -- Leitura B:
        tb_read_in <= '1';
        tb_address <= "11111111111111111111111111";
        tb_req <= '1';
        wait until tb_state_debug = read_st;
        wait until tb_state_debug = precharge;
        wait for 1 ns;
		  write(line_out, string("Espera-se '01100011'. Lido: "));
		  write(line_out, tb_data_out);
		  writeline(output, lineout);
        assert (tb_data_out = "01100011") report "ERRO GRAVE: Leu errado do banco 3" severity failure;
        tb_req <= '0'; tb_read_in <= '0';

        -- Teste Refresh
        wait until tb_state_debug = idle;
        tb_req <= '0';
        wait until tb_state_debug = refresh for 15 us;
        assert (tb_state_debug = refresh) report "FALHA DE REFRESH" severity failure;

        write(line_out, string'("SUCESSO TOTAL! CODIGO RESTAURADO COM PERFEICAO!"));
        writeline(output, line_out);
        wait;
    end process;


    -- Check DRAM control signals for each state as soon as the state is driven
    check_states_proc: process(tb_state_debug)
        variable line_out : line;
    begin
        case tb_state_debug is
            when preChargeAll =>
                assert tb_dram_ras_n = '0'
                    report "preChargeAll: DRAM_RAS_N deveria ser '0'" severity error;
                assert tb_dram_we_n = '0'
                    report "preChargeAll: DRAM_WE_N deveria ser '0'" severity error;
                assert tb_dram_addr(10) = '1'
                    report "preChargeAll: DRAM_ADDR(10) deveria ser '1'" severity error;

            when autoRefresh_Init =>
                assert tb_dram_ras_n = '0' and tb_dram_cas_n = '0' and tb_dram_we_n = '1'
                    report "autoRefresh_Init: esperado RAS='0' CAS='0' WE='1'" severity error;

            when LMR =>
                assert tb_dram_ras_n = '0' and tb_dram_cas_n = '0' and tb_dram_we_n = '0'
                    report "LMR: esperado RAS='0' CAS='0' WE='0'" severity error;
                assert tb_dram_ba = "00"
                    report "LMR: esperado DRAM_BA = '00'" severity error;

            when act =>
                assert tb_dram_ras_n = '0' and tb_dram_cas_n = '1' and tb_dram_we_n = '1'
                    report "act: esperado RAS='0' CAS='1' WE='1'" severity error;

            when read_st =>
                assert tb_dram_ras_n = '1' and tb_dram_cas_n = '0' and tb_dram_we_n = '1'
                    report "read_st: esperado RAS='1' CAS='0' WE='1'" severity error;
                assert tb_dram_addr(10) = '0'
                    report "read_st: esperado DRAM_ADDR(10) = '0'" severity error;

            when write_st =>
                assert tb_dram_ras_n = '1' and tb_dram_cas_n = '0' and tb_dram_we_n = '0'
                    report "write_st: esperado RAS='1' CAS='0' WE='0'" severity error;

            when NOP =>
                assert tb_dram_ras_n = '1' and tb_dram_cas_n = '1' and tb_dram_we_n = '1'
                    report "NOP: esperado RAS='1' CAS='1' WE='1'" severity error;

            when refresh =>
                assert tb_dram_ras_n = '0' and tb_dram_cas_n = '0' and tb_dram_we_n = '1'
                    report "refresh: esperado RAS='0' CAS='0' WE='1'" severity error;

            when others =>
                null;
        end case;
    end process;

    -- Measure time spent in deterministic states and assert expected durations
    check_state_timing: process(tb_state_debug)
        variable last_state  : state_type := tb_state_debug;
        variable last_time   : time := 0 ns;
        variable delta       : time;
        variable expected_t  : time;
    begin
        if tb_state_debug'event and tb_state_debug /= NOP then
            if last_time = 0 ns then
                -- first event, initialize
                last_time := now;
                last_state := tb_state_debug;
            else
                delta := now - last_time;

                -- Determine expected time (in cycles * CLK_PERIOD) for states we want to check
                case last_state is
                    when init =>
                        expected_t := 28572 * CLK_PERIOD;
                    when preChargeAll =>
                        expected_t := 5 * CLK_PERIOD;
                    when autoRefresh_Init =>
                        expected_t := 10 * CLK_PERIOD; -- each autorefresh iteration uses 9 cycles
                    when LMR =>
                        expected_t := 3 * CLK_PERIOD;
                    when act =>
                        expected_t := 4 * CLK_PERIOD;
                    when read_st =>
                        expected_t := 3 * CLK_PERIOD;
                    when write_st =>
                        expected_t := 3 * CLK_PERIOD;
                    when precharge =>
                        expected_t := 4 * CLK_PERIOD;
                    when refresh =>
                        expected_t := 10 * CLK_PERIOD;
                    when others =>
                        expected_t := 0 ns; -- do not check NOP/others
                end case;

                if expected_t > 0 ns then
                    -- allow ±1 clock tolerance
                    assert (delta >= expected_t - CLK_PERIOD) and (delta <= expected_t + CLK_PERIOD)
                        report "A temporização entre estados está errada. Estado: " & state_type'image(last_state) &
                               " Tempo medido=" & time'image(delta) & " Esperado=" & time'image(expected_t)
                        severity error;
                end if;

                -- update trackers
                last_time := now;
                last_state := tb_state_debug;
            end if;
        end if;
    end process;
end behavior;