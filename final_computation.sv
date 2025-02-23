module final_computation #(
    parameter N,
    parameter DATA_WIDTH = 16
)(
    input clk,
    input rst,
    input [DATA_WIDTH-1:0] A [0:N-1][0:N-1],
    input [DATA_WIDTH-1:0] B [0:N-1][0:N-1],
    input [2*DATA_WIDTH-1:0] intermediate [0:N-1][0:N-1],
    output reg [2*DATA_WIDTH+3:0] C [0:N-1][0:N-1]
);

    integer i, j;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < N; i = i + 1)
                for (j = 0; j < N; j = j + 1)
                    C[i][j] <= 0;
        end else begin
            // Handle odd matrix case
            if (N % 2 == 1) begin
                for (i = 0; i < N; i = i + 1) begin
                    for (j = 0; j < N; j = j + 1) begin
                        C[i][j] = intermediate[i][j] + A[i][N-1] * B[N-1][j];
                    end
                end
            end else begin
                for (i = 0; i < N; i = i + 1)
                    for (j = 0; j < N; j = j + 1)
                        C[i][j] = intermediate[i][j];
            end
        end
    end

endmodule

