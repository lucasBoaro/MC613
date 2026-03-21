library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

entity gerenciadorProduto_tb is
end gerenciadorProduto_tb;

architecture Behavioral of gerenciadorProduto_tb is
    component gerenciadorProduto
        Port (
            codigoProduto: in  std_logic_vector(3 downto 0);
            valorInserido: in  std_logic_vector(7 downto 0);
            --não temos sinal de cancela
            botaoAvancar: in  std_logic;
            valorAtual: out std_logic_vector(7 downto 0)
        );
    end component;
    
    signal test_codigo : STD_LOGIC_VECTOR(3 downto 0);
    signal test_valor : STD_LOGIC_VECTOR(7 downto 0);
    signal test_cancela : STD_LOGIC;
    signal test_avancar : STD_LOGIC;
    signal test_output : STD_LOGIC_VECTOR(7 downto 0);