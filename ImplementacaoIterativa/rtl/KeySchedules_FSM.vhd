library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.aes_package.all;

entity KeySchedules_FSM is
	port(
		key_in       : in  matrix;
		keychain_out : out matrix_128(10 downto 0);

		start        : in  std_logic;
		done         : out std_logic;

		clk          : in  std_logic;
		rst          : in  std_logic
	);
end entity KeySchedules_FSM;

architecture KeySchedules_FSM_arch of KeySchedules_FSM is

    component KeySchedule is
        port(
            key_in  : in matrix;
            key_out : out matrix;
            Rcon    : in std_logic_vector(7 downto 0);
            en      : in std_logic;
            start   : in std_logic;
            done    : out std_logic;
            clk     : in std_logic;
            rst     : in std_logic
        );
    end component;

    type state is (
        IDLE,
        START_KS,
        WAIT_KS
    );

    signal current_state : state := IDLE;

    signal round_counter : integer range 1 to 10 := 1;

    signal ks_en    : std_logic := '0';
    signal ks_done  : std_logic;
    signal ks_start : std_logic := '0';

    signal Rcon_round : std_logic_vector(7 downto 0);

    signal round_key_in  : matrix;
    signal round_key_out : matrix;

begin

    -- Usa diretamente o round_counter para buscar em RCON (1 a 10)
    Rcon_round <= RCON(round_counter);

    KeySchedule_Module : KeySchedule
        port map(
            key_in  => round_key_in,
            key_out => round_key_out,
            Rcon    => Rcon_round,
            en      => ks_en,
            start   => ks_start,
            done    => ks_done,
            clk     => clk,
            rst     => rst
        );

    process(clk)
    begin
        if rising_edge(clk) then

            if rst = '1' then

                current_state <= IDLE;
                round_counter <= 1;

                ks_start <= '0';
                ks_en    <= '0';

                done <= '0';

                for i in 3 downto 0 loop
                    for j in 3 downto 0 loop
                        round_key_in(i, j) <= (others => '0');
                    end loop;
                end loop;

                for l in 0 to 10 loop
                    for i in 0 to 3 loop
                        for j in 0 to 3 loop
                            keychain_out(l)(i, j) <= (others => '0');
                        end loop;
                    end loop;
                end loop;

            else

                ks_start <= '0';

                case current_state is

                    when IDLE =>

                        done  <= '0';
                        ks_en <= '0';

                        if start = '1' then

                            round_counter <= 1;

                            keychain_out(0) <= key_in;

                            round_key_in <= key_in;

                            ks_en <= '1';

                            current_state <= START_KS;

                        end if;

                    when START_KS =>

                        ks_start <= '1';
                        current_state <= WAIT_KS;

                    when WAIT_KS =>

                        if ks_done = '1' then

                            keychain_out(round_counter) <= round_key_out;

                            if round_counter = 10 then

                                done <= '1';
                                ks_en <= '0';
                                current_state <= IDLE;

                            else

                                round_counter <= round_counter + 1;
                                round_key_in <= round_key_out;
                                current_state <= START_KS;

                            end if;

                        end if;

                end case;

            end if;

        end if;
    end process;

end architecture;