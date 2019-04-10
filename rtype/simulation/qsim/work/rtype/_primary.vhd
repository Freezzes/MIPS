library verilog;
use verilog.vl_types.all;
entity rtype is
    port(
        clock           : in     vl_logic;
        addr            : out    vl_logic_vector(31 downto 0);
        result          : out    vl_logic_vector(31 downto 0);
        read1           : out    vl_logic_vector(31 downto 0);
        read2           : out    vl_logic_vector(31 downto 0)
    );
end rtype;
