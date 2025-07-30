`timescale 1ns/1ps

module systolic_array_tb;

    // Parameters
    parameter DATAWIDTH = 16;
    parameter N_SIZE = 3;                               //3x3 by matrix for simplicity in testing and calculating using calculator

    // Clock and Reset signals
    reg clk_tb;
    reg rst_n_tb;
    
    // Inputs
    reg valid_in_tb;
    reg signed [N_SIZE*DATAWIDTH-1:0] matrix_a_in_tb;
    reg signed [N_SIZE*DATAWIDTH-1:0] matrix_b_in_tb;
    
    // Outputs
    wire valid_out_tb;
    wire signed [N_SIZE*2*DATAWIDTH-1:0] matrix_c_out_tb;

    // DUT instantiation
    systolic_array #(
        .DATAWIDTH(DATAWIDTH),
        .N_SIZE(N_SIZE)
    ) dut (
        .clk(clk_tb),
        .rst_n(rst_n_tb),
        .valid_in(valid_in_tb),
        .matrix_a_in(matrix_a_in_tb),
        .matrix_b_in(matrix_b_in_tb),
        .valid_out(valid_out_tb),
        .matrix_c_out(matrix_c_out_tb)
    );

    // Clock generation
    initial begin
        clk_tb = 0;
    end
    always #5 clk_tb = ~clk_tb;                         //We will assume clk cycle 10 ns
    
    // Result storage
    reg signed [2*DATAWIDTH-1:0] result_matrix [0:N_SIZE-1][0:N_SIZE-1];            //To store the matrix output for comparing with the expected output for verification
    integer row_index = 0;
    
    // Monitor valid_out_tb in real-time
    initial begin
        $monitor("Time %0t: valid_out = %b", $time, valid_out_tb);
    end
    
    // Main test sequence
    initial begin
        // Initialize signals
        rst_n_tb = 1'b0;
        valid_in_tb = 1'b0;
        matrix_a_in_tb = 0;
        matrix_b_in_tb = 0;
        row_index = 0;

        // Waveform dumping
        $dumpfile("systolic_array.vcd");
        $dumpvars;

        // --- Test Case 1 ---
        $display("\n--- Starting 3x3 Matrix Multiplication Test Case 1 ---");
        $display("Matrix A:");
        $display("  [1, 2, 3]");
        $display("  [4, 5, 6]");
        $display("  [7, 8, 9]");
        $display("Matrix B:");
        $display("  [9, 8, 7]");
        $display("  [6, 5, 4]");
        $display("  [3, 2, 1]");
        $display("Expected Result:");
        $display("  [30, 24, 18]");
        $display("  [84, 69, 54]");
        $display("  [138, 114, 90]");

        // Apply reset
        #10;
        rst_n_tb = 1'b1;
        #10;
        
        // Note that inputs are reversed for design compatability for the delay chain I implemented in the design
        $display("\nApplying inputs for Test Case 1:");
        // Cycle 0
        valid_in_tb = 1'b1;
        matrix_a_in_tb = {16'd7, 16'd4, 16'd1};                 // A column 0: [1,4,7]
        matrix_b_in_tb = {16'd7, 16'd8, 16'd9};                 // B row 0: [9,8,7] 
        $display("  Cycle 0: A_col = [1, 4, 7], B_row = [9, 8, 7]");
        @(posedge clk_tb);
        
        // Cycle 1
        matrix_a_in_tb = {16'd8, 16'd5, 16'd2}; // A column 1: [2,5,8]
        matrix_b_in_tb = {16'd4, 16'd5, 16'd6}; // B row 1: [6,5,4]
        $display("  Cycle 1: A_col = [2, 5, 8], B_row = [6, 5, 4]");
        @(posedge clk_tb);
        
        // Cycle 2
        matrix_a_in_tb = {16'd9, 16'd6, 16'd3}; // A column 2: [3,6,9]
        matrix_b_in_tb = {16'd1, 16'd2, 16'd3}; // B row 2: [3,2,1]
        $display("  Cycle 2: A_col = [3, 6, 9], B_row = [3, 2, 1]");
        @(posedge clk_tb);
        
        // Deassert valid
        valid_in_tb = 1'b0;
        $display("\nInput complete for Test Case 1, waiting for results...");

        // Wait for all output rows for Test Case 1
        wait(row_index == N_SIZE);
        #20; // Additional delay for last row
        
        // Display captured results for Test Case 1
        $display("\nFull Matrix C (Test Case 1):");
        for (integer i = 0; i < N_SIZE; i = i + 1) begin
            $write("  Row %0d: [", i);
            for (integer j = 0; j < N_SIZE; j = j + 1) begin
                $write("%0d", result_matrix[i][j]);
                if (j < N_SIZE-1) $write(", ");
            end
            $display("]");
        end
        
        // Verify results for Test Case 1
        begin
            automatic integer errors = 0;
            automatic integer expected[0:N_SIZE-1][0:N_SIZE-1] = '{
                '{30, 24, 18}, 
                '{84, 69, 54}, 
                '{138, 114, 90}};
            for (integer i = 0; i < N_SIZE; i = i + 1) begin
                for (integer j = 0; j < N_SIZE; j = j + 1) begin
                    if (result_matrix[i][j] !== expected[i][j]) begin
                        $display("ERROR (Test Case 1): [%0d][%0d] - expected %0d, got %0d", 
                               i, j, expected[i][j], result_matrix[i][j]);
                        errors = errors + 1;
                    end
                end
            end
            
            if (errors == 0) 
                $display("\nPASS: All outputs match expected for Test Case 1!");
            else
                $display("\nFAIL: %0d errors found for Test Case 1", errors);
        end

        // Reset for the next test case
        #50; // Give some time between test cases
        rst_n_tb = 1'b0;            // Assert reset
        #10;
        rst_n_tb = 1'b1;            // Deassert reset
        valid_in_tb = 1'b0;
        matrix_a_in_tb = 0;
        matrix_b_in_tb = 0;
        row_index = 0;              // Reset row_index for the new test case

        // --- Test Case 2 ---
        $display("\n--- Starting 3x3 Matrix Multiplication Test Case 2 ---");
        $display("Matrix A:");
        $display("  [2, 3, 4]");
        $display("  [5, 6, 7]");
        $display("  [8, 9, 10]");
        $display("Matrix B:");
        $display("  [1, 2, 3]");
        $display("  [4, 5, 6]");
        $display("  [7, 8, 9]");
        $display("Expected Result:");
        $display("  [42,  51,  60]");
        $display("  [78,  96, 114]");
        $display("  [114, 141, 168]");

        $display("\nApplying inputs for Test Case 2:");
        // Cycle 0
        valid_in_tb = 1'b1;
        matrix_a_in_tb = {16'd8, 16'd5, 16'd2};             // Matrix A, column 0: [2, 5, 8]
        matrix_b_in_tb = {16'd3, 16'd2, 16'd1};             // Matrix B, row 0: [1, 2, 3]
        $display("  Cycle 0: A_col = [2, 5, 8], B_row = [1, 2, 3]");
        @(posedge clk_tb);
        
        // Cycle 1
        matrix_a_in_tb = {16'd9, 16'd6, 16'd3};             // Matrix B, row 0: [1, 2, 3]
        matrix_b_in_tb = {16'd6, 16'd5, 16'd4};             // Matrix B, row 1: [4, 5, 6]
        $display("  Cycle 1: A_col = [3, 6, 9], B_row = [4, 5, 6]");
        @(posedge clk_tb);
        
        // Cycle 2 
        matrix_a_in_tb = {16'd10, 16'd7, 16'd4};            // Matrix A, column 2: [4, 7, 10]
        matrix_b_in_tb = {16'd9, 16'd8, 16'd7};             // Matrix B, row 2: [7, 8, 9]
        $display("  Cycle 2: A_col = [4, 7, 10], B_row = [7, 8, 9]");
        @(posedge clk_tb);
        
        // Deassert valid
        valid_in_tb = 1'b0;
        $display("\nInput complete for Test Case 2, waiting for results...");

        // Wait for all output rows for Test Case 2
        wait(row_index == N_SIZE);
        #20; // Additional delay for last row
        
        // Display captured results for Test Case 2
        $display("\nFull Matrix C (Test Case 2):");
        for (integer i = 0; i < N_SIZE; i = i + 1) begin
            $write("  Row %0d: [", i);
            for (integer j = 0; j < N_SIZE; j = j + 1) begin
                $write("%0d", result_matrix[i][j]);
                if (j < N_SIZE-1) $write(", ");
            end
            $display("]");
        end
        
        // Verify results for Test Case 2
        begin
            automatic integer errors = 0;
            // Expected result for the new matrices
            automatic integer expected[0:N_SIZE-1][0:N_SIZE-1] = '{
                '{42,  51,  60}, 
                '{78,  96, 114}, 
                '{114, 141, 168}};
            for (integer i = 0; i < N_SIZE; i = i + 1) begin
                for (integer j = 0; j < N_SIZE; j = j + 1) begin
                    if (result_matrix[i][j] !== expected[i][j]) begin
                        $display("ERROR (Test Case 2): [%0d][%0d] - expected %0d, got %0d", 
                               i, j, expected[i][j], result_matrix[i][j]);
                        errors = errors + 1;
                    end
                end
            end
            
            if (errors == 0) 
                $display("\nPASS: All outputs match expected for Test Case 2!");
            else
                $display("\nFAIL: %0d errors found for Test Case 2", errors);
        end
        
        $display("\n--- Simulation Complete ---");
        $stop;
    end
    
    // Capture output rows
    always @(posedge clk_tb) begin
        if (valid_out_tb && row_index < N_SIZE) begin 
            $display("Time %0t: valid_out_tb detected - Capturing row %0d", $time, row_index);
            for (integer j = 0; j < N_SIZE; j = j + 1) begin
                result_matrix[row_index][j] = matrix_c_out_tb[j*2*DATAWIDTH +: 2*DATAWIDTH];
                $display("  Element[%0d] = %0d", j, matrix_c_out_tb[j*2*DATAWIDTH +: 2*DATAWIDTH]);
            end
            row_index <= row_index + 1;
        end
    end
    
endmodule