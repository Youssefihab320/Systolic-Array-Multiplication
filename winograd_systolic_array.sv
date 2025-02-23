module winograd_systolic_array #(
    parameter N ,
    parameter DATA_WIDTH = 16   
)(
    input clk,
    input rst,
    input [DATA_WIDTH-1:0] A [0:N-1][0:N-1],
    input [DATA_WIDTH-1:0] B [0:N-1][0:N-1],
    output [2*DATA_WIDTH+3:0] C [0:N-1][0:N-1]
);

    // Internal signals
    wire [DATA_WIDTH-1:0] row_sum [0:N-1];
    wire [DATA_WIDTH-1:0] col_sum [0:N-1];
    wire [2*DATA_WIDTH-1:0] intermediate [0:N-1][0:N-1];

    // Instantiate row and column sum module
    row_col_sum #(.N(N), .DATA_WIDTH(DATA_WIDTH)) row_col_sum_inst (
        .clk(clk),
        .rst(rst),
        .A(A),
        .B(B),
        .row_sum(row_sum),
        .col_sum(col_sum)
    );

    // Instantiate intermediate computation module
    intermediate_computation #(.N(N), .DATA_WIDTH(DATA_WIDTH)) intermediate_comp_inst (
        .clk(clk),
        .rst(rst),
        .A(A),
        .B(B),
        .row_sum(row_sum),
        .col_sum(col_sum),
        .intermediate(intermediate)
    );

    // Instantiate final computation module
    final_computation #(.N(N), .DATA_WIDTH(DATA_WIDTH)) final_comp_inst (
        .clk(clk),
        .rst(rst),
        .A(A),
        .B(B),
        .intermediate(intermediate),
        .C(C)
    );

endmodule

