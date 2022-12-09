//-----------------------------------------------------------------------------
// Title       : Cache Statistics
// Authors     : Naveen Babu Vanamala <>
//				 Pavan Kumar Govardhanam <>
//				 Sai Krishna Vallabhaneni <>
//				 Venkata Mohan Krishna Challa <ven4@pdx.edu>
//
// Description : This module will take the Trace file as input and parses the command and Address values. THen it sends the values to the Statistics file.			 
//		 	
//-----------------------------------------------------------------------------
import cache_specs::*;

module TB();

logic [Command_size - 1:0] command;
logic [Address_size - 1:0] address;
logic eof = false;

parameter trace_file;
integer file;
integer inp_value;
logic [Address_size - 1:0]dummy;

initial begin
file = $fopen(trace_file,"r");
while(!$feof(file)) begin
	#1;
	inp_value = $fscanf(file,"%d", command);
	if(command < 10) begin
		inp_value = $fscanf(file, "%h", address);
		//if (Normal_mode) $display("\nTRACE COMMAND = %s \nTRACE ADDRESS = %h\n",command_type'(command), address);
	end
	else ;
	#1;
	command = 'dz; address = 'dz;
	eof = false;
	end
eof = true;
$fclose(file);
	#10;
	$stop;
end

cache_statistics stats(.command(command),.address(address),.eof(eof));

endmodule

