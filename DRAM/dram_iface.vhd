library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity dram_iface is
    Port (
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
    signal state : state_type := Wait_ready;

    signal previous_key_3 : STD_LOGIC := '1'; 
    signal write_pending : STD_LOGIC := '0';
begin

    -- Bits 3 a 0 recebem os switches, bits 7 a 4 ficam em 0
    data_out_write(3 downto 0) <= data_in_write;
    data_out_write(7 downto 4) <= "0000";

    -- Mapeamento dos bits de endereço conforme os switches
    process(address)
    begin
        data_out_adress <= (others => '0'); 

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
                write_pending <= '0';        
                previous_key_3 <= '1';        
            else
                -- Lógica de detecção de borda no botão e espera para escrita
                previous_key_3 <= key_3;
                if previous_key_3 = '1' and key_3 = '0' then
                    write_pending <= '1'; 
                end if;
                
                -- Máquina de Estados (Transições)
                case state is
                    when Wait_ready =>
                        if ready = '1' then
                            if write_pending = '1' then
                                write_pending <= '0';
                                state <= Req_write;
                            else
                                state <= Req_read;
                            end if;
                        end if;

                    when Req_write =>
                        if ready = '0' then 
                            state <= wait_write; 
                        end if;
                    
                    when wait_write =>
                        if ready = '1' then 
                            state <= Wait_ready;
                        end if;

                    when Req_read =>
                        if ready = '0' then
                            state <= wait_read; 
                        end if;
                    
                    when wait_read =>
                        if ready = '1' then
                            state <= Wait_ready;
                        end if;

                    when others =>
                        state <= Wait_ready;                
                end case;

            end if;
        end if;
    end process;

    process(state)
    begin
        read_out <= '0';
        write_out <= '0';
        
        case state is
            when Req_write =>
                write_out <= '1';
                
            when Req_read =>
                read_out <= '1';
                
            when others =>
                null;
        end case;
    end process;

end behavior;
