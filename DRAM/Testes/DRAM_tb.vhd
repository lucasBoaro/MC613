library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

entity DRAM_tb is
end DRAM_tb;

architecture Behavioral of DRAM_tb is
    component DRAM
        port (
            -- Clock principal da placa
            CLOCK_50  : in  STD_LOGIC;

            -- Entradas da placa
            SW        : in  STD_LOGIC_VECTOR(9 downto 0);
            KEY       : in  STD_LOGIC_VECTOR(3 downto 0);

            -- Saidas dos displays
            HEX5      : out STD_LOGIC_VECTOR(6 downto 0);
            HEX4      : out STD_LOGIC_VECTOR(6 downto 0);
            HEX1      : out STD_LOGIC_VECTOR(6 downto 0);
            HEX0      : out STD_LOGIC_VECTOR(6 downto 0);

            -- Saidas e barramento da SDRAM
            DRAM_CLK   : out   STD_LOGIC;
            DRAM_CS_N  : out   STD_LOGIC;
            DRAM_RAS_N : out   STD_LOGIC;
            DRAM_CAS_N : out   STD_LOGIC;
            DRAM_WE_N  : out   STD_LOGIC;
            DRAM_ADDR  : out   STD_LOGIC_VECTOR(12 downto 0);
            DRAM_CKE   : out   STD_LOGIC;
            DRAM_LDQM  : out   STD_LOGIC;
            DRAM_UDQM  : out   STD_LOGIC;
            DRAM_BA    : out   STD_LOGIC_VECTOR(1 downto 0);
            DRAM_DQ    : inout STD_LOGIC_VECTOR(15 downto 0)
        );
    end component;

    signal tb_clk       : STD_LOGIC := '0';
    signal tb_switches  : STD_LOGIC_VECTOR(9 downto 0) := (others => '0');
    signal tb_buttons   : STD_LOGIC_VECTOR(3 downto 0) := (others => '1');

    signal tb_hex5      : STD_LOGIC_VECTOR(6 downto 0);
    signal tb_hex4      : STD_LOGIC_VECTOR(6 downto 0);
    signal tb_hex1      : STD_LOGIC_VECTOR(6 downto 0);
    signal tb_hex0      : STD_LOGIC_VECTOR(6 downto 0);

    signal tb_dram_clk   : STD_LOGIC;
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

    signal sim_finished : boolean := false;

    constant clk_period : time := 20 ns; -- periodo de clock de 50MHz

begin
    uut: DRAM
        port map (
            -- Clock principal da placa
            CLOCK_50  => tb_clk,

            -- Entradas da placa
            SW        => tb_switches,
            KEY       => tb_buttons,

            -- Saidas dos displays
            HEX5      => tb_hex5,
            HEX4      => tb_hex4,
            HEX1      => tb_hex1,
            HEX0      => tb_hex0,

            -- Saidas e barramento da SDRAM
            DRAM_CLK   => tb_dram_clk,
            DRAM_CS_N  => tb_dram_cs_n,
            DRAM_RAS_N => tb_dram_ras_n,
            DRAM_CAS_N => tb_dram_cas_n,
            DRAM_WE_N  => tb_dram_we_n,
            DRAM_ADDR  => tb_dram_addr,
            DRAM_CKE   => tb_dram_cke,
            DRAM_LDQM  => tb_dram_ldqm,
            DRAM_UDQM  => tb_dram_udqm,
            DRAM_BA    => tb_dram_ba,
            DRAM_DQ    => tb_dram_dq
        );

    clk_process : process -- gerador de clock
    begin
        while not sim_finished loop
            tb_clk <= '0'; wait for clk_period/2;
            tb_clk <= '1'; wait for clk_period/2;
        end loop;
        wait;
    end process;

    test_process: process
        variable line_out : line;
    begin
        write(line_out, string'("Teste DRAM top-level..."));
        writeline(output, line_out);

        -- Testa reset geral pelo KEY0
        tb_buttons(0) <= '0';
        wait for 100 ns;
        tb_buttons(0) <= '1';

        write(line_out, string'("Aguardando inicializacao da SDRAM"));
        writeline(output, line_out);

        wait for 205 us;

        -- Testa displays para endereco 5 e dado A
        tb_switches <= "0001011010";
        wait for 50 ns;

        assert (tb_hex5 = "1000000")
            report "HEX5 deveria mostrar 0 para SW(9 downto 8)=00"
            severity error;
        assert (tb_hex4 = "0010010")
            report "HEX4 deveria mostrar 5 para SW(7 downto 4)=0101"
            severity error;
        assert (tb_hex0 = "0001000")
            report "HEX0 deveria mostrar A para SW(3 downto 0)=1010"
            severity error;

        -- Testa requisicao de escrita pelo KEY3
        tb_buttons(3) <= '0';
        wait for 50 ns;
        tb_buttons(3) <= '1';
        wait for 150 ns;

        write(line_out, string'("As ondas de WE_N e CAS_N deveriam pulsar em 0 para escrita"));
        writeline(output, line_out);

        wait for 200 ns;

        -- Testa novo endereco para leitura
        tb_switches <= "0011001010";
        wait for 50 ns;

        assert (tb_hex4 = "1000110")
            report "HEX4 deveria mostrar C para SW(7 downto 4)=1100"
            severity error;

        -- Testa endereco 0x2A com SW9 ligado
        tb_switches <= "1010100110";
        wait for 50 ns;

        assert (tb_hex5 = "0100100")
            report "HEX5 deveria mostrar 2 para SW(9 downto 8)=10"
            severity error;
        assert (tb_hex4 = "0001000")
            report "HEX4 deveria mostrar A para SW(7 downto 4)=1010"
            severity error;
        assert (tb_hex0 = "0000010")
            report "HEX0 deveria mostrar 6 para SW(3 downto 0)=0110"
            severity error;

        wait for 150 ns;

        write(line_out, string'("A onda de CAS_N deveria pulsar em 0 para leitura"));
        writeline(output, line_out);

        wait for 200 ns;

        write(line_out, string'("Teste concluido sem erros"));
        writeline(output, line_out);

        sim_finished <= true;
        wait;
    end process;
end Behavioral;
