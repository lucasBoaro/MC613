library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

entity selecionarValor_tb is
end selecionarValor_tb;

architecture Behavioral of selecionarValor_tb is
    component selecionarValor
        Port (
			  BIN_SWITCH: in  std_logic_vector(5 downto 0);  --binário contendo os Switches ligados
			  BIN_VALOR: out std_logic_vector(7 downto 0)    --binário retornando o valor que está sendo inserido
        );
    end component;
    
    signal test_input : STD_LOGIC_VECTOR(5 downto 0);     
    signal test_output : STD_LOGIC_VECTOR(7 downto 0);
begin
    uut: selecionarValor
        port map (
            BIN_SWITCH => test_input,
            BIN_VALOR => test_output
        );
    
    test_process: process
        variable line_out : line;
    begin
-------------------------------------------------------------
        write(line_out, string'("Testando selecionarValor..."));
        writeline(output, line_out);
        
        -- Loop de 0 a 5
		write(line_out, string'("Testa os switches válidos"));  --testa um switch ligado por vez
		writeline(output, line_out);
        for i in 0 to 5 loop
            test_input <= (i => '1', others => '0');
            wait for 10 ns;  -- Aguarda para o sinal estabilizar
            write(line_out, string'("Entrada (em HEX): "));
            hwrite(line_out, test_input);
            write(line_out, string'(" | Saída: "));
            write(line_out, test_output);
            writeline(output, line_out);
        end loop;
		
-------------------------------------------------------------
		write(line_out, string'("Teste todos os switches"));  --testa todas as combinações de switch
		writeline(output, line_out);
        for i in 0 to 63 loop
            test_input <= STD_LOGIC_VECTOR(to_unsigned(i, 6));
            wait for 10 ns;  -- Aguarda para o sinal estabilizar
            write(line_out, string'("Entrada (em HEX): "));
            hwrite(line_out, test_input);
            write(line_out, string'(" | Saída: "));
            write(line_out, test_output);
            writeline(output, line_out);
        end loop;
        
        write(line_out, string'("Teste concluído"));
        writeline(output, line_out);
        wait;
    end process;
end Behavioral;