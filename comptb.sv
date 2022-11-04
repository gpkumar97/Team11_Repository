module comp_tb;

reg A,B;
wire GT,LT,ET;

comparator comp(A,B,GT,LT,ET);

initial begin
repeat(5)
begin
A=$random;
B=$random;
#10;$display("A=%d B=%d GT=%d LT=%d ET=%d",A,B,GT,LT,ET);
end
end

endmodule
