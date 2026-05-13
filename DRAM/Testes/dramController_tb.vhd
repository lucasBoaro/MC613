library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

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
            DRAM_DQ   => tb_dram_dq
        );

    clk_process : process
    begin
        while true loop
            tb_clk_143 <= '0';
            wait for 7 ns;
            tb_clk_143 <= '1';
            wait for 7 ns;
        end loop;
    end process;
    
    test_process: process
        variable line_out : line;
    begin
        if rising_edge(clk):
            if ()
        wait;
    end process;

    check_vga_clock_proc: process
        variable tempo_inicial : time;
        variable tempo_final   : time;
        variable periodo_medido : time;
		variable line_out       : line;
    begin
	    write(line_out, string'("Testando temporização"));
        writeline(output, line_out);
        wait for 10 us; -- espera para o sistema inicializar

        -- Verifica se o clock do VGA (e consequentemente do pixel) está oscilando na frequência correta (aproximadamente 25 MHz)
        wait until rising_edge(tb_vga_clk);
        tempo_inicial := now;
        wait until rising_edge(tb_vga_clk);
        tempo_final := now;
        periodo_medido := tempo_final - tempo_inicial;
        assert (periodo_medido > 39 ns and periodo_medido < 41 ns)
            report "Clock VGA nao esta oscilando ou esta na frequencia errada! " &
                   "Periodo medido: " & time'image(periodo_medido)
            severity error;

        write(line_out, string'("Teste concluido"));
        writeline(output, line_out);
        wait;
    end process;
end behavior;