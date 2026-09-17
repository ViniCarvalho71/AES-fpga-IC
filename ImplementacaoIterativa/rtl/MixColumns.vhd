library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.aes_package.all;

entity MixColumns is
    port(
        data_in  : in  matrix;
        data_out : out matrix;

        start    : in  std_logic;
        done     : out std_logic;

        clk      : in  std_logic;
        rst      : in  std_logic
    );
end entity MixColumns;

architecture MixColumns_arch of MixColumns is
    type state is (IDLE, PROCESSING);
    signal current_state : state := IDLE;
begin

    process(clk)
        variable col_in  : byte_column;
        variable col_out : byte_column;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                for i in 3 downto 0 loop
                    for j in 3 downto 0 loop
                        data_out(i, j) <= (others => '0');
                    end loop;
                end loop;
                done <= '0';
                current_state <= IDLE;
            else
                case current_state is
                    when IDLE =>
                        done <= '0';
                        if start = '1' then
                            for c in 3 downto 0 loop
                                col_in  := matrix2column(data_in, c);
                                col_out := mix_single_column(col_in);
                                
                                for r in 3 downto 0 loop
                                    data_out(r, c) <= col_out(r);
                                end loop;
                            end loop;
                            current_state <= PROCESSING;
                        end if;

                    when PROCESSING =>
                        done <= '1';
                        current_state <= IDLE;
                end case;
            end if;
        end if;
    end process;

end architecture MixColumns_arch;