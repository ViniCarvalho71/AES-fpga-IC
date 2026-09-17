library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.aes_package.all;

entity SubBytes_ShiftRows_tb is
end entity SubBytes_ShiftRows_tb;

architecture tb of SubBytes_ShiftRows_tb is

    signal data_in  : matrix(3 downto 0, 3 downto 0);
    signal data_out : matrix(3 downto 0, 3 downto 0);

    signal start : std_logic := '0';
    signal done  : std_logic;

    signal clk : std_logic := '0';
    signal rst : std_logic := '0';

    constant CLK_PERIOD : time := 10 ns;

begin

    DUT : entity work.SubBytes_ShiftRows
        port map (
            data_in  => data_in,
            data_out => data_out,
            start    => start,
            done     => done,
            clk      => clk,
            rst      => rst
        );

    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process;

    stimulus : process
    begin
        ----------------------------------------------------------------
        -- RESET INITIALIZATION
        ----------------------------------------------------------------
        rst   <= '1';
        start <= '0';
        wait for 2 * CLK_PERIOD;
        rst   <= '0';
        wait for CLK_PERIOD;

        ----------------------------------------------------------------
        -- ENTRADA FIPS 197 (Apêndice A.1 - Rodada 1)
        ----------------------------------------------------------------
        -- Linha 0
        data_in(0,0) <= x"19"; data_in(1,0) <= x"A0"; data_in(2,0) <= x"9A"; data_in(3,0) <= x"E9";
        -- Linha 1
        data_in(0,1) <= x"3D"; data_in(1,1) <= x"F4"; data_in(2,1) <= x"C6"; data_in(3,1) <= x"F8";
        -- Linha 2
        data_in(0,2) <= x"E3"; data_in(1,2) <= x"E2"; data_in(2,2) <= x"8D"; data_in(3,2) <= x"48";
        -- Linha 3
        data_in(0,3) <= x"BE"; data_in(1,3) <= x"2B"; data_in(2,3) <= x"2A"; data_in(3,3) <= x"08";

        ----------------------------------------------------------------
        -- PULSO DE START
        ----------------------------------------------------------------
        wait for CLK_PERIOD;
        start <= '1';
        wait for CLK_PERIOD;
        start <= '0';

        ----------------------------------------------------------------
        -- AGUARDA PROCESSAMENTO
        ----------------------------------------------------------------
        wait until done = '1';
        wait for 1 ns;

        ----------------------------------------------------------------
        -- VALIDAÇÃO DOS RESULTADOS OFICIAIS (FIPS 197)
        ----------------------------------------------------------------
        -- Linha 0 (Deslocamento 0): 19 A0 9A E9 -> D4 E0 B8 1E
        assert data_out(0,0) = x"D4" report "ERRO: data_out(0,0)" severity error;
        assert data_out(1,0) = x"E0" report "ERRO: data_out(1,0)" severity error;
        assert data_out(2,0) = x"B8" report "ERRO: data_out(2,0)" severity error;
        assert data_out(3,0) = x"1E" report "ERRO: data_out(3,0)" severity error;

        -- Linha 1 (Deslocamento 1 à Esquerda): F4 C6 F8 3D -> BF B4 41 27
        assert data_out(0,1) = x"BF" report "ERRO: data_out(0,1)" severity error;
        assert data_out(1,1) = x"B4" report "ERRO: data_out(1,1)" severity error;
        assert data_out(2,1) = x"41" report "ERRO: data_out(2,1)" severity error;
        assert data_out(3,1) = x"27" report "ERRO: data_out(3,1)" severity error;

        -- Linha 2 (Deslocamento 2 à Esquerda): 8D 48 E3 E2 -> 5D 52 11 98
        assert data_out(0,2) = x"5D" report "ERRO: data_out(0,2)" severity error;
        assert data_out(1,2) = x"52" report "ERRO: data_out(1,2)" severity error;
        assert data_out(2,2) = x"11" report "ERRO: data_out(2,2)" severity error;
        assert data_out(3,2) = x"98" report "ERRO: data_out(3,2)" severity error;

        -- Linha 3 (Deslocamento 3 à Esquerda): 08 BE 2B 2A -> 30 AE F1 E5
        assert data_out(0,3) = x"30" report "ERRO: data_out(0,3)" severity error;
        assert data_out(1,3) = x"AE" report "ERRO: data_out(1,3)" severity error;
        assert data_out(2,3) = x"F1" report "ERRO: data_out(2,3)" severity error;
        assert data_out(3,3) = x"E5" report "ERRO: data_out(3,3)" severity error;

        report "========================================";
        report "TESTE AES SUBBYTES + SHIFTROWS CORRIGIDO PASSOU!";
        report "========================================";

        wait;
    end process;

end architecture tb;