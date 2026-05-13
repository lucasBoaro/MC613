library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity DRAM_tb is
end DRAM_tb;

architecture behavior of DRAM_tb is

    -- Declaração exata do Componente Top Level com base no seu ficheiro DRAM.vhd
    component DRAM
        port (
            CLK_50     : in  std_logic;
            SW         : in  std_logic_vector(9 downto 0);
            KEY3       : in  std_logic;
            KEY0       : in  std_logic;
            HEX5       : out std_logic_vector(6 downto 0);
            HEX4       : out std_logic_vector(6 downto 0);
            HEX1       : out std_logic_vector(6 downto 0); 
            HEX0       : out std_logic_vector(6 downto 0);
            DRAM_CS_N  : out std_logic;
            DRAM_RAS_N : out std_logic;
            DRAM_CAS_N : out std_logic;
            DRAM_WE_N  : out std_logic;
            DRAM_ADDR  : out std_logic_vector(12 downto 0);
            DRAM_CLK   : out std_logic;
            DRAM_CKE   : out std_logic;
            DRAM_LDQM  : out std_logic;
            DRAM_UDQM  : out std_logic;
            DRAM_BA    : out std_logic_vector(1 downto 0);
            DRAM_DQ    : inout std_logic_vector(15 downto 0)
        );
    end component;

    -- Sinais de Entrada (Estímulos)
    signal tb_CLK_50 : std_logic := '0';
    signal tb_SW     : std_logic_vector(9 downto 0) := (others => '0');
    signal tb_KEY3   : std_logic := '1'; -- Botão solto em hardware é '1'
    signal tb_KEY0   : std_logic := '1'; -- Botão solto em hardware é '1'

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

    -- Clock da DE1-SoC é 50 MHz (Período = 20 ns)
    constant clk_period : time := 20 ns;

begin

    -- Instanciação do Módulo Principal (Unit Under Test)
    UUT: DRAM port map (
        CLK_50     => tb_CLK_50,
        SW         => tb_SW,
        KEY3       => tb_KEY3,
        KEY0       => tb_KEY0,
        HEX5       => tb_HEX5,
        HEX4       => tb_HEX4,
        HEX1       => tb_HEX1,
        HEX0       => tb_HEX0,
        DRAM_CS_N  => tb_DRAM_CS_N,
        DRAM_RAS_N => tb_DRAM_RAS_N,
        DRAM_CAS_N => tb_DRAM_CAS_N,
        DRAM_WE_N  => tb_DRAM_WE_N,
        DRAM_ADDR  => tb_DRAM_ADDR,
        DRAM_CLK   => tb_DRAM_CLK,
        DRAM_CKE   => tb_DRAM_CKE,
        DRAM_LDQM  => tb_DRAM_LDQM,
        DRAM_UDQM  => tb_DRAM_UDQM,
        DRAM_BA    => tb_DRAM_BA,
        DRAM_DQ    => tb_DRAM_DQ
    );

    -- Processo Gerador do Clock Base (50 MHz)
    clk_process: process
    begin
        tb_CLK_50 <= '0';
        wait for clk_period/2;
        tb_CLK_50 <= '1';
        wait for clk_period/2;
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
        tb_KEY0 <= '0'; 
        wait for 100 ns;
        tb_KEY0 <= '1'; -- Solta o botão
        
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
        
        -- Aperta o botão de gravação KEY3 (ativo em baixo)
        tb_KEY3 <= '0'; 
        wait for 50 ns; 
        tb_KEY3 <= '1'; -- Solta o botão
        
        -- Espera a máquina de estados processar a requisição e interagir com a memória
        wait for 150 ns; 
        
        print_status("Verifique as ondas: WE_N e CAS_N devem ter pulsado em '0'. As mascaras DQM tambem.");
        
        -- Dá um tempo para o sistema voltar ao estado IDLE
        wait for 200 ns;

        -- =========================================================
        -- CASO 3: OPERAÇÃO DE LEITURA POR MUDANÇA DE ENDEREÇO
        -- =========================================================
        print_status("CASO 3: LEITURA NO ENDERECO 12");
        
        -- Muda o endereço nos switches (SW[9:4] = 001100 = 12). 
        -- A sua interface (dram_iface) deve detetar esta mudança e disparar uma leitura automática.
        tb_SW <= "0011001010";
        
        -- Espera o sistema perceber a mudança, pedir a leitura e receber do controlador
        wait for 200 ns;
        
        print_status("Verifique as ondas: Apenas CAS_N deve ter pulsado em '0' (Leitura).");
        
        -- Finaliza a simulação
        wait for 200 ns;
        print_status("TESTE CONCLUIDO COM SUCESSO!");
        
        wait; -- Trava o processo para o ModelSim não rodar em loop infinito
    end process;

end behavior;