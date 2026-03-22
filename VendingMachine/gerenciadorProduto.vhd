library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gerenciadorProduto is
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
end gerenciadorProduto;

architecture behavior of gerenciadorProduto is
    signal valorProduto   : std_logic_vector(10 downto 0);
    signal saldo_inserido : unsigned(10 downto 0) := (others => '0'); -- O 'SAL' do seu diagrama!
    
    -- Flags de controle de estado
    signal em_pagamento   : std_logic := '0';
    signal timer_ativo    : std_logic := '0';
    signal compra_sucesso : std_logic := '0';
    signal troco_ativo    : std_logic := '0';
    
    -- Para a placa real, use 50000000. Para simulação no ModelSim, troque para 5.
    signal contador       : integer range 0 to 5 := 0; 
    
    signal confirm_antigo : std_logic := '0';
    signal cancela_antigo : std_logic := '0';
begin

    -- Tabela de Preços Exata do Enunciado
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
            
    -- Saídas dos LEDs corrigidas
    BIN_FIM_VENDA <= compra_sucesso; -- LEDR0 só acende se a compra deu certo
    BIN_TROCO     <= troco_ativo;    -- LEDR1 acende no troco ou devolução

    -- Mux do Display (Garante que a tela mostre o que o enunciado pede)
    process(timer_ativo, compra_sucesso, em_pagamento, saldo_inserido, valorProduto)
        variable v_prod : unsigned(10 downto 0);
    begin
        v_prod := unsigned(valorProduto);
        if timer_ativo = '1' then
            if compra_sucesso = '1' then
                BIN_VALOR_OUT <= std_logic_vector(saldo_inserido - v_prod); -- Mostra o Troco
            else
                BIN_VALOR_OUT <= std_logic_vector(saldo_inserido); -- Mostra a Devolução (Cancela)
            end if;
        elsif em_pagamento = '1' then
            BIN_VALOR_OUT <= std_logic_vector(v_prod - saldo_inserido); -- Falta pagar (Valor Restante)
        else
            BIN_VALOR_OUT <= valorProduto; -- Escolhendo produto (Preço cheio)
        end if;
    end process;

    -- Lógica Principal (Síncrona)
    process(CLK) 
        variable v_in : unsigned(10 downto 0);
        variable v_novo_saldo : unsigned(10 downto 0);
        variable v_prod : unsigned(10 downto 0);
    begin
        if rising_edge(CLK) then
            confirm_antigo <= KEY_CONFIRM;
            cancela_antigo <= KEY_CANCELA;

            -- 1. Timer de 1 segundo
            if timer_ativo = '1' then
                if contador < 5 then -- ATENÇÃO: Mude para 5 ao rodar no ModelSim!
                    contador <= contador + 1; 
                else
                    timer_ativo <= '0';
                    compra_sucesso <= '0';
                    troco_ativo <= '0';
                    saldo_inserido <= (others => '0');
                    em_pagamento <= '0';
                    contador <= 0; 
                end if;

            else
                -- 2. Lógica de Cancelamento
                if (KEY_CANCELA = '1' and cancela_antigo = '0') then
                    if em_pagamento = '1' then
                        if saldo_inserido > 0 then
                            timer_ativo <= '1';
                            compra_sucesso <= '0'; -- Garante que LEDR0 fique apagado!
                            troco_ativo <= '1';    -- LEDR1 acende (Devolução)
                        else
                            em_pagamento <= '0'; -- Reseta direto se não tem dinheiro
                        end if;
                    end if;

                -- 3. Lógica de Confirmação e Pagamento (SOMA SALDO)
                elsif (KEY_CONFIRM = '1' and confirm_antigo = '0') then
                    
                    if em_pagamento = '0' then
                        em_pagamento <= '1'; -- Trava o produto
                        saldo_inserido <= (others => '0');
                    else
                        v_in := resize(unsigned(BIN_VALOR_IN), 11);
                        
                        if v_in > 0 then -- Ignora cliques se o bloco selecionador mandar 0 (chaves inválidas)
                            v_novo_saldo := saldo_inserido + v_in; -- SAL + VAL !
                            saldo_inserido <= v_novo_saldo;
                            v_prod := unsigned(valorProduto);

                            -- Compara Saldo (SAL ? PRO)
                            if v_novo_saldo >= v_prod then
                                timer_ativo <= '1';
                                compra_sucesso <= '1';
                                if v_novo_saldo > v_prod then
                                    troco_ativo <= '1';
                                else
                                    troco_ativo <= '0';
                                end if;
                            end if;
                        end if;
                    end if;
                end if; 
            end if;
        end if;
    end process;
end behavior;