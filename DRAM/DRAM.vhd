library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Cria a entidade maior, o top level 
entity DRAM is
	port (
        CLK_50     : in  std_logic;
        SW      : in  std_logic_vector(9 downto 0);
        KEY3     : in  std_logic;
        KEY0     : in  std_logic;
        HEX5: out std_logic_vector(6 downto 0);
		HEX4: out std_logic_vector(6 downto 0);
		HEX1: out std_logic_vector(6 downto 0); 
		HEX0: out std_logic_vector(6 downto 0);
        
        -- Conexões para a DRAM 
        DRAM_CS_N : OUT STD_LOGIC;
        DRAM_RAS_N : OUT STD_LOGIC;
        DRAM_CAS_N : OUT STD_LOGIC;
        DRAM_WE_N : OUT STD_LOGIC;
        DRAM_ADDR : OUT STD_LOGIC_VECTOR (12 DOWNTO 0);
        DRAM_CKE : OUT STD_lOGIC;
        DRAM_LDQM : OUT STD_lOGIC;
        DRAM_UDQM : OUT STD_lOGIC;
        DRAM_BA : OUT STD_lOGIC_VECTOR (1 DOWNTO 0);
        DRAM_DQ : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
	
end entity;

architecture Behavioral of DRAM is

    -- Sinais internos
    signal address_in_iface         : std_logic_vector(5 downto 0);
    signal data_in_write_iface   : std_logic_vector(3 downto 0);
    signal ready          : std_logic;
    
    signal address : std_logic_vector(25 downto 0);
    signal data_write  : std_logic_vector(7 downto 0);
    signal bit_write       : std_logic;
    signal bit_read        : std_logic;

    signal clk              : std_logic;

    signal data_hex1 : std_logic_vector(7 downto 0);
    -- Sinais apara evitar o uso de operadores lógicos
    signal bin_in_hex5 : std_logic_vector(3 downto 0);
    signal req_controller : std_logic;

    -- PLL para gerar o clock de pixel
    COMPONENT pll IS
        PORT (
            refclk   : IN  STD_LOGIC := '0';
            rst      : IN  STD_LOGIC := '0';
            outclk_0 : OUT STD_LOGIC;
            locked   : OUT STD_LOGIC
        );
    END COMPONENT;

begin

    bin_in_hex5 <= "00" & SW(9 downto 8);
    req_controller <= bit_write or bit_read;
    -- Instância do PLL para gerar o clock de pixel ( MHz)
    instanciaPLL: pll
        port map (
            refclk   => CLK_50,
            rst      => '0',
            outclk_0 => clk,
            locked   => open
        );

    instancia_dram_iface: entity work.dram_iface
        port map (
            clk => clk,
            rst => not KEY0,
            address => SW(9 downto 4),  
            data_in_write => SW(3 downto 0),
            key_3 => KEY3,
            ready => ready,
            
            data_out_adress => address,
            data_out_write => data_write,
            write_out => bit_write,
            read_out => bit_read
        );

    instancia_bin2hex_addr_hex4: entity work.bin2hex
        port map (
            BIN => SW(7 downto 4),
            HEX => HEX4
        );
    
    instancia_bin2hex_addr_hex5: entity work.bin2hex
        port map (
            BIN => bin_in_hex5, -- Fio limpo, sem concatenação aqui!
            HEX => HEX5
        );

    instancia_bin2hex_data_hex0: entity work.bin2hex
        port map (
            BIN => data_write(3 downto 0),
            HEX => HEX0
        );

    instancia_bin2hex_data_hex1: entity work.bin2hex
        port map (
            BIN => data_hex1(3 downto 0),
            HEX => HEX1
        );

    instancia_dram_controller: entity work.dramController
        port map (
            clk_143 => clk,
            rst => not KEY0,
            address => address,
            data_in => data_write,
            data_out => data_hex1,
            req => req_controller,
            ready => ready,
            write_in => bit_write,
            read_in => bit_read,

            DRAM_CS_N => DRAM_CS_N,
            DRAM_RAS_N => DRAM_RAS_N,
            DRAM_CAS_N => DRAM_CAS_N,
            DRAM_WE_N => DRAM_WE_N,
            DRAM_ADDR => DRAM_ADDR,
            DRAM_CKE => DRAM_CKE,
            DRAM_LDQM => DRAM_LDQM,
            DRAM_UDQM => DRAM_UDQM,
            DRAM_BA => DRAM_BA,
            DRAM_DQ => DRAM_DQ
        );
END architecture Behavioral;
