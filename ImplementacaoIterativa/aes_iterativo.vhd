library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity aes_iterativo is
    port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        start       : in  std_logic;

        plaintext   : in  std_logic_vector(127 downto 0);
        key         : in  std_logic_vector(127 downto 0);

        ciphertext  : out std_logic_vector(127 downto 0);
        done        : out std_logic
    );
end entity aes_iterativo;


architecture aes_iterativo_arch of aes_iterativo is

begin

end architecture aes_iterativo_arch;