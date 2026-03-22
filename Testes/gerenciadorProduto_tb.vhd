library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

entity gerenciadorProduto_tb is
end gerenciadorProduto_tb;

architecture behavior of gerenciadorProduto_tb is

    component gerenciadorProduto
        port(
            CLK             : in  std_logic;
            BIN_PRODUTO     : in  std_logic_vector(3 downto 0);
            BIN_VALOR_IN    : in  std_logic_vector(7 downto 0);
            KEY_CANCELA     : in  std_logic;
            KEY_CONFIRM     : in  std_logic;
            BIN_VALOR_OUT   : out std_logic_vector(10 downto 0);
            BIN_TROCO       : out std_logic;
            BIN_FIM_VENDA   : out std_logic
        );
    end component;

    signal tb_CLK           : std_logic := '0';
    signal tb_BIN_PRODUTO   : std_logic_vector(3 downto 0) := (others => '0');
    signal tb_BIN_VALOR_IN  : std_logic_vector(7 downto 0) := (others => '0');
    signal tb_KEY_CANCELA   : std_logic := '0';
    signal tb_KEY_CONFIRM   : std_logic := '0';
    signal tb_BIN_VALOR_OUT : std_logic_vector(10 downto 0);
    signal tb_BIN_TROCO     : std_logic;
    signal tb_BIN_FIM_VENDA : std_logic;

    signal sim_finished     : boolean := false; 
    constant clk_period     : time := 20 ns;

begin

    UUT: gerenciadorProduto port map (
        CLK           => tb_CLK,
        BIN_PRODUTO   => tb_BIN_PRODUTO,
        BIN_VALOR_IN  => tb_BIN_VALOR_IN,
        KEY_CANCELA   => tb_KEY_CANCELA,
        KEY_CONFIRM   => tb_KEY_CONFIRM,
        BIN_VALOR_OUT => tb_BIN_VALOR_OUT,
        BIN_TROCO     => tb_BIN_TROCO,
        BIN_FIM_VENDA => tb_BIN_FIM_VENDA
    );

    clk_process : process  --gerador de clock
    begin
        while not sim_finished loop
            tb_CLK <= '0'; wait for clk_period/2;
            tb_CLK <= '1'; wait for clk_period/2;
        end loop;
        wait;
    end process;

    stim_proc: process
        variable line_out : line;
        
        procedure print_status(msg : string) is  --imprime os valores do display HEX, LEDR0 e LEDR1
        begin
            write(line_out, string'("--- ")); write(line_out, msg); write(line_out, string'(" ---")); writeline(output, line_out);
            write(line_out, string'("Display HEX: ")); write(line_out, to_integer(unsigned(tb_BIN_VALOR_OUT))); write(line_out, string'(" centavos"));
            write(line_out, string'(" | LEDR0 (Produto): ")); write(line_out, tb_BIN_FIM_VENDA);
            write(line_out, string'(" | LEDR1 (Troco): ")); write(line_out, tb_BIN_TROCO);
            writeline(output, line_out); writeline(output, line_out);
        end procedure;

    begin
        write(line_out, string'("Iniciando Teste...")); writeline(output, line_out); writeline(output, line_out);

        -- RESET INICIAL
        tb_KEY_CANCELA <= '1'; wait for 20 ns; tb_KEY_CANCELA <= '0'; wait for 40 ns;

        -------------------------------------------------------------
        write(line_out, string'("=== CENARIO 1: COMPRA EXATA (SEM TROCO) ===")); writeline(output, line_out);
        
        tb_BIN_PRODUTO <= "0001"; wait for 40 ns;
        tb_KEY_CONFIRM <= '1'; wait for 20 ns; tb_KEY_CONFIRM <= '0'; wait for 40 ns;
        print_status("Produto Escolhido (Valor 300)");
			--Saída esperada: HEX = 300, LEDR0 = 0 e LEDR1 = 0
			
        tb_BIN_VALOR_IN <= std_logic_vector(to_unsigned(200, 8)); -- R$ 2,00
        tb_KEY_CONFIRM <= '1'; wait for 20 ns; tb_KEY_CONFIRM <= '0'; wait for 40 ns;
        print_status("Inserido 200");
			--Saída esperada: HEX = 100, LEDR0 = 0 e LEDR1 = 0
		  
        tb_BIN_VALOR_IN <= std_logic_vector(to_unsigned(100, 8)); -- R$ 1,00
        tb_KEY_CONFIRM <= '1'; wait for 20 ns; tb_KEY_CONFIRM <= '0'; wait for 40 ns;
        print_status("Inserido 100 (Total pago)");
			--Saída esperada: HEX = 0, LEDR0 = 1 e LEDR1 = 0
		  
        wait for 200 ns; -- Aguarda o timer do auto-reset

        -------------------------------------------------------------
        write(line_out, string'("=== CENARIO 2: COMPRA COM TROCO ===")); writeline(output, line_out);
        
        tb_BIN_PRODUTO <= "0010"; wait for 40 ns;
        tb_KEY_CONFIRM <= '1'; wait for 20 ns; tb_KEY_CONFIRM <= '0'; wait for 40 ns;
        print_status("Produto Escolhido (Valor 175)");
			--Saída esperada: HEX = 175, LEDR0 = 0 e LEDR1 = 0

        tb_BIN_VALOR_IN <= std_logic_vector(to_unsigned(200, 8)); -- R$ 2,00
        tb_KEY_CONFIRM <= '1'; wait for 20 ns; tb_KEY_CONFIRM <= '0'; wait for 40 ns;
        print_status("Inserido 200 (Deve liberar produto e dar troco de 25)");
			--Saída esperada: HEX = 25, LEDR0 = 1 e LEDR1 = 1

        wait for 200 ns; -- Aguarda o timer do auto-reset

        -------------------------------------------------------------
        write(line_out, string'("=== CENARIO 3: CANCELA E DEVOLVE DINHEIRO ===")); writeline(output, line_out);
        
        tb_BIN_PRODUTO <= "0100"; wait for 40 ns;
        tb_KEY_CONFIRM <= '1'; wait for 20 ns; tb_KEY_CONFIRM <= '0'; wait for 40 ns;
        print_status("Produto Escolhido (Valor 225)");
			--Saída esperada: HEX = 225, LEDR0 = 0 e LEDR1 = 0
		  
        tb_BIN_VALOR_IN <= std_logic_vector(to_unsigned(50, 8)); -- R$ 0,50
        tb_KEY_CONFIRM <= '1'; wait for 20 ns; tb_KEY_CONFIRM <= '0'; wait for 40 ns;
        print_status("Inserido 50");
			--Saída esperada: HEX = 175, LEDR0 = 0 e LEDR1 = 0

			tb_BIN_VALOR_IN <= std_logic_vector(to_unsigned(100, 8)); -- R$ 1,00
        tb_KEY_CONFIRM <= '1'; wait for 20 ns; tb_KEY_CONFIRM <= '0'; wait for 40 ns;
        print_status("Inserido 100 (Total guardado = 150)");
			--Saída esperada: HEX = 75, LEDR0 = 0 e LEDR1 = 0
		  
        tb_KEY_CANCELA <= '1'; wait for 20 ns; tb_KEY_CANCELA <= '0'; wait for 40 ns;
        print_status("Apertou CANCELA (Deve devolver 150. Produto DEVE SER '0')");
			--Saída esperada: HEX = 150, LEDR0 = 0 e LEDR1 = 1

        wait for 200 ns; -- Aguarda o timer do auto-reset

        -------------------------------------------------------------
        write(line_out, string'("Teste concluido com sucesso!"));
        writeline(output, line_out);
        
        sim_finished <= true; 
        wait;
    end process;
end behavior;