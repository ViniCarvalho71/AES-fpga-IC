library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.aes_package.all;

entity KeySchedule_tb is
end entity KeySchedule_tb;

architecture sim of KeySchedule_tb is

    component KeySchedule is
        port(
            key_in  : in  matrix(3 downto 0, 3 downto 0);
            key_out : out matrix(3 downto 0, 3 downto 0);
            Rcon    : in  std_logic_vector(7 downto 0);
            en      : in  std_logic;
            start   : in  std_logic;
            done    : out std_logic;
            clk     : in  std_logic;
            rst     : in  std_logic
        );
    end component;

    signal clk     : std_logic := '0';
    signal rst     : std_logic := '1';
    signal en      : std_logic := '0';
    signal start   : std_logic := '0';
    signal done    : std_logic;
    signal Rcon    : std_logic_vector(7 downto 0) := (others => '0');
    signal key_in  : matrix(3 downto 0, 3 downto 0);
    signal key_out : matrix(3 downto 0, 3 downto 0);

    constant CLK_PERIOD : time := 10 ns;

    type byte_matrix is array(0 to 3, 0 to 3) of std_logic_vector(7 downto 0);

    -- Chave de teste do FIPS-197 (Apendice A.1): 2b7e151628aed2a6abf7158809cf4f3c
    -- Convencao: key_in(coluna, linha) -- coluna = palavra (w0..w3), linha = byte dentro da palavra

    -- Round key 1 esperada (oficial, FIPS-197): a0fafe17 88542cb1 23a33939 2a6c7605
    constant EXPECTED_ROUND_KEY1 : byte_matrix := (
        (x"a0", x"fa", x"fe", x"17"),  -- palavra w4
        (x"88", x"54", x"2c", x"b1"),  -- palavra w5
        (x"23", x"a3", x"39", x"39"),  -- palavra w6
        (x"2a", x"6c", x"76", x"05")   -- palavra w7
    );

    signal test_finished : boolean := false;

    -- carrega a chave de teste em key_in
    procedure load_test_key(signal ki : out matrix(3 downto 0, 3 downto 0)) is
    begin
        ki(0, 0) <= x"2b"; ki(0, 1) <= x"7e"; ki(0, 2) <= x"15"; ki(0, 3) <= x"16"; -- w0
        ki(1, 0) <= x"28"; ki(1, 1) <= x"ae"; ki(1, 2) <= x"d2"; ki(1, 3) <= x"a6"; -- w1
        ki(2, 0) <= x"ab"; ki(2, 1) <= x"f7"; ki(2, 2) <= x"15"; ki(2, 3) <= x"88"; -- w2
        ki(3, 0) <= x"09"; ki(3, 1) <= x"cf"; ki(3, 2) <= x"4f"; ki(3, 3) <= x"3c"; -- w3
    end procedure;

begin

    -- gerador de clock
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

    DUT : KeySchedule
        port map(
            key_in  => key_in,
            key_out => key_out,
            Rcon    => Rcon,
            en      => en,
            start   => start,
            done    => done,
            clk     => clk,
            rst     => rst
        );

    stim_process : process
        variable errors      : integer := 0;
        variable cycle_count : integer;
    begin
        ----------------------------------------------------------------
        -- TESTE 1: operacao normal, en sempre em '1'
        ----------------------------------------------------------------
        rst   <= '1';
        en    <= '0';
        start <= '0';
        wait for CLK_PERIOD * 2;
        wait until rising_edge(clk);
        rst <= '0';
        wait until rising_edge(clk);

        Rcon <= x"01";
        load_test_key(key_in);
        en <= '1';

        wait until rising_edge(clk);
        start <= '1';
        wait until rising_edge(clk);
        start <= '0';

        -- espera 'done' subir (maquina leva 4 ciclos ativos: COL0..COL3)
        cycle_count := 0;
        for k in 0 to 10 loop
            wait until rising_edge(clk);
            cycle_count := cycle_count + 1;
            exit when done = '1';
        end loop;

        assert done = '1'
            report "TESTE 1 - ERRO: 'done' nunca subiu"
            severity error;

        wait for 1 ns;

        for i in 0 to 3 loop
            for j in 0 to 3 loop
                if key_out(i, j) /= EXPECTED_ROUND_KEY1(i, j) then
                    errors := errors + 1;
                    report "TESTE 1 - ERRO em key_out(palavra=" & integer'image(i) &
                           ", byte=" & integer'image(j) & ")"
                        severity error;
                end if;
            end loop;
        end loop;

        if errors = 0 then
            report "TESTE 1 OK: round key 1 correta (levou " & integer'image(cycle_count) & " ciclos ativos)." severity note;
        else
            report "TESTE 1 FALHOU: " & integer'image(errors) & " byte(s) incorreto(s)." severity error;
        end if;

        wait until rising_edge(clk);

        ----------------------------------------------------------------
        -- TESTE 2: pausar a maquina de estados no meio via en='0'
        -- e confirmar que ela nao avanca nem ativa 'done' enquanto pausada,
        -- retomando corretamente depois e chegando ao MESMO resultado.
        ----------------------------------------------------------------
        errors := 0;
        rst    <= '1';
        en     <= '0';
        start  <= '0';
        wait for CLK_PERIOD * 2;
        wait until rising_edge(clk);
        rst <= '0';
        wait until rising_edge(clk);

        Rcon <= x"01";
        load_test_key(key_in);
        en <= '1';

        wait until rising_edge(clk);
        start <= '1';
        wait until rising_edge(clk);
        start <= '0';

        -- um ciclo com en='1' para entrar em COL0
        wait until rising_edge(clk);

        -- pausa a maquina por 4 ciclos: en='0'
        en <= '0';
        for k in 0 to 3 loop
            wait until rising_edge(clk);
            assert done = '0'
                report "TESTE 2 - ERRO: 'done' subiu durante a pausa (en='0'), FSM nao deveria avancar"
                severity error;
        end loop;

        -- retoma a maquina
        en <= '1';

        cycle_count := 0;
        for k in 0 to 10 loop
            wait until rising_edge(clk);
            cycle_count := cycle_count + 1;
            exit when done = '1';
        end loop;

        assert done = '1'
            report "TESTE 2 - ERRO: 'done' nunca subiu apos retomar (en='1')"
            severity error;

        wait for 1 ns;

        for i in 0 to 3 loop
            for j in 0 to 3 loop
                if key_out(i, j) /= EXPECTED_ROUND_KEY1(i, j) then
                    errors := errors + 1;
                    report "TESTE 2 - ERRO em key_out(palavra=" & integer'image(i) &
                           ", byte=" & integer'image(j) & ") apos pausa/retomada"
                        severity error;
                end if;
            end loop;
        end loop;

        if errors = 0 then
            report "TESTE 2 OK: pausa via 'en' funcionou, resultado final continua correto." severity note;
        else
            report "TESTE 2 FALHOU: " & integer'image(errors) & " byte(s) incorreto(s) apos pausa." severity error;
        end if;

        test_finished <= true;
        wait;
    end process;

end architecture sim;