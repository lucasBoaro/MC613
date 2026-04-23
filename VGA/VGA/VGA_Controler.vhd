LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

--Entidade disponibilizada no enunciado
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

architecture behavioral of VGAController is
    signal horizontal_counter : unsigned(9 downto 0);
    signal vertical_counter : unsigned(9 downto 0);

    constant H_ACTIVE   : integer := 640;
    constant H_FRONT    : integer := 16;
    constant H_SYNC     : integer := 96;
    constant H_BACK     : integer := 48;
    constant H_TOTAL    : integer := 800;

    constant V_ACTIVE   : integer := 480;
    constant V_FRONT    : integer := 11;
    constant V_SYNC     : integer := 2;
    constant V_BACK     : integer := 31;
    constant V_TOTAL    : integer := 524;

    begin
        -- Sinais fixos  
        VGA_SYNC_N <= '1'; 
        VGA_CLK    <= pixel_clk;

        pixel_x <= std_logic_vector(h_count);
        pixel_y <= std_logic_vector(v_count);

        process(pixel_clk, reset_n)
        begin

            --Sinal de reset (Não entendi onde isso entra mas o enunciado pede como entrada do controlador)
            if reset_n = '0' then
                h_count <= (others => '0');
                v_count <= (others => '0');

            --Contagem de pixels
            elsif rising_edge(pixel_clk) then
                if h_count < (H_TOTAL - 1) then
                    h_count <= h_count + 1;
                else
                    h_count <= (others => '0');
                    if v_count < (V_TOTAL - 1) then
                        v_count <= v_count + 1;
                    else
                        v_count <= (others => '0');
                    end if;
                end if;

                --Ativa o sincronismo horizontal durante o sync pulse horizintal
                if (h_count >= (H_ACTIVE + H_FRONT)) and 
                (h_count < (H_ACTIVE + H_FRONT + H_SYNC)) then
                    VGA_HS <= '0';
                else
                    VGA_HS <= '1';
                end if;

                --Ativa o sincronismo vertical durante o sync pulse vertical
                if (v_count >= (V_ACTIVE + V_FRONT)) and 
                (v_count < (V_ACTIVE + V_FRONT + V_SYNC)) then
                    VGA_VS <= '0';
                else
                    VGA_VS <= '1';
                end if;

                --Determina quando o vídeo deve estar ativo ou não 
                if (h_count < H_ACTIVE) and (v_count < V_ACTIVE) then
                    video_active <= '1';
                    VGA_BLANK_N  <= '1'; 
                else
                    video_active <= '0';
                    VGA_BLANK_N  <= '0'; 
                end if;

                if (video_active = '1') then                   
                    VGA_R <= r_in;
                    VGA_G <= g_in;
                    VGA_B <= b_in;
                else 
                    VGA_R <= (others => '0')
                    VGA_G <= (others => '0');
                    VGA_B <= (others => '0');
                end if;
            end if;
        end process;
    end behavioral;