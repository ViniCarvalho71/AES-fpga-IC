library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.aes_package.all;

entity KeySchedule_FSM_tb is
end entity KeySchedule_FSM_tb;

architecture sim of KeySchedule_FSM_tb is

    component KeySchedule_FSM is
        port(
            key_in       : in  matrix(3 downto 0, 3 downto 0);
            keychain_out : out matrix_128(10 downto 0);
            start        : in  std_logic;
            done         : out std_logic;
            clk          : in  std_logic;
            rst          : in  std_logic
        );
    end component;

    signal clk          : std_logic := '0';
    signal rst          : std_logic := '1';
    signal start        : std_logic := '0';
    signal done          : std_logic;
    signal key_in        : matrix(3 downto 0, 3 downto 0);
    signal keychain_out  : matrix_128(10 downto 0);

    constant CLK_PERIOD : time := 10 ns;

    type byte_matrix is array(0 to 3, 0 to 3) of std_logic_vector(7 downto 0);
    type round_key_array is array(0 to 10) of byte_matrix;

    -- Round keys esperadas (AES-128, chave de teste FIPS-197 2b7e151628aed2a6abf7158809cf4f3c)
    -- Convencao: (palavra, byte) = (coluna, linha)
    constant EXPECTED : round_key_array := (
        -- round 0
        (
            (x"2b", x"7e", x"15", x"16"),
            (x"28", x"ae", x"d2", x"a6"),
            (x"ab", x"f7", x"15", x"88"),
            (x"09", x"cf", x"4f", x"3c")
        ),
        -- round 1
        (
            (x"a0", x"fa", x"fe", x"17"),
            (x"88", x"54", x"2c", x"b1"),
            (x"23", x"a3", x"39", x"39"),
            (x"2a", x"6c", x"76", x"05")
        ),
        -- round 2
        (
            (x"f2", x"c2", x"95", x"f2"),
            (x"7a", x"96", x"b9", x"43"),
            (x"59", x"35", x"80", x"7a"),
            (x"73", x"59", x"f6", x"7f")
        ),
        -- round 3
        (
            (x"3d", x"80", x"47", x"7d"),
            (x"47", x"16", x"fe", x"3e"),
            (x"1e", x"23", x"7e", x"44"),
            (x"6d", x"7a", x"88", x"3b")
        ),
        -- round 4
        (
            (x"ef", x"44", x"a5", x"41"),
            (x"a8", x"52", x"5b", x"7f"),
            (x"b6", x"71", x"25", x"3b"),
            (x"db", x"0b", x"ad", x"00")
        ),
        -- round 5
        (
            (x"d4", x"d1", x"c6", x"f8"),
            (x"7c", x"83", x"9d", x"87"),
            (x"ca", x"f2", x"b8", x"bc"),
            (x"11", x"f9", x"15", x"bc")
        ),
        -- round 6
        (
            (x"6d", x"88", x"a3", x"7a"),
            (x"11", x"0b", x"3e", x"fd"),
            (x"db", x"f9", x"86", x"41"),
            (x"ca", x"00", x"93", x"fd")
        ),
        -- round 7
        (
            (x"4e", x"54", x"f7", x"0e"),
            (x"5f", x"5f", x"c9", x"f3"),
            (x"84", x"a6", x"4f", x"b2"),
            (x"4e", x"a6", x"dc", x"4f")
        ),
        -- round 8
        (
            (x"ea", x"d2", x"73", x"21"),
            (x"b5", x"8d", x"ba", x"d2"),
            (x"31", x"2b", x"f5", x"60"),
            (x"7f", x"8d", x"29", x"2f")
        ),
        -- round 9
        (
            (x"ac", x"77", x"66", x"f3"),
            (x"19", x"fa", x"dc", x"21"),
            (x"28", x"d1", x"29", x"41"),
            (x"57", x"5c", x"00", x"6e")
        ),
        -- round 10
        (
            (x"d0", x"14", x"f9", x"a8"),
            (x"c9", x"ee", x"25", x"89"),
            (x"e1", x"3f", x"0c", x"c8"),
            (x"b6", x"63", x"0c", x"a6")
        )
    );

    signal test_finished : boolean := false;

begin

    clk_process : process
    begin
        while not test_finished loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;

    DUT : KeySchedule_FSM
        port map(
            key_in       => key_in,
            keychain_out => keychain_out,
            start        => start,
            done         => done,
            clk          => clk,
            rst          => rst
        );

    stim_process : process
        variable errors : integer := 0;
        variable total  : integer := 0;
    begin
        -- reset (fixo, 2 ciclos)
        rst   <= '1';
        start <= '0';
        wait for CLK_PERIOD * 2;
        wait until rising_edge(clk);
        rst <= '0';
        wait until rising_edge(clk);

        -- chave de teste, hardcoded (2b7e151628aed2a6abf7158809cf4f3c)
        key_in(0, 0) <= x"2b"; key_in(0, 1) <= x"7e"; key_in(0, 2) <= x"15"; key_in(0, 3) <= x"16";
        key_in(1, 0) <= x"28"; key_in(1, 1) <= x"ae"; key_in(1, 2) <= x"d2"; key_in(1, 3) <= x"a6";
        key_in(2, 0) <= x"ab"; key_in(2, 1) <= x"f7"; key_in(2, 2) <= x"15"; key_in(2, 3) <= x"88";
        key_in(3, 0) <= x"09"; key_in(3, 1) <= x"cf"; key_in(3, 2) <= x"4f"; key_in(3, 3) <= x"3c";

        -- pulso de start (fixo, 1 ciclo)
        wait until rising_edge(clk);
        start <= '1';
        wait until rising_edge(clk);
        start <= '0';

        -- espera fixa (sem loop) -- tempo generoso pras 10 rodadas
        wait for 800 ns;

        assert done = '1'
            report "ERRO: 'done' do KeySchedule_FSM nao subiu no tempo esperado (800 ns apos o start)"
            severity error;

        -- comparacao das 11 round keys -- sem print por byte, so contagem final
        for r in 0 to 10 loop
            for i in 0 to 3 loop
                for j in 0 to 3 loop
                    total := total + 1;
                    if keychain_out(r)(i, j) /= EXPECTED(r)(i, j) then
                        errors := errors + 1;
                    end if;
                end loop;
            end loop;
        end loop;

        if errors = 0 then
            report "TESTE OK: todas as 11 round keys corretas (" & integer'image(total) & " bytes)." severity note;
        else
            report "TESTE FALHOU: " & integer'image(errors) & " de " & integer'image(total) & " bytes incorretos." severity error;
        end if;

        test_finished <= true;
        wait;
    end process;

end architecture sim;