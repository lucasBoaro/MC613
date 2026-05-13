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
	 
	test_input_process: process
        variable line_out : line;
    begin
        
        wait until tb_state_debug = idle;

        tb_write_in <= '1';
        tb_address <= "00000000000000000000000000";
        tb_data_in <= "00000001";
        tb_req <= '1';
        write(line_out, to_integer(unsigned(tb_data_out)));
        writeline(output, line_out);

        wait for 5 ns; -- CORRIGIDO AQUI: adicionado o "for"

        wait until tb_state_debug = idle;

        tb_read_in <= '1';
        tb_address <= "00000000000000000000000000";
        tb_data_in <= "00000001";
        tb_req <= '1';
        write(line_out, to_integer(unsigned(tb_data_out)));
        writeline(output, line_out);

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
                        expected_t := 4 * CLK_PERIOD;
                    when autoRefresh_Init =>
                        expected_t := 9 * CLK_PERIOD; -- each autorefresh iteration uses 9 cycles
                    when LMR =>
                        expected_t := 2 * CLK_PERIOD;
                    when act =>
                        expected_t := 3 * CLK_PERIOD;
                    when read_st =>
                        expected_t := 2 * CLK_PERIOD;
                    when write_st =>
                        expected_t := 2 * CLK_PERIOD;
                    when precharge =>
                        expected_t := 3 * CLK_PERIOD;
                    when refresh =>
                        expected_t := 9 * CLK_PERIOD;
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