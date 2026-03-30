entity VGA is 
    port(
        CLK_50         : in  std_logic;
        VGA_R        : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);  -- Saída VGA Vermelha
        VGA_G        : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);  -- Saída VGA Verde
        VGA_B        : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);  -- Saída VGA Azul
        VGA_HS       : OUT STD_LOGIC;                     -- Sincronismo Horizontal
        VGA_VS       : OUT STD_LOGIC;                     -- Sincronismo Vertical
        VGA_BLANK_N  : OUT STD_LOGIC;                     -- Fora da área visível (ou seja, deve ser '0' no blanking)
        VGA_SYNC_N   : OUT STD_LOGIC := '1';              -- Sincronização de vídeo (fixo em '1')
        VGA_CLK      : OUT STD_LOGIC                      -- Clock do pixel (espelho do pixel_clk)
    );
end VGA;

architecture Behavioral of VGA is

  signal pixel_clk : std_logic;
  signal pixel_x   : std_logic_vector(9 downto 0);
  signal pixel_y   : std_logic_vector(9 downto 0);
  signal video_active : std_logic;

begin
    instanciaPLL: entity work.PLL
        port map (
            refclk => CLK_50,
            rst => '0',
            outclk_0 => pixel_clk,
            locked => open
        );


    instanciaVGAControler: entity work.VGA_Controller
        port map (
            r_in => (others => '0'),
            g_in => (others => '0'),
            b_in => (others => '0'),
            pixel_clk => pixel_clk,
            reset_n => '1', 
            VGA_R => VGA_R,
            VGA_G => VGA_G,
            VGA_B => VGA_B,
            VGA_HS => VGA_HS,
            VGA_VS => VGA_VS,
            VGA_BLANK_N => VGA_BLANK_N,
            VGA_SYNC_N => VGA_SYNC_N,
            VGA_CLK => VGA_CLK,
            pixel_x => pixel_x,
            pixel_y => pixel_y,
            video_active => video_active
        );