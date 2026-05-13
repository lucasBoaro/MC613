LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

package dram_pkg is
    -- O tipo fica disponível globalmente para quem chamar este pacote
    type state_type is (reset_st, init, preChargeAll, autoRefresh_Init, LMR, idle, act, read_st, write_st, precharge, refresh, NOP);
end package dram_pkg;

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
use work.dram_pkg.all; -- Chama o pacote que acabou de ser criado acima!

ENTITY dramController is
    PORT(
        clk_143 : IN STD_LOGIC; -- Clk adaptado para a frequencia da dram
        rst : IN STD_LOGIC; --Valor que reinicializa/inicializa a memória
        address : IN STD_LOGIC_VECTOR(25 DOWNTO 0); -- Endereço de leitura/escrita
        data_in : IN STD_LOGIC_VECTOR(7 DOWNTO 0); --Dado para escrita
        data_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0); -- Dado que foi lido
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
        DRAM_BA : OUT STD_lOGIC_VECTOR (1 DOWNTO 0);
        DRAM_DQ : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0); -- INOUT porque os pinos são bidirecionais (Recebimento e envio de dados na mesma pinagem)
    
        state_debug : OUT state_type
        );
END dramController;

architecture behavior of dramController is
    SIGNAL counter : INTEGER RANGE 0 TO 28572 := 0;
    SIGNAL counter_refresh : INTEGER RANGE 0 to 8 := 0;
    SIGNAL counterAutoRefresh : integer := 0;
    SIGNAL IS_READY : STD_LOGIC := '0';
    SIGNAL block_idle : STD_LOGIC := '0';

    SIGNAL completed : STD_LOGIC := '1'; --Indica se a última requisição foi concluida ou não
    SIGNAL input_data : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL action : STD_LOGIC; -- 1 para Write e 0 para read
    SIGNAL save_addr : STD_LOGIC_VECTOR(25 DOWNTO 0);

    
	-- Register to hold the current state
	signal state : state_type;
    signal next_state : state_type;
    signal read_delay : std_logic_vector(4 downto 0) := "00000";

begin
    state_debug <= state;
    ready <= IS_READY;
	process (clk_143, rst)
	begin
		if rst = '1' then
			state <= reset_st;

		elsif (rising_edge(clk_143)) then
            -- =======================================================
            -- LÓGICA MOVIDA PARA CÁ (Dentro do MESMO process)
            -- Como estamos no mesmo process, o curto-circuito acaba!
            -- =======================================================
            if req = '1' and IS_READY = '1' then
                completed <= '0';
                IS_READY <= '0'; -- Derruba imediatamente para a iface não furar a fila
                input_data <= data_in;
                save_addr <= address;

                if write_in = '1' then
                    action <= '1';
                elsif read_in = '1' then
                    action <= '0';
                end if;
            end if;
            -- =======================================================

			case state is
				when reset_st=> 
						state <= init;
				when init=>
                    counter <= 28572;
                    state <= NOP;
                    next_state <= preChargeAll;
				when preChargeAll=>
                    counter <= 5;
                    state <= NOP;
                    next_state <= autoRefresh_Init;

				when autoRefresh_Init=>
                    if counter_refresh = 8 then
                        counter <= 10;
                        state <= NOP;
                        next_state <= LMR;
                    else
                        counter_refresh <= counter_refresh + 1;
                        counter <= 10;
                        state <= NOP;
                        next_state <= autoRefresh_Init;
                    end if;                    

                when LMR=>
                    counter <= 3;
                    state <= NOP;
                    next_state <= idle;

                when idle=>
                    if block_idle = '0' then
                        if completed = '0' then
                            state <= act;
                        else
                            IS_READY <= '1';
                        end if;
                    else
                        IS_READY <= '0';
                        state <= refresh; -- Ao invés de mexer nos pinos no outro processo, nós transicionamos o estado pra cá.
                    end if;

                when act=>
                    counter <= 4;
                    IS_READY <= '0';
                    if action = '1' then
                        next_state <= write_st;
                    elsif action = '0' then
                        next_state <= read_st;
                    end if;
                    state <= NOP;

                when write_st=>
                    counter <= 3;
                    next_state <= precharge;
                    state <= NOP;

                when read_st=>
                    counter <= 3;
                    next_state <= precharge;
                    state <= NOP;

                when precharge=>
                    counter <= 4;
                    next_state <= idle;
                    state <= NOP;
                    completed <= '1';

                when refresh=>
                    counter <= 10;
                    next_state <= idle;
                    state <= NOP;

                when NOP=>
                    if counter <= 1 then
                        state <= next_state;
                    else
                        counter <= counter - 1;
                    end if;
                    
			end case;

		end if;
	end process;

	-- Determine the output based only on the current state
	-- and the input (do not wait for a clock edge).
	process (state, save_addr, input_data)
	begin
        --Valores default - idle e qualquer estado "imprevisto" cai nesses valores
        DRAM_CS_N  <= '0';
        DRAM_RAS_N <= '1';
        DRAM_CAS_N <= '1';
        DRAM_WE_N  <= '1';
        DRAM_LDQM <= '0';
        DRAM_UDQM <= '0';
        DRAM_CKE <= '1';
        DRAM_ADDR <= (others => '0');
        DRAM_BA <= "00";
        DRAM_DQ <= (others => 'Z');

			case state is
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
                when act=>
                        DRAM_CS_N <= '0';
                        DRAM_RAS_N <= '0';
                        DRAM_CAS_N <= '1';
                        DRAM_WE_N <= '1';
                        DRAM_BA   <= save_addr(24 downto 23); -- 2 bits de banco
                        DRAM_ADDR <= save_addr(22 downto 10); -- 13 bits de linha
                when read_st=>
                        DRAM_CS_N <= '0';
                        DRAM_RAS_N <= '1';
                        DRAM_CAS_N <= '0';
                        DRAM_WE_N <= '1';
                        DRAM_ADDR(10) <= '0';
                        DRAM_BA   <= save_addr(24 downto 23);
                        DRAM_ADDR(9 downto 0) <= save_addr(9 downto 0); -- 10 bits de coluna
                        DRAM_LDQM <= '0';
                        DRAM_UDQM <= '0';
                when write_st=>
                        DRAM_CS_N <= '0';
                        DRAM_RAS_N <= '1';
                        DRAM_CAS_N <= '0';
                        DRAM_WE_N <= '0';
                        DRAM_ADDR(10) <= '0';
                        DRAM_BA   <= save_addr(24 downto 23);
                        DRAM_ADDR(9 downto 0) <= save_addr(9 downto 0); -- 10 bits de coluna
                        DRAM_DQ(7 downto 0)  <= input_data; 
                        DRAM_DQ(15 downto 8) <= (others => '0');
                        DRAM_LDQM <= '0';
                        DRAM_UDQM <= '0';
                when precharge =>
                        DRAM_CS_N <= '0';
                        DRAM_RAS_N <= '0';
                        DRAM_CAS_N <= '1';
                        DRAM_WE_N <= '0';
                        DRAM_ADDR(10) <= '1'; -- O bit 10 em '1' fecha todos os bancos com segurança
                when NOP=>
                        DRAM_CS_N <= '0';
                        DRAM_RAS_N <= '1';
                        DRAM_CAS_N <= '1';
                        DRAM_WE_N <= '1';
                when refresh=>
                        DRAM_CS_N <= '0';
                        DRAM_RAS_N <= '0';
                        DRAM_CAS_N <= '0';
                        DRAM_WE_N <= '1';
                when others => 
                        null;
			end case;
	end process;

    process (clk_143)
    begin
        if rising_edge(clk_143) then
            counterAutoRefresh <= counterAutoRefresh + 1;
            if IS_READY = '1' and counterAutoRefresh >= 1000 then
                block_idle <= '1';
                counterAutoRefresh <= 0;
            end if;

            if block_idle = '1' and counterAutoRefresh = 9 then
                block_idle <= '0';
                counterAutoRefresh <= 0;
            end if;
        end if;
    end process;
    
    process (clk_143, rst)
    begin
        if rst = '1' then
            data_out <= (others => '0');
            read_delay <= "00000";
        elsif falling_edge(clk_143) then
            -- Mapeamento rígido e exato para CAS Latency = 3
            -- O dado sai da DRAM na janela entre 29.9ns e 34.0ns.
            -- A borda falling_edge verdadeira correspondente atinge = 31.5ns (index 4).
            read_delay(0) <= '0';
            if state = read_st then
                read_delay(0) <= '1';
            end if;
            read_delay(1) <= read_delay(0);
            read_delay(2) <= read_delay(1);
            read_delay(3) <= read_delay(2);
            read_delay(4) <= read_delay(3);
            
            if read_delay(4) = '1' then
                data_out <= DRAM_DQ(7 downto 0);
            end if;
        end if;
    end process;
    
end behavior;
