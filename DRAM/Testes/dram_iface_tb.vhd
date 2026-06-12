library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity dram_iface_tb is
end dram_iface_tb;

architecture behavior of dram_iface_tb is

    signal tb_clk             : std_logic := '0';
    signal tb_rst             : std_logic := '0';
    signal tb_address_in      : std_logic_vector(5 downto 0) := (others => '0');
    signal tb_data_in_write   : std_logic_vector(3 downto 0) := (others => '0');
    signal tb_key_3           : std_logic := '1';
    signal tb_ready           : std_logic := '0';

    signal tb_address_out     : std_logic_vector(25 downto 0);
    signal tb_data_out_write  : std_logic_vector(7 downto 0);
    signal tb_write_req       : std_logic;
    signal tb_read_req        : std_logic;

    signal sim_finished       : boolean := false;
    constant clk_period       : time := 7 ns;

    subtype dram_addr_out_t is std_logic_vector(25 downto 0);

    function mapped_address(addr : std_logic_vector(5 downto 0))
        return dram_addr_out_t is
        variable result : dram_addr_out_t := (others => '0');
    begin
        result(0)  := addr(0);
        result(1)  := addr(1);
        result(21) := addr(2);
        result(22) := addr(3);
        result(23) := addr(4);
        result(25) := addr(5);
        return result;
    end function;

begin

    UUT: entity work.dram_iface
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

    clk_process : process
    begin
        while not sim_finished loop
            tb_clk <= '0';
            wait for clk_period / 2;
            tb_clk <= '1';
            wait for clk_period / 2;
        end loop;
        wait;
    end process;

    stim_proc: process
        procedure wait_cycles(cycles : positive) is
        begin
            for i in 1 to cycles loop
                wait until rising_edge(tb_clk);
            end loop;
            wait for 1 ns;
        end procedure;
    begin
        tb_rst <= '1';
        wait_cycles(2);
        tb_rst <= '0';
        wait_cycles(1);

        assert tb_write_req = '0' and tb_read_req = '0'
            report "Reset deveria deixar read_out/write_out em '0'"
            severity error;

        tb_address_in <= "101011";
        tb_data_in_write <= "1101";
        wait for 1 ns;

        assert tb_address_out = mapped_address(tb_address_in)
            report "Mapeamento de endereco nao corresponde ao dram_iface atual"
            severity error;
        assert tb_data_out_write = "00001101"
            report "Mapeamento de dado de escrita deveria zerar bits 7 downto 4"
            severity error;

        -- Sem escrita pendente, ready='1' dispara leitura e a mantem ate ready cair.
        tb_ready <= '1';
        wait_cycles(1);
        assert tb_read_req = '1' and tb_write_req = '0'
            report "Com ready='1' e sem escrita pendente, deveria solicitar leitura"
            severity error;

        wait_cycles(2);
        assert tb_read_req = '1' and tb_write_req = '0'
            report "Req_read deve permanecer ativo enquanto ready continuar em '1'"
            severity error;

        tb_ready <= '0';
        wait_cycles(1);
        assert tb_read_req = '0' and tb_write_req = '0'
            report "Depois do controlador aceitar a leitura, os requests deveriam cair"
            severity error;

        tb_ready <= '1';
        wait_cycles(1);
        assert tb_read_req = '0' and tb_write_req = '0'
            report "Ao concluir wait_read, a interface deve voltar para Wait_ready"
            severity error;

        wait_cycles(1);
        assert tb_read_req = '1' and tb_write_req = '0'
            report "Apos voltar a Wait_ready com ready='1', deve emitir nova leitura"
            severity error;

        tb_ready <= '0';
        wait_cycles(1);
        tb_ready <= '1';
        wait_cycles(1);

        -- Uma borda de descida em KEY_3 durante ready='0' agenda escrita.
        tb_ready <= '0';
        tb_data_in_write <= "0111";
        wait_cycles(1);
        tb_key_3 <= '0';
        wait_cycles(1);
        tb_key_3 <= '1';
        wait_cycles(1);

        assert tb_read_req = '0' and tb_write_req = '0'
            report "KEY_3 durante ready='0' deve apenas agendar a escrita"
            severity error;

        tb_ready <= '1';
        wait_cycles(1);
        assert tb_write_req = '1' and tb_read_req = '0'
            report "Escrita pendente deveria ter prioridade quando ready voltar a '1'"
            severity error;
        assert tb_data_out_write = "00000111"
            report "Dado de escrita deve refletir os switches atuais"
            severity error;

        tb_ready <= '0';
        wait_cycles(1);
        assert tb_write_req = '0' and tb_read_req = '0'
            report "Depois do controlador aceitar a escrita, write_out deveria cair"
            severity error;

        tb_ready <= '1';
        wait_cycles(1);
        assert tb_write_req = '0' and tb_read_req = '0'
            report "Ao concluir wait_write, a interface deve voltar para Wait_ready"
            severity error;

        wait_cycles(1);
        assert tb_read_req = '1' and tb_write_req = '0'
            report "Sem nova escrita pendente, a proxima requisicao deve ser leitura"
            severity error;

        tb_rst <= '1';
        wait_cycles(1);
        assert tb_write_req = '0' and tb_read_req = '0'
            report "Reset deveria cancelar requisicao ativa"
            severity error;

        tb_rst <= '0';
        wait_cycles(1);

        assert false report "dram_iface_tb concluido com sucesso" severity note;
        sim_finished <= true;
        wait;
    end process;

end behavior;
