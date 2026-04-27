library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

entity VGA_tb is
end VGA_tb;

architecture Behavioral of VGA_tb is
    component VGA
        Port (
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
    end component;
    
    signal tb_clk          : STD_LOGIC := '0';
    signal tb_reset_n      : STD_LOGIC := '0';
    signal tb_r_in         : STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '1');
    signal tb_g_in         : STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '1');
    signal tb_b_in         : STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '1');
    signal tb_pixel_x      : STD_LOGIC_VECTOR(9 DOWNTO 0);
    signal tb_pixel_y      : STD_LOGIC_VECTOR(9 DOWNTO 0);
    signal tb_video_active : STD_LOGIC;
    signal tb_vga_r        : STD_LOGIC_VECTOR(7 DOWNTO 0);
    signal tb_vga_g        : STD_LOGIC_VECTOR(7 DOWNTO 0);
    signal tb_vga_b        : STD_LOGIC_VECTOR(7 DOWNTO 0);
    signal tb_vga_hs       : STD_LOGIC;
    signal tb_vga_vs       : STD_LOGIC;
    signal tb_vga_blank_n  : STD_LOGIC;
    signal tb_vga_sync_n   : STD_LOGIC;
    signal tb_vga_clk      : STD_LOGIC;
	signal sim_finished     : boolean := false; 

    constant clk_period     : time := 40 ns; -- período aproximado de clock de 25.175MHz
begin
    uut: VGA
        port map (
            -- Entradas de Controle de Clock e Reset
            pixel_clk    => tb_clk,
            reset_n      => tb_reset_n,

            -- Entradas de Cor (vindos da PPU)
            r_in         => tb_r_in,
            g_in         => tb_g_in,
            b_in         => tb_b_in,

            -- Saídas de Controle Interno (enviados para a PPU)
            pixel_x      => tb_pixel_x,
            pixel_y      => tb_pixel_y,
            video_active => tb_video_active,

            -- Saídas Físicas (conectadas aos pinos da DE1-SoC)
            VGA_R        => tb_vga_r,
            VGA_G        => tb_vga_g,
            VGA_B        => tb_vga_b,
            VGA_HS       => tb_vga_hs,
            VGA_VS       => tb_vga_vs,
            VGA_BLANK_N  => tb_vga_blank_n,
            VGA_SYNC_N   => tb_vga_sync_n,
            VGA_CLK      => tb_vga_clk
        );
    
    clk_process : process  --gerador de clock
    begin
        while not sim_finished loop
            tb_CLK <= '0'; wait for clk_period/2;
            tb_CLK <= '1'; wait for clk_period/2;
        end loop;
        wait;
    end process;
    
    test_process: process
        variable line_out : line;
    begin
        write(line_out, string'("Testando VGA..."));
        writeline(output, line_out);
		  
		  write(line_out, string'("Testando para cada posição de pixel se há algum erro"));
		  writeline(output, line_out);

        -- Teste pixel_x e pixel_y
			for i in 0 to 8192 loop
                wait until rising_edge(tb_clk);
                assert (tb_pixel_x < "1100100000" and tb_pixel_y < "1000001100") 
                report "ERRO: Coordenadas invalidas! O VGA tentou acessar X = " & 
                       integer'image(to_integer(unsigned(tb_pixel_x))) & 
                       ", Y = " & 
                       integer'image(to_integer(unsigned(tb_pixel_y))) 
                severity error;				
                assert (tb_vga_sync_n = '1') report "Sinal de sincronização deve ser '1'" severity error;

                    -- Verifica se as cores estão certas na região ativa
                if (tb_video_active = '1') then
                    assert (tb_vga_r = tb_r_in and tb_vga_g = tb_g_in and tb_vga_b = tb_b_in) report "Cores VGA não correspondem às entradas" severity error;
                else
                    assert (tb_vga_blank_n = '0') report "Sinal de blanking deve ser '0' fora da area ativa" severity error;
                end if;

                    -- Verifica o sinal de vídeo ativo e VGA_Blank_N
                if (tb_pixel_x < "1010000000" and tb_pixel_y < "0111100000") then
                    assert (tb_video_active = '1' and tb_vga_blank_n = '1') report "Sinal de video ativo deve ser '1' dentro da area ativa" severity error;
                else
                    assert (tb_video_active = '0' and tb_vga_blank_n = '0') report "Sinal de video ativo deve ser '0' fora da area ativa" severity error;
                end if;

                    -- Verifica se o sync horizontal está nos limites
                if (tb_pixel_x >= "1010010000" and tb_pixel_x <= "1011101111") then
                    assert (tb_vga_hs = '0') report "Sinal de sincronismo horizontal devem ser '0' dentro da area ativa" severity error;
                else
                    assert (tb_vga_hs = '1') report "Sinal de sincronismo horizontal deve ser '1' fora da area ativa" severity error;
                end if;
            
				-- Verifica se o sync vertical está nos limites
				if (tb_pixel_y >= "0111101011" and tb_pixel_y <= "0111101100") then
                    assert (tb_vga_vs = '0') report "Sinal de sincronismo vertical deve ser '0' dentro da area ativa" severity error;
                else
                    assert (tb_vga_vs = '1') report "Sinal de sincronismo vertical deve ser '1' fora da area ativa" severity error;
                end if;
			end loop;
        
        write(line_out, string'("Teste concluido sem erros"));
        writeline(output, line_out);
        wait;
    end process;
end Behavioral;