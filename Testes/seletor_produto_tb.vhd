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
                CLK: in std_logic;
				KEY_CONFIRM: in  std_logic;
				BIN_PRODUTO: in  std_logic_vector(3 downto 0); 
				BIN_OUT: out std_logic_vector(3 downto 0);
                BIN_FIM_VENDA: in std_logic
        );
    end component;
    
    signal test_clk : std_logic := '0';
    signal test_input : STD_LOGIC_VECTOR(3 downto 0);
    signal test_confirm : STD_LOGIC;
    signal test_output : STD_LOGIC_VECTOR(3 downto 0);
    signal test_fim_venda : STD_LOGIC;

    constant clk_period     : time := 20 ns;
begin
    uut: seletor_produto
        port map (
            CLK => test_clk,
            BIN_PRODUTO => test_input,
			KEY_CONFIRM => test_confirm,
            BIN_OUT => test_output,
            BIN_FIM_VENDA => test_fim_venda
        );
    
    test_process: process
        variable line_out : line;
    begin
        write(line_out, string'("Testando seletor_produto..."));
        writeline(output, line_out);
        
        -- Loop de 0 a 15
		  write(line_out, string'("Teste sem clicar "));  --Espera-se como saída BIN_OUT = BIN_PRODUTO
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
		  
		  write(line_out, string'("Teste clicando e não soltando "));  --Espera-se como saída BIN_OUT = BIN_PRODUTO
		  writeline(output, line_out);		  
		  test_confirm <= '0';
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
		
		  write(line_out, string'("Teste depois de soltar "));  --Espera-se como saída BIN_OUT = último BIN_PRODUTO escolhido
		  writeline(output, line_out);
		  test_confirm <= '1';
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
		  
		  write(line_out, string'("Teste clicar de novo"));  --Espera-se como saída BIN_OUT = último BIN_PRODUTO escolhido
		  writeline(output, line_out);
		  test_confirm <= '0';
		  wait for 5 ns;
		  test_confirm <= '1';
		  for i in 0 to 15 loop
            test_input <= STD_LOGIC_VECTOR(to_unsigned(i, 4));
            wait for 10 ns;  -- Aguarda para o sinal estabilizar
            write(line_out, string'("Entrada: "));
            hwrite(line_out, test_input);
            write(line_out, string'(" | Saída: "));
            write(line_out, test_output);
            writeline(output, line_out);
        end loop;
		  
		  write(line_out, string'("Teste apertando cancela"));  --Espera-se como saída BIN_OUT = BIN_PRODUTO
		  writeline(output, line_out);
		  test_fim_venda <= '0';
		  for i in 0 to 15 loop
            test_input <= STD_LOGIC_VECTOR(to_unsigned(i, 4));
            wait for 10 ns;  -- Aguarda para o sinal estabilizar
            write(line_out, string'("Entrada: "));
            hwrite(line_out, test_input);
            write(line_out, string'(" | Saída: "));
            write(line_out, test_output);
            writeline(output, line_out);
        end loop;

          write(line_out, string'("Teste apertando cancela"));  --Espera-se como saída BIN_OUT = BIN_PRODUTO
		  writeline(output, line_out);
		  test_fim_venda <= '1';
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