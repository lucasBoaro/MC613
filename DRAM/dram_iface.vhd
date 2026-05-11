library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity dram_iface is
    Port (
        -- É fundamental ter um clock e, de preferência, um reset
        clk             : in  STD_LOGIC;         
        -- Mudei para 5 downto 0 (6 bits) para acomodar os switches de 9 a 4
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
    type state_type is (Wait_ready, Req_write, Req_read);
    signal state      : state_type := Wait_ready;
    
    -- Registrador para guardar o estado anterior das chaves
    signal previous_switches : STD_LOGIC_VECTOR(5 downto 0) := (others => '0');

begin

    -- =========================================================
    -- LÓGICA COMBINACIONAL: Mapeamento de Endereço e Dados
    -- =========================================================
    
    -- Mapeamento dos Dados (Data)
    -- Bits 3 a 0 recebem os switches, bits 7 a 4 ficam em 0
    data_out_write(3 downto 0) <= data_in_write;
    data_out_write(7 downto 4) <= "0000";

    -- Mapeamento do Endereço (Address)
    -- Primeiro, zera tudo
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


    -- =========================================================
    -- LÓGICA SEQUENCIAL: Máquina de Estados (com Clock!)
    -- =========================================================
    process (clk)
    begin    
        if rising_edge(clk) then
            
            -- Valores padrão para os sinais de controle (evita que fiquem travados em '1')
            write_out <= '0';
            read_out  <= '0';

            case state is
            
                when Wait_ready =>
                    -- Só aceita comandos se a memória estiver pronta
                    if ready = '1' then
                        -- Prioridade 1: Se o botão for apertado, vai escrever
                        if key_3 = '1' then
                            state <= Req_write;
                            
                        -- Prioridade 2: Se não for escrever, verifica se o endereço mudou
                        elsif address /= previous_switches then
                            previous_switches <= address; -- Atualiza a memória da chave
                            state <= Req_read;
                        end if;
                    end if;

                when Req_write =>
                    write_out <= '1';
                    state <= Wait_ready; -- Retorna para esperar o próximo comando

                when Req_read =>
                    read_out <= '1';
                    state <= Wait_ready; -- Retorna para esperar o próximo comando
                    
                when others =>
                    state <= Wait_ready;
                    
            end case;
        end if;
    end process;

end behavior;