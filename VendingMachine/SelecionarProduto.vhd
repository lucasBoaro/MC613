-- Módulo que processa o produto e analisa se o produto é 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity SelecionarProduto is 
	Port (
		IN_BIN: in std_logic_vector(3 downto 0);
		KEY: in std_logic;
		OUT_BIN: out std_logic_vector(3 downto 0)
	);
	end entity SelecionarProduto;
	

	
architecture Behavioral of SelecionarProduto is
begin
	process(IN_BIN, KEY)
		if (KEY = '1') then:
			OUT_BIN <= IN_BIN;
		end if;
	end process;
end Behavioral;	
