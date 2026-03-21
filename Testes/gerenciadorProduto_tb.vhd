library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

entity gerenciadorProduto_tb is
end gerenciadorProduto_tb;

architecture Behavioral of gerenciadorProduto_tb is

    -- Component declaration for the Unit Under Test (UUT)
    component gerenciadorProduto
        Port (
            CLK : in std_logic;
        BIN_PRODUTO     : in  std_logic_vector(3 downto 0); -- No top-level, temos que fazer essa entrada receber um signal. Se fizermos conexão direta com a saída do selecionar produto, ele vai ignorar a troca de estado
        BIN_VALOR_IN    : in  std_logic_vector(7 downto 0);
        KEY_CANCELA     : in  std_logic;
        KEY_CONFIRM     : in  std_logic;
        BIN_VALOR_OUT   : out std_logic_vector(10 downto 0);
        BIN_TROCO       : out std_logic := '0';
        BIN_FIM_VENDA   : out std_logic := '0'
        );
    end component;

    -- Signals to connect to the UUT
    signal teste_clk : std_logic := '0';
    signal teste_bin_produto : std_logic_vector(3 downto 0) := (others => '0');
    signal teste_bin_valor_in : std_logic_vector(7 downto 0) := (others => '0');
    signal teste_key_cancela : std_logic := '0';
    signal teste_key_confirm : std_logic := '0';
    signal teste_bin_valor_out : std_logic_vector(10 downto 0);
    signal teste_bin_troco : std_logic := '0';
    signal teste_bin_fim_venda : std_logic := '0';

begin
    -- Instantiate the Unit Under Test (UUT)
    uut: gerenciadorProduto
        port map (
            CLK => teste_clk,
            BIN_PRODUTO => teste_bin_produto,
            BIN_VALOR_IN => teste_bin_valor_in,
            KEY_CANCELA => teste_key_cancela,
            KEY_CONFIRM => teste_key_confirm,
            BIN_VALOR_OUT => teste_bin_valor_out,
            BIN_TROCO => teste_bin_troco,
            BIN_FIM_VENDA => teste_bin_fim_venda
        );

    clk_process :process
    begin
        while true loop
            teste_clk <= '0';
            wait for 10 ns;
            teste_clk <= '1';
            wait for 10 ns;
        end loop;
    end process;

    
    test_process: process
        variable line_out : line;
    begin
        write(line_out, string'("Testando gerenciadorProduto..."));
        writeline(output, line_out);
        
        -- Teste 1: Selecionar produto e inserir valor do produto
        write(line_out, string'("Teste 1: Selecionar produto e inserir valor correto do produto"));
        writeline(output, line_out);
        
        teste_bin_produto <= "0001"; -- Seleciona o produto com preço 300
        wait for 20 ns; -- Aguarda para o sinal estabilizar
        --gerenciadorProduto não deve ter acesso à key confirma, código está errado,
        -- tem que ser o processo de selecionarValor que tem acesso a key confirma, 
        --e o gerenciadorProduto tem que ler o valor do produto selecionado e o valor inserido, 
        --comparar e decidir se a venda é finalizada ou se tem que devolver troco. 
        
        teste_bin_valor_in <= "10010110"; -- Insere R$ 3.00 (300 em decimal)
        wait for 20 ns;     
        
        
        write(line_out, string'("Valor do Produto (em decimal): "));
        hwrite(line_out, teste_bin_valor_out);
        write(line_out, string'(" | Troco: "));
        write(line_out, teste_bin_troco);
        write(line_out, string'(" | Fim da Venda: "));
        write(line_out, teste_bin_fim_venda);
        writeline(output, line_out);
        