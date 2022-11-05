module test;

int f;

int id;

string str;

typedef enum logic {silent, normal} mode_t;

mode_t mode;

initial begin

f = $fopen("trace_file.txt","r");
if(f) $display("file has been opened :%0d",f);
else $display("file has not been opened :%0d",f);

while (!$feof(f)) begin
	$fgets(str,f);
	$display("Line: %s",str); // display line
	end
	
	while($fscanf(f, "%s = %0d",str,id) == 2) begin
		$display("Line: %s = %0d",str,id);
	end
	$fclose(f);
	
if(mode == silent)
$display("Operating in Silent mode");
else if (mode == normal)
$display("Operating in Normal mode");
end



endmodule