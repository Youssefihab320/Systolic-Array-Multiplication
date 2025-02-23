`timescale 1ns / 1ps

module winograd_systolic_array_tb;

    parameter N = 2;            // to test for both 2x2 matrix and 3x3 matrix
    parameter DATA_WIDTH = 16;  // Bit width for each matrix element

    reg clk, rst;
    reg [DATA_WIDTH-1:0] A [0:N-1][0:N-1];
    reg [DATA_WIDTH-1:0] B [0:N-1][0:N-1];
    wire [2*DATA_WIDTH+3:0] C [0:N-1][0:N-1];

    winograd_systolic_array #(.N(N), .DATA_WIDTH(DATA_WIDTH)) dut (
        .clk(clk),
        .rst(rst),
        .A(A),
        .B(B),
        .C(C)
    );

    always #10 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        
        #20 rst = 0;

        // Initialize Matrices A and B based on N
        if (N == 2) begin
            A[0][0] = 8'd1;  A[0][1] = 8'd2;
            A[1][0] = 8'd3;  A[1][1] = 8'd4;

            B[0][0] = 8'd5;  B[0][1] = 8'd6;
            B[1][0] = 8'd7;  B[1][1] = 8'd8;
        end 
        else if (N == 3) begin
            A[0][0] = 8'd1;  A[0][1] = 8'd2;  A[0][2] = 8'd3;
            A[1][0] = 8'd4;  A[1][1] = 8'd5;  A[1][2] = 8'd6;
            A[2][0] = 8'd7;  A[2][1] = 8'd8;  A[2][2] = 8'd9;

            B[0][0] = 8'd9;  B[0][1] = 8'd8;  B[0][2] = 8'd7;
            B[1][0] = 8'd6;  B[1][1] = 8'd5;  B[1][2] = 8'd4;
            B[2][0] = 8'd3;  B[2][1] = 8'd2;  B[2][2] = 8'd1;
        end

        // Print input matrices
        $display("Input Matrix A:");
        for (int i = 0; i < N; i = i + 1) begin
            for (int j = 0; j < N; j = j + 1)
                $write("%d ", A[i][j]);
            $write("\n");
        end

        $display("Input Matrix B:");
        for (int i = 0; i < N; i = i + 1) begin
            for (int j = 0; j < N; j = j + 1)
                $write("%d ", B[i][j]);
            $write("\n");
        end

        // Wait for systolic array processing to complete
        #100; 
        
        // Print Output Matrix C
        $display("Output Matrix C:");
        for (int i = 0; i < N; i = i + 1) begin
            for (int j = 0; j < N; j = j + 1)
                $write("%d ", C[i][j]);
            $write("\n");
        end

        $stop;
    end

endmodule
