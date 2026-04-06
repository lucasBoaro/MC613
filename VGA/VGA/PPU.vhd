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
    
    -- Sinais booleanos para saber se estamos dentro da caixa do sprite
    SIGNAL dentro_x, dentro_y : BOOLEAN;

BEGIN

    -- ==========================================
    -- LÓGICA DE COLISÃO E ENDEREÇAMENTO (O "Pixel Interceptor")
    -- ==========================================
    
    -- 1. Conversão de tipos para podermos fazer contas matemáticas (+ e -)
    p_x <= UNSIGNED(pixel_x);
    p_y <= UNSIGNED(pixel_y);
    
    -- Para o nosso primeiro teste, vamos focar no Switch 0.
    -- Mandamos a RAM ler sempre o endereço 0 durante o tempo visível da tela.
    ram_addr_leitura <= x"00"; 
    
    -- Lemos a posição Y da alavanca 0 que está salva na RAM e convertemos para 10 bits
    sprite_y <= RESIZE(UNSIGNED(ram_dout_fio), 10);

    -- 2. A "Bounding Box" (Caixa de Colisão)
    -- Vamos fixar a posição X do primeiro switch no pixel 100 da tela.
    -- O sprite tem 8 pixels de largura (então vai do 100 ao 107).
    dentro_x <= (p_x >= 100) AND (p_x < 108);
    
    -- A posição Y depende da RAM. Vai do sprite_y até sprite_y + 7.
    dentro_y <= (p_y >= sprite_y) AND (p_y < sprite_y + 8);

    -- 3. Em qual pixel "interno" do desenho o monitor está agora? (De 0 a 7)
    diff_x <= p_x - 100;
    diff_y <= p_y - sprite_y;

    -- 4. A Mágica do Hardware: Fatiamento de Bits para calcular o Endereço!
    -- Em vez de fazer (diff_y * 8) + diff_x, nós simplesmente pegamos os 3 bits 
    -- menos significativos de Y e concatenamos (&) com os 3 bits de X. 
    -- Isso forma perfeitamente o número de 0 a 63 (6 bits) para ler a nossa ROM!
    rom_addr_fio <= STD_LOGIC_VECTOR(diff_y(2 DOWNTO 0) & diff_x(2 DOWNTO 0)) WHEN (dentro_x AND dentro_y) ELSE (OTHERS => '0');

    -- 5. A Regra de Ouro da Transparência:
    -- O sprite só "acende" na tela se o pixel do monitor estiver dentro da caixa 
    -- E a cor que acabou de sair da ROM for diferente do índice transparente (0).
    sprite_ativo <= '1' WHEN (dentro_x AND dentro_y) AND (rom_data_fio /= x"00") ELSE '0';
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
            
            -- Só atualizamos a memória quando o monitor NÃO estiver desenhando
            IF video_active = '0' THEN
                -- Habilita a escrita na RAM
                ram_we_fio <= '1';
                
                -- Se o switch atual estiver LIGADO ('1')
                IF switches(scan_idx) = '1' THEN
                    ram_din_fio <= STD_LOGIC_VECTOR(TO_UNSIGNED(200, 8)); -- Y = 200 (Alavanca para Cima)
                ELSE
                    ram_din_fio <= STD_LOGIC_VECTOR(TO_UNSIGNED(240, 8)); -- Y = 240 (Alavanca para Baixo)
                END IF;
                
                -- Prepara para ler o próximo switch no próximo pulso de clock
                IF scan_idx = 9 THEN
                    scan_idx <= 0;
                ELSE
                    scan_idx <= scan_idx + 1;
                END IF;
                
            ELSE
                -- Se o monitor estiver desenhando a tela visível, 
                -- DESLIGA a escrita para que possamos ler a memória em paz!
                ram_we_fio <= '0';
            END IF;
            
        END IF;
    END PROCESS;

    -- Multiplexador do Endereço da RAM:
    -- Se a tela tá apagada, o fio de endereço da RAM recebe o 'scan_idx' para a escrita.
    -- Se a tela tá acesa, o fio recebe o endereço de leitura para desenhar.
    ram_addr_fio <= STD_LOGIC_VECTOR(TO_UNSIGNED(scan_idx, 8)) WHEN video_active = '0' ELSE ram_addr_leitura;
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