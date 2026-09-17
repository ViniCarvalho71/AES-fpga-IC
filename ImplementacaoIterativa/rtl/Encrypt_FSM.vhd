library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.aes_package.all;

entity Encrypt_FSM is
    port(
        key_in         : in  matrix;
        data_block_in  : in  matrix;
        data_block_out : out matrix;
        key_load       : in  std_logic;
        start          : in  std_logic;
        done           : out std_logic;
        busy           : out std_logic;
        clk            : in  std_logic;
        rst            : in  std_logic
    );
end entity Encrypt_FSM;


architecture RTL of Encrypt_FSM is

    ----------------------------------------------------------------
    -- Key Schedule
    ----------------------------------------------------------------

    component KeySchedules_FSM
        port(
            key_in       : in  matrix;
            keychain_out : out matrix_128(10 downto 0);
            start        : in  std_logic;
            done         : out std_logic;
            clk          : in  std_logic;
            rst          : in  std_logic
        );
    end component;


    ----------------------------------------------------------------
    -- SubBytes + ShiftRows
    ----------------------------------------------------------------

    component SubBytes_ShiftRows
        port(
            data_in  : in  matrix;
            data_out : out matrix;
            start    : in  std_logic;
            done     : out std_logic;
            clk      : in  std_logic;
            rst      : in  std_logic
        );
    end component;


    ----------------------------------------------------------------
    -- MixColumns
    ----------------------------------------------------------------

    component MixColumns
        port(
            data_in  : in  matrix;
            data_out : out matrix;
            start    : in  std_logic;
            done     : out std_logic;
            clk      : in  std_logic;
            rst      : in  std_logic
        );
    end component;


    ----------------------------------------------------------------
    -- Sinais internos
    ----------------------------------------------------------------

    signal latched_data_in : matrix;
    signal latched_key_in  : matrix;

    signal round_data_in   : matrix;
    signal round_data_out  : matrix;

    signal ss_data_in      : matrix;
    signal ss_data_out     : matrix;

    signal mc_data_in      : matrix;
    signal mc_data_out     : matrix;

    signal keychain        : matrix_128(10 downto 0);


    ----------------------------------------------------------------
    -- Sinais de Controle
    ----------------------------------------------------------------

    signal ks_start : std_logic := '0';
    signal ks_done  : std_logic := '0';

    signal ss_start : std_logic := '0';
    signal ss_done  : std_logic := '0';

    signal mc_start : std_logic := '0';
    signal mc_done  : std_logic := '0';

    signal round_counter : integer range 1 to 10 := 1;


    ----------------------------------------------------------------
    -- Estados da FSM
    ----------------------------------------------------------------

    type state is (
        IDLE,
        KEY_SCHEDULE_START,
        KEY_SCHEDULE_WAIT,
        INITIAL_ROUND,
        SUBBYTES_START,
        SUBBYTES_WAIT,
        MIXCOLUMNS_START,
        MIXCOLUMNS_WAIT,
        ADD_ROUND_KEY,
        FINAL_ROUND,
        ENC_OUTPUT,
        ENC_DONE
    );

    signal current_state : state := IDLE;


begin

    ----------------------------------------------------------------
    -- Instanciações
    ----------------------------------------------------------------

    Inst_KeySchedules_FSM : KeySchedules_FSM
        port map(
            key_in       => latched_key_in,
            keychain_out => keychain,
            start        => ks_start,
            done         => ks_done,
            clk          => clk,
            rst          => rst
        );

    Inst_SubBytes_ShiftRows : SubBytes_ShiftRows
        port map(
            data_in  => ss_data_in,
            data_out => ss_data_out,
            start    => ss_start,
            done     => ss_done,
            clk      => clk,
            rst      => rst
        );

    Inst_MixColumns : MixColumns
        port map(
            data_in  => mc_data_in,
            data_out => mc_data_out,
            start    => mc_start,
            done     => mc_done,
            clk      => clk,
            rst      => rst
        );


    ----------------------------------------------------------------
    -- Processo Principal da FSM
    ----------------------------------------------------------------

    state_proc : process(clk)
    begin
        if rising_edge(clk) then

            if rst = '1' then
                current_state <= IDLE;
                round_counter <= 1;

                ks_start <= '0';
                ss_start <= '0';
                mc_start <= '0';

                done <= '0';
                busy <= '0';

                for i in 3 downto 0 loop
                    for j in 3 downto 0 loop
                        latched_data_in(i,j) <= (others => '0');
                        latched_key_in(i,j)  <= (others => '0');

                        round_data_in(i,j)   <= (others => '0');
                        round_data_out(i,j)  <= (others => '0');

                        ss_data_in(i,j)      <= (others => '0');
                        mc_data_in(i,j)      <= (others => '0');

                        data_block_out(i,j)  <= (others => '0');
                    end loop;
                end loop;

            else
                -- Pulsos padrão de controle (1 ciclo)
                ks_start <= '0';
                ss_start <= '0';
                mc_start <= '0';
                done     <= '0';

                case current_state is

                    when IDLE =>
                        busy <= '0';
                        if key_load = '1' then
                            latched_key_in <= key_in;
                            current_state <= KEY_SCHEDULE_START;
                        elsif start = '1' then
                            latched_data_in <= data_block_in;
                            current_state <= INITIAL_ROUND;
                        end if;

                    when KEY_SCHEDULE_START =>
                        busy <= '1';
                        ks_start <= '1';
                        current_state <= KEY_SCHEDULE_WAIT;

                    when KEY_SCHEDULE_WAIT =>
                        busy <= '1';
                        if ks_done = '1' then
                            current_state <= IDLE;
                        end if;

                    when INITIAL_ROUND =>
                        busy <= '1';
                        round_data_in <= matrix_xor(latched_data_in, keychain(0));
                        round_counter <= 1;
                        current_state <= SUBBYTES_START;

                    when SUBBYTES_START =>
                        busy <= '1';
                        ss_data_in <= round_data_in;
                        ss_start <= '1';
                        current_state <= SUBBYTES_WAIT;

                    when SUBBYTES_WAIT =>
                        busy <= '1';
                        if ss_done = '1' then
                            if round_counter = 10 then
                                current_state <= FINAL_ROUND;
                            else
                                current_state <= MIXCOLUMNS_START;
                            end if;
                        end if;

                    when MIXCOLUMNS_START =>
                        busy <= '1';
                        mc_data_in <= ss_data_out;
                        mc_start <= '1';
                        current_state <= MIXCOLUMNS_WAIT;

                    when MIXCOLUMNS_WAIT =>
                        busy <= '1';
                        if mc_done = '1' then
                            current_state <= ADD_ROUND_KEY;
                        end if;

                    when ADD_ROUND_KEY =>
                        busy <= '1';
                        round_data_in <= matrix_xor(mc_data_out, keychain(round_counter));
                        round_counter <= round_counter + 1;
                        current_state <= SUBBYTES_START;

                    when FINAL_ROUND =>
                        busy <= '1';
                        round_data_out <= matrix_xor(ss_data_out, keychain(10));
                        current_state <= ENC_OUTPUT;

                    when ENC_OUTPUT =>
                        busy <= '0';
                        done <= '1';
                        data_block_out <= round_data_out;
                        current_state <= ENC_DONE;

                    when ENC_DONE =>
                        busy <= '0';
                        done <= '1';
                        current_state <= IDLE;

                end case;
            end if;
        end if;
    end process state_proc;

end architecture RTL;