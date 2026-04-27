library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

entity PPU_tb is
end PPU_tb;

architecture Behavioral of PPU_tb is
    component PPU
        Port (
        switches     : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
        buttons      : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
        pixel_x      : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
        pixel_y      : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
        video_active : IN  STD_LOGIC;
        r            : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        g            : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        b            : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
        );
    end component;

    signal tb_switches     : STD_LOGIC_VECTOR(9 DOWNTO 0) := (others => '0');
    signal tb_buttons      : STD_LOGIC_VECTOR(3 DOWNTO 0) := (others => '1');
    signal tb_pixel_x      : STD_LOGIC_VECTOR(9 DOWNTO 0) := (others => '0');
    signal tb_pixel_y      : STD_LOGIC_VECTOR(9 DOWNTO 0) := (others => '0');
    signal tb_video_active : STD_LOGIC := '0';
    signal tb_r            : STD_LOGIC_VECTOR(7 DOWNTO 0);
    signal tb_g            : STD_LOGIC_VECTOR(7 DOWNTO 0);
    signal tb_b            : STD_LOGIC_VECTOR(7 DOWNTO 0);

begin
    uut: PPU
        port map (
            switches     => tb_switches,
            buttons      => tb_buttons,
            pixel_x      => tb_pixel_x,
            pixel_y      => tb_pixel_y,
            video_active => tb_video_active,
            r            => tb_r,
            g            => tb_g,
            b            => tb_b
        );
    
    
    test_process: process
        variable line_out : line;
    begin
        write(line_out, string'("Testando PPU"));
        writeline(output, line_out);
        
        -- Testa pixels dos switches desligados
        for i in 0 to 8 loop
            tb_pixel_x <= STD_LOGIC_VECTOR(to_unsigned(70 + 64 * i, 10)); -- Testa o pixel (1,0)
            tb_pixel_y <= STD_LOGIC_VECTOR(to_unsigned(192, 10));
            wait for 40 ns;  
            assert (tb_r = x"FF" and tb_g = x"00" and tb_b = x"00") report "Cor do pixel (" & integer'image(70 + 64 * i) & ",192) não é vermelho quando o switch " & integer'image(9 - i) & " está desligado" severity error;
            tb_pixel_x <= STD_LOGIC_VECTOR(to_unsigned(70 + 64 * i, 10)); 
            tb_pixel_y <= STD_LOGIC_VECTOR(to_unsigned(160, 10));
            wait for 40 ns; 
            assert (tb_r = x"00" and tb_g = x"00" and tb_b = x"00") report "Cor do pixel (" & integer'image(70 + 64 * i) & ",160) não é preto quando o switch " & integer'image(9 - i) & " está desligado" severity error;

        end loop;

        -- Testa pixels dos switches ligados
        for i in 0 to 8 loop
            tb_switches(9 - i) <= '1'; -- Liga cada switch um por um para testar a mudança de cor
            tb_pixel_x <= STD_LOGIC_VECTOR(to_unsigned(70 + 64 * i, 10)); -- Testa o pixel (1,0)
            tb_pixel_y <= STD_LOGIC_VECTOR(to_unsigned(192, 10));
            wait for 40 ns; 
            assert (tb_r = x"00" and tb_g = x"00" and tb_b = x"00") report "Cor do pixel (" & integer'image(70 + 64 * i) & ",192) não é preto quando o switch " & integer'image(9 - i) & " está ligado" severity error;
            tb_pixel_x <= STD_LOGIC_VECTOR(to_unsigned(70 + 64 * i, 10)); 
            tb_pixel_y <= STD_LOGIC_VECTOR(to_unsigned(160, 10));
            wait for 40 ns; 
            assert (tb_r = x"FF" and tb_g = x"00" and tb_b = x"00") report "Cor do pixel (" & integer'image(70 + 64 * i) & ",160) não é vermelho quando o switch " & integer'image(9 - i) & " está ligado" severity error;

        end loop;

        -- Testa pixels dos botões não apertados
        for i in 0 to 3 loop
            tb_pixel_x <= STD_LOGIC_VECTOR(to_unsigned(190 + 96 * i, 10));
            tb_pixel_y <= STD_LOGIC_VECTOR(to_unsigned(300, 10));
            wait for 40 ns; 
            assert (tb_r = x"FF" and tb_g = x"00" and tb_b = x"00") report "Cor do botao em (x=" & integer'image(190 + 96 * i) & ", y=300) não é vermelha quando o botao " & integer'image(i) & " está em '1'" severity error;
        end loop;
        
        -- Testa pixels dos botões apertados
        for i in 0 to 3 loop
            tb_buttons(3 - i) <= '0'; -- Mapeamento horizontal: botao i usa bit (3-i)
            tb_pixel_x <= STD_LOGIC_VECTOR(to_unsigned(190 + 96 * i, 10));
            tb_pixel_y <= STD_LOGIC_VECTOR(to_unsigned(300, 10));
            wait for 40 ns; 
            assert (tb_r = x"00" and tb_g = x"FF" and tb_b = x"00") report "Cor do botao em (x=" & integer'image(190 + 96 * i) & ", y=300) não é verde quando o botao " & integer'image(3 - i) & " está em '0'" severity error;
        end loop;


        write(line_out, string'("Teste concluido sem erros"));
        writeline(output, line_out);
        wait;
    end process;
end Behavioral;