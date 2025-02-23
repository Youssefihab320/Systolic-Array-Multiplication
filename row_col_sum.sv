module row_col_sum #(
    parameter N,
    parameter DATA_WIDTH = 16
)(
    input clk,
    input rst,
    input [DATA_WIDTH-1:0] A [0:N-1][0:N-1],
    input [DATA_WIDTH-1:0] B [0:N-1][0:N-1],
    output reg [DATA_WIDTH-1:0] row_sum [0:N-1],
    output reg [DATA_WIDTH-1:0] col_sum [0:N-1]
);

    integer i, j;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < N; i = i + 1) begin
                row_sum[i] <= 0;                    
                col_sum[i] <= 0;
            end
        end else begin
            for (i = 0; i < N; i = i + 1) begin
                row_sum[i] = 0;                    //new row --> reset
                col_sum[i] = 0;
                for (j = 0; j < N/2; j = j + 1) begin
                    row_sum[i] = row_sum[i] + A[i][2*j] * A[i][2*j+1];
                    col_sum[i] = col_sum[i] + B[2*j][i] * B[2*j+1][i];
                end
            end
        end
    end

endmodule

