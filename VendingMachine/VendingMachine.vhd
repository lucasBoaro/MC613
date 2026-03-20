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
	signal fioBCD : std_logic_vector(15 downto 0);
	signal fioHex3 : std_logic_vector(3 downto 0);
	signal fioHex2 : std_logic_vector(3 downto 0);
	signal fioHex1 : std_logic_vector(3 downto 0);
	signal fioHex0 : std_logic_vector(3 downto 0);
	
	
begin

	instanciaSelProd: entity work.seletor_produto
		port map (
			BIN_PRODUTO => SW(3 downto 0),
			BIN_OUT => fioSaidaSelProd,
			KEY_CONFIRM => KEY(0)
		);
		
------------------ instancias bin2hex-----------------------		
	instanciaBin2Hex: entity work.bin2hex
		port map (
			BIN => fioSaidaSelProd,
			HEX => HEX5
		);
		
		instanciaHex3: entity work.bin2hex
		port map (
			BIN => fioBDC(15 downto 12)
			HEX => HEX3
		)
		
	instanciaHex2: entity work.bin2hex
		port map (
			BIN => fioBDC(11 downto 8)
			HEX => HEX2
		)
		
	instanciaHex1: entity work.bin2hex
		port map (
			BIN => fioBDC(7 downto 4)
			HEX => HEX1
		)

	instanciaHex0: entity work.bin2hex
		port map (
			BIN => fioBDC(3 downto 0)
			HEX => HEX02
		)
--------------------------------------------------------------
		
	instanciaBin11toBcd: entity work.bin11_to_bcd4
		port map (
			bin => 
			bcd => fioBCD
		);
		
		
		
end architecture;		