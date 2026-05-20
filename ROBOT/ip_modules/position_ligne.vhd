LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY position_ligne IS
    PORT (
        data_capteur : IN  STD_LOGIC_VECTOR(6 DOWNTO 0);
        pos_ligne    : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        data_ready   : IN  STD_LOGIC;
        led          : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
		VIRAGE       : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
    );
END ENTITY position_ligne;

ARCHITECTURE position_ligne_arch_rtl OF position_ligne IS

BEGIN
    posLigne: process(data_ready)
	 variable PPU, PDU  : integer;
	 variable first_one : boolean := false;
    BEGIN
        if data_ready = '1' then
				PPU := 7;
				PDU := 7;
				first_one := false;
            for i in 0 to 6 loop
                if data_capteur(i) = '1' then
                    if not first_one then
                        PPU       := i;
                        first_one := true;
                    end if;
                    PDU := i;
						  led(i) <= '1';
                end if;
            end loop;
                    
            if PPU /= 7 and PDU /= 7 then
					 pos_ligne <= std_logic_vector(to_signed((PPU + PDU - 6), 4));
					 if(PPU = 3 and PDU >= 5) then 
						VIRAGE <= "01";
					 elsif(PPU = 0 and PDU >= 2) then 
						VIRAGE <= "11";
					 else
						VIRAGE <= "00";
					 end if;
				else
					 pos_ligne <= std_logic_vector(to_unsigned(8, 4));
				end if;
        else
            led <= (others => '0');
        end if;
    end process posLigne;
END ARCHITECTURE position_ligne_arch_rtl;
