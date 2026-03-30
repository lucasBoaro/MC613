library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Cria a entidade maior, o top level VendingMachine
entity VendingMachine is
	port (
		-- Mapeamento das entradas da placa
		CLOCK_50 : in std_logic; 												-- entrada de clock											
		SW : in std_logic_vector(9 downto 0);									-- switches da entrada do valor do produto e valor do dinheiro
		KEY: in std_logic_vector(1 downto 0);									-- botões de confirmar e cancelar
		
		LEDR: out std_logic_vector(1 downto 0);									
		HEX5: out std_logic_vector(6 downto 0);
		HEX3: out std_logic_vector(6 downto 0);
		HEX2: out std_logic_vector(6 downto 0); 
		HEX1: out std_logic_vector(6 downto 0); 
		HEX0: out std_logic_vector(6 downto 0)
	);
	
end entity;

architecture estrutural of VendingMachine is
	signal fioNumProduto : std_logic_vector(3 downto 0);						-- fio que passa o número do produto em binário
	signal fioBCD : std_logic_vector(15 downto 0);								-- fio que passa um valor em BCD
	signal fioValorInserido : std_logic_vector(7 downto 0);						-- fio que passa o valor que foi inserido em binário
	signal fioValorRestanteParaCompra : std_logic_vector(10 downto 0);			-- fio que passa o valor faltante para a compra ou o valor do troco
	signal fioDestravarSelProd : std_logic;
	
begin

	instanciaSelProd: entity work.seletor_produto 		
		port map (		
			CLK => CLOCK_50,
			-- mapeamento das entradas e saídas da entidade selecionarProduto
			BIN_PRODUTO => SW(3 downto 0),
			BIN_OUT => fioNumProduto,
			KEY_CONFIRM => KEY(0),
			BIN_FIM_VENDA => fioDestravarSelProd
		);

	instanciaSelValor: entity work.selecionarValor
		port map(
			-- mapeamento da entrada e saída da entidade selecionarValor
			BIN_SWITCH => SW(9 downto 4),
			BIN_VALOR => fioValorInserido
		);

	instanciaGerenciador: entity work.gerenciadorProduto 
		port map(
			-- mapeamento das entradas e saídas da entidade gerenciadorProduto
			CLK => CLOCK_50,
			BIN_PRODUTO => fioNumProduto,
			BIN_VALOR_IN => fioValorInserido,
			KEY_CANCELA => KEY(1),
			KEY_CONFIRM => KEY(0),
			BIN_VALOR_OUT => fioValorRestanteParaCompra,
			BIN_TROCO => LEDR(1),
			BIN_FIM_VENDA => LEDR(0),
			CMD_DESTRAVAR_SEL_PROD => fioDestravarSelProd
		);
		
------------------ instancias bin2hex-----------------------		
	instanciaBin2Hex: entity work.bin2hex
		port map (
			BIN => fioNumProduto,
			HEX => HEX5
		);
		
		instanciaHex3: entity work.bin2hex
		port map (
			BIN => fioBCD(15 downto 12),
			HEX => HEX3
		);
		
	instanciaHex2: entity work.bin2hex
		port map (
			BIN => fioBCD(11 downto 8),
			HEX => HEX2
		);
		
	instanciaHex1: entity work.bin2hex
		port map (
			BIN => fioBCD(7 downto 4),
			HEX => HEX1
		);

	instanciaHex0: entity work.bin2hex
		port map (
			BIN => fioBCD(3 downto 0),
			HEX => HEX0
		);
--------------------------------------------------------------
		
	instanciaBin11toBcd: entity work.bin11_to_bcd4
		port map (
			-- mapeamento da entrada e saída da entidade bin11_to_bcd4
			bin => fioValorRestanteParaCompra,
			bcd => fioBCD
		);
		
end architecture;		