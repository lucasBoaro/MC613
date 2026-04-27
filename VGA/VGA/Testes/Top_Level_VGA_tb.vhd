library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

entity Top_Level_VGA_tb is
end Top_Level_VGA_tb;

architecture Behavioral of Top_Level_VGA_tb is
    component Top_Level_VGA
        port(
            -- Clock principal da placa
            CLK_50       : IN  STD_LOGIC;
            
            -- Entradas da placa
            SW           : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
            KEY          : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);

            -- Saídas VGA
            VGA_R        : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);  
            VGA_G        : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);  
            VGA_B        : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);  
            VGA_HS       : OUT STD_LOGIC;                     
            VGA_VS       : OUT STD_LOGIC;                     
            VGA_BLANK_N  : OUT STD_LOGIC;  
            VGA_SYNC_N   : OUT STD_LOGIC := '1';              
            VGA_CLK      : OUT STD_LOGIC                   
        );
    end component;

    signal tb_clk          : STD_LOGIC := '0';
    signal tb_switches     : STD_LOGIC_VECTOR(9 DOWNTO 0) := (others => '0');
    signal tb_buttons      : STD_LOGIC_VECTOR(3 DOWNTO 0) := (others => '1');
    signal tb_pixel_x      : STD_LOGIC_VECTOR(9 DOWNTO 0) := (others => '0');
    signal tb_pixel_y      : STD_LOGIC_VECTOR(9 DOWNTO 0) := (others => '0');
    signal tb_video_active : STD_LOGIC := '0';
    signal tb_r            : STD_LOGIC_VECTOR(7 DOWNTO 0);
    signal tb_g            : STD_LOGIC_VECTOR(7 DOWNTO 0);
    signal tb_b            : STD_LOGIC_VECTOR(7 DOWNTO 0);
    signal tb_hs           : STD_LOGIC;
    signal tb_vs           : STD_LOGIC;
    signal tb_blank_n      : STD_LOGIC;
    signal tb_sync_n       : STD_LOGIC := '1';
    signal tb_vga_clk      : STD_LOGIC;
	 

	 signal sim_finished     : boolean := false; 

    constant clk_period     : time := 10 ns; -- período de clock de 100MHz
begin
    uut: Top_Level_VGA
        port map (
            -- Clock principal da placa
            CLK_50       => tb_clk,
            
            -- Entradas da placa
            SW           => tb_switches,
            KEY          => tb_buttons,

            -- Saídas VGA
            VGA_R        => tb_r,
            VGA_G        => tb_g,
            VGA_B        => tb_b,
            VGA_HS       => tb_hs,
            VGA_VS       => tb_vs,
            VGA_BLANK_N  => tb_blank_n,
            VGA_SYNC_N   => tb_sync_n,
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
        write(line_out, string'("Testando Top_Level_VGA"));
        writeline(output, line_out);
        write(line_out, string'("Verificando se VGA_BLANK_N esta em 0 no sincronismo"));
        writeline(output, line_out);
        write(line_out, string'("Verificando se as cores estao em x'00' no sincronismo"));
        writeline(output, line_out);

        if rising_edge(tb_CLK) then
            -- Verifica se o tb_blank
            if (tb_hs = '1' or tb_vs = '1') then
                assert (tb_blank_n = '0') report "Sinal VGA_BLANK_N deve estar em '0' durante o periodo de sincronismo" severity error;
                assert (tb_b = x"00") report "Sinal VGA_B deve estar em '0' durante o periodo de sincronismo" severity error;
                assert (tb_g = x"00") report "Sinal VGA_G deve estar em '0' durante o periodo de sincronismo" severity error;
                assert (tb_r = x"00") report "Sinal VGA_R deve estar em '0' durante o periodo de sincronismo" severity error;
            end if;
        end if;
        
		write(line_out, string'("Teste concluido"));
        writeline(output, line_out);
        wait;
    end process;
    
    check_vga_clock_proc: process
        variable tempo_inicial : time;
        variable tempo_final   : time;
        variable periodo_medido : time;
		  variable line_out       : line;
    begin
	    write(line_out, string'("Testando clock"));
        writeline(output, line_out);
        wait for 10 us; -- espera para o sistema inicializar

        -- Verifica se o clock do VGA (e consequentemente do pixel) está oscilando na frequência correta (aproximadamente 25 MHz)
        wait until rising_edge(tb_vga_clk);
        tempo_inicial := now;
        wait until rising_edge(tb_vga_clk);
        tempo_final := now;
        periodo_medido := tempo_final - tempo_inicial;
        write(line_out, string'("O periodo medido foi de:")); write(line_out, periodo_medido);
        writeline(output, line_out);
        assert (periodo_medido > 39 ns and periodo_medido < 41 ns)
            report "Clock VGA nao esta oscilando ou esta na frequencia errada! " &
                   "Periodo medido: " & time'image(periodo_medido)
            severity error;

        write(line_out, string'("Teste concluido"));
        writeline(output, line_out);
        wait;
    end process;
end Behavioral;