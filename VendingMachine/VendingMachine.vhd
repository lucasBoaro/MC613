library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity VendingMachine is
	port (
		SW : in std_logic_vector(9 downto 0);
		KEY: in std_logic_vector(1 downto 0);
		
		LEDR: out std_logic_vector(1 downto 0);
		HEX5: out std_logic_vector(6 downto 0);
		HEX3: out std_logic_vector(6 downto 0);
		HEX2: out std_logic_vector(6 downto 0); 
		HEX1: out std_logic_vector(6 downto 0); 
		HEX0: out std_logic_vector(6 downto 0)
	);
	
end entity;

architecture estrutural of VendingMachine is
	signal fioSaidaSelProd : std_logic_vector(3 downto 0);
	
begin

	instanciaSelProd: entity work.seletor_produto
		port map (
			BIN_PRODUTO => SW(3 downto 0),
			BIN_OUT => fioSaidaSelProd,
			KEY_CONFIRM => KEY(0),
			KEY_CANCEL => KEY(1)
		);
		
		
	instanciaBin2Hex: entity work.bin2hex
		port map (
			BIN => fioSaidaSelProd,
			HEX => HEX5
		);
			
		
		