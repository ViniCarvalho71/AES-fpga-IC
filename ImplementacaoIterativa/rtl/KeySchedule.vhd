library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.aes_package.all;

entity KeySchedule is
    port(
        key_in  : in  matrix;
        key_out : out matrix;
        Rcon    : in  std_logic_vector(7 downto 0);
        en      : in  std_logic;
        start   : in  std_logic;
        done    : out std_logic;
        clk     : in  std_logic;
        rst     : in  std_logic
    );
end entity KeySchedule;

architecture KeySchedule_arch of KeySchedule is

    component sbox is
        port(
            input_byte  : in  std_logic_vector(7 downto 0);
            output_byte : out std_logic_vector(7 downto 0)
        );
    end component;

    type state is (IDLE, COL0, COL1, COL2, COL3);

    signal latched_key_in : matrix;

    signal temp_column0 : byte_column;
    signal temp_column1 : byte_column;
    signal temp_column2 : byte_column;
    signal temp_column3 : byte_column;

    signal current_state : state := IDLE;

    signal rotated_column3 : byte_column;
    signal sbox_out        : byte_column;

begin

    -- RotWord
    rotated_column3 <= column_rotate(
        matrix2column(latched_key_in, 3),
        1
    );

    -- SubWord
    sbox_gen : for I in 3 downto 0 generate
        sbox_inst : sbox
            port map(
                input_byte  => rotated_column3(I),
                output_byte => sbox_out(I)
            );
    end generate;

    process(clk)
        variable new_column0 : byte_column;
        variable new_column1 : byte_column;
        variable new_column2 : byte_column;
        variable new_column3 : byte_column;
    begin

        if rising_edge(clk) then

            if rst = '1' then

                current_state  <= IDLE;
                
                for i in 3 downto 0 loop
                    for j in 3 downto 0 loop
                        latched_key_in(i, j) <= (others => '0');
                        key_out(i, j)        <= (others => '0');
                    end loop;
                end loop;

                temp_column0 <= (others => (others => '0'));
                temp_column1 <= (others => (others => '0'));
                temp_column2 <= (others => (others => '0'));
                temp_column3 <= (others => (others => '0'));

                done <= '0';

            elsif en = '1' then

                case current_state is

                    when IDLE =>

                        done <= '0';

                        if start = '1' then

                            latched_key_in <= key_in;

                            temp_column0 <= matrix2column(key_in, 0);
                            temp_column1 <= matrix2column(key_in, 1);
                            temp_column2 <= matrix2column(key_in, 2);
                            temp_column3 <= matrix2column(key_in, 3);

                            current_state <= COL0;

                        end if;

                    when COL0 =>

                        for I in 3 downto 0 loop
                            if I = 0 then
                                new_column0(I) := byte_xor(byte_xor(sbox_out(I), matrix2column(latched_key_in, 0)(I)), Rcon);
                            else
                                new_column0(I) := byte_xor(sbox_out(I), matrix2column(latched_key_in, 0)(I));
                            end if;
                        end loop;

                        temp_column0 <= new_column0;
                        current_state <= COL1;
                        done <= '0';

                    when COL1 =>

                        new_column1 := column_xor(temp_column0, matrix2column(latched_key_in, 1));
                        temp_column1 <= new_column1;
                        current_state <= COL2;
                        done <= '0';

                    when COL2 =>

                        new_column2 := column_xor(temp_column1, matrix2column(latched_key_in, 2));
                        temp_column2 <= new_column2;
                        current_state <= COL3;
                        done <= '0';

                    when COL3 =>

                        new_column3 := column_xor(temp_column2, matrix2column(latched_key_in, 3));
                        temp_column3 <= new_column3;

                        key_out <= column2matrix(
                            temp_column0,
                            temp_column1,
                            temp_column2,
                            new_column3
                        );

                        done <= '1';
                        current_state <= IDLE;

                end case;

            else
                done <= '0';
            end if;

        end if;

    end process;

end architecture KeySchedule_arch;