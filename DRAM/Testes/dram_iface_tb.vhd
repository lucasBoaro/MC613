library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

entity dram_iface_tb is
end dram_iface_tb;

architecture Behavioral of dram_iface_tb is
    component dram_iface
        Port (
            clk             : in  STD_LOGIC;
            rst             : in  STD_LOGIC;
            address         : in  STD_LOGIC_VECTOR(5 downto 0);
            data_in_write   : in  STD_LOGIC_VECTOR(3 downto 0);
            key_3           : in  STD_LOGIC;
            ready           : in  STD_LOGIC;
            data_out_adress : out STD_LOGIC_VECTOR(25 downto 0);
            data_out_write  : out STD_LOGIC_VECTOR(7 downto 0);
            write_out       : out STD_LOGIC;
            read_out        : out STD_LOGIC
        );
    end component;

    signal tb_clk            : STD_LOGIC := '0';
    signal tb_rst            : STD_LOGIC := '0';
    signal tb_address_in     : STD_LOGIC_VECTOR(5 downto 0) := (others => '0');
    signal tb_data_in_write  : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal tb_key_3          : STD_LOGIC := '1';
    signal tb_ready          : STD_LOGIC := '0';
    signal tb_address_out    : STD_LOGIC_VECTOR(25 downto 0);
    signal tb_data_out_write : STD_LOGIC_VECTOR(7 downto 0);
    signal tb_write_req      : STD_LOGIC;
    signal tb_read_req       : STD_LOGIC;
    signal sim_finished      : boolean := false;

    constant clk_period      : time := 7 ns;

begin
    uut: dram_iface
        port map (
            clk             => tb_clk,
            rst             => tb_rst,
            address         => tb_address_in,
            data_in_write   => tb_data_in_write,
            key_3           => tb_key_3,
            ready           => tb_ready,
            data_out_adress => tb_address_out,
            data_out_write  => tb_data_out_write,
            write_out       => tb_write_req,
            read_out        => tb_read_req
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
        write(line_out, string'("Testando dram_iface..."));
        writeline(output, line_out);

        -- Testa reset da interface
        tb_rst <= '1';
        wait for clk_period * 2;
        tb_rst <= '0';
        wait for clk_period;

        assert (tb_write_req = '0' and tb_read_req = '0')
            report "Reset deveria deixar read_out e write_out em 0"
            severity error;

        -- Testa mapeamento dos switches para endereco e dado
        tb_address_in <= "101011";
        tb_data_in_write <= "1101";
        wait for 5 ns;

        assert (tb_data_out_write = "00001101")
            report "data_out_write deveria receber data_in_write nos bits baixos"
            severity error;
        assert (tb_address_out(0) = '1' and tb_address_out(1) = '1')
            report "Bits 0 e 1 do endereco nao foram mapeados corretamente"
            severity error;
        assert (tb_address_out(21) = '0' and tb_address_out(22) = '1' and tb_address_out(23) = '0')
            report "Bits 21 a 23 do endereco nao foram mapeados corretamente"
            severity error;
        assert (tb_address_out(25) = '1' and tb_address_out(24) = '0' and tb_address_out(20 downto 2) = "0000000000000000000")
            report "Demais bits do endereco deveriam seguir o mapeamento atual"
            severity error;

        -- Testa requisicao de leitura quando ready esta ativo e nao existe escrita pendente
        tb_ready <= '1';
        wait for clk_period + 1 ns;

        assert (tb_read_req = '1' and tb_write_req = '0')
            report "A interface deveria solicitar leitura quando ready=1 sem escrita pendente"
            severity error;

        wait for clk_period * 2;
        assert (tb_read_req = '1' and tb_write_req = '0')
            report "read_out deveria continuar ativo enquanto ready permanecer em 1"
            severity error;

        -- Testa aceite da leitura pelo controlador
        tb_ready <= '0';
        wait for clk_period + 1 ns;

        assert (tb_read_req = '0' and tb_write_req = '0')
            report "read_out deveria cair quando o controlador aceita a leitura"
            severity error;

        -- Testa retorno para estado de espera e nova leitura automatica
        tb_ready <= '1';
        wait for clk_period + 1 ns;

        assert (tb_read_req = '0' and tb_write_req = '0')
            report "A interface deveria voltar para o estado de espera apos a leitura"
            severity error;

        wait for clk_period + 1 ns;
        assert (tb_read_req = '1' and tb_write_req = '0')
            report "Sem escrita pendente, a proxima requisicao deveria ser leitura"
            severity error;

        -- Finaliza a leitura antes de testar escrita
        tb_ready <= '0';
        wait for clk_period + 1 ns;
        tb_ready <= '1';
        wait for clk_period + 1 ns;

        -- Testa escrita agendada pelo botao enquanto ready esta em '0'
        tb_ready <= '0';
        tb_data_in_write <= "0111";
        wait for clk_period;
        tb_key_3 <= '0';
        wait for clk_period;
        tb_key_3 <= '1';
        wait for clk_period;

        assert (tb_read_req = '0' and tb_write_req = '0')
            report "Botao KEY_3 durante ready=0 deveria apenas agendar a escrita"
            severity error;

        tb_ready <= '1';
        wait for clk_period + 1 ns;

        assert (tb_write_req = '1' and tb_read_req = '0')
            report "Escrita pendente deveria ter prioridade quando ready volta para 1"
            severity error;
        assert (tb_data_out_write = "00000111")
            report "Dado de escrita deveria refletir data_in_write atual"
            severity error;

        -- Testa aceite da escrita pelo controlador
        tb_ready <= '0';
        wait for clk_period + 1 ns;

        assert (tb_write_req = '0' and tb_read_req = '0')
            report "write_out deveria cair quando o controlador aceita a escrita"
            severity error;

        -- Testa reset durante uma requisicao ativa
        tb_ready <= '1';
        wait for clk_period + 1 ns;
        wait for clk_period + 1 ns;
        tb_rst <= '1';
        wait for clk_period + 1 ns;

        assert (tb_write_req = '0' and tb_read_req = '0')
            report "Reset deveria cancelar requisicoes ativas"
            severity error;

        tb_rst <= '0';
        wait for clk_period;

        write(line_out, string'("Teste concluido sem erros"));
        writeline(output, line_out);

        sim_finished <= true;
        wait;
    end process;
end Behavioral;
