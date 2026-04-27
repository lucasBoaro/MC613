library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

entity rom_tb is
end rom_tb;

architecture Behavioral of rom_tb is
    component rom
        PORT (
            bank_sel : IN STD_LOGIC_VECTOR(1 DOWNTO 0); -- banco: '0' fundo, '10' botão
            addr     : IN STD_LOGIC_VECTOR (12 DOWNTO 0); -- Valor reusltante dos endereços x e y do pixel atual, que indica o valor do tile de fundo ou do botão a ser desenhado
            data_out : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
        );
    end component;
    
    signal tb_bank_sel : STD_LOGIC_VECTOR(1 DOWNTO 0) := (others => '0');
    signal tb_addr     : STD_LOGIC_VECTOR(12 DOWNTO 0) := (others => '0');
    signal tb_data_out : STD_LOGIC_VECTOR(7 DOWNTO 0);

begin

    uut: rom
        port map (
            bank_sel => tb_bank_sel, -- banco: '0' fundo, '10' botão
            addr     => tb_addr, -- Valor reusltante dos endereços x e y do pixel atual, que indica o valor do tile de fundo ou do botão a ser desenhado
            data_out => tb_data_out
        );

    test_process: process
        variable line_out : line;
    begin
        write(line_out, string'("Testando rom..."));
        writeline(output, line_out);

        -- Testa limites do indice para o banco de fundo
        for i in 0 to 8191 loop
            tb_addr <= STD_LOGIC_VECTOR(to_unsigned(i, 13));
            wait for 10 ns; 
            assert (tb_data_out = x"00" or tb_data_out = x"01" or tb_data_out = x"02" or tb_data_out = x"03") report "Erro: data_out fora do esperado para addr = " & integer'image(i) severity error;
            if i > 4799 then
                assert (tb_data_out = x"00") report "data_out não corresponde ao valor esperado para addr = " & integer'image(i) severity error;
            end if;
        end loop;

        -- Testa limites do indice para o banco de botões
        tb_bank_sel <= "10"; -- Muda para o banco de botões
        for i in 0 to 8191 loop
            tb_addr <= STD_LOGIC_VECTOR(to_unsigned(i, 13));
            wait for 10 ns;
            if i > 48 then
                assert (tb_data_out = x"00") report "data_out não corresponde ao valor esperado para addr = " & integer'image(i) severity error;
            end if;
        end loop;

        -- Testa valores específicos para o banco de botões
        tb_bank_sel <= "10"; -- Muda para o banco de botões
        tb_addr <= STD_LOGIC_VECTOR(to_unsigned(0, 13));
        wait for 10 ns;
        assert (tb_data_out = x"00") report "data_out não corresponde ao valor esperado para addr = 0" severity error;
        tb_addr <= STD_LOGIC_VECTOR(to_unsigned(2, 13));
        wait for 10 ns;
        assert (tb_data_out = x"01") report "data_out não corresponde ao valor esperado para addr = 2" severity error;
        tb_addr <= STD_LOGIC_VECTOR(to_unsigned(24, 13));
        wait for 10 ns;
        assert (tb_data_out = x"01") report "data_out não corresponde ao valor esperado para addr = 24" severity error;
        tb_addr <= STD_LOGIC_VECTOR(to_unsigned(48, 13));
        wait for 10 ns;
        assert (tb_data_out = x"00") report "data_out não corresponde ao valor esperado para addr = 48" severity error;
        tb_addr <= STD_LOGIC_VECTOR(to_unsigned(49, 13));
        wait for 10 ns;
        assert (tb_data_out = x"00") report "data_out não corresponde ao valor esperado para addr = 49" severity error;

        write(line_out, string'("Teste concluido sem erros"));
        writeline(output, line_out);
        wait;
    end process;
end Behavioral;