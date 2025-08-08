`include "alu.v"

// defines
`define PASS 1'b1
`define FAIL 1'b0
`define no_of_testcase 56

// Test bench for ALU design

module alu_tb();

	parameter 	stimulus_packet_size = 61,
				response_packet_size = 85,
				WIDTH = 8;
	
//	`ifdef hello 
//		wire [(2*WIDTH)-1:0] RES;
//	`else
//		wire [WIDTH:0] RES;
//	`endif

	reg [60:0] curr_test_case = 'd0;
	reg [60:0] stimulus_mem [0:`no_of_testcase-1];
	reg [84:0] response_packet;

//Stimulus declarations
	integer i,j;
	event fetch_stimulus; 
	// Inputs
	reg CLK,RST,CE;
	reg [7:0] OPA,OPB; 
	reg [3:0] CMD;
    reg MODE,CIN;
	reg [7:0] Feature_ID;
	reg [1:0] INP_VALID;
	reg [2:0] Comparison_GLE;
	reg [(2*WIDTH)-1:0] Expected_RES; 
	reg err,cout,ov,neg,zero;
    reg [2:0] res1;

//Decl to Cop UP the DUT OPERATION
	wire ERR,OFLOW,COUT,NEG,ZERO;
	wire [2:0] GLE;
	wire [(2*WIDTH)-1:0] RES;
	wire [23:0] expected_data;
    reg [23:0] exact_data;

//READ DATA FROM THE TEXT VECTOR FILE	
	task read_stimulus();	
		begin 
	    	#10 $readmemb ("stimulus.txt",stimulus_mem);
        end
    endtask 

	alu_new #(.WIDTH(WIDTH)) DUT( 
		.CLK(CLK), 
		.RST(RST), 
		.MODE(MODE), 
		.CE(CE),
		.CIN(CIN),
		.INP_VALID(INP_VALID), 
		.CMD(CMD), 
		.OPA(OPA),
		.OPB(OPB),
		.ERR(ERR),
		.RES(RES),
		.OFLOW(OFLOW),
		.COUT(COUT), 
		.G(GLE[2]),
		.L(GLE[1]),
		.E(GLE[0]),
		.NEG(NEG),
		.ZERO(ZERO)
	);

//STIMULUS GENERATOR
	integer stim_mem_ptr = 0, stim_stimulus_mem_ptr = 0, fid =0 , pointer =0 ;

	always@(fetch_stimulus)
		begin
			curr_test_case = stimulus_mem[stim_mem_ptr];
			$display ("stimulus_mem data = %0b \n", stimulus_mem[stim_mem_ptr]);
			$display ("packet data = %0b \n", curr_test_case);			
			stim_mem_ptr = stim_mem_ptr + 1;
		end

//INITIALIZING CLOCK
	initial 
	begin 
		CLK=0;
		forever 		
			#60 CLK=~CLK;
	end

//DRIVER MODULE
	task driver ();
		begin
            ->fetch_stimulus;
			@(posedge CLK);
                res1 = curr_test_case[60:58];
            	Feature_ID = curr_test_case[57:50];
				RST = curr_test_case[49];
                CE = curr_test_case[48];
		  		MODE = curr_test_case[47];
		  		CMD	= curr_test_case[46:43];
				INP_VALID = curr_test_case[42:41];
				OPA	= curr_test_case[40:33];
	          	OPB = curr_test_case[32:25];
                CIN	= curr_test_case[24];
                Expected_RES = curr_test_case[23:8];
                cout = curr_test_case[7];	
                ov = curr_test_case[6];	
                err = curr_test_case[5];	
               	Comparison_GLE = curr_test_case[4:2]; 
                neg = curr_test_case[1];	
                zero = curr_test_case[0];	
		 		$display("At time (%0t), Feature_ID = %0d, Reserved_bit = %2b, OPA = %8b, OPB = %8b, CMD = %4b, CIN = %1b, CE = %1b,INP_VALID = %2b, MODE = %1b, expected_result = %16b, cout = %1b, Comparison_GLE = %3b, ov = %1b, err = %1b, neg = %1b, zero = %1b",$time,Feature_ID,res1,OPA,OPB,CMD,CIN,CE,INP_VALID, MODE, Expected_RES,cout,Comparison_GLE,ov,err,neg,zero);
		end
	endtask

//GLOBAL DUT RESET
	task dut_reset ();
		begin 
			CE=1;
        	#10 RST=1;
			#20 RST=0;
		end
	endtask

//GLOBAL INITIALIZATION
	task global_init ();
		begin
			curr_test_case = 'd0;
			response_packet = 'd0;
			stim_mem_ptr = 0;
		end
	endtask	


//MONITOR PROGRAM 
task monitor ();
	begin
    	repeat(4)@(posedge CLK);
		#5 response_packet[60:0] = curr_test_case;
		response_packet[84:69]	= RES;
		response_packet[68]	= COUT;
		response_packet[67]	= OFLOW;
        response_packet[66]	= ERR;
		response_packet[65:63]	= {GLE};
        response_packet[62]	= NEG;
        response_packet[61]	= ZERO;
        $display("Monitor response: At time (%0t), RES = %b, COUT = %1b, GLE = %3b, OFLOW = %1b, ERR = %1b, NEG = %1b, ZERO = %1b",$time,RES,COUT,{GLE},OFLOW,ERR,NEG,ZERO);  	
        exact_data ={RES,COUT,{GLE},OFLOW,ERR,NEG,ZERO};
		end
	endtask
	assign expected_data = {Expected_RES,cout,Comparison_GLE,ov,err,neg,zero};

//SCORE BOARD PROGRAM TO CHECK THE DUT OP WITH EXPECTD OP
	
   reg [50:0] scb_stimulus_mem [0:`no_of_testcase-1];
   
   task score_board();
	   reg [15:0] expected_res;
	   reg [7:0] feature_id;
	   reg [23:0] response_data;
	   begin
		   #5;
		   feature_id = curr_test_case[57:50];
		   expected_res = curr_test_case[23:8];
		   response_data = response_packet[84:61];
		   $display("expected result = %24b ,response data = %24b",expected_data,exact_data);               
		   if(expected_data === exact_data)
			   scb_stimulus_mem[stim_stimulus_mem_ptr] = {1'b0,feature_id, expected_res,response_data, 1'b0,`PASS};
		   else
			   scb_stimulus_mem[stim_stimulus_mem_ptr] = {1'b0,feature_id, expected_res,response_data, 1'b0,`FAIL};
		   stim_stimulus_mem_ptr = stim_stimulus_mem_ptr + 1;
	   end
	endtask


//Generating the report `no_of_testcase-1
	task gen_report;
		integer file_id,pointer;
		reg [50:0] status;
		begin
			file_id = $fopen("results.txt", "w");
			for(pointer = 0; pointer <= `no_of_testcase - 1 ; pointer = pointer + 1 )
    		begin
				status = scb_stimulus_mem[pointer];
				if(status[0])
					$fdisplay(file_id, "Feature ID %d : PASS", status[49:42]);
  		    	else
					$fdisplay(file_id, "Feature ID %d : FAIL", status[49:42]);
       		end  		   
		end   
	endtask


	initial 
		begin 
			#10;
			global_init();
	      	dut_reset();
            read_stimulus();
   			for(j=0;j<=`no_of_testcase-1;j=j+1)
			begin
                fork                      
					driver();
                	monitor();
                join   
				score_board();  
				$display("-----------------------------------------------------------------------------------------");
            end
			gen_report();
            $fclose(fid);
			#300 $finish();
	    end
endmodule
