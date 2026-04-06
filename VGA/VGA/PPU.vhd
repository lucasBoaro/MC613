LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY PPU IS
  PORT (
    -- Entradas de Controle de Clock e Reset
    clk          : IN  STD_LOGIC;                     -- Clock principal do sistema
    reset_n      : IN  STD_LOGIC;                     -- Reset assíncrono (ativo baixo)

    -- Entradas de Interação (Interface com a Placa)
    -- As larguras podem ser ajustadas conforme a necessidade do seu projeto (ex: 10 switches, 4 botões na DE1)
    switches     : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);  
    buttons      : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);  

    -- Sinais de Sincronismo (vindos do VGA_Controller)
    pixel_x      : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);  -- Coordenada X do pixel atual
    pixel_y      : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);  -- Coordenada Y do pixel atual
    video_active : IN  STD_LOGIC;                     -- Indica se a tela está sendo desenhada

    -- Saídas de Cor (enviadas para o VGA_Controller)
    r            : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);  -- Vermelho do pixel a ser desenhado
    g            : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);  -- Verde do pixel a ser desenhado
    b            : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)   -- Azul do pixel a ser desenhado
  );
END PPU;