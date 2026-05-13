library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity dram_iface is
    Port (
        -- É fundamental ter um clock e, de preferência, um reset
        clk             : in  STD_LOGIC;     
        rst             : in  STD_LOGIC;    
        address         : in  STD_LOGIC_VECTOR(5 downto 0); 
        data_in_write   : in  STD_LOGIC_VECTOR(3 downto 0);
        key_3           : in  STD_LOGIC;
        ready           : in  STD_LOGIC;
        data_out_adress : out STD_LOGIC_VECTOR(25 downto 0);
        data_out_write  : out STD_LOGIC_VECTOR(7 downto 0);
        write_out       : out STD_LOGIC;
        read_out        : out STD_LOGIC
    );
end dram_iface;

architecture behavior of dram_iface is

    -- Declaração dos estados
    type state_type is (Wait_ready, Req_write, Req_read, wait_write, wait_read);
    signal state      : state_type := Wait_ready;
    
    -- Registrador para guardar o estado anterior das chaves
    signal previous_switches : STD_LOGIC_VECTOR(5 downto 0) := (others => '0');

    signal req_counter : integer range 0 to 3 := 0;

    signal previous_key_3 : STD_LOGIC := '1'; 
    signal write_pendindg : STD_LOGIC := '0';
begin

    -- =========================================================
    -- LÓGICA COMBINACIONAL: Mapeamento de Endereço e Dados
    -- =========================================================
    
    -- Mapeamento dos Dados (Data)
    -- Bits 3 a 0 recebem os switches, bits 7 a 4 ficam em 0
    data_out_write(3 downto 0) <= data_in_write;
    data_out_write(7 downto 4) <= "0000";

    process(address)
    begin
        data_out_adress <= (others => '0'); 
        
        -- Agora sobrescreve apenas as posições especificadas
        -- SW[5:4] -> address[1:0]
        data_out_adress(0)  <= address(0); 
        data_out_adress(1)  <= address(1); 
        
        -- SW[8:6] -> address[23:21]
        data_out_adress(21) <= address(2); 
        data_out_adress(22) <= address(3); 
        data_out_adress(23) <= address(4); 
        
        -- SW[9] -> address[25]
        data_out_adress(25) <= address(5); 
    end process;


    process (clk)
    begin    
        if rising_edge(clk) then
            if rst = '1' then 
                state <= Wait_ready;
                req_counter <= 0;             
                write_pendindg <= '0';        
                write_out <= '0';             
                read_out <= '0';              
                previous_switches <= address; 
                previous_key_3 <= '1';        
            
            else
                previous_key_3 <= key_3;
                if previous_key_3 = '1' and key_3 = '0' then
                    write_pendindg <= '1'; 
                end if;
                case state is
                
                    when Wait_ready =>
                        read_out <= '0';
                        write_out <= '0';
                        -- Só aceita comandos se a memória estiver pronta
                        if ready = '1' then
                            if write_pendindg = '1' then
                                write_pendindg <= '0';
                                state <= Req_write;
                            elsif address /= previous_switches then
                                previous_switches <= address; -- Atualiza a memória da chave
                                state <= Req_read;
                            end if;
                        end if;

                    when Req_write =>
                        write_out <= '1';
                        if req_counter < 2 then
                            req_counter <= req_counter + 1; -- Incrementa o contador de requisições
                            state <= Req_write; -- Continua no estado de escrita
                        else
                            req_counter <= 0; -- Reseta o contador
                            state <= wait_write; -- Volta para esperar o próximo comando
                        end if;
                    
                    when wait_write =>
                        write_out <= '0';
                        if ready = '1' then 
                            state <= Req_read; -- Retorna para esperar o próximo comando
                        else
                            state <= wait_write; -- Continua esperando
                        end if;

                    when Req_read =>
                        read_out <= '1';
                        if req_counter < 2 then
                            req_counter <= req_counter + 1; -- Incrementa o contador de requisições
                            state <= Req_read; -- Continua no estado de leitura
                        else
                            req_counter <= 0; -- Reseta o contador
                            state <= wait_read; -- Volta para esperar o próximo comando
                        end if;
                    
                    when wait_read =>
                        read_out <= '0';
                        if ready = '1' then
                            state <= Wait_ready; -- Retorna para esperar o próximo comando
                        else
                            state <= wait_read; -- Continua esperando
                        end if;

                    when others =>
                        state <= Wait_ready;
                        
                end case;
				end if;
        end if;
    end process;

end behavior;