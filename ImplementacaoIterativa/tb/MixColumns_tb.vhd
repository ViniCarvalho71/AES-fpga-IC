library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.aes_package.all;


entity MixColumns_tb is
end entity MixColumns_tb;


architecture tb of MixColumns_tb is

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
    -- Clock
    --------------------------------------------------------------------

    constant CLK_PERIOD : time := 10 ns;


begin

    --------------------------------------------------------------------
    -- DUT
    --------------------------------------------------------------------

    DUT : entity work.MixColumns
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
    -- Estímulos
    --------------------------------------------------------------------

    stimulus : process
    begin

        ----------------------------------------------------------------
        -- RESET
        ----------------------------------------------------------------

        rst   <= '1';
        start <= '0';

        wait for 2 * CLK_PERIOD;

        rst <= '0';

        wait for CLK_PERIOD;


        ----------------------------------------------------------------
        -- MATRIZ DE ENTRADA
        --
        -- Cada coluna contém:
        --
        -- DB
        -- 13
        -- 53
        -- 45
        --
        ----------------------------------------------------------------

        -- Coluna 0
			data_in(0,0) <= x"DB";
			data_in(0,1) <= x"13";
			data_in(0,2) <= x"53";
			data_in(0,3) <= x"45";

			-- Coluna 1
			data_in(1,0) <= x"00";
			data_in(1,1) <= x"00";
			data_in(1,2) <= x"00";
			data_in(1,3) <= x"00";

			-- Coluna 2
			data_in(2,0) <= x"00";
			data_in(2,1) <= x"00";
			data_in(2,2) <= x"00";
			data_in(2,3) <= x"00";

			-- Coluna 3
			data_in(3,0) <= x"00";
			data_in(3,1) <= x"00";
			data_in(3,2) <= x"00";
			data_in(3,3) <= x"00";


        start <= '1';
			wait for CLK_PERIOD;
			start <= '0';

			wait until done = '1';

        assert data_out(0,0) = x"8E"
            report "ERRO: coluna 0, linha 0"
            severity error;

        assert data_out(0,1) = x"4D"
            report "ERRO: coluna 0, linha 1"
            severity error;

        assert data_out(0,2) = x"A1"
            report "ERRO: coluna 0, linha 2"
            severity error;

        assert data_out(0,3) = x"BC"
            report "ERRO: coluna 0, linha 3"
            severity error;


        wait;

    end process;

end architecture tb;
