library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- IMPORTANTE:
-- Troque "aes_package" pelo nome do package onde
-- você declarou o tipo matrix.
use work.aes_package.all;


entity SubBytes_ShiftRows_tb is
end entity SubBytes_ShiftRows_tb;


architecture tb of SubBytes_ShiftRows_tb is

    --------------------------------------------------------------------
    -- Sinais do DUT
    --------------------------------------------------------------------

    signal data_in  : matrix(3 downto 0, 3 downto 0);
    signal data_out : matrix(3 downto 0, 3 downto 0);

    signal start : std_logic := '0';
    signal done  : std_logic;

    signal clk : std_logic := '0';
    signal rst : std_logic := '0';


    --------------------------------------------------------------------
    -- Período do clock
    --------------------------------------------------------------------

    constant CLK_PERIOD : time := 10 ns;


begin

    --------------------------------------------------------------------
    -- Instância do módulo que estamos testando
    --------------------------------------------------------------------

    DUT : entity work.SubBytes_ShiftRows
        port map (
            data_in  => data_in,
            data_out => data_out,

            start    => start,
            done     => done,

            clk      => clk,
            rst      => rst
        );


    --------------------------------------------------------------------
    -- Geração do clock
    --------------------------------------------------------------------

    clk_process : process
    begin

        while true loop

            clk <= '0';
            wait for CLK_PERIOD / 2;

            clk <= '1';
            wait for CLK_PERIOD / 2;

        end loop;

    end process;


    --------------------------------------------------------------------
    -- Processo de teste
    --------------------------------------------------------------------

    stimulus : process
    begin

        ----------------------------------------------------------------
        -- RESET
        ----------------------------------------------------------------

        rst <= '1';
        start <= '0';

        wait for 2 * CLK_PERIOD;

        rst <= '0';

        wait for CLK_PERIOD;


        ----------------------------------------------------------------
        -- MATRIZ DE ENTRADA
        --
        -- Estamos usando:
        --
        --       coluna
        --       0    1    2    3
        --
        -- linha 0
        -- linha 1
        -- linha 2
        -- linha 3
        --
        ----------------------------------------------------------------

        -- Linha 0
        data_in(0,0) <= x"19";
        data_in(1,0) <= x"A0";
        data_in(2,0) <= x"9A";
        data_in(3,0) <= x"E9";

        -- Linha 1
        data_in(0,1) <= x"3D";
        data_in(1,1) <= x"F4";
        data_in(2,1) <= x"C6";
        data_in(3,1) <= x"F8";

        -- Linha 2
        data_in(0,2) <= x"E3";
        data_in(1,2) <= x"E2";
        data_in(2,2) <= x"8D";
        data_in(3,2) <= x"48";

        -- Linha 3
        data_in(0,3) <= x"BE";
        data_in(1,3) <= x"2B";
        data_in(2,3) <= x"2A";
        data_in(3,3) <= x"08";


        ----------------------------------------------------------------
        -- START
        ----------------------------------------------------------------

        wait for CLK_PERIOD;

        start <= '1';

        wait for CLK_PERIOD;

        start <= '0';


        ----------------------------------------------------------------
        -- ESPERA DONE
        ----------------------------------------------------------------

        wait until done = '1';

        wait for 1 ns;


        ----------------------------------------------------------------
        -- RESULTADO ESPERADO
        --
        -- Primeiro fazemos ShiftRows:
        --
        -- 19 A0 9A E9
        -- F8 3D F4 C6
        -- 8D 48 E3 E2
        -- 2B 2A 08 BE
        --
        -- Depois SubBytes:
        --
        -- D4 E0 B8 1E
        -- 41 27 BF B4
        -- 5D 52 11 98
        -- F1 E5 30 AE
        ----------------------------------------------------------------


        ----------------------------------------------------------------
        -- Linha 0
        ----------------------------------------------------------------

        assert data_out(0,0) = x"D4"
            report "ERRO: data_out(0,0)"
            severity error;

        assert data_out(1,0) = x"E0"
            report "ERRO: data_out(1,0)"
            severity error;

        assert data_out(2,0) = x"B8"
            report "ERRO: data_out(2,0)"
            severity error;

        assert data_out(3,0) = x"1E"
            report "ERRO: data_out(3,0)"
            severity error;


        ----------------------------------------------------------------
        -- Linha 1
        ----------------------------------------------------------------

        assert data_out(0,1) = x"41"
            report "ERRO: data_out(0,1)"
            severity error;

        assert data_out(1,1) = x"27"
            report "ERRO: data_out(1,1)"
            severity error;

        assert data_out(2,1) = x"BF"
            report "ERRO: data_out(2,1)"
            severity error;

        assert data_out(3,1) = x"B4"
            report "ERRO: data_out(3,1)"
            severity error;


        ----------------------------------------------------------------
        -- Linha 2
        ----------------------------------------------------------------

        assert data_out(0,2) = x"5D"
            report "ERRO: data_out(0,2)"
            severity error;

        assert data_out(1,2) = x"52"
            report "ERRO: data_out(1,2)"
            severity error;

        assert data_out(2,2) = x"11"
            report "ERRO: data_out(2,2)"
            severity error;

        assert data_out(3,2) = x"98"
            report "ERRO: data_out(3,2)"
            severity error;


        ----------------------------------------------------------------
        -- Linha 3
        ----------------------------------------------------------------

        assert data_out(0,3) = x"F1"
            report "ERRO: data_out(0,3)"
            severity error;

        assert data_out(1,3) = x"E5"
            report "ERRO: data_out(1,3)"
            severity error;

        assert data_out(2,3) = x"30"
            report "ERRO: data_out(2,3)"
            severity error;

        assert data_out(3,3) = x"AE"
            report "ERRO: data_out(3,3)"
            severity error;


        ----------------------------------------------------------------
        -- Se chegou aqui, passou
        ----------------------------------------------------------------

        report "========================================";
        report "TESTE AES SUBBYTES + SHIFTROWS PASSOU!";
        report "========================================";


        wait;

    end process;

end architecture tb;