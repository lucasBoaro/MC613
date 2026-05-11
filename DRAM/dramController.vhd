LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY dramController is
    PORT(
        clk_143 : IN STD_LOGIC; -- Clk adaptado para a frequencia da dram
        rst : IN STD_LOGIC; --Valor que reinicializa/inicializa a memória
        address : IN STD_LOGIC_VECTOR(25 DOWNTO 0); -- Endereço de leitura/escrita
        data_in : IN STD_LOGICVECTOR(7 DOWNTO 0); --Dado para escrita
        data_out : OUT STD_LOGICVECTOR(7 DOWNTO 0); -- Dado que foi lido
        req : IN STD_LOGIC; -- Indica se há requisição
        ready : OUT STD_LOGIC; -- Indica que o controlador pode receber uma requisição
        write_in : IN STD_lOGIC;
        read_in  : IN STD_LOGIC;

        DRAM_CS_N : OUT STD_LOGIC;
        DRAM_RAS_N : OUT STD_LOGIC;
        DRAM_CAS_N : OUT STD_LOGIC;
        DRAM_WE_N : OUT STD_LOGIC;
        DRAM_ADDR : OUT STD_LOGIC_VECTOR (12 DOWNTO 0);
        DRAM_CKE : OUT STD_lOGIC;
        DRAM_LDQM : OUT STD_lOGIC;
        DRAM_UDQM : OUT STD_lOGIC;
        DRAM_BA : OUT STD_lOGIC_VECTOR (1 DOWNTO 0)
        
    )
END dramController;

architecture behavior of dramController is
    SIGNAL counter : INTEGER RANGE 0 TO 28572 := 0;
    SIGNAL counter_refresh : INTEGER RANGE 0 to 8 := 0;
    SIGNAL counterAutoRefresh : integer range 0 to 1116;
    SIGNAL IS_READY : STD_LOGIC := '0';
    SIGNAL block_idle : STD_LOGIC := '0';

    
    

	-- Build an enumerated type for the state machine
	type state_type is (reset, init, preChargeAll, autoRefresh_Init, LMR, idle, act, read, write, precharge, refresh, NOP);

	-- Register to hold the current state
	signal state : state_type;
    signal next_state : state_type;

begin
    ready <= IS_READY;
	process (clk, reset)
	begin
		if rising_edge(reset) then
			state <= reset;

		elsif (rising_edge(clk)) then
			case state is
				when reset=> 
						state <= init;
				when init=>
                    counter = 28572;
                    state <= NOP;
                    next_state <= preChargeAll;
				when preChargeAll=>
                    counter = 4;
                    state <= NOP;
                    next_state <= autoRefresh_Init;

				when autoRefresh_Init=>
                    if counter_refresh = 8 then
                        state <= LMR;
                    end if;                    
                    counter_refresh += 1;
                    counter = 9
                    state <= NOP
                    next_state <= autoRefresh_Init;

                when LMR=>
                    counter = 2;
                    state <= NOP;
                    next_state <= idle;

                when idle=>
                    IS_READY <= '1';
                    
                    if block_idle = '0' then
                        if req = '1' then
                            state <= act;
                        end if;
                    end if;

                when NOP=>
                    if counter =< 1 then
                        state <= next_state;
                    else
                        counter -= 1;
                    end if;
                when act=>
                    counter = 3;
                    state <= NOP;

                    if write_in = '1' then
                        next_state <= write;
                    elsif read_in = '1' then
                        next_state <= read;
                    end if;

                when write=>
                    
			end case;

		end if;
	end process;

	-- Determine the output based only on the current state
	-- and the input (do not wait for a clock edge).
	process (state, input)
	begin
			case state is
				when init=>
                        DRAM_CS_N <= '0';
                        DRAM_RAS_N <= '1';
                        DRAM_CAS_N <= '1';
                        DRAM_WE_N <= '1';
                        DRAM_LDQM <= '1';
                        DRAM_UDQM <= '1';
                        DRAM_CKE <= '1';
				when preChargeAll=>
					    DRAM_CS_N <= '0';
                        DRAM_RAS_N <= '0';
                        DRAM_CAS_N <= '1';
                        DRAM_WE_N <= '0';
                        DRAM_ADDR(10) <= '1';
				when autoRefresh_Init=>
					    DRAM_CS_N <= '0';
                        DRAM_RAS_N <= '0';
                        DRAM_CAS_N <= '0';
                        DRAM_WE_N <= '1';
                when LMR=>
                        DRAM_CS_N <= '0';
                        DRAM_RAS_N <= '0';
                        DRAM_CAS_N <= '0';
                        DRAM_WE_N <= '0';
                        DRAM_BA <= "00";
                        DRAM_ADDR <= "0000000110000"; --M4 e M5 setados iguais a 1
                when NOP=>
                        DRAM_CS_N <= '0';
                        DRAM_RAS_N <= '1';
                        DRAM_CAS_N <= '1';
                        DRAM_WE_N <= '1';
			end case;
	end process;

    process (clk) is
        begin
            counterAutoRefresh += 1;
            if IS_READY = '1' and counterAutoRefresh >= 1000 then
                block_idle <= '1';
                DRAM_CS_N <= '0';
                DRAM_RAS_N <= '0';
                DRAM_CAS_N <= '0';
                DRAM_WE_N <= '1';
                counterAutoRefresh = 0;
            end if;

            if block_idle = 1 and counterAutoRefresh = 9 then
                block_idle <= '0';
                counterAutoRefresh = 0;
            end if;

            

end rtl;

        

    BEGIN
