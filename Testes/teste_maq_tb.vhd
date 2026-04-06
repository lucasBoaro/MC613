library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

entity teste_maq_tb is
end teste_maq_tb;

architecture behavior of teste_maq_tb is

    component teste_maq
        port (
            CLOCK_50 : in std_logic;
            SW       : in std_logic_vector(9 downto 0);
            KEY      : in std_logic_vector(1 downto 0);
            LEDR     : out std_logic_vector(1 downto 0);
            HEX5     : out std_logic_vector(6 downto 0);
            HEX3     : out std_logic_vector(6 downto 0);
            HEX2     : out std_logic_vector(6 downto 0); 
            HEX1     : out std_logic_vector(6 downto 0); 
            HEX0     : out std_logic_vector(6 downto 0)
        );
    end component;

    signal tb_CLOCK_50 : std_logic := '0';
    signal tb_SW       : std_logic_vector(9 downto 0) := (others => '0');
    signal tb_KEY      : std_logic_vector(1 downto 0) := (others => '0');
    
    signal tb_LEDR     : std_logic_vector(1 downto 0);
    signal tb_HEX5     : std_logic_vector(6 downto 0);
    signal tb_HEX3     : std_logic_vector(6 downto 0);
    signal tb_HEX2     : std_logic_vector(6 downto 0);
    signal tb_HEX1     : std_logic_vector(6 downto 0);
    signal tb_HEX0     : std_logic_vector(6 downto 0);

    signal sim_finished : boolean := false;
    constant clk_period : time := 20 ns;

    -- =========================================================================
    -- NOVA FEATURE: Tradutor de Display 7-Segmentos (Lógica Negativa - Anodo Comum)
    -- =========================================================================
    function decode_hex(hex_in : std_logic_vector(6 downto 0)) return character is
    begin
        case hex_in is
            when "1000000" => return '0';
            when "1111001" => return '1';
            when "0100100" => return '2';
            when "0110000" => return '3';
            when "0011001" => return '4';
            when "0010010" => return '5';
            when "0000010" => return '6';
            when "1111000" => return '7';
            when "0000000" => return '8';
            when "0010000" => return '9';
            when "0011000" => return '9'; -- Variação comum do dígito 9
            when "1111111" => return ' '; -- Display totalmente apagado
            when others    => return '?'; -- Estado desconhecido (ex: U, X)
        end case;
    end function;

begin

    UUT: teste_maq port map (
        CLOCK_50 => tb_CLOCK_50,
        SW       => tb_SW,
        KEY      => tb_KEY,
        LEDR     => tb_LEDR,
        HEX5     => tb_HEX5,
        HEX3     => tb_HEX3,
        HEX2     => tb_HEX2,
        HEX1     => tb_HEX1,
        HEX0     => tb_HEX0
    );

    clk_process : process
    begin
        while not sim_finished loop
            tb_CLOCK_50 <= '0'; wait for clk_period/2;
            tb_CLOCK_50 <= '1'; wait for clk_period/2;
        end loop;
        wait;
    end process;

    stim_proc: process
        variable line_out : line;
        
        procedure print_msg(msg : string) is
        begin
            write(line_out, string'("-> ")); write(line_out, msg); 
            writeline(output, line_out);
        end procedure;

        -- =========================================================================
        -- STATUS ATUALIZADO: Agora imprime os LEDs e os Números da Tela
        -- =========================================================================
        procedure print_status is
        begin
            -- Imprime os LEDs
            write(line_out, string'("   [LEDS] Fim Venda: ")); write(line_out, tb_LEDR(0));
            write(line_out, string'(" | Troco/Cancela: ")); write(line_out, tb_LEDR(1));
            writeline(output, line_out);
            
            -- Imprime os Displays traduzidos
            write(line_out, string'("   [TELA] Produto: [")); 
            write(line_out, decode_hex(tb_HEX5));
            write(line_out, string'("] | Valor: ["));
            write(line_out, decode_hex(tb_HEX3));
            write(line_out, decode_hex(tb_HEX2));
            write(line_out, decode_hex(tb_HEX1));
            write(line_out, decode_hex(tb_HEX0));
            write(line_out, string'("] centavos"));
            writeline(output, line_out); writeline(output, line_out);
        end procedure;

        procedure press_confirm is
        begin
            tb_KEY(0) <= '1'; 
            wait for 40 ns;
            tb_KEY(0) <= '0'; 
            wait for 20 ns;
        end procedure;

        procedure press_cancel is
        begin
            tb_KEY(1) <= '1'; 
            wait for 40 ns; 
            tb_KEY(1) <= '0'; 
            wait for 40 ns;
        end procedure;

    begin
        write(line_out, string'("Iniciando Teste do Top Level (Vending Machine)...")); 
        writeline(output, line_out); writeline(output, line_out);

        -- RESET INICIAL PARA DESTRAVAR TUDO
        press_cancel;

        -------------------------------------------------------------
        print_msg("=== CENARIO 1: COMPRA EXATA (SEM TROCO) ===");
        
        tb_SW(3 downto 0) <= "0001"; wait for 40 ns;
        press_confirm;
        print_msg("Produto '1' selecionado e confirmado.");

        tb_SW(9 downto 4) <= "100000"; wait for 20 ns;
        press_confirm;
        print_msg("Inserido nota de R$ 2,00 via SW(9)");

        tb_SW(9 downto 4) <= "010000"; wait for 20 ns;
        press_confirm;
        print_msg("Inserido moeda de R$ 1,00 via SW(8)");

        wait for 10 ns; 
        print_status; -- Substitui o antigo print_leds
        wait for 200 ns;

        -------------------------------------------------------------
        print_msg("=== CENARIO 2: COMPRA COM TROCO ===");
        
        press_cancel; 

        tb_SW(3 downto 0) <= "0010"; wait for 40 ns;
        press_confirm;
        print_msg("Produto '2' selecionado e confirmado.");

        tb_SW(9 downto 4) <= "100000"; wait for 20 ns;
        press_confirm;
        print_msg("Inserido nota de R$ 2,00 via SW(9). (Produto custa 1,75)");

        wait for 10 ns;
        print_status;
        wait for 200 ns;

        -------------------------------------------------------------
        print_msg("=== CENARIO 3: CANCELAMENTO NO MEIO DA OPERACAO ===");
        
        press_cancel; 

        tb_SW(3 downto 0) <= "0100"; wait for 40 ns;
        press_confirm;
        print_msg("Produto '4' selecionado e confirmado.");

        tb_SW(9 downto 4) <= "001000"; wait for 20 ns;
        press_confirm;
        print_msg("Inserido moeda de R$ 0,50 via SW(7)");
        
        tb_SW(9 downto 4) <= "010000"; wait for 20 ns;
        press_confirm;
        print_msg("Inserido moeda de R$ 1,00 via SW(8)");

        press_cancel;
        print_msg("Cliente apertou CANCELAR (KEY 1)");

        wait for 10 ns;
        print_status;
        wait for 200 ns;

        -------------------------------------------------------------
        print_msg("Fim da simulacao do Top Level!");
        sim_finished <= true; 
        wait;
        
    end process;

end behavior;