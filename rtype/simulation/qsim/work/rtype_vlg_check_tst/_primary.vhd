library verilog;
use verilog.vl_types.all;
entity rtype_vlg_check_tst is
    port(
        addr            : in     vl_logic_vector(31 downto 0);
        read1           : in     vl_logic_vector(31 downto 0);
        read2           : in     vl_logic_vector(31 downto 0);
        result          : in     vl_logic_vector(31 downto 0);
        sampler_rx      : in     vl_logic
    );
end rtype_vlg_check_tst;
