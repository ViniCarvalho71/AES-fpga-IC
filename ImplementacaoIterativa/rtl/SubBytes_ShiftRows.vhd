library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.aes_package.all;



entity SubBytes_ShiftRows is
    port(
        data_in  : in  matrix(3 downto 0, 3 downto 0);
        data_out : out matrix(3 downto 0, 3 downto 0);

        start    : in  std_logic;
        done     : out std_logic;

        clk      : in  std_logic;
        rst      : in  std_logic
    );
end entity SubBytes_ShiftRows;


architecture SubBytes_ShiftRows_arch of SubBytes_ShiftRows is

    component sbox is
        port (
            input_byte  : in  std_logic_vector(7 downto 0);
            output_byte : out std_logic_vector(7 downto 0)
        );
    end component;

    type state is (IDLE, PROCESSING);
    signal current_state : state := IDLE;

    -- Entradas das 16 S-Boxes
    signal sbox_in : matrix(3 downto 0, 3 downto 0);
 
    -- Saídas das 16 S-Boxes
    signal sbox_out : matrix(3 downto 0, 3 downto 0);

begin

    --------------------------------------------------------------------
    -- SBOX 0
    --------------------------------------------------------------------
    sbox_00 : sbox
        port map (
            input_byte  => sbox_in(0,0),
            output_byte => sbox_out(0,0)
        );

    sbox_01 : sbox
        port map (
            input_byte  => sbox_in(0,1),
            output_byte => sbox_out(0,1)
        );

    sbox_02 : sbox
        port map (
            input_byte  => sbox_in(0,2),
            output_byte => sbox_out(0,2)
        );

    sbox_03 : sbox
        port map (
            input_byte  => sbox_in(0,3),
            output_byte => sbox_out(0,3)
        );


    --------------------------------------------------------------------
    -- SBOX 1
    --------------------------------------------------------------------
    sbox_10 : sbox
        port map (
            input_byte  => sbox_in(1,0),
            output_byte => sbox_out(1,0)
        );

    sbox_11 : sbox
        port map (
            input_byte  => sbox_in(1,1),
            output_byte => sbox_out(1,1)
        );

    sbox_12 : sbox
        port map (
            input_byte  => sbox_in(1,2),
            output_byte => sbox_out(1,2)
        );

    sbox_13 : sbox
        port map (
            input_byte  => sbox_in(1,3),
            output_byte => sbox_out(1,3)
        );


    --------------------------------------------------------------------
    -- SBOX 2
    --------------------------------------------------------------------
    sbox_20 : sbox
        port map (
            input_byte  => sbox_in(2,0),
            output_byte => sbox_out(2,0)
        );

    sbox_21 : sbox
        port map (
            input_byte  => sbox_in(2,1),
            output_byte => sbox_out(2,1)
        );

    sbox_22 : sbox
        port map (
            input_byte  => sbox_in(2,2),
            output_byte => sbox_out(2,2)
        );

    sbox_23 : sbox
        port map (
            input_byte  => sbox_in(2,3),
            output_byte => sbox_out(2,3)
        );


    --------------------------------------------------------------------
    -- SBOX 3
    --------------------------------------------------------------------
    sbox_30 : sbox
        port map (
            input_byte  => sbox_in(3,0),
            output_byte => sbox_out(3,0)
        );

    sbox_31 : sbox
        port map (
            input_byte  => sbox_in(3,1),
            output_byte => sbox_out(3,1)
        );

    sbox_32 : sbox
        port map (
            input_byte  => sbox_in(3,2),
            output_byte => sbox_out(3,2)
        );

    sbox_33 : sbox
        port map (
            input_byte  => sbox_in(3,3),
            output_byte => sbox_out(3,3)
        );


    --------------------------------------------------------------------
    -- SUBBYTES + SHIFTROWS
    --
    -- A entrada da SBOX já recebe o byte correspondente ao ShiftRows.
    --
    -- Linha 0: 0 1 2 3
    -- Linha 1: 1 2 3 0
    -- Linha 2: 2 3 0 1
    -- Linha 3: 3 0 1 2
    --------------------------------------------------------------------

    -- Linha 0
    sbox_in(0,0) <= data_in(0,0);
    sbox_in(1,0) <= data_in(1,0);
    sbox_in(2,0) <= data_in(2,0);
    sbox_in(3,0) <= data_in(3,0);

    -- Linha 1
    sbox_in(0,1) <= data_in(3,1);
    sbox_in(1,1) <= data_in(0,1);
    sbox_in(2,1) <= data_in(1,1);
    sbox_in(3,1) <= data_in(2,1);

    -- Linha 2
    sbox_in(0,2) <= data_in(2,2);
    sbox_in(1,2) <= data_in(3,2);
    sbox_in(2,2) <= data_in(0,2);
    sbox_in(3,2) <= data_in(1,2);

    -- Linha 3
    sbox_in(0,3) <= data_in(1,3);
    sbox_in(1,3) <= data_in(2,3);
    sbox_in(2,3) <= data_in(3,3);
    sbox_in(3,3) <= data_in(0,3);


    --------------------------------------------------------------------
    -- Controle
    --------------------------------------------------------------------
    process(clk)
    begin

        if rising_edge(clk) then

            if rst = '1' then

                current_state <= IDLE;
                done <= '0';

            else

                case current_state is

                    when IDLE =>

                        done <= '0';

                        if start = '1' then
                            current_state <= PROCESSING;
                        end if;


                    when PROCESSING =>

                        current_state <= IDLE;
                        done <= '1';

                end case;

            end if;

        end if;

    end process;

    data_out <= sbox_out;

end architecture SubBytes_ShiftRows_arch;