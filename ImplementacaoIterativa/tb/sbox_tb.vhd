library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity sbox_tb is 
end sbox_tb;

architecture sbox_tb_arch of sbox_tb is

    component sbox is
        port (
            input_byte  : in  std_logic_vector(7 downto 0);
            output_byte : out std_logic_vector(7 downto 0)
        );
    end component;

    signal i_tb, o_tb : std_logic_vector(7 downto 0);

begin

    dut:sbox 
        port map (
            input_byte  => i_tb,
            output_byte => o_tb
        );

    stim:process
    begin
			i_tb <= x"00";
			wait for 10 ns;
			i_tb <= x"FF";
			wait for 10 ns;
			i_tb <= x"A6";
			wait for 10 ns;
			i_tb <= x"53";
			wait for 10 ns;
			i_tb <= x"63";
			wait for 10 ns;
			wait;
    end process;

end sbox_tb_arch;