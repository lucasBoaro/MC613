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

    -- Sinais de Cores que já tínhamos feito
    SIGNAL bg_r, bg_g, bg_b : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL sp_r, sp_g, sp_b : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL sprite_ativo     : STD_LOGIC;

    -- Sinal para varrer os 10 switches
    SIGNAL scan_idx : INTEGER RANGE 0 TO 9 := 0;
    SIGNAL ram_write_addr : INTEGER RANGE 0 TO 9 := 0;
    
    -- Sinal interno para o endereço que a PPU vai ler na hora de desenhar
    SIGNAL ram_addr_leitura : STD_LOGIC_VECTOR(7 DOWNTO 0);

    -- ==========================================
    -- PASSO 1: DECLARAÇÃO DOS COMPONENTES
    -- ==========================================
    -- Avisamos a PPU sobre o formato da ROM (apenas leitura)
    COMPONENT rom IS
        PORT (
            addr     : IN STD_LOGIC_VECTOR (5 DOWNTO 0);
            data_out : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
        );
    END COMPONENT;

    -- Avisamos a PPU sobre o formato da RAM (leitura e escrita)
    COMPONENT ram IS
        PORT (
            clock    : IN STD_LOGIC;
            wr_en    : IN STD_LOGIC;
            addr     : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
            data_in  : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
            data_out : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
        );
    END COMPONENT;

    -- Sinais internos ("fios") para ligar nas memórias
    -- Sinais internos ("fios") para ligar nas memórias
    SIGNAL rom_data_fio : STD_LOGIC_VECTOR(7 DOWNTO 0); -- Os dados continuam com 8 bits
    SIGNAL rom_addr_fio : STD_LOGIC_VECTOR(5 DOWNTO 0); -- O endereço agora tem 6 bits!
    
    SIGNAL ram_we_fio                 : STD_LOGIC;
    SIGNAL ram_addr_fio               : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL ram_din_fio, ram_dout_fio  : STD_LOGIC_VECTOR(7 DOWNTO 0);

    -- Sinais matemáticos para facilitar a lógica de colisão
    SIGNAL p_x, p_y      : UNSIGNED(9 DOWNTO 0);
    SIGNAL sprite_y      : UNSIGNED(9 DOWNTO 0);
    SIGNAL diff_x, diff_y: UNSIGNED(9 DOWNTO 0);

    SIGNAL current_sprite_x  : UNSIGNED(9 DOWNTO 0);
    SIGNAL current_sprite_id : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL sprite_hit        : STD_LOGIC;
    
    -- Sinais booleanos para saber se estamos dentro da caixa do sprite
    SIGNAL dentro_x, dentro_y : BOOLEAN;

BEGIN

   -- ==========================================
    -- LÓGICA DE COLISÃO E ENDEREÇAMENTO (10 SWITCHES COM ZOOM 4X)
    -- ==========================================
    p_x <= UNSIGNED(pixel_x);
    p_y <= UNSIGNED(pixel_y);

    -- 1. Ampliamos a largura de cada switch de 8 para 32 pixels
    current_sprite_id <=
        x"00" WHEN (p_x >= 100 AND p_x < 132) ELSE
        x"01" WHEN (p_x >= 140 AND p_x < 172) ELSE
        x"02" WHEN (p_x >= 180 AND p_x < 212) ELSE
        x"03" WHEN (p_x >= 220 AND p_x < 252) ELSE
        x"04" WHEN (p_x >= 260 AND p_x < 292) ELSE
        x"05" WHEN (p_x >= 300 AND p_x < 332) ELSE
        x"06" WHEN (p_x >= 340 AND p_x < 372) ELSE
        x"07" WHEN (p_x >= 380 AND p_x < 412) ELSE
        x"08" WHEN (p_x >= 420 AND p_x < 452) ELSE
        x"09" WHEN (p_x >= 460 AND p_x < 492) ELSE
        x"FF";

    current_sprite_x <=
        TO_UNSIGNED(100, 10) WHEN current_sprite_id = x"00" ELSE
        TO_UNSIGNED(140, 10) WHEN current_sprite_id = x"01" ELSE
        TO_UNSIGNED(180, 10) WHEN current_sprite_id = x"02" ELSE
        TO_UNSIGNED(220, 10) WHEN current_sprite_id = x"03" ELSE
        TO_UNSIGNED(260, 10) WHEN current_sprite_id = x"04" ELSE
        TO_UNSIGNED(300, 10) WHEN current_sprite_id = x"05" ELSE
        TO_UNSIGNED(340, 10) WHEN current_sprite_id = x"06" ELSE
        TO_UNSIGNED(380, 10) WHEN current_sprite_id = x"07" ELSE
        TO_UNSIGNED(420, 10) WHEN current_sprite_id = x"08" ELSE
        TO_UNSIGNED(460, 10) WHEN current_sprite_id = x"09" ELSE
        TO_UNSIGNED(0, 10);

    ram_addr_leitura <= current_sprite_id WHEN current_sprite_id /= x"FF" ELSE x"00";
    sprite_y <= RESIZE(UNSIGNED(ram_dout_fio), 10);

    -- 2. Ampliamos a altura da caixa de colisão para 32 pixels
    sprite_hit <= '1' WHEN (current_sprite_id /= x"FF") AND (p_y >= sprite_y) AND (p_y < sprite_y + 32) ELSE '0';

    diff_x <= p_x - current_sprite_x;
    diff_y <= p_y - sprite_y;

    -- 3. A Mágica do Zoom: diff_y(4 downto 2) e diff_x(4 downto 2)
    -- Isso descarta os 2 bits menos significativos (divide a coordenada por 4)
    rom_addr_fio <= STD_LOGIC_VECTOR(diff_y(4 DOWNTO 2) & diff_x(4 DOWNTO 2)) WHEN sprite_hit = '1' ELSE (OTHERS => '0');

    sprite_ativo <= '1' WHEN (sprite_hit = '1') AND (rom_data_fio /= x"00") ELSE '0';
    -- ==========================================
    -- PALETA DE CORES DOS SPRITES
    -- ==========================================
    -- Traduz o índice (rom_data_fio) para as cores RGB reais do Sprite
    
    WITH rom_data_fio SELECT
        sp_r <= x"FF" WHEN x"01", -- 1 = Branco (Vermelho no máximo)
                x"80" WHEN x"02", -- 2 = Cinza  (Vermelho na metade)
                x"00" WHEN OTHERS;-- 0 = Transparente (Ignorado)

    WITH rom_data_fio SELECT
        sp_g <= x"FF" WHEN x"01", -- 1 = Branco (Verde no máximo)
                x"80" WHEN x"02", -- 2 = Cinza  (Verde na metade)
                x"00" WHEN OTHERS;

    WITH rom_data_fio SELECT
        sp_b <= x"FF" WHEN x"01", -- 1 = Branco (Azul no máximo)
                x"80" WHEN x"02", -- 2 = Cinza  (Azul na metade)
                x"00" WHEN OTHERS;
    -- ==========================================
    -- MÁQUINA DE ATUALIZAÇÃO DA OAM (RAM)
    -- ==========================================
    PROCESS(clk, reset_n)
    BEGIN
        IF reset_n = '0' THEN
            scan_idx <= 0;
            ram_we_fio <= '0';
        ELSIF RISING_EDGE(clk) THEN
            IF video_active = '0' THEN
                ram_we_fio <= '1';
                
                -- Sincroniza o endereço de gravação com o ciclo atual!
                ram_write_addr <= scan_idx; 
                
                -- Invertemos a leitura: scan_idx 0 (esquerda da tela) lê o switch 9 (esquerda da placa)
                IF switches(9 - scan_idx) = '1' THEN
                    ram_din_fio <= STD_LOGIC_VECTOR(TO_UNSIGNED(200, 8)); -- Y = 200
                ELSE
                    ram_din_fio <= STD_LOGIC_VECTOR(TO_UNSIGNED(240, 8)); -- Y = 240
                END IF;
                
                IF scan_idx = 9 THEN
                    scan_idx <= 0;
                ELSE
                    scan_idx <= scan_idx + 1;
                END IF;
            ELSE
                ram_we_fio <= '0';
            END IF;
        END IF;
    END PROCESS;

    -- Usa o novo endereço sincronizado para a escrita. 
    -- A MUDANÇA: O MUX agora é controlado pelo ram_we_fio!
    ram_addr_fio <= STD_LOGIC_VECTOR(TO_UNSIGNED(ram_write_addr, 8)) WHEN ram_we_fio = '1' ELSE ram_addr_leitura;
    -- ==========================================
    -- PASSO 2: INSTANCIAÇÃO (Ligando os fios)
    -- ==========================================
    
    -- Criando a memória de DESENHO (ROM)
    instancia_sprite_rom : rom
        PORT MAP (
            addr     => rom_addr_fio,   -- A PPU vai dizer qual pixel do desenho ela quer ler
            data_out => rom_data_fio    -- A ROM vai devolver a cor desse pixel
        );

    -- Criando a memória de ATRIBUTOS / POSIÇÕES (RAM OAM)
    instancia_oam_ram : ram
        PORT MAP (
            clock    => clk,            -- Usa o clock principal da PPU
            wr_en    => ram_we_fio,     -- 1 para salvar nova posição, 0 para ler posição atual
            addr     => ram_addr_fio,   -- Qual switch estamos lendo/escrevendo? (0 a 9)
            data_in  => ram_din_fio,    -- A nova posição Y caso o usuário tenha mexido
            data_out => ram_dout_fio    -- A posição Y atual guardada na memória
        );


    -- ==========================================
    -- LÓGICA DE CORES E COMPOSIÇÃO (Que já fizemos)
    -- ==========================================
    -- Background Azul Escuro
    bg_r <= x"00";
    bg_g <= x"00";
    bg_b <= x"80";

    -- Multiplexador de Camadas (Layer Selector)
    r <= sp_r WHEN sprite_ativo = '1' ELSE bg_r;
    g <= sp_g WHEN sprite_ativo = '1' ELSE bg_g;
    b <= sp_b WHEN sprite_ativo = '1' ELSE bg_b;

    -- [Aqui entrará a lógica que controla a leitura/escrita dessas memórias]

END behavior;