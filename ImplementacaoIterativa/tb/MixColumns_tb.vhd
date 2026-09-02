library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.aes_package.all;

entity MixColumns_tb is
end entity MixColumns_tb;

architecture sim of MixColumns_tb is

    component MixColumns is
        port(
            data_in  : in  matrix(3 downto 0, 3 downto 0);
            data_out : out matrix(3 downto 0, 3 downto 0);
            start    : in  std_logic;
            done     : out std_logic;
            clk      : in  std_logic;
            rst      : in  std_logic
        );
    end component;

    signal clk      : std_logic := '0';
    signal rst      : std_logic := '1';
    signal start    : std_logic := '0';
    signal done     : std_logic;
    signal data_in  : matrix(3 downto 0, 3 downto 0);
    signal data_out : matrix(3 downto 0, 3 downto 0);

    constant CLK_PERIOD : time := 10 ns;

    type byte_matrix is array(0 to 3, 0 to 3) of std_logic_vector(7 downto 0);

    -- Convencao confirmada a partir do aes_package:
    --   data_in(coluna, linha)  -> matrix2column(mat,k) le mat(k, 0..3)
    --   data_out(linha, coluna) -> o proprio MixColumns escreve data_out(j, i)
    --
    -- data_in e carregado por atribuicoes explicitas no processo abaixo,
    -- deixando claro qual byte vai para qual (coluna,linha).
    --
    -- Saida esperada (FIPS-197), guardada como EXPECTED_OUTPUT(linha, coluna):
    constant EXPECTED_OUTPUT : byte_matrix := (
        (x"04", x"e0", x"48", x"28"),  -- linha 0
        (x"66", x"cb", x"f8", x"06"),  -- linha 1
        (x"81", x"19", x"d3", x"26"),  -- linha 2
        (x"e5", x"9a", x"7a", x"4c")   -- linha 3
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

    DUT : MixColumns
        port map(
            data_in  => data_in,
            data_out => data_out,
            start    => start,
            done     => done,
            clk      => clk,
            rst      => rst
        );

    stim_process : process
        variable errors : integer := 0;
    begin
        rst   <= '1';
        start <= '0';
        wait for CLK_PERIOD * 2;
        wait until rising_edge(clk);
        rst <= '0';
        wait until rising_edge(clk);

        -- Carrega data_in(coluna, linha) explicitamente com o estado do FIPS-197:
        -- coluna 0: linhas d4,bf,5d,30
        data_in(0, 0) <= x"d4"; data_in(0, 1) <= x"bf"; data_in(0, 2) <= x"5d"; data_in(0, 3) <= x"30";
        -- coluna 1: linhas e0,b4,52,ae
        data_in(1, 0) <= x"e0"; data_in(1, 1) <= x"b4"; data_in(1, 2) <= x"52"; data_in(1, 3) <= x"ae";
        -- coluna 2: linhas b8,41,11,f1
        data_in(2, 0) <= x"b8"; data_in(2, 1) <= x"41"; data_in(2, 2) <= x"11"; data_in(2, 3) <= x"f1";
        -- coluna 3: linhas 1e,27,98,e5
        data_in(3, 0) <= x"1e"; data_in(3, 1) <= x"27"; data_in(3, 2) <= x"98"; data_in(3, 3) <= x"e5";

        wait until rising_edge(clk);
        start <= '1';
        wait until rising_edge(clk);
        start <= '0';

        for k in 0 to 5 loop
            wait until rising_edge(clk);
            exit when done = '1';
        end loop;

        assert done = '1'
            report "ERRO: 'done' nao foi ativado apos o start"
            severity error;

        wait for 1 ns;

        -- data_out(linha, coluna) comparado com EXPECTED_OUTPUT(linha, coluna)
        for row in 0 to 3 loop
            for col in 0 to 3 loop
                if data_out(row, col) /= EXPECTED_OUTPUT(row, col) then
                    errors := errors + 1;
                    report "ERRO em data_out(linha=" & integer'image(row) & ", coluna=" & integer'image(col) & ")"
                        severity error;
                end if;
            end loop;
        end loop;

        if errors = 0 then
            report "TESTE OK: MixColumns bate com o vetor FIPS-197." severity note;
        else
            report "TESTE FALHOU: " & integer'image(errors) & " byte(s) incorreto(s)." severity error;
        end if;

        test_finished <= true;
        wait;
    end process;

end architecture sim;