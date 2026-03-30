library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

entity bin2hex_tb is
end bin2hex_tb;

architecture Behavioral of bin2hex_tb is
    component bin2hex
        Port (
            BIN : in STD_LOGIC_VECTOR(3 downto 0);
            HEX : out STD_LOGIC_VECTOR(6 downto 0)
        );
    end component;
    
    signal test_input : STD_LOGIC_VECTOR(3 downto 0);
    signal test_output : STD_LOGIC_VECTOR(6 downto 0);
begin
    uut: bin2hex
        port map (
            BIN => test_input,
            HEX => test_output
        );
    
    test_process: process
        variable line_out : line;
    begin
        write(line_out, string'("Testando bin2hex..."));
        writeline(output, line_out);
        
        -- Loop de 0 a 15
        for i in 0 to 15 loop
            test_input <= STD_LOGIC_VECTOR(to_unsigned(i, 4));
            wait for 10 ns;  -- Aguarda para o sinal estabilizar
            write(line_out, string'("Entrada: "));
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