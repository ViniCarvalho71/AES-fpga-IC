library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package aes_package is

    subtype byte is std_logic_vector(7 downto 0);
    type byte_column is array (3 downto 0) of byte;
    type matrix is array (3 downto 0, 3 downto 0) of byte;
    type matrix_128 is array (natural range <>) of matrix;
    type expanded_key_array is array (0 to 43) of byte;

    type rcon_array is array (0 to 10) of byte;
    constant RCON : rcon_array := (
        x"00", x"01", x"02", x"04", x"08", x"10", x"20", x"40", x"80", x"1b", x"36"
    );

    -- Funções explícitas de XOR (evitam qualquer conflito de Use Clause)
    function byte_xor (l, r : byte) return byte;
    function column_xor (l, r : byte_column) return byte_column;
    function matrix_xor (l, r : matrix) return matrix;

    -- Funções auxiliares
    function column2matrix(C0, C1, C2, C3 : in byte_column) return matrix;
    function matrix2column(M : in matrix; c : integer) return byte_column;
    function column_rotate(col : in byte_column; shift : integer) return byte_column;
    function gmul(a, b : in byte) return byte;
    function mix_single_column(col : in byte_column) return byte_column;

end package aes_package;

package body aes_package is

    function byte_xor (l, r : byte) return byte is
        variable res : byte;
    begin
        for i in 7 downto 0 loop
            res(i) := l(i) xor r(i);
        end loop;
        return res;
    end function byte_xor;

    function column_xor (l, r : byte_column) return byte_column is
        variable res : byte_column;
    begin
        for i in 3 downto 0 loop
            res(i) := byte_xor(l(i), r(i));
        end loop;
        return res;
    end function column_xor;

    function matrix_xor (l, r : matrix) return matrix is
        variable res : matrix; -- Removido (3 downto 0, 3 downto 0)
    begin
        for i in 3 downto 0 loop
            for j in 3 downto 0 loop
                res(i, j) := byte_xor(l(i, j), r(i, j));
            end loop;
        end loop;
        return res;
    end function matrix_xor;

    function column2matrix(C0, C1, C2, C3 : in byte_column) return matrix is
        variable out_matrix : matrix; -- Removido (3 downto 0, 3 downto 0)
    begin
        for i in 3 downto 0 loop
            out_matrix(i, 0) := C0(i);
            out_matrix(i, 1) := C1(i);
            out_matrix(i, 2) := C2(i);
            out_matrix(i, 3) := C3(i);
        end loop;
        return out_matrix;
    end function column2matrix;

    function matrix2column(M : in matrix; c : integer) return byte_column is
        variable col : byte_column;
    begin
        for i in 3 downto 0 loop
            col(i) := M(i, c);
        end loop;
        return col;
    end function matrix2column;

    function column_rotate(col : in byte_column; shift : integer) return byte_column is
        variable res : byte_column;
    begin
        for i in 3 downto 0 loop
            res(i) := col((i + shift) mod 4);
        end loop;
        return res;
    end function column_rotate;

    function gmul(a, b : in byte) return byte is
        variable p : byte := (others => '0');
        variable hi_bit : std_logic;
        variable a_v, b_v : byte;
    begin
        a_v := a;
        b_v := b;
        for i in 0 to 7 loop
            if (b_v(0) = '1') then
                p := byte_xor(p, a_v);
            end if;
            hi_bit := a_v(7);
            a_v := std_logic_vector(unsigned(a_v) sll 1);
            if (hi_bit = '1') then
                a_v := byte_xor(a_v, x"1b");
            end if;
            b_v := std_logic_vector(unsigned(b_v) srl 1);
        end loop;
        return p;
    end function gmul;

    function mix_single_column(col : in byte_column) return byte_column is
        variable res : byte_column;
    begin
        res(0) := byte_xor(byte_xor(byte_xor(gmul(x"02", col(0)), gmul(x"03", col(1))), col(2)), col(3));
        res(1) := byte_xor(byte_xor(byte_xor(col(0), gmul(x"02", col(1))), gmul(x"03", col(2))), col(3));
        res(2) := byte_xor(byte_xor(byte_xor(col(0), col(1)), gmul(x"02", col(2))), gmul(x"03", col(3)));
        res(3) := byte_xor(byte_xor(byte_xor(gmul(x"03", col(0)), col(1)), col(2)), gmul(x"02", col(3)));
        return res;
    end function mix_single_column;

end package body aes_package;