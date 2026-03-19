library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

entity seletor_produto_tb is
end seletor_produto_tb;

architecture Behavioral of seletor_produto_tb is
    component seletor_produto
        Port (
           KEY_CONFIRM: in  std_logic;                    
			  BIN_PRODUTO: in  std_logic_vector(3 downto 0); 
			  BIN_OUT: out std_logic_vector(3 downto 0) 
        );
    end component;
    
    signal test_input : STD_LOGIC_VECTOR(3 downto 0);
	 signal test_key : STD_LOGIC;
    signal test_output : STD_LOGIC_VECTOR(3 downto 0);
begin
    uut: seletor_produto
        port map (
            BIN_PRODUTO => test_input,
				KEY_CONFIRM => test_key,
            BIN_OUT => test_output
        );
    
    test_process: process
        variable line_out : line;
    begin
        write(line_out, string'("Testando seletor_produto..."));
        writeline(output, line_out);
        
        -- Loop de 0 a 15
		  write(line_out, string'("Teste sem clicar "));
		  writeline(output, line_out);
        for i in 0 to 15 loop
            test_input <= STD_LOGIC_VECTOR(to_unsigned(i, 4));
            wait for 10 ns;  -- Aguarda para o sinal estabilizar
            write(line_out, string'("Entrada: "));
            hwrite(line_out, test_input);
            write(line_out, string'(" | Saída: "));
            write(line_out, test_output);
            writeline(output, line_out);
        end loop;
		  
		  write(line_out, string'("Teste clicando e não soltando "));
		  writeline(output, line_out);		  
		  test_key <= '0';
		  wait for 5 ns;
		  for i in 0 to 15 loop
            test_input <= STD_LOGIC_VECTOR(to_unsigned(i, 4));
            wait for 10 ns;  -- Aguarda para o sinal estabilizar
            write(line_out, string'("Entrada: "));
            hwrite(line_out, test_input);
            write(line_out, string'(" | Saída: "));
            write(line_out, test_output);
            writeline(output, line_out);
        end loop;
		
		  write(line_out, string'("Teste depois de soltar "));
		  writeline(output, line_out);
		  test_key <= '1';
		  wait for 5 ns;
		  for i in 0 to 15 loop
            test_input <= STD_LOGIC_VECTOR(to_unsigned(i, 4));
            wait for 10 ns;  -- Aguarda para o sinal estabilizar
            write(line_out, string'("Entrada: "));
            hwrite(line_out, test_input);
            write(line_out, string'(" | Saída: "));
            write(line_out, test_output);
            writeline(output, line_out);
        end loop;
		  
		  write(line_out, string'("Teste clicar de novo"));
		  writeline(output, line_out);
		  test_key <= '0';
		  wait for 5 ns;
		  test_key <= '1';
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