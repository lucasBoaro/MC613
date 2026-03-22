library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gerenciadorProduto is
    port(
        CLK : in std_logic;
        BIN_PRODUTO     : in  std_logic_vector(3 downto 0); -- No top-level, temos que fazer essa entrada receber um signal. Se fizermos conexão direta com a saída do selecionar produto, ele vai ignorar a troca de estado
        BIN_VALOR_IN    : in  std_logic_vector(7 downto 0);
        KEY_CANCELA     : in  std_logic;
        KEY_CONFIRM     : in  std_logic;
        BIN_VALOR_OUT   : out std_logic_vector(10 downto 0);
        BIN_TROCO       : out std_logic := '0';
        BIN_FIM_VENDA   : out std_logic := '0'
    );
end gerenciadorProduto;

architecture behavior of gerenciadorProduto is
    signal valorProduto    : std_logic_vector(10 downto 0);
    signal primeiroAvancar : std_logic := '1'; --Flag para indicar que é o primeiro ciclo desse estado
    signal valorAtual      : std_logic_vector(10 downto 0) := (others => '0');
    signal vendaFinalizada : std_logic := '0';
    signal devolverTroco   : std_logic := '0';
    signal contador        : integer range 0 to 50000000 := 0;
    signal confirm_antigo  : std_logic := '0';
    signal cancela_antigo  : std_logic := '0';

begin

    with BIN_PRODUTO select
        valorProduto <= 
            std_logic_vector(to_unsigned(125, 11)) when "0000",
            std_logic_vector(to_unsigned(300, 11)) when "0001",
            std_logic_vector(to_unsigned(175, 11)) when "0010",
            std_logic_vector(to_unsigned(450, 11)) when "0011",
            std_logic_vector(to_unsigned(225, 11)) when "0100",
            std_logic_vector(to_unsigned(350, 11)) when "0101",
            std_logic_vector(to_unsigned(250, 11)) when "0110",
            std_logic_vector(to_unsigned(425, 11)) when "0111",
            std_logic_vector(to_unsigned(500, 11)) when "1000",
            std_logic_vector(to_unsigned(325, 11)) when "1001",
            std_logic_vector(to_unsigned(600, 11)) when "1010",
            std_logic_vector(to_unsigned(275, 11)) when "1011",
            std_logic_vector(to_unsigned(700, 11)) when "1100",
            std_logic_vector(to_unsigned(475, 11)) when "1101",
            std_logic_vector(to_unsigned(525, 11)) when "1110",
            std_logic_vector(to_unsigned(800, 11)) when "1111", 
            std_logic_vector(to_unsigned(0, 11))   when others; 
    
    BIN_VALOR_OUT <= valorProduto when primeiroAvancar = '1' else valorAtual; --Essa linha roda em paralelo, mostra do valor do produto desejado. Deixa o valor fixo quando aperta confirmar.
    BIN_FIM_VENDA <= vendaFinalizada;
    BIN_TROCO <= devolverTroco;

    process(CLK, KEY_CANCELA)
        variable v_in_extendido : unsigned(10 downto 0); -- Valor inserido pelo cliente, estendido para 11 bits
        variable v_atual  : unsigned(10 downto 0); -- Valor que o cliente tem que pagar, vai diminuindo conforme ele insere dinheiro
        variable v_temp   : unsigned(10 downto 0); -- vetor auxiliar para fazer contas
        variable v_produto : unsigned(10 downto 0); -- Valor do produto selecionado
    begin

        if (rising_edge(CLK)) then
            -- Guarda o estado atual do botão para comparar no próximo ciclo
            confirm_antigo <= KEY_CONFIRM;
            cancela_antigo <= KEY_CANCELA;

            -- Fim da venda, inicia o timer de 1 segundo
            if (vendaFinalizada = '1') then
                if (contador < 50000000) then
                    contador <= contador + 1; -- Vai contando...
                else
                    -- Auto-reset após 1 segundo
                    devolverTroco <= '0';
                    vendaFinalizada <= '0';
                    primeiroAvancar <= '1';
                    valorAtual <= (others => '0');
                    contador <= 0; -- Zera o cronômetro para a próxima venda
                end if;

            else
                --LÓGICA DE CANCELAMENTO (Detector de borda de subida)
                if (KEY_CANCELA = '1' and cancela_antigo = '0') then
                    
                    if (primeiroAvancar = '0') then
                        v_atual   := unsigned(valorAtual);
                        v_produto := unsigned(valorProduto);
                        
                        -- Verifica se o cliente já inseriu algum dinheiro
                        if (v_atual < v_produto) then
                            -- Calcula o dinheiro inserido (Produto - O que ainda falta pagar)
                            v_temp := v_produto - v_atual;
                            
                            -- Mostra o dinheiro sendo devolvido no display
                            valorAtual <= std_logic_vector(v_temp);
                            
                            -- Acende o LED Troco e ativa a flag que inicia o timer de 1 segundo
                            devolverTroco <= '1';
                            vendaFinalizada <= '1'; 
                        else
                            -- Escolheu produto, mas não colocou dinheiro: Reseta instantaneamente
                            primeiroAvancar <= '1';
                            valorAtual <= (others => '0');
                        end if;
                    else
                        -- Apertou Cancela na tela de seleção inicial: Reseta instantaneamente
                        primeiroAvancar <= '1';
                        valorAtual <= (others => '0');
                    end if;

                -- Só faz a conta se o botão Confirmar for '1' agora, mas era '0' 1 ciclo atrás. Para evitar que segurar o botão execute várias vezes a mesma coisa.
                elsif (KEY_CONFIRM = '1' and confirm_antigo = '0') then
                    
                    if (primeiroAvancar = '1') then
                        valorAtual <= valorProduto;
                        primeiroAvancar <= '0';
                        devolverTroco <= '0';
                        vendaFinalizada <= '0';
                    else
                        v_in_extendido := resize(unsigned(BIN_VALOR_IN), 11);
                        v_atual  := unsigned(valorAtual);

                        if (v_in_extendido >= v_atual) then
                            v_temp := v_in_extendido - v_atual;
                            
                            valorAtual <= std_logic_vector(v_temp);
                            vendaFinalizada <= '1'; 
                            
                            if (v_in_extendido > v_atual) then
                                devolverTroco <= '1';
                            else
                                devolverTroco <= '0';
                            end if;
                        else
                            v_temp := v_atual - v_in_extendido;
                            valorAtual <= std_logic_vector(v_temp);
                            devolverTroco <= '0';
                        end if;
                    end if;
                    
                end if; 
            end if;
        end if;
    end process;

end behavior;