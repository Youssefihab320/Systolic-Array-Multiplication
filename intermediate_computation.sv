module intermediate_computation #(
    parameter N ,
    parameter DATA_WIDTH = 16
)(
    input clk,
    input rst,
    input [DATA_WIDTH-1:0] A [0:N-1][0:N-1],
    input [DATA_WIDTH-1:0] B [0:N-1][0:N-1],
    input [DATA_WIDTH-1:0] row_sum [0:N-1],
    input [DATA_WIDTH-1:0] col_sum [0:N-1],
    output reg [2*DATA_WIDTH-1:0] intermediate [0:N-1][0:N-1]
);

    integer i, j, k;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < N; i = i + 1)
                for (j = 0; j < N; j = j + 1)
                    intermediate[i][j] <= 0;
        end else begin
            for (i = 0; i < N; i = i + 1) begin
                for (j = 0; j < N; j = j + 1) begin
                    intermediate[i][j] = -row_sum[i] - col_sum[j];
                    for (k = 0; k < N/2; k = k + 1)
                        intermediate[i][j] = intermediate[i][j] +
                                             (A[i][2*k] + B[2*k+1][j]) * (A[i][2*k+1] + B[2*k][j]);
                end
            end
        end
    end

endmodule

