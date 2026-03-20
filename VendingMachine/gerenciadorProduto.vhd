library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; -- Necessária para manipulação numérica

entity gerenciadorProduto is
    port(
        codigoProduto    : in  std_logic_vector(3 downto 0);
        valorInserido    : in  std_logic_vector(7 downto 0);
        sinalCancela     : in  std_logic;
        botaoAvancar     : in  std_logic;
        valorAtual       : out std_logic_vector(7 downto 0)
    );
end gerenciadorProduto;

architecture behavior of gerenciadorProduto is
    signal valorProduto : std_logic_vector(7 downto 0); 
begin

    with codigoProduto select
        valorProduto <= 
            std_logic_vector(to_unsigned(125, 8)) when "0000", -- 0 (1,25)
            std_logic_vector(to_unsigned(300, 8)) when "0001", -- 1 (3,00)
            std_logic_vector(to_unsigned(175, 8)) when "0010", -- 2 (1,75)
            std_logic_vector(to_unsigned(450, 8)) when "0011", -- 3 (4,50)
            std_logic_vector(to_unsigned(225, 8)) when "0100", -- 4 (2,25)
            std_logic_vector(to_unsigned(350, 8)) when "0101", -- 5 (3,50)
            std_logic_vector(to_unsigned(250, 8)) when "0110", -- 6 (2,50)
            std_logic_vector(to_unsigned(425, 8)) when "0111", -- 7 (4,25)
            std_logic_vector(to_unsigned(500, 8)) when "1000", -- 8 (5,00)
            std_logic_vector(to_unsigned(325, 8)) when "1001", -- 9 (3,25)
            std_logic_vector(to_unsigned(600, 8)) when "1010", -- A (6,00)
            std_logic_vector(to_unsigned(275, 8)) when "1011", -- B (2,75)
            std_logic_vector(to_unsigned(700, 8)) when "1100", -- C (7,00)
            std_logic_vector(to_unsigned(475, 8)) when "1101", -- D (4,75)
            std_logic_vector(to_unsigned(525, 8)) when "1110", -- E (5,25)
            std_logic_vector(to_unsigned(800, 8)) when "1111",
            std_logic_vector(to_unsigned(0, 8)) when others; -- F (8,00)

    valorAtual <= valorProduto;


end behavior;