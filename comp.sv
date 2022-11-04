module comparator(
input logic A,B,
output logic GT,LT,ET
);

assign GT = A>B;
assign LT = A<B;
assign ET = A==B;

endmodule