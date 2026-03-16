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

	instanciaSelProd: entity work.SelecionarProduto
		port map (
			IN_BIN => SW(3 downto 0),
			OUT_BIN => fioSaidaSelProd,
			KEY => KEY(0)
		);
		
		
	instanciaBin2Hex: entity work.bin2hex
		port map (
			BIN => fioSaidaSelProd,
			HEX => HEX5
		);
			
		
		