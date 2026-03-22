library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gerenciadorProduto_tb is
-- Entidade de testbench é sempre vazia
end gerenciadorProduto_tb;

architecture behavior of gerenciadorProduto_tb is

    -- 1. Declaração do Componente a ser testado
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

    -- 2. Sinais internos para conectar ao componente
    signal tb_CLK           : std_logic := '0';
    signal tb_BIN_PRODUTO   : std_logic_vector(3 downto 0) := (others => '0');
    signal tb_BIN_VALOR_IN  : std_logic_vector(7 downto 0) := (others => '0');
    signal tb_KEY_CANCELA   : std_logic := '0';
    signal tb_KEY_CONFIRM   : std_logic := '0';
    signal tb_BIN_VALOR_OUT : std_logic_vector(10 downto 0);
    signal tb_BIN_TROCO     : std_logic;
    signal tb_BIN_FIM_VENDA : std_logic;

    -- Período do clock (50 MHz = 20 ns)
    constant clk_period : time := 20 ns;

begin

    -- 3. Instanciando o Componente (Unit Under Test - UUT)
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

    -- 4. Processo Gerador de Clock
    clk_process : process
    begin
        tb_CLK <= '0';
        wait for clk_period/2;
        tb_CLK <= '1';
        wait for clk_period/2;
    end process;

    -- 5. Processo de Estímulos (A "Historinha" do usuário)
    stim_proc: process
    begin
        -- INÍCIO: Dá um reset inicial para garantir que tudo comece zerado
        tb_KEY_CANCELA <= '1';
        wait for 40 ns;
        tb_KEY_CANCELA <= '0';
        wait for 40 ns;

        -------------------------------------------------------------
        -- CENÁRIO 1: Compra exata (Sem Troco)
        -- Escolhendo Produto 1 ("0001" -> Valor: 300)
        -------------------------------------------------------------
        tb_BIN_PRODUTO <= "0001"; 
        wait for 40 ns;
        
        -- Aperta Confirmar para escolher o produto
        tb_KEY_CONFIRM <= '1';
        wait for 20 ns;
        tb_KEY_CONFIRM <= '0';
        wait for 40 ns;
        
        -- Insere 150 de dinheiro
        tb_BIN_VALOR_IN <= std_logic_vector(to_unsigned(150, 8));
        wait for 20 ns;
        -- Aperta Confirmar para adicionar o dinheiro
        tb_KEY_CONFIRM <= '1';
        wait for 20 ns;
        tb_KEY_CONFIRM <= '0';
        wait for 40 ns; -- Neste momento a tela deve mostrar que faltam 150

        -- Insere mais 150 de dinheiro
        tb_BIN_VALOR_IN <= std_logic_vector(to_unsigned(150, 8));
        wait for 20 ns;
        tb_KEY_CONFIRM <= '1';
        wait for 20 ns;
        tb_KEY_CONFIRM <= '0';
        
        -- Espera para ver a venda finalizada (FIM_VENDA = 1, TROCO = 0)
        wait for 100 ns; 
        
        -- Dá um reset manual (KEY_CANCELA) para ir direto para o próximo teste
        -- (Isso evita termos que simular os 50 milhões de ciclos do seu timer de 1 segundo)
        tb_KEY_CANCELA <= '1'; wait for 20 ns; tb_KEY_CANCELA <= '0'; wait for 40 ns;

        -------------------------------------------------------------
        -- CENÁRIO 2: Compra com Troco
        -- Escolhendo Produto 2 ("0010" -> Valor: 175)
        -------------------------------------------------------------
        tb_BIN_PRODUTO <= "0010";
        wait for 40 ns;
        
        -- Aperta Confirmar para escolher o produto
        tb_KEY_CONFIRM <= '1'; wait for 20 ns; tb_KEY_CONFIRM <= '0'; wait for 40 ns;
        
        -- Cliente insere 200 de dinheiro de uma vez
        tb_BIN_VALOR_IN <= std_logic_vector(to_unsigned(200, 8));
        wait for 20 ns;
        tb_KEY_CONFIRM <= '1'; wait for 20 ns; tb_KEY_CONFIRM <= '0';
        
        -- Espera para ver a venda finalizada (FIM_VENDA = 1, TROCO = 1)
        wait for 100 ns;
        
        -- Reset manual para o próximo teste
        tb_KEY_CANCELA <= '1'; wait for 20 ns; tb_KEY_CANCELA <= '0'; wait for 40 ns;

        -------------------------------------------------------------
        -- CENÁRIO 3: Desistência no meio da operação (Cancela)
        -- Escolhendo Produto 4 ("0100" -> Valor: 225)
        -------------------------------------------------------------
        tb_BIN_PRODUTO <= "0100";
        wait for 40 ns;
        
        -- Confirma o produto
        tb_KEY_CONFIRM <= '1'; wait for 20 ns; tb_KEY_CONFIRM <= '0'; wait for 40 ns;
        
        -- Cliente insere apenas 100 de dinheiro
        tb_BIN_VALOR_IN <= std_logic_vector(to_unsigned(100, 8));
        wait for 20 ns;
        tb_KEY_CONFIRM <= '1'; wait for 20 ns; tb_KEY_CONFIRM <= '0'; wait for 100 ns;
        -- Neste momento faltariam 125 para pagar...
        
        -- Mas o cliente desiste e aperta Cancela
        tb_KEY_CANCELA <= '1'; wait for 20 ns; tb_KEY_CANCELA <= '0';
        
        -- Espera um pouco para observar os sinais voltando para 0
        wait for 100 ns;

        -- Finaliza a simulação
        wait;
        
    end process;

end behavior;