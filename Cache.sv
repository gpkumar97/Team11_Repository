//-----------------------------------------------------------------------------
// Title       : Cache Statistics
// Authors     : Naveen Babu Vanamala <>
//				 Pavan Kumar Govardhanam <>
//				 Sai Krishna Vallabhaneni <>
//				 Venkata Mohan Krishna Challa <ven4@pdx.edu>
//
// Description : Cache LLC Deisgn file
//
//-----------------------------------------------------------------------------


import cache_specs::*;

module cache(
	input logic [Command_size - 1:0]inp_cmd,		
	input logic [address_bits-1:0]inp_addr,
	output real read,						
	output real write,				
	output real cache_hit,			
	output real cache_miss
);	

logic tag_hit 	= 0;
logic tag_miss 	= 0;

logic [bits_state-1:0] STATE[sets-1:0][ways-1:0];  	
logic [Tag_bits-1:0] TAG[sets-1:0][ways-1:0];  

logic [(Tag_bits+Set_bits)-1:0]trace_address;
logic [(Tag_bits+Set_bits)-1:0]evict_address;

logic [Set_bits-1:0]req_set; 
logic [Tag_bits-1:0]req_tag; 
logic [bits_state-1:0]hit_state;
integer hit_way;

logic [PLRU_bits-1:0]LRU_way;
logic [(Tag_bits+Set_bits)-1:0]L1_address;
logic [ways-2:0]PLRU_status_bits[sets-1:0];

snp_rslt_t SnoopResult;


bit [PLRU_bits-1:0] way_returned_by_LRU;

logic LRU;

initial 
begin

	for(int x = 0; x < sets; x = x + 1'b1) begin
	
			PLRU_status_bits [x]  = 7'b0000000;
	
		end
	end


initial	Clear_Cache;


always@(inp_cmd) begin
	case(inp_cmd) 
		
		

		SNOOP_read:
		begin
				check_cache_for_data;
				if(tag_hit) begin
					MESI_task;
				end
				else if(tag_miss) begin
					PutSnoopResult(trace_address, NO_HIT);
				end
		end	

		SNOOP_write:                                                                              
		begin
				check_cache_for_data;
				if(tag_hit) begin
					MESI_task;
				end
				else if(tag_miss) begin
					PutSnoopResult(trace_address, NO_HIT);
				end
		end	

		SNOOP_rdX:
		begin
				check_cache_for_data;
				if(tag_hit) begin
					MESI_task;
				end
				else if(tag_miss) begin
					PutSnoopResult(trace_address, NO_HIT);
				end
		end	
		
        SNOOP_invalidate:
		begin
				check_cache_for_data;
				if(tag_hit) begin
					MESI_task;
				end
				else if(tag_miss) begin
					PutSnoopResult(trace_address, NO_HIT);
				end
		end	
	

		CPU_data_read:																
		begin
				read = read + 1'b1;	 
				check_cache_for_data;														
				if(tag_hit) begin
					if( STATE[req_set][hit_way] != I) begin
						cache_hit = cache_hit + 1'b1;										
		
						
					end
					else begin
						cache_miss = cache_miss + 1'b1;										
				
						
					end
				end
				else if(tag_miss) begin
					cache_miss = cache_miss + 1'b1;											
					
					
				end	
				PLRU_task;														
				MESI_task;				
		end	

		CPU_data_write:																
		begin
				write = write + 1'b1;
				check_cache_for_data;														
				if(tag_hit) begin													
					if( STATE[req_set][hit_way] == M || STATE[req_set][hit_way] == E || STATE[req_set][hit_way] == S ) begin
						cache_hit = cache_hit + 1'b1;										
		
						
					end
					else if(STATE[req_set][hit_way] == I)begin
						cache_miss = cache_miss + 1'b1;										
				
						
					end
				end
				else if(tag_miss) begin
					cache_miss = cache_miss + 1'b1;											
					
					
				end
				PLRU_task;														
				MESI_task;														
		end

		CLEAR:
		begin
				Clear_Cache;
		end

		PRINT :
		begin 
				PRINT_CACHE_LINES;	
		end
	endcase
		
	
end



task PLRU_task;

if(tag_hit) update_LRU(req_set,hit_way);
else get_LRU(req_set);

endtask: PLRU_task

task update_LRU(int Set,int way);
case(way)
	0 : PLRU_status_bits[Set]	 = PLRU_status_bits[Set]	& 7'd120;
	1 : PLRU_status_bits[Set]	 = PLRU_status_bits[Set]	& 7'd120|7'd4;
	2 : PLRU_status_bits[Set]	 = PLRU_status_bits[Set]	& 7'd120|7'd2;
	3 : PLRU_status_bits[Set]	 = PLRU_status_bits[Set]	& 7'd120|7'd3;
	4 : PLRU_status_bits[Set]	 = PLRU_status_bits[Set]	& 7'b11001110;
	5 : PLRU_status_bits[Set]	 = PLRU_status_bits[Set]	& 7'b11001110|7'b00000001;
	6 : PLRU_status_bits[Set]	 = PLRU_status_bits[Set]	& 7'b101111|7'b0001001;
	7 : PLRU_status_bits[Set]	 = PLRU_status_bits[Set]  | 7'b1010001;
endcase
 LRU_way = way;
endtask

task get_LRU(int Set);
	if(PLRU_status_bits[Set][0]==0)
		begin
			if(PLRU_status_bits[Set][1]==0)
				begin
					if(PLRU_status_bits[Set][2]==0)
						begin
			              way_returned_by_LRU = 7;
						end
					else
						begin
							way_returned_by_LRU = 6;
						end
				end
			else
				begin
					if(PLRU_status_bits[Set][3]==0)
						begin
			              way_returned_by_LRU = 5;
						end
					else
						begin
							way_returned_by_LRU = 4;
						end

				end
		end
	else
		begin
		if(PLRU_status_bits[Set][4]==0)
				begin
					if(PLRU_status_bits[Set][5]==0)
						begin
			              way_returned_by_LRU = 3;
						end
					else
						begin
							way_returned_by_LRU = 2;
						end
				end
			else
				begin
					if(PLRU_status_bits[Set][6]==0)
						begin
			              way_returned_by_LRU = 1;
						end
					else
						begin
							way_returned_by_LRU = 0;
						end
				end
		end		
	
	 LRU_way = way_returned_by_LRU ;
	
evict_address = {TAG[Set][way_returned_by_LRU],Set};
	
PLRU_status_bits[Set][0] = ~PLRU_status_bits[Set][0];
	if(way_returned_by_LRU == 0 )
	begin 
	PLRU_status_bits[Set][1] = ~PLRU_status_bits[Set][1];
	PLRU_status_bits[Set][2] = ~PLRU_status_bits[Set][2];
	end else if(way_returned_by_LRU == 1 )
	begin 
	PLRU_status_bits[Set][1] = ~PLRU_status_bits[Set][1];
	PLRU_status_bits[Set][2] = ~PLRU_status_bits[Set][2];
	end else if(way_returned_by_LRU == 2 )
	begin 
	PLRU_status_bits[Set][1] = ~PLRU_status_bits[Set][1];
	PLRU_status_bits[Set][3] = ~PLRU_status_bits[Set][3];
	end else if(way_returned_by_LRU == 3 )
	begin 
	PLRU_status_bits[Set][1] = ~PLRU_status_bits[Set][1];
	PLRU_status_bits[Set][2] = ~PLRU_status_bits[Set][2];
	end else if(way_returned_by_LRU == 4 )
	begin 
	PLRU_status_bits[Set][4] = ~PLRU_status_bits[Set][4];
	PLRU_status_bits[Set][5] = ~PLRU_status_bits[Set][5];
	end else if(way_returned_by_LRU == 5 )
	begin 
	PLRU_status_bits[Set][4] = ~PLRU_status_bits[Set][4];
	PLRU_status_bits[Set][5] = ~PLRU_status_bits[Set][5];
	end else if(way_returned_by_LRU == 6 )
	begin 
	PLRU_status_bits[Set][4] = ~PLRU_status_bits[Set][4];
	PLRU_status_bits[Set][6] = ~PLRU_status_bits[Set][6];
	end else if(way_returned_by_LRU == 7 )
	begin 
	PLRU_status_bits[Set][4] = ~PLRU_status_bits[Set][4];
	PLRU_status_bits[Set][6] = ~PLRU_status_bits[Set][6];
	end

	
endtask


task MESI_task;

	if(tag_hit) begin
		case(STATE[req_set][LRU_way])
			
			
			I :   
			begin
					if(inp_cmd == CPU_data_read) begin
						BusOperation(READ, trace_address);	
			       		L1_address = TAG[req_set][LRU_way];
						if((SnoopResult == HIT) || (SnoopResult == HIT_M)) begin		
							STATE[req_set][LRU_way] = S;
							MessageToL1Cache(2,L1_address);	 
						end
						else if(SnoopResult == NO_HIT) begin
							STATE[req_set][LRU_way] = E;
							MessageToL1Cache(2,L1_address);

							
						end
					end
					else if(inp_cmd == CPU_data_write) begin
						STATE[req_set][LRU_way] = M;
						BusOperation(RWIM, trace_address);	

					end						if(inp_cmd == SNOOP_read) begin
							STATE[req_set][hit_way] = I;
							PutSnoopResult(trace_address, NO_HIT);				

							
						end
						else if(inp_cmd == SNOOP_write) begin	
							STATE[req_set][hit_way] = I;
							PutSnoopResult(trace_address, NO_HIT);				

							
						end
						else if(inp_cmd == SNOOP_invalidate) begin	
							STATE[req_set][hit_way] = I;
							PutSnoopResult(trace_address, NO_HIT);				

							
						end
						else if(inp_cmd == SNOOP_rdX) begin	
							STATE[req_set][hit_way] = I;
							PutSnoopResult(trace_address, NO_HIT);				

							
						end
			end
			
			S :	   
			begin
					if(inp_cmd == CPU_data_read) begin
						STATE[req_set][LRU_way] = S;	
	      				L1_address = TAG[req_set][LRU_way];
                        MessageToL1Cache(2,L1_address);
	
					end
					else if(inp_cmd == CPU_data_write) begin
						STATE[req_set][LRU_way] = M;
						BusOperation(INVALIDATE, trace_address);
						
					end 						if(inp_cmd == SNOOP_read) begin
							STATE[req_set][hit_way] = S;
							PutSnoopResult(trace_address, HIT);					

							
						end
						
						else if(inp_cmd == SNOOP_invalidate) begin	
							STATE[req_set][hit_way] = I;
							PutSnoopResult(trace_address, HIT);					
							 
							 
							L1_address = trace_address;							
							MessageToL1Cache(3,L1_address);
							
						end
						else if(inp_cmd == SNOOP_rdX) begin	
							STATE[req_set][hit_way] = I;
							PutSnoopResult(trace_address, HIT);					
							 
							 
							L1_address = trace_address;							
							MessageToL1Cache(3,L1_address);
							
						end	
			end		
	

			M : 	
			begin
					
	
					if(inp_cmd == CPU_data_read) begin
						STATE[req_set][LRU_way] = M;
	      				L1_address = TAG[req_set][LRU_way];
						MessageToL1Cache(2,L1_address);

					end
					else if(inp_cmd == CPU_data_write) begin
						STATE[req_set][LRU_way] = M;
					end	if(inp_cmd == SNOOP_read) begin
							STATE[req_set][hit_way] = S;	
							PutSnoopResult(trace_address, HIT_M);
							BusOperation(WRITE, trace_address);	
							L1_address = TAG[req_set][hit_way];
							MessageToL1Cache(1,L1_address);		
						end
						
						else if(inp_cmd == SNOOP_rdX) begin	
							STATE[req_set][hit_way] = I;
							PutSnoopResult(trace_address, HIT_M);				
							BusOperation(WRITE, trace_address);											 										
							L1_address = trace_address;
							MessageToL1Cache(4,L1_address);
							
						end			
			end		
	
			E : 
			begin
					if(inp_cmd == CPU_data_read) begin
						STATE[req_set][LRU_way] = E;
	      				L1_address = TAG[req_set][LRU_way];
						MessageToL1Cache(2,L1_address);
						
					end
					else if(inp_cmd == CPU_data_write) begin
					
						STATE[req_set][LRU_way] = M;		
						
						
					end	if(inp_cmd == SNOOP_read) begin
							STATE[req_set][hit_way] = S;
							PutSnoopResult(trace_address, HIT);										
						end
						
						else if(inp_cmd == SNOOP_rdX) begin	
							STATE[req_set][hit_way] = I;
							PutSnoopResult(trace_address, HIT);												 
							L1_address = trace_address;							
							MessageToL1Cache(3,L1_address);
							
						end
			end
	

		endcase 
		end	
	

	else if(tag_miss) begin

			case(STATE[req_set][LRU_way])
				M : 
				begin
						if(inp_cmd == CPU_data_read) begin
							BusOperation(WRITE, evict_address);					
							 
							L1_address = evict_address;	
							MessageToL1Cache(4,L1_address);							
							BusOperation(READ, trace_address);								
							if((SnoopResult == HIT) || (SnoopResult == HIT_M)) begin	
								STATE[req_set][LRU_way] = S;
								TAG[req_set][LRU_way] = inp_addr[address_bits - 1: (Set_bits + Byte_select_bits)];
								
							
							end
							else if(SnoopResult == NO_HIT) begin
								STATE[req_set][LRU_way] = E;
								TAG[req_set][LRU_way] = inp_addr[address_bits - 1: (Set_bits + Byte_select_bits)];
	
								
							end
						end
						else if(inp_cmd == CPU_data_write) begin
							BusOperation(WRITE, evict_address);							
							 
							L1_address = evict_address;		
							MessageToL1Cache(4,L1_address);									
							BusOperation(RWIM, trace_address);							
							STATE[req_set][LRU_way] = M;
							TAG[req_set][LRU_way] = inp_addr[address_bits - 1: (Set_bits + Byte_select_bits)];
		
							
						end				
				end			
		
				E : 
				begin
						if(inp_cmd == CPU_data_read) begin
							BusOperation(READ, trace_address);							
							 
							L1_address = evict_address;	
							
							MessageToL1Cache(4,L1_address);									
							if((SnoopResult == HIT) || (SnoopResult == HIT_M)) begin	
								STATE[req_set][LRU_way] = S;	
								TAG[req_set][LRU_way] = inp_addr[address_bits - 1: (Set_bits + Byte_select_bits)];
	
								
							end
							else if(SnoopResult == NO_HIT) begin
								STATE[req_set][LRU_way] = E;
								TAG[req_set][LRU_way] = inp_addr[address_bits - 1: (Set_bits + Byte_select_bits)];
	
								
							end
						end
						else if(inp_cmd == CPU_data_write) begin
							BusOperation(RWIM, trace_address);							
							 
							L1_address = evict_address;	
							MessageToL1Cache(4,L1_address);																
							STATE[req_set][LRU_way] = M;
							TAG[req_set][LRU_way] = inp_addr[address_bits - 1: (Set_bits + Byte_select_bits)];
	
							
						end	
				end
	
				S :	   
				begin
						if(inp_cmd == CPU_data_read) begin
							BusOperation(READ, trace_address);						
							 
							L1_address = evict_address;	
							MessageToL1Cache(4,L1_address);																
							if((SnoopResult == HIT) || (SnoopResult == HIT_M)) begin
								STATE[req_set][LRU_way] = S;
								TAG[req_set][LRU_way] = inp_addr[address_bits - 1: (Set_bits + Byte_select_bits)];
		
								
							end
							else if(SnoopResult == NO_HIT) begin
								STATE[req_set][LRU_way] = E;
								TAG[req_set][LRU_way] = inp_addr[address_bits - 1: (Set_bits + Byte_select_bits)];
	
								
							end
						end
						else if(inp_cmd == CPU_data_write) begin
							BusOperation(RWIM, trace_address);							
							 
							L1_address = evict_address;	
							MessageToL1Cache(4,L1_address);
							STATE[req_set][LRU_way] = M;
							TAG[req_set][LRU_way] = inp_addr[address_bits - 1: (Set_bits + Byte_select_bits)];	

							
						end	
				end		
	
				I :   
				begin
						if(inp_cmd == CPU_data_read) begin
							BusOperation(READ, trace_address);								
							if((SnoopResult == HIT) || (SnoopResult == HIT_M)) begin
								STATE[req_set][LRU_way] = S;
								TAG[req_set][LRU_way] = inp_addr[address_bits - 1: (Set_bits + Byte_select_bits)];
								L1_address = TAG[req_set][LRU_way];
								MessageToL1Cache(2,L1_address);

								
							end
							else if(SnoopResult == NO_HIT) begin
								STATE[req_set][LRU_way] = E;
								TAG[req_set][LRU_way] = inp_addr[address_bits - 1: (Set_bits + Byte_select_bits)];
								L1_address = TAG[req_set][LRU_way];
								MessageToL1Cache(2,L1_address);
	
							end
						end
						else if(inp_cmd == CPU_data_write) begin
							BusOperation(RWIM, trace_address);								
							STATE[req_set][LRU_way] = M;
							TAG[req_set][LRU_way] = inp_addr[address_bits - 1: (Set_bits + Byte_select_bits)];

							
						end	
				end
			endcase 
	end

			 												

endtask : MESI_task



task BusOperation(input bus_op_t bus_op, input [(Tag_bits+Set_bits)-1:0]Address);
	GetSnoopResult(inp_addr, SnoopResult);
	if(Normal_mode) $display("\n==> BusOp = %s",bus_op);
endtask :  BusOperation



task GetSnoopResult(input [address_bits-1:0]Address, output snp_rslt_t snp_rslt);
	bit [1:0]snoop_bits;
	assign snoop_bits = Address[1:0];
	case(snoop_bits)
			2'b00 	: snp_rslt = HIT;
			2'b01 	: snp_rslt = HIT_M;
			default : snp_rslt = NO_HIT;
	endcase

endtask : GetSnoopResult


task PutSnoopResult(input [(Tag_bits+Set_bits)-1:0]Address, input snp_rslt_t put_snp_rslt);
	//if(Normal_mode) $display("\n ==> Putsnoop Address = %h, \n ==> Put Snoop Result = %s", Address, put_snp_rslt);

endtask : PutSnoopResult


assign trace_address = inp_addr[address_bits-1:Byte_select_bits];
assign req_set = inp_addr[(Byte_select_bits + Set_bits)-1 : Byte_select_bits ]; 			
assign req_tag = inp_addr[ address_bits-1 :(Set_bits + Byte_select_bits) ];

assign hit_state = STATE[req_set][hit_way];

task check_cache_for_data;
	tag_hit = false;
	tag_miss = false;
	for(int way_cnt = 0; way_cnt < ways; way_cnt = way_cnt + 1'b1) begin
		if(TAG[req_set][way_cnt] == req_tag) begin
			tag_hit = true;
			tag_miss = false; 
			hit_way = way_cnt;

			end
	end
	if(tag_hit == false) begin
		tag_hit = false;
		tag_miss = true;
	
		
	end
endtask : check_cache_for_data


task Clear_Cache;
	cache_hit 	= 0;
	cache_miss 	= 0;
	read 	= 0;
	write 	= 0;
	
	for(bit [sets-1:0] set_cnt = 0; set_cnt < sets; set_cnt = set_cnt + 1'b1) begin
			for(bit[ways-1:0] way_cnt = 0; way_cnt < ways; way_cnt = way_cnt + 1'b1) begin
				if(STATE[set_cnt][way_cnt] != I) begin
					BusOperation(WRITE,{TAG[set_cnt][way_cnt],set_cnt});
					MessageToL1Cache(3,{TAG[set_cnt][way_cnt],set_cnt});
				end
				STATE[set_cnt][way_cnt] = I;
				TAG[set_cnt][way_cnt] = 'b0;
			end
			PLRU_status_bits[set_cnt] = 7'b0000000;
	end
	//$display("CACHE IS CLEARED");
	
endtask : Clear_Cache


task PRINT_CACHE_LINES;
	
	$display("\n Valid lines in L2 cache \n");
	for(int set_func = 0; set_func < sets; set_func = set_func + 1'b1) begin
	print_LRU (set_func);
		for(int way_funct = 0; way_funct < ways; way_funct = way_funct + 1'b1) begin
			if(STATE[set_func][way_funct] != I) begin
			$display("MESI_STATE = %s  	 TAG = %h  LRU = %d          SET = %d     WAY = %d ", state_t'(STATE[set_func][way_funct]), TAG[set_func][way_funct], LRU,  set_func, way_funct);
			end
		end
	end

endtask :  PRINT_CACHE_LINES

task print_LRU(int Set);
	if(PLRU_status_bits[Set][0]==0)
		begin
			if(PLRU_status_bits[Set][1]==0)
				begin
					if(PLRU_status_bits[Set][2]==0)
						begin
			              way_returned_by_LRU = 7;
						end
					else
						begin
							way_returned_by_LRU = 6;
						end
				end
			else
				begin
					if(PLRU_status_bits[Set][3]==0)
						begin
			              way_returned_by_LRU = 5;
						end
					else
						begin
							way_returned_by_LRU = 4;
						end

				end
		end
	else
		begin
		if(PLRU_status_bits[Set][4]==0)
				begin
					if(PLRU_status_bits[Set][5]==0)
						begin
			              way_returned_by_LRU = 3;
						end
					else
						begin
							way_returned_by_LRU = 2;
						end
				end
			else
				begin
					if(PLRU_status_bits[Set][6]==0)
						begin
			              way_returned_by_LRU = 1;
						end
					else
						begin
							way_returned_by_LRU = 0;
						end
				end
		end	
LRU = 		way_returned_by_LRU;
endtask

task MessageToL1Cache(int message, input [(Tag_bits)-1:0]Address);
	
if(Normal_mode)	
begin
case (message)
1: $display("==> MESSAGE TO L1: GETLINE  %h",inp_addr[address_bits-1:Byte_select_bits]);
2: $display("==> MESSAGE TO L1: SENDLINE %h",inp_addr[address_bits-1:Byte_select_bits]);
3: $display("==> MESSAGE TO L1: INVALIDATE %h",evict_address);
4: $display("==> MESSAGE TO L1: EVICTLINE %h",evict_address);
endcase	
end	
	
endtask : MessageToL1Cache


endmodule 