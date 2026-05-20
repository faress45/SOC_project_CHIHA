LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY capteurs_avalon_interface IS
    PORT (
        clk, reset_n            : IN  STD_LOGIC;
        read, write, chipselect : IN  STD_LOGIC;
        address                 : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
        writedata               : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        byteenable              : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
        readdata                : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        -- Conduit SPI export
        ADC_CONVST              : OUT STD_LOGIC;
        ADC_SCK                 : OUT STD_LOGIC;
        ADC_SDI                 : OUT STD_LOGIC;
        ADC_SDO                 : IN  STD_LOGIC
    );
END capteurs_avalon_interface;

ARCHITECTURE Structure OF capteurs_avalon_interface IS

    -- Seul registre de contrôle : le seuil NIVEAU
    SIGNAL reg_niveau    : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');

    -- Signaux lus depuis le composant capteur
    SIGNAL sig_data_ready : STD_LOGIC;
    SIGNAL sig_vect_capt  : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL sig_data0      : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL sig_data1      : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL sig_data2      : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL sig_data3      : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL sig_data4      : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL sig_data5      : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL sig_data6      : STD_LOGIC_VECTOR(7 DOWNTO 0);


    SIGNAL clk_40MHZ, clk_2KHZ      : STD_LOGIC ;

    COMPONENT capteurs_sol_seuil
        PORT (
            clk          : IN  STD_LOGIC;
            reset_n      : IN  STD_LOGIC;
            data_capture : IN  STD_LOGIC;
            data_readyr  : OUT STD_LOGIC;
            data0r       : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            data1r       : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            data2r       : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            data3r       : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            data4r       : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            data5r       : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            data6r       : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            NIVEAU       : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
            vect_capt    : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
            ADC_CONVSTr  : OUT STD_LOGIC;
            ADC_SCK      : OUT STD_LOGIC;
            ADC_SDIr     : OUT STD_LOGIC;
            ADC_SDO      : IN  STD_LOGIC
        );
    END COMPONENT;
	
	component pll_2freqs IS
			PORT
			(
				areset		: IN STD_LOGIC  := '0';
				inclk0		: IN STD_LOGIC  := '0';
				c0		      : OUT STD_LOGIC ;
				c1		      : OUT STD_LOGIC 
			);
	END component pll_2freqs;	

BEGIN

    capteurs_inst : capteurs_sol_seuil
        PORT MAP (
            clk          => clk_40MHZ,
            reset_n      => reset_n,
            data_capture => clk_2KHZ,   -- ← branché directement sur la PLL 2KHz
            data_readyr  => sig_data_ready,
            data0r       => sig_data0,
            data1r       => sig_data1,
            data2r       => sig_data2,
            data3r       => sig_data3,
            data4r       => sig_data4,
            data5r       => sig_data5,
            data6r       => sig_data6,
            NIVEAU       => reg_niveau,
            vect_capt    => sig_vect_capt,
            ADC_CONVSTr  => ADC_CONVST,
            ADC_SCK      => ADC_SCK,
            ADC_SDIr     => ADC_SDI,
            ADC_SDO      => ADC_SDO
        );


	pll2freqs: pll_2freqs
	PORT MAP (
				areset		    => NOT reset_n,
				inclk0		    => clk,
				c0		    	=> clk_40MHZ,
				c1		    	=> clk_2KHZ
			);
			
			
    -- -------------------------------------------------------
    -- Écriture : seuil NIVEAU uniquement (adresse 0x00)
    -- bits 15:8 = NIVEAU
    -- -------------------------------------------------------
    PROCESS(clk, reset_n)
    BEGIN
        IF reset_n = '0' THEN
            reg_niveau <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            IF chipselect = '1' AND write = '1' AND address = "00" THEN
                IF byteenable(1) = '1' THEN
                    reg_niveau <= writedata(15 DOWNTO 8);
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- -------------------------------------------------------
    -- Lecture des registres
    -- -------------------------------------------------------
    PROCESS(chipselect, read, address,
            sig_data_ready, sig_vect_capt,
            sig_data0, sig_data1, sig_data2, sig_data3,
            sig_data4, sig_data5, sig_data6)
    BEGIN
        readdata <= (OTHERS => '0');
        IF chipselect = '1' AND read = '1' THEN
            CASE address IS
                -- Registre 0x00 : status
                -- bit 0      = data_readyr
                -- bits 7:1   = vect_capt
                WHEN "00" =>
                    readdata(0)          <= sig_data_ready;
                    readdata(7 DOWNTO 1) <= sig_vect_capt;

                -- Registre 0x04 : data0 à data3
                WHEN "01" =>
                    readdata(7  DOWNTO  0) <= sig_data0;
                    readdata(15 DOWNTO  8) <= sig_data1;
                    readdata(23 DOWNTO 16) <= sig_data2;
                    readdata(31 DOWNTO 24) <= sig_data3;

                -- Registre 0x08 : data4 à data6
                WHEN "10" =>
                    readdata(7  DOWNTO  0) <= sig_data4;
                    readdata(15 DOWNTO  8) <= sig_data5;
                    readdata(23 DOWNTO 16) <= sig_data6;

                WHEN OTHERS =>
                    readdata <= (OTHERS => '0');
            END CASE;
        END IF;
    END PROCESS;

END Structure;