LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY VGA_Controller IS
  port (
    -- Entradas de Controle de Clock e Reset
    pixel_clk    : IN  STD_LOGIC;                     -- Clock de 25.175 MHz gerado pelo PLL
    reset_n      : IN  STD_LOGIC;                     -- Reset assíncrono (ativo baixo)

    -- Entradas de Cor (vindos da PPU)
    r_in         : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);  -- Intensidade do vermelho do pixel atual
    g_in         : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);  -- Intensidade do verde do pixel atual
    b_in         : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);  -- Intensidade do azul do pixel atual

    -- Saídas de Controle Interno (enviados para a PPU)
    pixel_x      : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);  -- Coordenada X atual
    pixel_y      : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);  -- Coordenada Y atual
    video_active : OUT STD_LOGIC;                     -- '1' se estiver dentro da área visível (Active Video)

    -- Saídas Físicas (conectadas aos pinos da DE1-SoC)
    VGA_R        : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);  -- Saída VGA Vermelha
    VGA_G        : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);  -- Saída VGA Verde
    VGA_B        : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);  -- Saída VGA Azul
    VGA_HS       : OUT STD_LOGIC;                     -- Sincronismo Horizontal
    VGA_VS       : OUT STD_LOGIC;                     -- Sincronismo Vertical
    VGA_BLANK_N  : OUT STD_LOGIC;                     -- Fora da área visível (ou seja, deve ser '0' no blanking)
    VGA_SYNC_N   : OUT STD_LOGIC;                     -- Sincronização de vídeo (fixo em '1')
    VGA_CLK      : OUT STD_LOGIC                      -- Clock do pixel (espelho do pixel_clk)
  );
END VGA_Controller;

architecture Behavioral of VGA_Controller is
  
  signal h_counter : integer range 0 to 799 := 0;  -- Contador horizontal (0-799)
  signal v_counter : integer range 0 to 523 := 0;  -- Contador vertical (0-523)

  