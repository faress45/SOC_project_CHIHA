LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY Mux IS
    PORT(
			  clk, rst  : IN STD_LOGIC;
			  Start_SL  : IN STD_LOGIC;
			  Start_rot : IN STD_LOGIC;
			  CmdLR_rot : IN STD_LOGIC_VECTOR(27 DOWNTO 0);
			  CmdLR_SL  : IN STD_LOGIC_VECTOR(27 DOWNTO 0);
			  PosLigne  : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
			  START     : OUT STD_LOGIC;
			  CmdLR     : OUT STD_LOGIC_VECTOR(27 DOWNTO 0)		  
		  );
END ENTITY Mux;

ARCHITECTURE Mux_rtl OF Mux IS

type state_type is (S0, S1, S2, S3);

signal autom : state_type := S0;

constant MAX_COUNT : integer := 50_000_000;

BEGIN

	Mux_Autom : process(rst, clk)
	variable posL, count : integer;
	begin
		if(rst = '0') then
			CmdLR <= (others => '0');
			count := 0;
			START <= '0';
		elsif(rising_edge(clk)) then 
			case(autom) is
				when S0 =>
					posL := to_integer(signed(posLigne)); 
					if (posL < -6 OR posL > 6) then
						autom <= S0;
					else 
						START <= '1';
						autom <= S1;
					end if;
				when S1 =>
					if(Start_SL = '1') then
						CmdLR <= CmdLR_SL;
					else
						if(count >= Max_COUNT) then
							count := 0;
							autom <= S2;
						else
							count := count + 1;
						end if;
					end if;
				when S2 =>
					if(Start_rot = '1') then
						CmdLR <= CmdLR_rot;
					else
						if(count >= Max_COUNT) then
							count := 0;
							autom <= S3;
						else
							count := count + 1;
						end if;
					end if;
				when S3 =>
					if(Start_SL = '1') then
						autom <= S1;
					else
						autom <= S3;
					end if;
			end case;
		end if;
	end process;

END ARCHITECTURE Mux_rtl;