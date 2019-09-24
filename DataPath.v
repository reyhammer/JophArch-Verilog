module DataPath(
	input physical_clock, // Clock 50MHz

	input [21:0] IO_input, // 0-17 SWs; 18-21 Keys;
	output wire [25:0] IO_output, // 0-7 GreenLEDS; 8-25;
	
	output [15:0] DISPLAY_1,
	output [15:0] DISPLAY_2,
	output [31:0] DISPLAY_3,

	input DMA_Apply_Btn,
	output clock

);
	wire [57:0] IO_out;

	assign IO_output[25:0] = IO_out[25:0];

	VerilogDisplay inst_display1_0(
		IO_out[29:26],
		DISPLAY_1[7:0]
	);
	
	VerilogDisplay inst_display1_1(
		IO_out[33:30],
		DISPLAY_1[15:8]
	);
	







	VerilogDisplay inst_display2_0(
		IO_out[37:34],
		DISPLAY_2[7:0]
	);
	
	VerilogDisplay inst_display2_1(
		IO_out[41:38],
		DISPLAY_2[15:8]
	);






	VerilogDisplay inst_display3_0(
		IO_out[45:42],
		DISPLAY_3[7:0]
	);
	
	VerilogDisplay  inst_display3_1(
		IO_out[49:46],
		DISPLAY_3[15:8]
	);
	
	VerilogDisplay  inst_display3_2(
		IO_out[53:50],
		DISPLAY_3[23:16]
	);
	
	VerilogDisplay  inst_display3_3(
		IO_out[57:54],
		DISPLAY_3[31:24]
	);

	// wire clock;
	
	wire REG_write_back_flag;
	wire [7:0] REG_write_back_code;
	wire [31:0] REG_write_back_data;

	wire ALU_ENB;
	wire DMA_ENB;
	wire STACK_ENB;
	wire JMP_ENB;
	
	wire CALL_flag;
	wire RET_flag;

	wire [15:0] PC_pos;
	wire [31:0] JMP_pos;

	wire [31:0] r_eax;
	wire [31:0] r_ebx;
	wire [31:0] r_ecx;
	wire [31:0] r_edx;
	wire [3:0] r_clk;
	wire [15:0] r_esp;
	
	wire [7:0] f_register_code;
	wire [31:0] f_register_value;
  
	wire [7:0] s_register_code;
	wire [31:0] s_register_value;
  
	wire [7:0] t_register_code;
	wire [31:0] t_register_value;

	reg init_flag = 0;
	wire [31:0] DMA_current_instruction; // CURRENT INSTRUCTION
	wire [2:0] ID_type;
	wire [4:0] ID_func;
	wire [23:0] immediate;
	
	//wire ALU_ENB,
	wire ALU_write_back_flag;
	wire [7:0] ALU_write_back_code;
	wire [31:0] ALU_write_back_value;
	
	//wire DMA_ENB;
	wire DMA_write_back_flag;
	wire [7:0] DMA_write_back_code;
	wire [31:0] DMA_write_back_value;

	//wire STACK_ENB;
	wire STACK_write_back_flag;
	wire [7:0] STACK_write_back_code;
	wire [31:0] STACK_write_back_value;

	//wire JMP_ENB;
	wire JMP_write_back_flag;
	wire [7:0] JMP_write_back_code;
	wire [31:0] JMP_write_back_value;
	
	wire [31:0] clock_eff;

	assign clock_eff = ( r_clk == 0 )? 16 : ( r_clk == 1 )?  50000 : ( r_clk == 2 )? 500000 : ( r_clk == 3 )? 5000000 : 50000000;


	// FLAGS

	reg write_back_flag;
	reg ALU_src_flag;
	wire JMP_flag;

	// Program Counter

	
	// Program Decoder
	
	wire [3:0] M_ALU_op;
	wire [31:0] M_ALU_v1;
	wire [31:0] M_ALU_v2;
	wire [31:0] M_ALU_out;

	// ALU Decoder
	
	wire [4:0] ALU_op;
	wire [31:0] ALU_v1;
	wire [31:0] ALU_v2;

	// Instruction Decoder

	// DMA Instructions Wires
  
	wire DMA_stack_flag;
	wire [15:0] DMA_stack_data;
	// REGISTERs Wires
	
	reg n_reset = 1;
	
	wire DMA_Apply_clock;
	
	DeBounce inst_debounce(
		physical_clock,
		n_reset,
		DMA_Apply_Btn,
		DMA_Apply_clock
	);

	VirtualClock inst_virtualclock(
		physical_clock,
		clock_eff,
		clock
	);
  
	ProgramCounter inst_programcounter(
		clock,
		init_flag,
		JMP_flag,
		JMP_pos,

		CALL_flag,
		RET_flag,

		PC_pos
	);

	WriteController inst_writecontroller(

		ALU_ENB,
		ALU_write_back_flag,
		ALU_write_back_code,
		ALU_write_back_value,

		STACK_ENB,
		STACK_write_back_flag,
		STACK_write_back_code,
		STACK_write_back_value,

		JMP_ENB,
		JMP_write_back_flag,
		JMP_write_back_code,
		JMP_write_back_value,

		DMA_ENB,
		DMA_write_back_flag,
		DMA_write_back_code,
		DMA_write_back_value,

		REG_write_back_flag,
		REG_write_back_code,
		REG_write_back_data
	);
  
	TypeMux inst_typemux(
		ID_type,
		ALU_ENB,
		STACK_ENB,
		JMP_ENB,
		DMA_ENB
	);
	
	NDMA inst_new_dma(
		init_flag,
		clock,
		DMA_Apply_clock,
		DMA_ENB,
		DMA_current_instruction,
		f_register_value,
		s_register_value,
		t_register_value,
		IO_input,
		RAM_data,
		r_esp,
		IO_out,
		DMA_write_back_flag,
		DMA_write_back_code,
		DMA_write_back_value,
		RAM_write_flag,
		RAM_write_addr,
		RAM_write_data,
		DMA_stack_flag,
		DMA_stack_data
	);
	
	single_port_rom inst_instructionmem(
		PC_pos,
		physical_clock,
		DMA_current_instruction
	);

	wire [31:0] RAM_data;

	wire RAM_write_flag;
	wire [15:0] RAM_write_addr;
	wire [31:0] RAM_write_data;
	
	RAMMemory inst_datamem(
		RAM_write_data,
		RAM_write_addr,
		RAM_write_flag,
		physical_clock,
		RAM_data
	);
	
	ProgramDecoder inst_programdec(
		JMP_ENB,
		DMA_current_instruction,
		f_register_value,
		s_register_value,
		t_register_value,
		DMA_current_instruction[23:0],
		PC_pos,

		JMP_flag,
		CALL_flag,
		RET_flag,

		M_ALU_op,
		M_ALU_v1,
		M_ALU_v2
	);
	
	MiniALU inst_minialu(
		JMP_ENB,
		M_ALU_op,
		M_ALU_v1,
		M_ALU_v2,
		JMP_pos
	);
  
	//Test inst_2 (clock, write_back_code, write_back_value);

	InstructionDecoder inst_instdec(
		DMA_current_instruction,
		ID_type,
		ID_func,
		f_register_code,
		s_register_code,
		t_register_code,
		immediate
	);
	
	ALUDecoder inst_aludec(
		ALU_ENB,
		DMA_current_instruction,
		f_register_value,
		s_register_value,
		t_register_value,
		DMA_current_instruction[23:0],

		ALU_op,
		ALU_v1,
		ALU_v2,

		ALU_write_back_flag,
		ALU_write_back_code
	);

	ALU inst_alu(
		ALU_ENB,
		ALU_op,
		ALU_v1,
		ALU_v2,
		ALU_write_back_value
	);
  
	Registers inst_registers(
		init_flag,
		clock,

		REG_write_back_flag,
		REG_write_back_code,
		REG_write_back_data,

		f_register_code,
		s_register_code,
		t_register_code,

		STACK_TOP,
		STACK_AMOUNT,

		CALL_flag,
		RET_flag,
		
		DMA_stack_flag,
		DMA_stack_data,

		f_register_value,
		s_register_value,
		t_register_value,
		
		r_eax,
		r_ebx,
		r_ecx,
		r_edx,
		r_clk,
		r_esp,
		
		STACK_push_flag,
		STACK_push_value
	);
	
	/*wire write_bkp;

	assign write_bkp = 1;
	
	single_port_reg_bkp_ram (
		registers_bkp,
		bkp_pos,
		write_bkp,
		physical_clock,
		
		
	
	);*/



	wire [31:0] STACK_data;

	wire STACK_write_flag;
	wire [15:0] STACK_write_addr;
	wire [31:0] STACK_write_data;
	
	StackMemory inst_stack_ram(
		STACK_write_data,
		STACK_write_addr,
		STACK_write_flag,
		physical_clock,
		STACK_data
	);


	wire STACK_pop_flag;
	wire STACK_push_flag;
	wire [31:0] STACK_push_value;

	wire [31:0] STACK_TOP;

	wire [15:0] STACK_AMOUNT;
	
	NStacks inst_nstacks(
		STACK_ENB,
		clock,
		
		STACK_pop_flag,
		STACK_push_flag,
		STACK_push_value,
		STACK_data,

		STACK_TOP,
		STACK_AMOUNT,

		STACK_write_flag,
		STACK_write_addr,
		STACK_write_data
	);
	
	NStackDecoder inst_stackdec(
		init_flag,
		STACK_ENB,
		DMA_current_instruction,
		f_register_value,
		s_register_value,
		t_register_value,
		DMA_current_instruction[23:0],
	
		STACK_TOP,
	
		STACK_AMOUNT,

		STACK_pop_flag,

		STACK_write_back_flag,
		STACK_write_back_code,
		STACK_write_back_value

	);
  
	always@(negedge clock) begin
		init_flag = 1;
	end

endmodule
  
  