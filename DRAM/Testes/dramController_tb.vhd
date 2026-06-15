library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use work.dram_pkg.all;

entity dramController_tb is
end dramController_tb;

architecture Behavioral of dramController_tb is
    component dramController
        PORT(
            clk_143     : IN    STD_LOGIC;
            rst         : IN    STD_LOGIC;
            address     : IN    STD_LOGIC_VECTOR(25 DOWNTO 0);
            data_in     : IN    STD_LOGIC_VECTOR(7 DOWNTO 0);
            data_out    : OUT   STD_LOGIC_VECTOR(7 DOWNTO 0);
            req         : IN    STD_LOGIC;
            ready       : OUT   STD_LOGIC;
            write_in    : IN    STD_LOGIC;
            read_in     : IN    STD_LOGIC;

            DRAM_CS_N   : OUT   STD_LOGIC;
            DRAM_RAS_N  : OUT   STD_LOGIC;
            DRAM_CAS_N  : OUT   STD_LOGIC;
            DRAM_WE_N   : OUT   STD_LOGIC;
            DRAM_ADDR   : OUT   STD_LOGIC_VECTOR(12 DOWNTO 0);
            DRAM_CKE    : OUT   STD_LOGIC;
            DRAM_LDQM   : OUT   STD_LOGIC;
            DRAM_UDQM   : OUT   STD_LOGIC;
            DRAM_BA     : OUT   STD_LOGIC_VECTOR(1 DOWNTO 0);
            DRAM_DQ     : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            state_debug : OUT   state_type
        );
    end component;

    signal tb_clk_143    : STD_LOGIC := '0';
    signal tb_rst        : STD_LOGIC := '0';
    signal tb_address    : STD_LOGIC_VECTOR(25 downto 0) := (others => '0');
    signal tb_data_in    : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal tb_data_out   : STD_LOGIC_VECTOR(7 downto 0);
    signal tb_req        : STD_LOGIC := '0';
    signal tb_ready      : STD_LOGIC;
    signal tb_write_in   : STD_LOGIC := '0';
    signal tb_read_in    : STD_LOGIC := '0';

    signal tb_dram_cs_n  : STD_LOGIC;
    signal tb_dram_ras_n : STD_LOGIC;
    signal tb_dram_cas_n : STD_LOGIC;
    signal tb_dram_we_n  : STD_LOGIC;
    signal tb_dram_addr  : STD_LOGIC_VECTOR(12 downto 0);
    signal tb_dram_cke   : STD_LOGIC;
    signal tb_dram_ldqm  : STD_LOGIC;
    signal tb_dram_udqm  : STD_LOGIC;
    signal tb_dram_ba    : STD_LOGIC_VECTOR(1 downto 0);
    signal tb_dram_dq    : STD_LOGIC_VECTOR(15 downto 0) := (others => 'Z');
    signal tb_state_debug : state_type;

    signal fake_mem_0    : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal fake_mem_1    : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal fake_mem_2    : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal fake_mem_3    : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
    signal sim_finished  : boolean := false;

    constant CLK_PERIOD  : time := 7 ns;

begin
    uut: dramController
        port map(
            clk_143     => tb_clk_143,
            rst         => tb_rst,
            address     => tb_address,
            data_in     => tb_data_in,
            data_out    => tb_data_out,
            req         => tb_req,
            ready       => tb_ready,
            write_in    => tb_write_in,
            read_in     => tb_read_in,

            DRAM_CS_N   => tb_dram_cs_n,
            DRAM_RAS_N  => tb_dram_ras_n,
            DRAM_CAS_N  => tb_dram_cas_n,
            DRAM_WE_N   => tb_dram_we_n,
            DRAM_ADDR   => tb_dram_addr,
            DRAM_CKE    => tb_dram_cke,
            DRAM_LDQM   => tb_dram_ldqm,
            DRAM_UDQM   => tb_dram_udqm,
            DRAM_BA     => tb_dram_ba,
            DRAM_DQ     => tb_dram_dq,
            state_debug => tb_state_debug
        );

    clk_process : process -- gerador de clock
    begin
        while not sim_finished loop
            tb_clk_143 <= '0'; wait for CLK_PERIOD/2;
            tb_clk_143 <= '1'; wait for CLK_PERIOD/2;
        end loop;
        wait;
    end process;

    fake_dram_chip_proc: process
        variable banco_lido : STD_LOGIC_VECTOR(1 downto 0);
    begin
        wait until falling_edge(tb_clk_143);
        tb_dram_dq <= (others => 'Z');

        -- Testa comando de escrita enviado pelo controlador
        if (tb_dram_cs_n = '0' and tb_dram_ras_n = '1' and tb_dram_cas_n = '0' and tb_dram_we_n = '0') then
            case tb_dram_ba is
                when "00" => fake_mem_0 <= tb_dram_dq;
                when "01" => fake_mem_1 <= tb_dram_dq;
                when "10" => fake_mem_2 <= tb_dram_dq;
                when others => fake_mem_3 <= tb_dram_dq;
            end case;
        end if;

        -- Testa comando de leitura enviado pelo controlador
        if (tb_dram_cs_n = '0' and tb_dram_ras_n = '1' and tb_dram_cas_n = '0' and tb_dram_we_n = '1') then
            banco_lido := tb_dram_ba;
            wait for CLK_PERIOD * 2;

            case banco_lido is
                when "00" => tb_dram_dq <= fake_mem_0;
                when "01" => tb_dram_dq <= fake_mem_1;
                when "10" => tb_dram_dq <= fake_mem_2;
                when others => tb_dram_dq <= fake_mem_3;
            end case;

            wait for CLK_PERIOD * 2;
            tb_dram_dq <= (others => 'Z');
        end if;
    end process;

    test_process: process
        variable line_out : line;
    begin
        write(line_out, string'("Testando dramController..."));
        writeline(output, line_out);

        -- Testa reset e inicializacao da SDRAM
        tb_rst <= '1';
        wait for 20 ns;
        tb_rst <= '0';

        wait until tb_state_debug = idle;
        wait for 10 ns;

        assert (tb_ready = '1')
            report "Controlador deveria ficar pronto apos inicializacao"
            severity error;

        -- Testa escrita do valor 10 no banco 0
        tb_write_in <= '1';
        tb_read_in <= '0';
        tb_address <= "00000000000000000000000000";
        tb_data_in <= "00001010";
        tb_req <= '1';

        wait until tb_state_debug = write_st;
        wait until tb_state_debug = precharge;
        tb_req <= '0';
        tb_write_in <= '0';

        wait until tb_state_debug = idle;
        wait for 10 ns;

        -- Testa escrita do valor 99 no banco 3
        tb_write_in <= '1';
        tb_address <= "11111111111111111111111111";
        tb_data_in <= "01100011";
        tb_req <= '1';

        wait until tb_state_debug = write_st;
        wait until tb_state_debug = precharge;
        tb_req <= '0';
        tb_write_in <= '0';

        wait until tb_state_debug = idle;
        wait for 10 ns;

        -- Testa leitura do banco 0
        tb_read_in <= '1';
        tb_address <= "00000000000000000000000000";
        tb_req <= '1';

        wait until tb_state_debug = read_st;
        wait until tb_state_debug = precharge;
        wait for 1 ns;

        write(line_out, string'("Espera-se 00001010. Lido: "));
        write(line_out, tb_data_out);
        writeline(output, line_out);

        assert (tb_data_out = "00001010")
            report "Leitura do banco 0 retornou valor incorreto"
            severity failure;

        tb_req <= '0';
        tb_read_in <= '0';

        wait until tb_state_debug = idle;
        wait for 10 ns;

        -- Testa leitura do banco 3
        tb_read_in <= '1';
        tb_address <= "11111111111111111111111111";
        tb_req <= '1';

        wait until tb_state_debug = read_st;
        wait until tb_state_debug = precharge;
        wait for 1 ns;

        write(line_out, string'("Espera-se 01100011. Lido: "));
        write(line_out, tb_data_out);
        writeline(output, line_out);

        assert (tb_data_out = "01100011")
            report "Leitura do banco 3 retornou valor incorreto"
            severity failure;

        tb_req <= '0';
        tb_read_in <= '0';

        -- Testa refresh automatico
        wait until tb_state_debug = idle;
        wait until tb_state_debug = refresh for 15 us;

        assert (tb_state_debug = refresh)
            report "Controlador nao entrou em refresh dentro do tempo esperado"
            severity failure;

        write(line_out, string'("Teste concluido sem erros"));
        writeline(output, line_out);

        sim_finished <= true;
        wait;
    end process;

    check_states_proc: process(tb_state_debug)
    begin
        -- Verifica sinais de comando da DRAM em cada estado principal
        case tb_state_debug is
            when preChargeAll =>
                assert (tb_dram_ras_n = '0' and tb_dram_we_n = '0' and tb_dram_addr(10) = '1')
                    report "preChargeAll deveria ativar RAS_N, WE_N e A10"
                    severity error;

            when autoRefresh_Init =>
                assert (tb_dram_ras_n = '0' and tb_dram_cas_n = '0' and tb_dram_we_n = '1')
                    report "autoRefresh_Init deveria gerar comando de refresh"
                    severity error;

            when LMR =>
                assert (tb_dram_ras_n = '0' and tb_dram_cas_n = '0' and tb_dram_we_n = '0' and tb_dram_ba = "00")
                    report "LMR deveria carregar o modo no banco 00"
                    severity error;

            when act =>
                assert (tb_dram_ras_n = '0' and tb_dram_cas_n = '1' and tb_dram_we_n = '1')
                    report "act deveria gerar comando ACTIVE"
                    severity error;

            when read_st =>
                assert (tb_dram_ras_n = '1' and tb_dram_cas_n = '0' and tb_dram_we_n = '1' and tb_dram_addr(10) = '0')
                    report "read_st deveria gerar comando READ"
                    severity error;

            when write_st =>
                assert (tb_dram_ras_n = '1' and tb_dram_cas_n = '0' and tb_dram_we_n = '0')
                    report "write_st deveria gerar comando WRITE"
                    severity error;

            when NOP =>
                assert (tb_dram_ras_n = '1' and tb_dram_cas_n = '1' and tb_dram_we_n = '1')
                    report "NOP deveria manter RAS_N, CAS_N e WE_N em '1'"
                    severity error;

            when refresh =>
                assert (tb_dram_ras_n = '0' and tb_dram_cas_n = '0' and tb_dram_we_n = '1')
                    report "refresh deveria gerar comando de auto refresh"
                    severity error;

            when others =>
                null;
        end case;
    end process;
end Behavioral;
