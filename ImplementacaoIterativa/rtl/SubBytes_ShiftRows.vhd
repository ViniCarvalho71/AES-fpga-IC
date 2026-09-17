library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.aes_package.all;

entity SubBytes_ShiftRows is
    port(
        data_in  : in  matrix;
        data_out : out matrix;

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

    signal sbox_in  : matrix;
    signal sbox_out : matrix;

begin

    -- ShiftRows e Instanciação das S-Boxes
    gen_rows : for r in 0 to 3 generate
        gen_cols : for c in 0 to 3 generate
            -- Deslocamento circular à esquerda por linha 'r'
            sbox_in(r, c) <= data_in(r, (c + r) mod 4);

            sbox_inst : sbox
                port map (
                    input_byte  => sbox_in(r, c),
                    output_byte => sbox_out(r, c)
                );
        end generate;
    end generate;

    -- Controle FSM
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
                        done <= '1';
                        current_state <= IDLE;
                end case;
            end if;
        end if;
    end process;

    -- Atribuição final correta sem múltiplos drivers
    data_out <= sbox_out;

end architecture SubBytes_ShiftRows_arch;