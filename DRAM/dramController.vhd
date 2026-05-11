LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY dramController is
    PORT(
        clk_143 : IN STD_LOGIC; -- Clk adaptado para a frequencia da dram
        rst : IN STD_LOGIC; --Valor que reinicializa/inicializa a memória
        address : IN STD_LOGIC_VECTOR(25 DOWNTO 0); -- Endereço de leitura/escrita
        data_in : IN STD_LOGICVECTOR(7 DOWNTO 0); --Dado para escrita
        data_out : OUT STD_LOGICVECTOR(7 DOWNTO 0); -- Dado que foi lido
        req : IN STD_LOGIC; -- Indica se há requisição
        wEn : IN STD_LOGIC; -- 
        ready : OUT STD_LOGIC -- Indica que o controlador pode receber uma requisição
    )
END dramController;

architecture behavior of dramController is
    
