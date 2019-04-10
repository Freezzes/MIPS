LIBRARY ieee;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.All;
USE ieee.std_logic_signed.ALL;
USE ieee.std_logic_unsigned.All;

entity rtype is
	port (clock: in STD_LOGIC;
			addr: out std_logic_vector(31 downto 0);
			result: out std_logic_vector(31 downto 0);
			read1: out std_logic_vector(31 downto 0);
			read2: out std_logic_vector(31 downto 0));

end rtype;

architecture behav of rtype is

signal instruction: std_logic_vector(31 downto 0); -- The actual instruction to run
signal now_address: std_logic_vector(31 downto 0);
signal add2_result, mux4_result,concatenated_pc_and_jump_address,mem_read_data: std_logic_vector(31 downto 0):= "00000000000000000000000000000000";
signal shifted_jump_address: std_logic_vector(27 downto 0);
signal last_instr_address,extended_immediate, shifted_immediate,read_data_1,read_data_2,write_data,alu_in_2,alu_result: std_logic_vector(31 downto 0):= "00000000000000000000000000000000"; -- vhdl does not allow me to port map " y => incremented_address(31 downto 28) & shifted_jump_address "
signal reg_dest, jump, branch, mem_read, mem_to_reg, mem_write, alu_src, reg_write, alu_zero, branch_and_alu_zero: std_logic:= '0'; -- vhdl does not allow me to port map " s => (branch and alu_zero) "
signal extendsign: std_logic_vector(15 downto 0);
signal opcode,funct: std_logic_vector(5 downto 0);
signal rs, rt, rd, shampt, write_regis: std_logic_vector(4 downto 0);
signal jump_address: std_logic_vector(25 downto 0);
signal alu_con_op: std_logic_vector(3 downto 0);
signal alu_op: std_logic_vector(1 downto 0);
signal read_addr: std_logic_vector(31 downto 0);
signal incremented_address: std_logic_vector(31 downto 0);




 -- Enum for checking if the instructions have loaded
type state is (loading, running, done);
signal s: state:= loading;

-- The clock for the other components; starts when the state is ready
signal en: std_logic:= '0';

	component control
		PORT (
		opcode        : IN std_logic_vector(5 DOWNTO 0); -- instruction 31-26
		regDst        : OUT std_logic;
		jump          : OUT std_logic;
		branch        : OUT std_logic;
		memRead       : OUT std_logic;
		memToRegister : OUT std_logic;
		ALUop         : OUT std_logic_vector(1 DOWNTO 0);
		memWrite      : OUT std_logic;
		ALUsrc        : OUT std_logic;
		regWrite      : OUT std_logic);
	end component;

	component mux
		GENERIC (n: NATURAL:= 1); -- number of bits in the choices
		port (a, b : IN STD_LOGIC_VECTOR(n-1 DOWNTO 0);
				sel  : IN STD_LOGIC;
				y    : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0));
	end component;
	
	component registers
		port ( clk			:	IN		STD_LOGIC;
				write_en		:	IN		STD_LOGIC;
				write_reg	:	IN		STD_LOGIC_VECTOR(4 DOWNTO 0);
				read_reg_1	:	IN		STD_LOGIC_VECTOR(4 DOWNTO 0);
				read_reg_2	:	IN		STD_LOGIC_VECTOR(4 DOWNTO 0);
				write_data	:	IN		STD_LOGIC_VECTOR(31 DOWNTO 0);
				read_data_1	:	OUT	STD_LOGIC_VECTOR(31 DOWNTO 0);
				read_data_2	:	OUT	STD_LOGIC_VECTOR(31 DOWNTO 0));
	end component;
	
	component pc
		port ( clk               : IN  STD_LOGIC;
	        current_instruction : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
	        next_instruction    : OUT STD_LOGIC_VECTOR(31 DOWNTO 0));
	end component;
	
	component instructions_memory IS
		port( instruction_addr  : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
				opcode :out  STD_LOGIC_VECTOR(5 DOWNTO 0);
				rs :out  STD_LOGIC_VECTOR(4 DOWNTO 0);
				rt :out  STD_LOGIC_VECTOR(4 DOWNTO 0);
				rd :out  STD_LOGIC_VECTOR(4 DOWNTO 0);
				shampt :out  STD_LOGIC_VECTOR(4 DOWNTO 0);
				funct :out  STD_LOGIC_VECTOR(5 DOWNTO 0);
				extendsign :out  STD_LOGIC_VECTOR(15 DOWNTO 0);
				jump_address :out  STD_LOGIC_VECTOR(25 DOWNTO 0));
	end component;
	
	component alu 
		port(	in1, in2	:	IN		STD_LOGIC_VECTOR(31 DOWNTO 0);
					op		:	IN		STD_LOGIC_VECTOR(3 DOWNTO 0);
					zero  :  OUT   STD_LOGIC;
					res	:	OUT	STD_LOGIC_VECTOR(31 DOWNTO 0));
	end component;
	
	component alu_control 
		port ( ALU_op		: in 	std_logic_vector(1 downto 0);
				Funct_field : in 	STD_LOGIC_VECTOR (5 downto 0);
				Operation 	: out STD_LOGIC_VECTOR (3 downto 0));
	end component;

	component adder 
		port ( x,y: in std_logic_vector(31 downto 0);
					z: out std_logic_vector(31 downto 0)	);
	end component;
	
	begin
	
		Prog_Count: pc 
		port map (clock,now_address,read_addr); 
		
		ADD1: adder 
		port map (read_addr,"00000000000000000000000000000000",incremented_address);

		branch_and_alu_zero <= branch and alu_zero;
		MUX4: mux generic map (32) 
		port map (incremented_address,add2_result,branch_and_alu_zero,now_address);
		
		IM: instructions_memory 
		port map (read_addr,opcode,rs,rt,rd,shampt,funct,extendsign,jump_address);
		
	
		ALU_CONTRL: alu_control 
		port map (alu_op, funct, alu_con_op);

		REG: registers 
		port map (clock,reg_write,rd,rs,rt,write_data,read_data_1,read_data_2);
		
		ALUIN: alu
		port map( read_data_1,read_data_2,alu_con_op,alu_zero,write_data);
				
		CONTROLLER: control
		port map(opcode,reg_dest,jump, branch, mem_read, mem_to_reg,alu_op,mem_write, alu_src, reg_write);
	
	read1 <= read_data_1;
	read2 <= read_data_2;
	result <= write_data;
	addr <= incremented_address;
end behav;