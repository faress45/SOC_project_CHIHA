LIBRARY ieee;
USE ieee.std_logic_1164.all;
ENTITY hex7seg IS
    PORT (
        hex     : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
        display : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
    );
END hex7seg;
ARCHITECTURE Behavior OF hex7seg IS
BEGIN
    --      --0--
    --     5|   |1
    --      --6--
    --     4|   |2
    --      --3--
    -- display(n) contrôle le segment n (actif bas)
    PROCESS (hex)
    BEGIN
        CASE hex IS
            WHEN "0000" => display <= "1000000"; -- 0
            WHEN "0001" => display <= "1111001"; -- 1
            WHEN "0010" => display <= "0100100"; -- 2
            WHEN "0011" => display <= "0110000"; -- 3
            WHEN "0100" => display <= "0011001"; -- 4
            WHEN "0101" => display <= "0010010"; -- 5
            WHEN "0110" => display <= "0000010"; -- 6
            WHEN "0111" => display <= "1111000"; -- 7
            WHEN "1000" => display <= "0000000"; -- 8
            WHEN "1001" => display <= "0011000"; -- 9
            WHEN "1010" => display <= "0001000"; -- A
            WHEN "1011" => display <= "0000011"; -- b
            WHEN "1100" => display <= "1000110"; -- C
            WHEN "1101" => display <= "0100001"; -- d
            WHEN "1110" => display <= "0000110"; -- E
            WHEN "1111" => display <= "0001110"; -- F
        END CASE;
    END PROCESS;
END Behavior;