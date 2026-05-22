library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

entity dram_iface_tb is
end dram_iface_tb;

architecture behavior of dram_iface_tb is

    component dram_iface
        Port (
            clk             : in  STD_LOGIC;         
            rst             : in  STD_LOGIC;
            address         : in  STD_LOGIC_VECTOR(5 downto 0); 
            data_in_write   : in  STD_LOGIC_VECTOR(3 downto 0);
            key_3           : in  STD_LOGIC;
            ready           : in  STD_LOGIC;
            data_out_adress     : out STD_LOGIC_VECTOR(25 downto 0);
            data_out_write  : out STD_LOGIC_VECTOR(7 downto 0);
            write_out       : out STD_LOGIC;
            read_out        : out STD_LOGIC
        );
    end component;

    signal tb_clk             : std_logic := '0';
    signal tb_rst             : std_logic := '0';
    signal tb_address_in      : std_logic_vector(5 downto 0) := (others => '0');
    signal tb_data_in_write   : std_logic_vector(3 downto 0) := (others => '0');
    signal tb_key_3           : std_logic := '1';
    signal tb_ready           : std_logic := '0';

    signal tb_address_out     : std_logic_vector(25 downto 0);
    signal tb_data_out_write  : std_logic_vector(7 downto 0);
    signal tb_write_req       : std_logic;
    signal tb_read_req        : std_logic;

    signal sim_finished       : boolean := false; 
    constant clk_period       : time := 7 ns;

begin

    UUT: dram_iface port map (
        clk             => tb_clk,
        address         => tb_address_in,
        rst             => tb_rst,
        data_in_write   => tb_data_in_write,
        key_3           => tb_key_3,
        ready           => tb_ready,
        data_out_adress     => tb_address_out,
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

        -- =========================================================
        -- OPERACAO DE ESCRITA
        -- =========================================================
			write(line_out, string'("OPERACAO DE ESCRITA"));
        -- Simula usuário digitando o valor 10 e em seguida apertando o botão key 3 para solicitar a requisição da escrita
        tb_data_in_write <= "1010"; 
        tb_key_3 <= '0'; wait for 7 ns; tb_key_3 <= '1'; -- Simula clicar o botão
        tb_ready <= '1';  
        
        wait for 14 ns; -- Devemos esperar dois ciclos de clock para que o estado seja atualizado (deve entrar no estado de requisição de escrita)
        wait for 70 ns; -- Podemos esperar o tempo que for, pois o estado só deve mudar após o sinal ready = 0
        print_status("Apertou KEY_3. (write_req deve estar em '1')");
        
        tb_ready <= '0'; -- Está processando a escrita
        wait for 14 ns; -- Espera dois ciclos de clock para atualizar o estado
        wait for 70 ns; -- Podemos esperar o tempo que for, pois o estado só deve mudar após o sinal ready = 1
        print_status("A requisição de escrita já foi realizada, agora deve estar no estado wait_write, esperando o ready voltar a '1' para finalizar a escrita. (write_req deve estar em '0')");
        tb_ready <= '1'; -- Terminou de gravar e voltou a ficar pronto para receber requisições
        
        wait for 21 ns; -- Espera três ciclos de clock para atualizar o estado 
        print_status("Escrita terminou. (read_req automatico deve estar em '1')");
        
        tb_ready <= '0'; -- Está processando a leitura
        wait for 14 ns; -- Espera dois ciclos de clock para atualizar o estado
        wait for 70 ns; -- Podemos esperar o tempo que for, pois o estado só deve mudar após o sinal ready = 1        
        print_status("A requisição de leitura já foi realizada, agora deve estar no estado wait_read, esperando o ready voltar a '1' para finalizar a leitura. (read_req deve estar em '0')");
        tb_ready <= '1'; -- Terminou de ler e voltou a ficar pronto para receber requisições

        -- =========================================================
        -- OPERACAO DE LEITURA AUTOMÁTICA
        -- =========================================================
        write(line_out, string'("=== OPERACAO DE LEITURA AUTOMATICA ===")); writeline(output, line_out);
        
        tb_address_in <= "000011"; -- Usuário altera o switch
        wait for 21 ns; -- Espera um ciclo de clock para que o estado seja atualizado (deve entrar no estado de requisição de leitura)        
        print_status("Leitura automática solicitada. (read_req deve estar em '1')");
        
        tb_ready <= '0'; -- Está processando a leitura
        wait for 14 ns; -- Espera dois ciclos de clock para atualizar o estado
        wait for 70 ns; -- Podemos esperar o tempo que for, pois o estado só deve mudar após o sinal ready = 1        
        print_status("A requisição de leitura já foi realizada, agora deve estar no estado wait_read, esperando o ready voltar a '1' para finalizar a leitura. (read_req deve estar em '0')");
        tb_ready <= '1'; -- Terminou de ler e voltou a ficar pronto para receber requisições
        wait for 7 ns;

        -- =========================================================
        -- OPERACAO DE ESCRITA, DURANTE UM REFRESH (READY EM '0')
        -- =========================================================
        write(line_out, string'("=== OPERACAO DE ESCRITA, DURANTE UM REFRESH (READY EM '0') ===")); writeline(output, line_out);
        
        tb_ready <= '0'; -- Controlador está fazendo um Refresh
        wait for 21 ns;
        
        -- Simula o usuário mudando o valor a ser escrito para 7
        tb_data_in_write <= "0111"; 
        tb_key_3 <= '0'; wait for 14 ns; tb_key_3 <= '1'; -- Simula clicar e soltar o botão para solicitar a escrita
        wait for 14 ns; 
        
        print_status("Botao apertado, mas a RAM esta em Refresh (write_req DEVE ser '0')");
        wait for 49 ns;  
        
        tb_ready <= '1'; -- Controlador finaliza o Refresh e volta a ficar pronto para receber requisições
        wait for 14 ns; 
        
        print_status("Refresh acabou, a chamada da escrita deve ser realizada agora. (write_req deve estar em '1')");
        
        tb_ready <= '0'; -- Controlador processa a escrita
        wait for 49 ns;
        tb_ready <= '1'; -- Controlador finaliza a escrita e volta a ficar pronto para receber requisições
        
        wait for 14 ns;
        tb_ready <= '0'; -- Leitura automática
        wait for 49 ns;

        -- =========================================================
        -- OPERACAO INTERROMPIDA POR RESET
        -- =========================================================
        write(line_out, string'("=== OPERACAO INTERROMPIDA POR RESET ===")); writeline(output, line_out);   

        -- Simula usuario a pedir para escrever o valor 15 
        tb_data_in_write <= "1111";
        tb_key_3 <= '0'; wait for 7 ns; tb_key_3 <= '1';
        tb_ready <= '1'; -- Controlador recebe a requisição de escrita
        
        wait for 7 ns; -- Espera 1 ciclo para entrar no estado Req_write
        
        print_status("Iniciou a escrita. O sinal (write_req deve estar em '1')");

        -- Simula o usuário apertando o botão de reset durante a escrita
        tb_rst <= '1';
        wait for 14 ns; 
        
        print_status("Reset apertado. A maquina deve voltar ao estado inicial (write_req deve cair para '0')");
        
        -- Solta o botao de reset
        tb_rst <= '0';
        wait for 7 ns;
        
        print_status("Reset solto. Sistema em Wait_ready.");
        -- =========================================================
        write(line_out, string'("Teste concluido com sucesso!"));
        writeline(output, line_out);
        
        sim_finished <= true; -- Para o clock e encerra a simulação
        wait;
    end process;
end behavior;