//-----------------------------------------------------------------------------
// Title       : Cache Statistics
// Authors     : Naveen Babu Vanamala <>
//				 Pavan Kumar Govardhanam <>
//				 Sai Krishna Vallabhaneni <>
//				 Venkata Mohan Krishna Challa <ven4@pdx.edu>
//
// Description : Displays the statistics of the Cache like no_of_readss, no_of_writess, Hits, Misses, Cache_Ratio and also sends the types of commands to the Cache design.			 
//		 	
//-----------------------------------------------------------------------------
import cache_specs::*;

module cache_statistics(
	input [Command_size - 1:0]command,
	input [address_bits-1:0]address,
	input eof
);
 
logic [Command_size - 1:0]inp_cmd;
logic [address_bits-1:0]inp_addr;


real read=0;
real write=0;
real cache_hit=0;
real cache_miss=0;
real total_count;
real cache_hit_ratio;



always @(posedge eof) begin
	//$display("\nEND OF TRACE FILE, THE FOLLOWING ARE THE CHACHE STATSITICS:");
	$display("\n==>  CACHE_READS = %0d \n==>  CACHE_WRITES=%0d \n==>  CACHE_HITS=%0d \n==>  CACHE_MISSES=%0d \n==>  CACHE_HIT_RATIO=%0f\n",read,write,cache_hit,cache_miss, cache_hit_ratio*100);
end

always@(command)
begin
	case(command)

		0 : inp_cmd = CPU_read;
		1 : inp_cmd = CPU_write;
		2 : inp_cmd = CPU_read;
		3 : inp_cmd = SNOOP_invalidate;
		4 : inp_cmd = SNOOP_read;
		5 : inp_cmd = SNOOP_write;
		6 : inp_cmd = SNOOP_rdX;
		8 : inp_cmd = CLEAR;
		9 : inp_cmd = PRINT; 
		default	: inp_cmd = command;
	endcase
	inp_addr = address;
end

always @(cache_hit or cache_miss) begin
	cache_hit_ratio = cache_hit/total_count;
end


assign total_count = cache_hit + cache_miss;

cache LLC(
	.inp_cmd(inp_cmd),
	.inp_addr(inp_addr),
	.cache_hit(cache_hit),
	.cache_miss(cache_miss),
	.write(write),
	.read(read)	
);

endmodule 
 