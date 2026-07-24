library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity sbox is
    port (
        input_byte  : in  std_logic_vector(7 downto 0);
        output_byte : out std_logic_vector(7 downto 0)
    );
end entity sbox;

architecture sbox_arch of sbox is

    type sbox_array is array (0 to 255) of std_logic_vector(7 downto 0);

    constant SBOX : sbox_array := (
	 -- LINHA 1 --
        16#00# => x"63",
        16#01# => x"7C",
        16#02# => x"77",
        16#03# => x"7B",
        16#04# => x"F2",
        16#05# => x"6B",
        16#06# => x"6F",
        16#07# => x"30",
		  16#08# => x"01",
		  16#09# => x"67",
		  16#0A# => x"2B",
		  16#0B# => x"FE",
		  16#0C# => x"D7",
		  16#0D# => x"AB",
		  16#0E# => x"76",
	 -- LINHA 2 --
		  16#0F# => x"CA",
		  16#10# => x"82",
		  16#11# => x"C9",
		  16#12# => x"7D",
		  16#13# => x"FA",
		  16#14# => x"59",
		  16#15# => x"47",
		  16#16# => x"F0",
		  16#17# => x"AD",
		  16#18# => x"D4",
		  16#19# => x"A2",
		  16#1A# => x"AF",
		  16#1B# => x"9C",
		  16#1C# => x"A4",
		  16#1D# => x"72",
		  16#1E# => x"C0",
	 -- LINHA 3 --
		  16#1F# => x"B7",
		  16#20# => x"FD",
		  16#21# => x"93",
		  16#22# => x"26",
		  16#23# => x"36",
		  16#24# => x"3F",
		  16#25# => x"F7",
		  16#26# => x"CC",
		  16#27# => x"34",
		  16#28# => x"A5",
		  16#29# => x"E5",
		  16#2A# => x"F1",
		  16#2B# => x"71",
		  16#2C# => x"D8",
		  16#2D# => x"31",
		  16#2E# => x"15",
	-- LINHA 4 --
		  16#2F# => x"04",
		  16#30# => x"C7",
		  16#31# => x"23",
		  16#32# => x"C3",
		  16#33# => x"18",
		  16#34# => x"96",
		  16#35# => x"9A",
		  16#36# => x"07",
		  16#37# => x"12",
		  16#38# => x"80",
		  16#39# => x"E2",
		  16#3A# => x"EB",
		  16#3B# => x"27",
		  16#3C# => x"B2",
		  16#3D# => x"75",
	-- LINHA 5 --
		  16#3E# => x"09",
		  16#3F# => x"83",
		  16#40# => x"2C",
		  16#41# => x"1A",
		  16#42# => x"1B",
		  16#43# => x"6E",
		  16#44# => x"5A",
		  16#45# => x"A0",
		  16#46# => x"52",
		  16#47# => x"3B",
		  16#48# => x"D6",
		  16#49# => x"B3",
		  16#4A# => x"29",
		  16#4B# => x"E3",
		  16#4C# => x"2F",
		  16#4D# => x"84",
	-- LINHA 6 --
		  16#4E# => x"53",
		  16#4F# => x"D1",
		  16#50# => x"00",
		  16#51# => x"ED",
		  16#52# => x"20",
		  16#53# => x"FC",
		  16#54# => x"B1",
		  16#55# => x"5B",
		  16#56# => x"6A",
		  16#57# => x"CB",
		  16#58# => x"BE",
		  16#59# => x"39",
		  16#5A# => x"4A",
		  16#5B# => x"4C",
		  16#5C# => x"58",
		  16#5D# => x"CF",
	-- LINHA 7 --
		  16#5E# => x"D0",
		  16#5F# => x"EF",
		  
		  
        16#FF# => x"16"
    );

begin

    output_byte <= SBOX(to_integer(unsigned(input_byte)));

end architecture sbox_arch;