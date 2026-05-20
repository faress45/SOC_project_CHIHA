LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY Automate_suiveur_de_ligne IS
    PORT (
        posLigne : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
		VIRAGE   : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        Start_SL : IN  STD_LOGIC;
        clk, rst : IN STD_LOGIC;
        Fin_SL   : OUT STD_LOGIC;
        CmdLR_SL : OUT STD_LOGIC_VECTOR(27 DOWNTO 0)
    );
END ENTITY Automate_suiveur_de_ligne;

ARCHITECTURE arch_rtl OF Automate_suiveur_de_ligne IS

    type etat is (S0, S1, S2);
    signal autom : etat := S0;

    constant CONSIGNE_MOTEUR     : integer := 1900; 
    constant PID                 : integer := 90;    
    constant CONSIGNE_MOTEUR_MAX : integer := 2810;
    constant CONSIGNE_MOTEUR_MIN : integer := 500; 
    constant SEUIL_VIRAGE        : integer := 5;
	 constant CORRECTION_VIRAGE   : integer := 288; 

BEGIN
   automate: process(rst, clk)
   variable posL, var, var1 : integer;
   Variable consigne_MTRR, consigne_MTRL : unsigned(13 downto 0);
   begin 
		if (rst = '0') then 
			CmdLR_SL <= (others => '0');
			Fin_SL   <= '0';
			autom    <= S0;
		elsif rising_edge(clk) then
			case (autom) is
				when S0 =>
					if (Start_SL = '1') then
						Fin_SL<= '0';
						autom <= S1;
					else 
						autom <= S0;
					end if;
				when S1 =>
					posL := to_integer(signed(posLigne)); 
					if (posL < -6 OR posL > 6) then
						Fin_SL <= '1';
						CmdLR_SL <= (others => '0');
						autom <= S2;
					else
						if (VIRAGE = "11") then
							consigne_MTRR := "10" & to_unsigned(CONSIGNE_MOTEUR+CORRECTION_VIRAGE, 12);
							consigne_MTRL := "11" & to_unsigned(CONSIGNE_MOTEUR+CORRECTION_VIRAGE, 12);
						elsif (VIRAGE = "01") then
							consigne_MTRR := "11" & to_unsigned(CONSIGNE_MOTEUR+CORRECTION_VIRAGE, 12);
							consigne_MTRL := "10" & to_unsigned(CONSIGNE_MOTEUR+CORRECTION_VIRAGE, 12);
						else
							var  := CONSIGNE_MOTEUR - PID*posL;
							var1 := CONSIGNE_MOTEUR + PID*posL;
							consigne_MTRR := "10" & to_unsigned(var, 12);
							consigne_MTRL := "10" & to_unsigned(var1, 12);
						end if;
                  CmdLR_SL <= std_LOGIC_VECTOR(consigne_MTRR & consigne_MTRL);
					end if;
				when S2 =>
					if (Start_SL = '0') then
						autom <= S0;
					else
						autom <= S2;
					end if;
			end case;
		end if;
	end process automate;
END ARCHITECTURE arch_rtl;
