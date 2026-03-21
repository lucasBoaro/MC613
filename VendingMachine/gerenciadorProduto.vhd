library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gerenciadorProduto is
    port(
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

    process(KEY_CONFIRM, KEY_CANCELA)
            variable v_in_extendido : unsigned(10 downto 0);
            variable v_atual  : unsigned(10 downto 0);
            variable v_temp   : unsigned(10 downto 0);
        begin
            if rising_edge(KEY_CANCELA) then
                BIN_TROCO <= '0';
                BIN_FIM_VENDA <= '0';
                primeiroAvancar <= '1';
                valorAtual <= (others => '0');
                
           elsif rising_edge(KEY_CONFIRM) then
                if (primeiroAvancar = '1') then
                    valorAtual <= valorProduto;
                    primeiroAvancar <= '0';
                    BIN_TROCO <= '0';
                    BIN_FIM_VENDA <= '0';
                else
                    v_in_extendido := resize(unsigned(BIN_VALOR_IN), 11);
                    v_atual  := unsigned(valorAtual);

                    if (v_in_extendido >= v_atual) then
                        v_temp := v_in_extendido - v_atual;
                        
                        valorAtual <= std_logic_vector(v_temp);
                        BIN_FIM_VENDA <= '1';
                        
                        if (v_in_extendido > v_atual) then
                            BIN_TROCO <= '1';
                        else
                            BIN_TROCO <= '0';
                        end if;
                    else
                        v_temp := v_atual - v_in_extendido;
                        valorAtual <= std_logic_vector(v_temp);
                        BIN_TROCO <= '0';
                    end if;
                end if;
            end if;
        end process;

end behavior;