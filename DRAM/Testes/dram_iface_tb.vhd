library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

entity tb_dram_iface is
end tb_dram_iface;

architecture behavior of tb_dram_iface is

    component dram_iface
        Port (
            clk             : in  STD_LOGIC;         
            address_in      : in  STD_LOGIC_VECTOR(5 downto 0); 
            data_in_write   : in  STD_LOGIC_VECTOR(3 downto 0);
            key_3           : in  STD_LOGIC;
            ready           : in  STD_LOGIC;
            address_out     : out STD_LOGIC_VECTOR(25 downto 0);
            data_out_write  : out STD_LOGIC_VECTOR(7 downto 0);
            write_out       : out STD_LOGIC;
            read_out        : out STD_LOGIC
        );
    end component;

    -- Sinais de entrada para o DUT
    signal tb_clk             : std_logic := '0';
    signal tb_address_in      : std_logic_vector(5 downto 0) := (others => '0');
    signal tb_data_in_write   : std_logic_vector(3 downto 0) := (others => '0');
    signal tb_key_3           : std_logic := '1';
    signal tb_ready           : std_logic := '0';

    -- Sinais de saída do DUT
    signal tb_address_out     : std_logic_vector(25 downto 0);
    signal tb_data_out_write  : std_logic_vector(7 downto 0);
    signal tb_write_req       : std_logic;
    signal tb_read_req        : std_logic;

    -- Controle da simulação
    signal sim_finished       : boolean := false; 
    constant clk_period       : time := 20 ns;

begin

    UUT: dram_iface port map (
        clk             => tb_clk,
        address_in      => tb_address_in,
        data_in_write   => tb_data_in_write,
        key_3           => tb_key_3,
        ready           => tb_ready,
        address_out     => tb_address_out,
        data_out_write  => tb_data_out_write,
        write_out       => tb_write_req,
        read_out        => tb_read_req
    );

    clk_process : process 
    begin
        while not sim_finished loop
            tb_clk <= '0'; wait for clk_period/2;
            tb_clk <= '1'; wait for clk_period/2;
        end loop;
        wait;
    end process;

    stim_proc: process
        variable line_out : line;
        
        procedure print_status(msg : string) is 
        begin
            write(line_out, string'("--- ")); write(line_out, msg); write(line_out, string'(" ---")); writeline(output, line_out);
            write(line_out, string'("Addr Out: ")); write(line_out, to_integer(unsigned(tb_address_out)));
            write(line_out, string'(" | Data Out: ")); write(line_out, to_integer(unsigned(tb_data_out_write)));
            write(line_out, string'(" | Write Req: ")); write(line_out, tb_write_req);
            write(line_out, string'(" | Read Req: ")); write(line_out, tb_read_req);
            writeline(output, line_out); writeline(output, line_out);
        end procedure;

    begin
        write(line_out, string'("Iniciando Teste do dram_iface com Log...")); writeline(output, line_out); writeline(output, line_out);
        
        -- Simulamos que o controlador DRAM está ligado e pronto para receber uma requisição
        tb_ready <= '1'; 
        wait for 100 ns;

        -- =========================================================
        -- OPERAÇÃO DE ESCRITA
        -- =========================================================
        write(line_out, string'("=== OPERAÇÃO DE ESCRITA ===")); writeline(output, line_out);
        
        -- Simula usuário digitando o valor 10 e em seguida apertando o botão key 3 para solicitar a requisição da escrita
        tb_data_in_write <= "1010"; 
        tb_key_3 <= '0'; wait for 40 ns; tb_key_3 <= '1'; -- Simula clicar e soltar o botão
        
        wait for 40 ns; -- Devemos esperar um ciclo de clock para que o estado seja atualizado (deve entrar no estado de requisição de escrita)

        print_status("Apertou KEY_3. (write_req deve estar em '1')");
        
        tb_ready <= '0'; -- Está processando a escrita
        wait for 140 ns; -- Espera o tempo necessário para processar a escrita
        print_status("Passou os 3 clocks dentro do estado de requisição de escrita, agora deve estar no estado wait_write, esperando o ready voltar a '1' para finalizar a escrita. (write_req deve estar em '0')");
        tb_ready <= '1'; -- Terminou de gravar e voltou a ficar pronto para receber requisições
        
        wait for 40 ns; -- Espera um ciclo de clock para atualizar o estado 
        print_status("Escrita terminou. (read_req automatico deve estar em '1')");
        
        tb_ready <= '0'; -- Está processando a leitura
        wait for 140 ns; -- Espera o tempo necessário para processar a leitura
        print_status("Passou os 3 clocks dentro do estado de requisição de leitura, agora deve estar no estado wait_read, esperando o ready voltar a '1' para finalizar a leitura. (read_req deve estar em '0')");
        tb_ready <= '1'; -- Terminou de ler e voltou a ficar pronto para receber requisições
        wait for 100 ns;

        -- =========================================================
        -- OPERAÇÃO DE LEITURA POR MUDANÇA DE ENDEREÇO
        -- =========================================================
        write(line_out, string'("=== OPERAÇÃO DE LEITURA POR MUDANÇA DE ENDEREÇO ===")); writeline(output, line_out);
        
        -- Nota: Simulando os bits mapeados (SW 5 e 4 controlam os bits 1 e 0 do Address)
        tb_address_in <= "000011"; -- Usuário altera o switch
        wait for 40 ns; -- Espera um ciclo de clock para que o estado seja atualizado (deve entrar no estado de requisição de leitura)        
        print_status("Switch alterado. (read_req deve estar em '1')");
        
        tb_ready <= '0'; -- Está processando a leitura
        wait for 140 ns;
        print_status("Passou os 3 clocks dentro do estado de requisição de leitura, agora deve estar no estado wait_read, esperando o ready voltar a '1' para finalizar a leitura. (read_req deve estar em '0')");
        tb_ready <= '1'; -- Terminou de ler e voltou a ficar pronto para receber requisições
        wait for 100 ns;

        -- =========================================================
        -- OPERAÇÃO DE ESCRITA, DURANTE UM REFRESH (READY EM '0')
        -- =========================================================
        write(line_out, string'("=== OPERAÇÃO DE ESCRITA, DURANTE UM REFRESH (READY EM '0') ===")); writeline(output, line_out);
        
        tb_ready <= '0'; -- Controlador está fazendo um Refresh
        wait for 60 ns;
        
        -- Simula o usuário mudando o valor a ser escrito para 7
        tb_data_in_write <= "0111"; 
        tb_key_3 <= '0'; wait for 40 ns; tb_key_3 <= '1'; -- Simula clicar e soltar o botão para solicitar a escrita
        wait for 40 ns; 
        
        print_status("Botao apertado, mas a RAM esta em Refresh (write_req DEVE ser '0')");
        wait for 140 ns;  
        
        tb_ready <= '1'; -- Controlador finaliza o Refresh e volta a ficar pronto para receber requisições
        wait for 40 ns; 
        
        print_status("Refresh acabou, a chamada da escrita deve ser realizada agora. (write_req deve estar em '1')");
        
        tb_ready <= '0'; -- Controlador processa a escrita
        wait for 140 ns;
        tb_ready <= '1'; -- Controlador finaliza a escrita e volta a ficar pronto para receber requisições
        
        wait for 40 ns;
        tb_ready <= '0'; -- Leitura automática
        wait for 140 ns;
        tb_ready <= '1';
        wait for 100 ns;

        -- =========================================================
        write(line_out, string'("Teste concluido com sucesso!"));
        writeline(output, line_out);
        
        sim_finished <= true; -- Para o clock e encerra a simulação lindamente
        wait;
    end process;
end behavior;