library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package aes_package is

    type matrix is array (
        integer range <>,
        integer range <>
    ) of std_logic_vector(7 downto 0);

		type generic_memory is array (integer range <>) of std_logic_vector(7 downto 0);
		type matrix_128 is array (integer range <>) of matrix(3 downto 0, 3 downto 0);
		constant Rcon_const : generic_memory(9 downto 0) := (
		X"01", X"02", X"04", X"08", X"10", X"20", X"40", X"80", X"1b", X"36"
	);
		
		function matrix2row(mat : in matrix; row : in integer) return generic_memory;
		function matrix2column(mat : in matrix; column : in integer) return generic_memory;
		function column2matrix(C0, C1, C2, C3 : in generic_memory) return matrix;

		function column_modulo_mul(column : in generic_memory) return std_logic_vector;
		function column_rotate(column : in generic_memory; rotation : in integer) return generic_memory;
		function "XOR"(L, R : matrix) return matrix;
		function "XOR"(L, R : generic_memory) return generic_memory;
		function xtime(byte : std_logic_vector(7 downto 0)) return std_logic_vector;
		
end package aes_package;

package body aes_package is

	function xtime(byte : std_logic_vector(7 downto 0))
	return std_logic_vector is

		 variable result : std_logic_vector(7 downto 0);

	begin

		 if byte(7) = '1' then
			  result := (byte(6 downto 0) & '0') XOR x"1B";
		 else
			  result := byte(6 downto 0) & '0';
		 end if;

		 return result;

	end xtime;
	
	function matrix2row(mat : in matrix; row : in integer) return generic_memory is
		variable mem_out : generic_memory(3 downto 0);
	begin
		for I in 0 to 3 loop
			mem_out(I) := mat(I, row);
		end loop;
		return mem_out;
	end matrix2row;

	function matrix2column(mat : in matrix; column : in integer) return generic_memory is
		variable mem_out : generic_memory(3 downto 0);
	begin
		for I in 0 to 3 loop
			mem_out(I) := mat(column, I);
		end loop;
		return mem_out;
	end matrix2column;

	function column2matrix(C0, C1, C2, C3 : in generic_memory) return matrix is
		variable out_matrix : matrix(3 downto 0, 3 downto 0);
	begin
		for I in 0 to 3 loop
			out_matrix(0, I) := C0(I);
		end loop;

		for I in 0 to 3 loop
			out_matrix(1, I) := C1(I);
		end loop;

		for I in 0 to 3 loop
			out_matrix(2, I) := C2(I);
		end loop;

		for I in 0 to 3 loop
			out_matrix(3, I) := C3(I);
		end loop;

		return out_matrix;
	end column2matrix;

		function column_modulo_mul(column : in generic_memory)
		return std_logic_vector is

			 variable out_byte : std_logic_vector(7 downto 0);

		begin

			 out_byte :=
				  xtime(column(0))
				  XOR
				  xtime(column(1))
				  XOR
				  column(1)
				  XOR
				  column(2)
				  XOR
				  column(3);

			 return out_byte;

		end column_modulo_mul;

	function column_rotate(column : in generic_memory; rotation : in integer) return generic_memory is
		variable out_column : generic_memory(3 downto 0);
	begin
		case rotation is
			when 1 =>
				out_column(0) := column(1);
				out_column(1) := column(2);
				out_column(2) := column(3);
				out_column(3) := column(0);
			when 2 =>
				out_column(0) := column(2);
				out_column(1) := column(3);
				out_column(2) := column(0);
				out_column(3) := column(1);
			when 3 =>
				out_column(0) := column(3);
				out_column(1) := column(0);
				out_column(2) := column(1);
				out_column(3) := column(2);
			when others =>
				out_column := column;
		end case;
		return out_column;
	end column_rotate;

	function "XOR"(L, R : matrix) return matrix is
		variable out_matrix : matrix(L'range(1), L'range(2));
	begin
		for I in L'range(1) loop
			for J in L'range(2) loop
				out_matrix(I, J) := L(I, J) XOR R(I, J);
			end loop;
		end loop;
		return out_matrix;
	end "XOR";

	function "XOR"(L, R : generic_memory) return generic_memory is
		variable out_memory : generic_memory(L'range);
	begin
		for I in L'range loop
			out_memory(I) := L(I) XOR R(I);
		end loop;
		return out_memory;
	end "XOR";

end package body aes_package;