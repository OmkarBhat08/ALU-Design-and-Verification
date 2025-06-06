module alu_new #(parameter WIDTH = 8) (
	input CLK, RST, MODE, CE, CIN, 
  	input [1:0] INP_VALID,
  	input [3:0] CMD,
  	input [WIDTH-1:0] OPA, OPB,
 	output reg ERR, OFLOW, COUT, G, L, E, NEG, ZERO,
  	output reg [(2*WIDTH)-1:0] RES
	);

//	`ifdef hello 
//		output reg [(2*WIDTH)-1:0] RES;
//	`else
//		output reg [WIDTH:0] RES;
//	`endif
		
  
	reg mode_stage1, ce_stage1, cin_stage1;
 	reg [1:0] inp_valid_stage1;
  	reg [3:0] cmd_stage1;
  	reg [WIDTH-1:0] opa_stage1, opb_stage1;
  
  	reg err_stage2, oflow_stage2, cout_stage2, g_stage2, l_stage2, e_stage2, neg_stage2, zero_stage2;
  	reg [(2*WIDTH)-1:0] res_stage2;
  	reg [(2*WIDTH)-1:0] mulres;
  	reg [(2*WIDTH)-1:0] finalres;
  
  	localparam POW_2_N = $clog2(WIDTH);
  	wire [POW_2_N - 1:0] SH_AMT;
  	assign SH_AMT = OPB [POW_2_N - 1:0];
  	integer i =0;
  	reg [WIDTH - POW_2_N - 2 : 0] count[POW_2_N-1:0] ;
  	
  	// stage 1
  	always@(posedge CLK or posedge RST)
  	begin
  		if(RST)
  		begin
  			mode_stage1 <= 'd0;
  			ce_stage1 <= 'd0;
  			cin_stage1 <= 'd0;
  			inp_valid_stage1 <= 'd0;
  			cmd_stage1 <= 'd0;
  			opa_stage1 <= 'd0;
  			opb_stage1 <= 'd0;
  		end
  		else
  		begin
  			mode_stage1 <= MODE;
  			ce_stage1 <= CE;
  			cin_stage1 <= CIN;
  			inp_valid_stage1 <= INP_VALID;
  			cmd_stage1 <= CMD;
  			opa_stage1 <= OPA;
  			opb_stage1 <= OPB;
  		end
	end
	
  	always@(posedge CLK or posedge RST)
  	begin
  		if(RST)		// If RST is 1 set output to zero
  		begin
  			RES <= 'd0;
  			ERR <= 'd0;
  			OFLOW <= 'd0;
  			COUT <= 'd0;
  			{G,L,E} <= 'd0;
  			NEG <= 'd0;
  			ZERO <= 'd0;
  		end
  		else if((mode_stage1 == 1) && ((cmd_stage1 == 4'b1001) || (cmd_stage1 == 4'b1010)))
		begin
  			RES <= finalres;
			ERR <= 'd0;
			OFLOW <= 'd0;
			COUT <= 'd0;
			{G,L,E} <= 'd0;
			NEG <= 'd0;
			ZERO <= 'd0;
		end
  		else		// If RST is 0
  		begin
  			RES <= 16'h01FF & res_stage2;
			ERR <= err_stage2;
			OFLOW <= oflow_stage2;
			COUT <= cout_stage2;
			{G,L,E} <= {g_stage2,l_stage2,e_stage2};
			NEG <= neg_stage2;
			ZERO <= zero_stage2;
  		end
	end

	always @(*)
  	begin
  		if(RST)
  		begin
			oflow_stage2 = 'd0;
			cout_stage2 = 'd0;
			g_stage2 = 'd0;
			l_stage2 = 'd0;
			e_stage2 = 'd0;
			neg_stage2 = 'd0;
			zero_stage2 = 'd0;
			res_stage2 = 'd0;
			err_stage2 = 'd0;
			mulres = 'd0;
  		end
  		else
  		begin
			// Prevent latching issues
  			cout_stage2 = 'd0;
  			g_stage2 = 'd0;
			l_stage2 = 'd0;
			e_stage2 = 'd0;
			oflow_stage2 = 'd0;
			mulres = 'd0;
			neg_stage2 = 'd0;
			res_stage2 = 'd0;
			zero_stage2 = 'd0;
			
			if(ce_stage1)		//If CE is high
			begin
				if(mode_stage1)
				begin
					case(inp_valid_stage1)
					2'b00:      // Neither OPA nor OPB are enabled
					begin
						res_stage2 = 'd0;
						cout_stage2 = 'd0;
						oflow_stage2 = 'd0;
						err_stage2 = 'd1;
					end
					2'b10:	// When only OPB is enabled
					begin
						case(cmd_stage1)
						4'b0110:    // INC_B
						begin
							res_stage2 =opb_stage1 + 1;
							cout_stage2 = res_stage2[WIDTH];
							err_stage2 = 'd0;
						end
						4'b0111:    // DEC_B
						begin
							res_stage2 = opb_stage1 - 1;
							cout_stage2 = (opb_stage1==0);
							err_stage2 = 'd0;
						end
						default: 
						begin
							res_stage2 = 'd0;
							err_stage2 = 'd1;
							cout_stage2 = 'd0;
						end
						endcase		// End of CMD
					end		// End of 2'b01
					2'b01:	// When only OPA is enabled
					begin
						case(cmd_stage1)
						4'b0100:    // INC_A
						begin
							res_stage2 = opa_stage1 + 1;
							cout_stage2 = res_stage2[WIDTH];
							err_stage2 = 'd0;
						end
						4'b0101:    // DEC_A
						begin
							res_stage2 = opa_stage1 - 1;
							cout_stage2 = (opa_stage1==0);
							err_stage2 = 'd0;
						end
						default: 
						begin
							res_stage2 = 'd0;
							err_stage2 = 'd1;
							cout_stage2 = 'd0;
						end
						endcase		// End of cmd
					end		// End of 2'b10
					2'b11: // Both OPA and OPB are enabled
					begin
						case(cmd_stage1)
						4'b0000:	// ADD
                		begin
                			res_stage2 = opa_stage1 + opb_stage1;
                 			cout_stage2 = res_stage2[WIDTH];
                 			oflow_stage2 = res_stage2[WIDTH];
                  			err_stage2 = 'd0;
                		end
                		4'b0001:	// Subtract
                		begin
                			res_stage2 = opa_stage1 - opb_stage1;
                			oflow_stage2 = (opa_stage1 < opb_stage1);
                			cout_stage2 = res_stage2[WIDTH];
                			err_stage2 = 'd0;
                		end
                		4'b0010:	// ADD_CIN
                		begin
                			res_stage2 = opa_stage1 + opb_stage1 + cin_stage1;
                			cout_stage2 = res_stage2[WIDTH];
                			oflow_stage2 = res_stage2[WIDTH];
                			err_stage2 = 'd0;
                		end
                		4'b0011:		// SUB_CIN
                		begin
                			res_stage2 = (opa_stage1 - opa_stage1) - cin_stage1;
                			oflow_stage2 = ((opa_stage1 < opb_stage1) || ((opa_stage1 == opb_stage1) && (cin_stage1 != 0)));
                			cout_stage2 = res_stage2[WIDTH];
                			err_stage2 = 'd0;
                		end
                		4'b1000:		// CMP
                		begin
                			if(opa_stage1 == opb_stage1)
                				{g_stage2,l_stage2,e_stage2} = 3'b001;
                			else if (opa_stage1 > opb_stage1)
                				{g_stage2,l_stage2,e_stage2} = 3'b100;
                			else
                				{g_stage2,l_stage2,e_stage2} = 3'b010;
                		
                			err_stage2 = 'd0;
                			res_stage2 = 'd0;
                		end
                		4'b1001:		// Increment and multiply
                		begin
                			mulres[15:0] = (opa_stage1+1) *(opb_stage1+1);
                			err_stage2 = 'd0;
                			{g_stage2,l_stage2,e_stage2} = 3'b000;
                		end
                		4'b1010:		// SLL_A * B
                		begin
                			mulres[15:0] = (opa_stage1 << 1) * opb_stage1;
                			err_stage2 = 'd0;
                			{g_stage2,l_stage2,e_stage2} = 3'b000;
                		end
                		4'b1011:    // Signed Addition
                		begin
							res_stage2 = $signed(opa_stage1) + $signed(opb_stage1);
							cout_stage2 = res_stage2[WIDTH];
                			err_stage2 = 'd0;
                	
                			oflow_stage2 = (($signed(opa_stage1[WIDTH-1]) == $signed(opb_stage1[WIDTH-1])) && ($signed(opa_stage1[WIDTH-1]) != res_stage2[WIDTH-1]));		// Compute overflow

                			neg_stage2 = res_stage2[WIDTH];		// Update neg flag
                  			zero_stage2 = (res_stage2 == 0)?'d1:'d0;	// Update zero flag
                  	
                  			if($signed(opa_stage1) > $signed(opb_stage1))	// Update GLE flags
                				{g_stage2,l_stage2,e_stage2} = 3'b100;
                  			else if($signed(opa_stage1) < $signed(opb_stage1))
                				{g_stage2,l_stage2,e_stage2} = 3'b010;
							else
                				{g_stage2,l_stage2,e_stage2} = 3'b001;
                		end
                		4'b1100:    // Signed Subtraction
                		begin
							res_stage2 = $signed(opa_stage1) - $signed(opb_stage1);
                			cout_stage2 = res_stage2[WIDTH];
                			err_stage2 = 'd0;
                			oflow_stage2 = (($signed(opa_stage1[WIDTH-1]) == $signed(opb_stage1[WIDTH-1])) && ($signed(opa_stage1[WIDTH-1]) != res_stage2[WIDTH-1]));		// Compute overflow

                			neg_stage2 = res_stage2[WIDTH];		// Update neg flag
                  			zero_stage2 = (res_stage2 == 0)?'d1:'d0;	// Update zero flag
                  	
                  			if($signed(opa_stage1) > $signed(opb_stage1))	// Update GLE flags
                				{g_stage2,l_stage2,e_stage2} = 3'b100;
                  			else if($signed(opa_stage1) < $signed(opb_stage1))
                				{g_stage2,l_stage2,e_stage2} = 3'b010;
							else
                				{g_stage2,l_stage2,e_stage2} = 3'b001;
						end
                		default:
                		begin
                			res_stage2 = 'd0;
                			cout_stage2 = 'd0;
                			oflow_stage2 = 'd0;
                			err_stage2 = 'd1;
                		end
              			endcase		// End of CMD for arithmetic operations
            		end		// End for 2'b11
          			endcase		// end for inp_valid
        		end			// End of mode=1 (Arithmetic)
        		else		//	if mode = 0 (Logical) 
        		begin
        			case(inp_valid_stage1)
        			2'b00:		// Neither OPA nor OPB are enabled
        			begin
        				res_stage2 = 'd0;
        				err_stage2 = 'd1;
        			end
        			2'b10:		// When only OPB is enabled
        			begin
        				case(cmd_stage1)
        				4'b0111:    // NOT_B
        				begin
        					res_stage2 =  16'h00FF & (~opb_stage1);
        					err_stage2 = 'd0;
        				end
        				4'b1010:		// SHR1_B
        				begin
        					res_stage2 = 16'h00FF & (opb_stage1 >> 1);
        					err_stage2 = 'd0;
        				end
        				4'b1011:    // SHL1_B
        				begin
        					res_stage2 = 16'h00FF & (opb_stage1 << 1);
        					err_stage2 = 'd0;
        				end
        				default:
        				begin
        					res_stage2 = 'd0;
        					err_stage2 = 'd1;
        				end
        				endcase
        			end		// End of 2'b01
        			2'b01:	// When only OPA is enabled
        			begin
        				case(cmd_stage1)
        				4'b0110:    //NOT_A
        				begin
        					res_stage2 = 16'h00FF & (~opa_stage1);
        					err_stage2 = 'd0;
        				end
        				4'b1000:    // SHR1_A
        				begin
        					res_stage2 = 16'h00FF & (opa_stage1 >> 1);
        					err_stage2 = 'd0;
        				end
        				4'b1001:    // SHL1_A
        				begin
        					res_stage2 = 16'h00FF & (opa_stage1 << 1);
        					err_stage2 = 'd0;
        				end
        				default:
        				begin
        					res_stage2 = 'd0;
        					err_stage2 = 'd1;
        				end
        				endcase
        			end		// End of 2'b10
        			2'b11:		// When both OPA and OPB are enabled
        			begin
        				case(CMD)
        				4'b0000:    // AND
        				begin
        					res_stage2 = 16'h00FF & (opa_stage1 & opb_stage1);
        					err_stage2 = 'd0;
        				end
        				4'b0001:    // NAND
        				begin
        					res_stage2 = 16'h00FF & (~(opa_stage1 & opb_stage1));
        					err_stage2 = 'd0;
        				end
        				4'b0010:    // OR
        				begin
        					res_stage2 = 16'h00FF & (opa_stage1 | opb_stage1);
        					err_stage2 = 'd0;
        				end
        				4'b0011:    // NOR
        				begin
        					res_stage2 = 16'h00FF &  (~(opa_stage1 | opb_stage1));
        					err_stage2 = 'd0;
        				end
        				4'b0100:    // XOR
        				begin
        					res_stage2 = 16'h00FF & (opa_stage1 ^ opb_stage1);
        					err_stage2 = 'd0;
        				end
        				4'b0101:    // XNOR
        				begin
        					res_stage2 = 16'h00FF & (~(opa_stage1 ^ opb_stage1));
        					err_stage2 = 'd0;
        				end
        				4'b1100:    // ROL_A_B
        				begin
        					res_stage2 = 16'h00FF & ({1'b0,(opa_stage1 << SH_AMT | opa_stage1 >> (WIDTH - SH_AMT))});
        					err_stage2 = |opb_stage1[WIDTH - 1 : POW_2_N +1];
        				end
        				4'b1101:        // ROR_A_B
        				begin
        					res_stage2 = 16'h00FF & ({1'b0,opa_stage1 << (WIDTH- SH_AMT) | opa_stage1 >> SH_AMT});
        					err_stage2 = |opb_stage1[WIDTH - 1 : POW_2_N +1];
        				end
        				default:
        				begin
        					res_stage2 = 'd0;
        					err_stage2 = 'd1;
        				end
        				endcase
        			end		// End of 2'b11
        			endcase
        		end		// End of mode=0 (Logical)
			end			// End of CE =1
			else		//If CE is low
			begin
				err_stage2 = 'd0;
  				res_stage2 = 'd0;
  				oflow_stage2 = 'd0;
  				cout_stage2 = 'd0;
  				{g_stage2,l_stage2,e_stage2} = 'd0;
  				neg_stage2 = 'd0;
  				zero_stage2 = 'd0;
			end
		end
	end
  
  	always @(posedge CLK or posedge RST)
  	begin
  		if(RST)
  			finalres <= 'd0;
  		else
  			finalres <= mulres;
  	end
endmodule
