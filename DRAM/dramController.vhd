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
        wEn : IN STD_LOGIC; -- 
        ready : OUT STD_LOGIC -- Indica que o controlador pode receber uma requisição
    )
END dramController;

architecture behavior of dramController is
    SIGNAL counter : INTEGER RANGE 0 TO 28572 := 0;

	-- Build an enumerated type for the state machine
	type state_type is (reset, init, preChargeAll, autoRefresh_Init, LMR, idle, act, read, write, precharge, refresh, NOP);

	-- Register to hold the current state
	signal state : state_type;

begin

	process (clk, reset)
	begin

		if reset = '1' then
			state <= reset;

		elsif (rising_edge(clk)) then

			counter += 1;
			case state is
				when reset=>
						state <= init;
				when init=>
					if input = '1' then
						state <= preChargeAll;
					else
						state <= init;
					end if;
				when preChargeAll=>
					if input = '1' then
						state <= autoRefresh_Init;
					else
						state <= preChargeAll;
					end if;
				when autoRefresh_Init=>
					if input = '1' then
						state <= autoRefresh_Init;
					else
						state <= init;
					end if;
                
			end case;

		end if;
	end process;

	-- Determine the output based only on the current state
	-- and the input (do not wait for a clock edge).
	process (state, input)
	begin
			case state is
				when reset=>
					if input = '1' then
						output <= "00";
					else
						output <= "01";
					end if;
				when init=>
					if input = '1' then
						output <= "01";
					else
						output <= "11";
					end if;
				when preChargeAll=>
					if input = '1' then
						output <= "10";
					else
						output <= "10";
					end if;
				when autoRefresh_Init=>
					if input = '1' then
						output <= "11";
					else
						output <= "10";
					end if;
			end case;
	end process;

end rtl;

        

    BEGIN
