library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

library work;
use work.aes_package.all;

entity encrypt_fsm_tb is
end entity encrypt_fsm_tb;

architecture tb_arch of encrypt_fsm_tb is

    -- Componente Sob Teste (DUT)
    component Encrypt_FSM is
        port(
            clk            : in  std_logic;
            rst            : in  std_logic;
            start          : in  std_logic;
            key_load       : in  std_logic;
            key_in         : in  matrix;
            data_block_in  : in  matrix;
            data_block_out : out matrix;
            done           : out std_logic;
            busy           : out std_logic
        );
    end component;

    -- Sinais do Testbench (Sem os intervalos restritos)
    signal clk            : std_logic := '0';
    signal rst            : std_logic := '1';
    signal start          : std_logic := '0';
    signal key_load       : std_logic := '0';
    signal key_in         : matrix := (others => (others => (others => '0')));
    signal data_block_in  : matrix := (others => (others => (others => '0')));
    signal data_block_out : matrix;
    signal done           : std_logic;
    signal busy           : std_logic;

    constant CLK_PERIOD : time := 10 ns;

    -- Função de conversão Hexadecimal VHDL-93
    function to_hex_string(slv : std_logic_vector(7 downto 0)) return string is
        constant hex_chars : string(1 to 16) := "0123456789ABCDEF";
        variable hi, lo    : integer;
        variable result    : string(1 to 2);
    begin
        hi := to_integer(unsigned(slv(7 downto 4)));
        lo := to_integer(unsigned(slv(3 downto 0)));
        result(1) := hex_chars(hi + 1);
        result(2) := hex_chars(lo + 1);
        return result;
    end function;

    -- Procedure para imprimir a matriz 4x4 no console
    procedure print_matrix(header : in string; m : in matrix) is
        variable l : line;
    begin
        write(l, header);
        writeline(output, l);
        for row in 0 to 3 loop
            write(l, to_hex_string(m(row,0)) & "   " &
                     to_hex_string(m(row,1)) & "   " &
                     to_hex_string(m(row,2)) & "   " &
                     to_hex_string(m(row,3)));
            writeline(output, l);
        end loop;
        write(l, string'("----------------------------------------"));
        writeline(output, l);
    end procedure;

begin

    DUT: Encrypt_FSM
        port map (
            clk            => clk,
            rst            => rst,
            start          => start,
            key_load       => key_load,
            key_in         => key_in,
            data_block_in  => data_block_in,
            data_block_out => data_block_out,
            done           => done,
            busy           => busy
        );

    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    stim_proc: process
        variable cycle_cnt : integer := 0;
    begin
        -- 1. Reset
        rst <= '1';
        start <= '0';
        key_load <= '0';
        wait for 20 ns;
        
        rst <= '0';
        wait until rising_edge(clk);

        -- 2. Atribuição da Chave Oficial do NIST (FIPS-197)
        -- Key = 2b 7e 15 16 28 ae d2 a6 ab f7 15 88 09 cf 4f 3c
        -- Coluna 0
        key_in(0,0) <= X"2B"; key_in(1,0) <= X"7E"; key_in(2,0) <= X"15"; key_in(3,0) <= X"16";
        -- Coluna 1
        key_in(0,1) <= X"28"; key_in(1,1) <= X"AE"; key_in(2,1) <= X"D2"; key_in(3,1) <= X"A6";
        -- Coluna 2
        key_in(0,2) <= X"AB"; key_in(1,2) <= X"F7"; key_in(2,2) <= X"15"; key_in(3,2) <= X"88";
        -- Coluna 3
        key_in(0,3) <= X"09"; key_in(1,3) <= X"CF"; key_in(2,3) <= X"4F"; key_in(3,3) <= X"3C";

        wait for 1 ns; 
        print_matrix("[TB] Chave de Entrada (key_in):", key_in);

        key_load <= '1';
        wait until rising_edge(clk);
        key_load <= '0';
        
        -- Aguarda o Key Schedule terminar de verdade (busy volta a '0')
        wait until busy = '0';
        wait until rising_edge(clk);

        -- 3. Atribuição do Texto Claro Oficial do NIST (FIPS-197)
        -- Input = 32 43 f6 a8 88 5a 30 8d 31 31 98 a2 e0 37 07 34
        -- Coluna 0
        data_block_in(0,0) <= X"32"; data_block_in(1,0) <= X"43"; data_block_in(2,0) <= X"F6"; data_block_in(3,0) <= X"A8";
        -- Coluna 1
        data_block_in(0,1) <= X"88"; data_block_in(1,1) <= X"5A"; data_block_in(2,1) <= X"30"; data_block_in(3,1) <= X"8D";
        -- Coluna 2
        data_block_in(0,2) <= X"31"; data_block_in(1,2) <= X"31"; data_block_in(2,2) <= X"98"; data_block_in(3,2) <= X"A2";
        -- Coluna 3
        data_block_in(0,3) <= X"E0"; data_block_in(1,3) <= X"37"; data_block_in(2,3) <= X"07"; data_block_in(3,3) <= X"34";

        wait for 1 ns; 
        print_matrix("[TB] Texto Claro de Entrada (data_block_in):", data_block_in);

        -- 4. Início da Execução
        start <= '1';
        wait until rising_edge(clk);
        start <= '0';

        report "=== INICIO DA EXECUCAO (Monitoramento por Ciclo) ===" severity note;

        -- Loop com timeout de segurança (ex: máximo de 200 ciclos)
        cycle_cnt := 0;
        while done = '0' loop
            wait until rising_edge(clk);
            cycle_cnt := cycle_cnt + 1;
            
            if cycle_cnt > 200 then
                report "[ERRO] Timeout: A FSM demorou ciclos demais e travou!" severity failure;
                exit;
            end if;
        end loop;

        report "=== FIM DA EXECUCAO (Sinal done detectado) ===" severity note;
        print_print: print_matrix("[TB] Resultado Final Obtido:", data_block_out);

        report "--- TESTE CONCLUIDO ---" severity note;
        wait;
    end process;

end architecture tb_arch;