 LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY PWM_avalon_interface IS
    PORT (
        clk, reset_n            : IN  STD_LOGIC;
        read, write, chipselect : IN  STD_LOGIC;
        address                 : IN  STD_LOGIC;   -- '0'=droit, '1'=gauche
        writedata               : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
        byteenable              : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
        readdata                : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        -- Exports vers les moteurs
        dc_motor_p_R, dc_motor_n_R : OUT STD_LOGIC;
        dc_motor_p_L, dc_motor_n_L : OUT STD_LOGIC
    );
END PWM_avalon_interface;

ARCHITECTURE Structure OF PWM_avalon_interface IS

    -- Registres internes stockant les commandes
    SIGNAL reg_R : STD_LOGIC_VECTOR(13 DOWNTO 0) := (OTHERS => '0');
    SIGNAL reg_L : STD_LOGIC_VECTOR(13 DOWNTO 0) := (OTHERS => '0');

    -- Signaux d'écriture décodés
    SIGNAL we_R, we_L : STD_LOGIC;

    COMPONENT PWM_generation
        PORT (
            clk, reset_n        : IN  STD_LOGIC;
            s_writedataR        : IN  STD_LOGIC_VECTOR(13 DOWNTO 0);
            s_writedataL        : IN  STD_LOGIC_VECTOR(13 DOWNTO 0);
            dc_motor_p_R, dc_motor_n_R : OUT STD_LOGIC;
            dc_motor_p_L, dc_motor_n_L : OUT STD_LOGIC
        );
    END COMPONENT;

BEGIN

    -- -------------------------------------------------------
    -- Décodage écriture : chipselect AND write AND adresse
    -- -------------------------------------------------------
    we_R <= chipselect AND write AND (NOT address);
    we_L <= chipselect AND write AND address;

    -- -------------------------------------------------------
    -- Registre moteur DROIT
    -- -------------------------------------------------------
    PROCESS(clk, reset_n)
    BEGIN
        IF reset_n = '0' THEN
            reg_R <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            IF we_R = '1' THEN
                IF byteenable(0) = '1' THEN
                    reg_R(7 DOWNTO 0) <= writedata(7 DOWNTO 0);
                END IF;
                IF byteenable(1) = '1' THEN
                    reg_R(13 DOWNTO 8) <= writedata(13 DOWNTO 8);
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- -------------------------------------------------------
    -- Registre moteur GAUCHE
    -- -------------------------------------------------------
    PROCESS(clk, reset_n)
    BEGIN
        IF reset_n = '0' THEN
            reg_L <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            IF we_L = '1' THEN
                IF byteenable(0) = '1' THEN
                    reg_L(7 DOWNTO 0) <= writedata(7 DOWNTO 0);
                END IF;
                IF byteenable(1) = '1' THEN
                    reg_L(13 DOWNTO 8) <= writedata(13 DOWNTO 8);
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- -------------------------------------------------------
    -- Lecture : mux sur l'adresse
    -- -------------------------------------------------------
    readdata <= "00" & reg_R WHEN (chipselect AND read) = '1' AND address = '0' ELSE
                "00" & reg_L WHEN (chipselect AND read) = '1' AND address = '1' ELSE
                (OTHERS => '0');

    -- -------------------------------------------------------
    -- Instanciation du PWM
    -- -------------------------------------------------------
    pwm_inst : PWM_generation
        PORT MAP (
            clk          => clk,
            reset_n      => reset_n,
            s_writedataR => reg_R,
            s_writedataL => reg_L,
            dc_motor_p_R => dc_motor_p_R,
            dc_motor_n_R => dc_motor_n_R,
            dc_motor_p_L => dc_motor_p_L,
            dc_motor_n_L => dc_motor_n_L
        );

END Structure;