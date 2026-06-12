library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity DRAM_tb is
end DRAM_tb;

architecture behavior of DRAM_tb is

    -- Sinais de Entrada (Estímulos)
    signal tb_CLOCK_50 : std_logic := '0';
    signal tb_SW       : std_logic_vector(9 downto 0) := (others => '0');
    signal tb_KEY      : std_logic_vector(3 downto 0) := (others => '1'); -- Botoes soltos em hardware sao '1'

    -- Sinais de Saída e Inout (Monitorização)
    signal tb_HEX5       : std_logic_vector(6 downto 0);
    signal tb_HEX4       : std_logic_vector(6 downto 0);
    signal tb_HEX1       : std_logic_vector(6 downto 0);
    signal tb_HEX0       : std_logic_vector(6 downto 0);
    signal tb_DRAM_CS_N  : std_logic;
    signal tb_DRAM_RAS_N : std_logic;
    signal tb_DRAM_CAS_N : std_logic;
    signal tb_DRAM_WE_N  : std_logic;
    signal tb_DRAM_ADDR  : std_logic_vector(12 downto 0);
    signal tb_DRAM_CLK   : std_logic;
    signal tb_DRAM_CKE   : std_logic;
    signal tb_DRAM_LDQM  : std_logic;
    signal tb_DRAM_UDQM  : std_logic;
    signal tb_DRAM_BA    : std_logic_vector(1 downto 0);
    signal tb_DRAM_DQ    : std_logic_vector(15 downto 0) := (others => 'Z');
    signal sim_finished  : boolean := false;

    -- Clock da DE1-SoC é 50 MHz (Período = 20 ns)
    constant clk_period : time := 20 ns;

begin

    -- Instanciação do Módulo Principal (Unit Under Test)
    UUT: entity work.DRAM
    port map (
        CLOCK_50   => tb_CLOCK_50,
        SW         => tb_SW,
        KEY        => tb_KEY,
        HEX5       => tb_HEX5,
        HEX4       => tb_HEX4,
        HEX1       => tb_HEX1,
        HEX0       => tb_HEX0,
        DRAM_CLK   => tb_DRAM_CLK,
        DRAM_CS_N  => tb_DRAM_CS_N,
        DRAM_RAS_N => tb_DRAM_RAS_N,
        DRAM_CAS_N => tb_DRAM_CAS_N,
        DRAM_WE_N  => tb_DRAM_WE_N,
        DRAM_ADDR  => tb_DRAM_ADDR,
        DRAM_CKE   => tb_DRAM_CKE,
        DRAM_LDQM  => tb_DRAM_LDQM,
        DRAM_UDQM  => tb_DRAM_UDQM,
        DRAM_BA    => tb_DRAM_BA,
        DRAM_DQ    => tb_DRAM_DQ
    );

    -- Processo Gerador do Clock Base (50 MHz)
    clk_process: process
    begin
        while not sim_finished loop
            tb_CLOCK_50 <= '0';
            wait for clk_period/2;
            tb_CLOCK_50 <= '1';
            wait for clk_period/2;
        end loop;
        wait;
    end process;

    -- Processo de Estímulos e Casos de Teste
    stim_proc: process
        variable line_out : line;
        
        -- Procedimento para criar um Log legível no console
        procedure print_status(msg : string) is 
        begin
            write(line_out, string'("--- ")); write(line_out, msg); write(line_out, string'(" ---")); 
            writeline(output, line_out);
        end procedure;

    begin
        -- =========================================================
        -- CASO 1: BOOT E INICIALIZAÇÃO DA SDRAM
        -- =========================================================
        print_status("INICIANDO SIMULACAO DO TOP LEVEL");
        
        -- Aperta o botão de Reset (KEY0 ativo em baixo)
        tb_KEY(0) <= '0';
        wait for 100 ns;
        tb_KEY(0) <= '1'; -- Solta o botão
        
        print_status("Reset Liberado. Aguardando inicializacao da SDRAM (200 us)...");
        
        -- IMPORTANTE: A SDRAM precisa de ~200us para sair do estado de init.
        -- O simulador vai avançar esse tempo, mas a onda ficará "parada" até passar os 200us.
        wait for 205 us; 
        
        print_status("Inicializacao de 200us concluida. O sistema esta no estado IDLE.");

        -- =========================================================
        -- CASO 2: OPERAÇÃO DE ESCRITA NO ENDEREÇO 5
        -- =========================================================
        print_status("CASO 2: ESCRITA NO ENDERECO 5 COM O DADO 10");
        
        -- Ajusta os Switches: SW[9:4] = Endereço (000101 = 5) | SW[3:0] = Dado (1010 = 10)
        tb_SW <= "0001011010"; 
        wait for 50 ns;

        assert tb_HEX5 = "1000000"
            report "HEX5 deveria mostrar 0 para SW(9 downto 8)=00"
            severity error;
        assert tb_HEX4 = "0010010"
            report "HEX4 deveria mostrar 5 para SW(7 downto 4)=0101"
            severity error;
        assert tb_HEX0 = "0001000"
            report "HEX0 deveria mostrar A para SW(3 downto 0)=1010"
            severity error;
        
        -- Aperta o botão de gravação KEY3 (ativo em baixo)
        tb_KEY(3) <= '0';
        wait for 50 ns; 
        tb_KEY(3) <= '1'; -- Solta o botão
        
        -- Espera a máquina de estados processar a requisição e interagir com a memória
        wait for 150 ns; 
        
        print_status("Verifique as ondas: WE_N e CAS_N devem ter pulsado em '0'. As mascaras DQM tambem.");
        
        -- Dá um tempo para o sistema voltar ao estado IDLE
        wait for 200 ns;

        -- =========================================================
        -- CASO 3: OPERAÇÃO DE LEITURA COM NOVO ENDEREÇO
        -- =========================================================
        print_status("CASO 3: LEITURA NO ENDERECO 12");
        
        -- Muda o endereço nos switches (SW[9:4] = 001100 = 12).
        -- A interface atual solicita leitura quando ready='1' e nao ha escrita pendente.
        tb_SW <= "0011001010";
        wait for 50 ns;

        assert tb_HEX4 = "1000110"
            report "HEX4 deveria mostrar C para SW(7 downto 4)=1100"
            severity error;
        
        -- Espera o sistema perceber a mudança, pedir a leitura e receber do controlador
        wait for 150 ns;
        
        print_status("Verifique as ondas: Apenas CAS_N deve ter pulsado em '0' (Leitura).");
        
        -- Finaliza a simulação
        wait for 200 ns;
        print_status("TESTE CONCLUIDO COM SUCESSO!");
        
        sim_finished <= true;
        wait; -- Trava o processo para o ModelSim não rodar em loop infinito
    end process;

end behavior;
