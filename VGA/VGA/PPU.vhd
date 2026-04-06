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

ARCHITECTURE behavior OF PPU IS

    -- 1. Sinais da Camada de Background
    SIGNAL bg_r, bg_g, bg_b : STD_LOGIC_VECTOR(7 DOWNTO 0);

    -- 2. Sinais da Camada de Sprites (As alavancas dos switches)
    SIGNAL sp_r, sp_g, sp_b : STD_LOGIC_VECTOR(7 DOWNTO 0);
    
    -- Sinal crucial: O monitor está desenhando em cima de um sprite agora?
    SIGNAL sprite_ativo     : STD_LOGIC;

BEGIN

    -- ==========================================
    -- BLOCO 1: Geração do Background
    -- ==========================================
    -- Como decidimos que o fundo inteiro será Azul Escuro fixo, 
    -- podemos fazer a atribuição direta aqui.
    -- (No futuro, você pode colocar a lógica de leitura da memória de mapa aqui)
    bg_r <= x"00";
    bg_g <= x"00";
    bg_b <= x"80"; -- Azul escuro

    -- ==========================================
    -- BLOCO 2: Geração dos Sprites (Alavancas e Botões)
    -- ==========================================
    -- Aqui vai entrar a lógica que lê a entrada "switches" e "keys" 
    -- e altera o sp_r, sp_g, sp_b e o sprite_ativo baseada no pixel_x e pixel_y.
    -- (Vamos construir isso no próximo passo)


    -- ==========================================
    -- BLOCO 3: O Multiplexador de Composição (Layer Selector)
    -- ==========================================
    -- Aqui nós decidimos a cor final que sai da PPU (sinais r, g, b).

    -- [SEU CÓDIGO VAI AQUI]
    r <= sp_r WHEN sprite_ativo = '1' ELSE bg_r;
    g <= sp_g WHEN sprite_ativo = '1' ELSE bg_g;
    b <= sp_b WHEN sprite_ativo = '1' ELSE bg_b;

END behavior;