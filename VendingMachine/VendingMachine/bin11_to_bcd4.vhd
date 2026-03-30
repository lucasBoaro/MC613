library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bin11_to_bcd4 is
  port (
    bin  : in  std_logic_vector(10 downto 0);  -- 0..2047 (usar 0..1499)
    bcd  : out std_logic_vector(15 downto 0)   -- milhar|centena|dezena|unidade
  );
end entity;

architecture rtl of bin11_to_bcd4 is
begin
  process(all)
    variable x   : unsigned(10 downto 0);
    variable acc : unsigned(15 downto 0);
  begin
    x   := unsigned(bin);
    acc := (others => '0');

    for i in 10 downto 0 loop

      if acc(3 downto 0)   > 4 then acc(3 downto 0)   := acc(3 downto 0)   + 3; end if;
      if acc(7 downto 4)   > 4 then acc(7 downto 4)   := acc(7 downto 4)   + 3; end if;
      if acc(11 downto 8)  > 4 then acc(11 downto 8)  := acc(11 downto 8)  + 3; end if;
      if acc(15 downto 12) > 4 then acc(15 downto 12) := acc(15 downto 12) + 3; end if;

      acc := acc(14 downto 0) & x(i);
    end loop;

    bcd <= std_logic_vector(acc);
  end process;
end architecture;