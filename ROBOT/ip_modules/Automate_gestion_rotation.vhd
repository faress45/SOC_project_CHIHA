LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY Automate_gestion_rotation IS
    PORT (
        start_rot   : IN  STD_LOGIC;
		  dir_rot   : IN  STD_LOGIC;
		  clk       : IN  STD_LOGIC;
		  rst       : IN  STD_LOGIC;
		  posLigne  : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
        fin_rot     : OUT STD_LOGIC;
        CmdLR_rot   : OUT STD_LOGIC_VECTOR(27 DOWNTO 0)
    );
END ENTITY Automate_gestion_rotation;

ARCHITECTURE Automate_gestion_rotation_rtl OF Automate_gestion_rotation IS

    type etat is (S1, S2);
    signal autom : etat := S1;

    constant CONSIGNE_MOTEUR : integer := 1900; 

BEGIN
    automate: process(rst, clk)
    variable posL, var, var1 : integer;
    Variable consigne_MTRR, consigne_MTRL : unsigned(13 downto 0);
    begin 
        if (rst = '0') then 
            CmdLR_rot <= (others => '0');
            Fin_rot   <= '1';
            autom     <= S1;
        elsif rising_edge(clk) then
            case (autom) is
                when S1 => 
						if(start_rot = '1') then
							Fin_rot <= '0';
							posL := to_integer(signed(posLigne));
							if(posL = 0) then
								CmdLR_rot <= (others => '0');
								Fin_rot <= '1';
								autom   <= S2;
						else
							if(dir_rot =  '1') then 
								consigne_MTRR := "10" & to_unsigned(CONSIGNE_MOTEUR, 12);
								consigne_MTRL := "11" & to_unsigned(CONSIGNE_MOTEUR, 12);
							else 
								consigne_MTRR := "11" & to_unsigned(CONSIGNE_MOTEUR, 12);
								consigne_MTRL := "10" & to_unsigned(CONSIGNE_MOTEUR, 12);
							end if;
							CmdLR_rot <= std_LOGIC_VECTOR(consigne_MTRR & consigne_MTRL);
						end if;
					else
						autom <= S1;
					end if;
				when S2 =>
					if (start_rot = '0') then
						autom <= S1;
					else 
						autom <= S2;
					end if;
            end case;
        end if;
    end process automate;
END ARCHITECTURE Automate_gestion_rotation_rtl;
				