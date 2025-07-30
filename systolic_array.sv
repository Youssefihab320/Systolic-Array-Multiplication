// systolic_array.sv
module systolic_array #(

    // Parameters with Default values
    // Defines the bit width of the data.
    parameter DATAWIDTH = 16,
    // Defines the size of the square matrix (N x N).
    parameter N_SIZE = 5            
) (
    // Clock and reset signals.
    input  wire                     clk,
    input  wire                     rst_n,
    // Input signal indicating valid data.
    input  wire                     valid_in,
 
    // Input matrix A, Each Column Supposed to enter indvidually
    input  wire signed [N_SIZE*DATAWIDTH-1:0] matrix_a_in,
    // Input matrix B, Each Row Supposed to enter indvidually
    input  wire signed [N_SIZE*DATAWIDTH-1:0] matrix_b_in,
    // Output signal indicating valid result.
    output reg valid_out,
    // Output matrix C, flattened.
    output reg signed [N_SIZE*2*DATAWIDTH-1:0] matrix_c_out                 //Double the size due to multiplication operation
);

    // Internal wires for connecting Processing Elements (PEs).
    // 'a' data flows horizontally.
    wire signed [DATAWIDTH-1:0] a_internal_flow [0:N_SIZE-1][0:N_SIZE];
    // 'b' data flows vertically.
    wire signed [DATAWIDTH-1:0] b_internal_flow [0:N_SIZE][0:N_SIZE-1];
    // 'c' results from each PE.
    wire signed [2*DATAWIDTH-1:0] c_pe_out [0:N_SIZE-1][0:N_SIZE-1];
    // Valid signal for each PE, staggered.
    wire valid_pe_input [0:N_SIZE-1][0:N_SIZE-1];

    // Shift register for generating the output valid signal.
    reg [0:2*N_SIZE-1] valid_shift;
    // Pulse indicating the start of valid output rows.
    // To Trigger the valid_out signal when the first PE is calculated
    wire valid_out_start = valid_shift[2*N_SIZE-1];
    // Shift register to control the duration of the valid_out signal.
    reg [N_SIZE-1:0] valid_out_shift;
    // Width of the row counter based on N_SIZE.
    localparam ROW_CNT_WIDTH = ($clog2(N_SIZE) > 0) ? $clog2(N_SIZE) : 1;
    // Counter to select the current output row.
    reg [ROW_CNT_WIDTH-1:0] row_counter;

    // Loop variables for generate blocks.
    genvar i, j;

    // --- Input Staggering for matrix_a_in ---
    // This generate block creates delay chains for each element of matrix A
    // to ensure proper timing for the systolic array.
    // to ensure that each element arrives at the correct timing for calculation in the PEs 
    generate
        for (i = 0; i < N_SIZE; i = i + 1) begin : a_input_delay_gen
            // Delay chain for the i-th element of matrix A.
            reg signed [DATAWIDTH-1:0] a_delay_chain [0:i];
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    // Resets the delay chain.
                    for (integer k = 0; k <= i; k = k + 1) begin
                        a_delay_chain[k] <= 0;
                    end
                end else begin
                    // Captures the input element.
                    a_delay_chain[0] <= matrix_a_in[i*DATAWIDTH +: DATAWIDTH];
                    // Shifts data along the delay chain.
                    for (integer k = 0; k < i; k = k + 1) begin
                        a_delay_chain[k+1] <= a_delay_chain[k];
                    end
                end
            end
            // Connects the delayed input to the first column of PEs.
            assign a_internal_flow[i][0] = a_delay_chain[i];
        end
    endgenerate

    // --- Input Staggering for matrix_b_in ---
    // We will do the same but for matrix B
    generate
        for (j = 0; j < N_SIZE; j = j + 1) begin : b_input_delay_gen
            // Delay chain for the j-th element of matrix B.
            reg signed [DATAWIDTH-1:0] b_delay_chain [0:j];
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    // Resets the delay chain.
                    for (integer k = 0; k <= j; k = k + 1) begin
                        b_delay_chain[k] <= 0;
                    end
                end else begin
                    // Captures the input element.
                    b_delay_chain[0] <= matrix_b_in[j*DATAWIDTH +: DATAWIDTH];
                    // Shifts data along the delay chain.
                    for (integer k = 0; k < j; k = k + 1) begin
                        b_delay_chain[k+1] <= b_delay_chain[k];
                    end
                end
            end
            // Connects the delayed input to the first row of PEs.
            assign b_internal_flow[0][j] = b_delay_chain[j];
        end
    endgenerate

    // --- Valid Signal Staggering ---
    // Creates delay chains for the 'valid_in' signal for each PE.
    // The same for valid_in signal
    generate
        for (i = 0; i < N_SIZE; i = i + 1) begin : valid_row_gen
            for (j = 0; j < N_SIZE; j = j + 1) begin : valid_col_gen
                // Delay chain for the valid signal for PE at (i,j).
                reg valid_delay_chain [0:i+j];
                always @(posedge clk or negedge rst_n) begin
                    if (!rst_n) begin
                        // Resets the valid delay chain.
                        for (integer k = 0; k <= (i+j); k = k + 1) begin
                            valid_delay_chain[k] <= 1'b0;
                        end
                    end else begin
                        // Captures the initial valid_in.
                        valid_delay_chain[0] <= valid_in;
                        // Shifts valid signal along the delay chain.
                        for (integer k = 0; k < (i+j); k = k + 1) begin
                            valid_delay_chain[k+1] <= valid_delay_chain[k];
                        end
                    end
                end
                // Connects the delayed valid signal to the corresponding PE.
                assign valid_pe_input[i][j] = valid_delay_chain[i+j];
            end
        end
    endgenerate

    // --- Processing Elements Instantiation ---
    // Instantiates an N x N grid of processing_element modules.
    generate
        for (i = 0; i < N_SIZE; i = i + 1) begin : row_gen
            for (j = 0; j < N_SIZE; j = j + 1) begin : col_gen
                // Instantiates a single processing element.
                processing_element #(
                    .DATAWIDTH(DATAWIDTH)
                ) pe_inst (
                    .clk(clk),
                    .rst_n(rst_n),
                    .valid_in(valid_pe_input[i][j]), // Staggered valid input
                    .a_in_pe(a_internal_flow[i][j]), // Input A from left PE or delayed input
                    .b_in_pe(b_internal_flow[i][j]), // Input B from top PE or delayed input
                    .a_out_pe(a_internal_flow[i][j+1]), // Output A to right PE
                    .b_out_pe(b_internal_flow[i+1][j]), // Output B to bottom PE
                    .c_out_pe(c_pe_out[i][j]),       // Result from this PE
                    .valid_out_pe()                  // Not used for the overall valid_out
                );
            end
        end
    endgenerate

    // --- Valid Shift Register for Output Control ---
    // This shift register tracks the progress of the valid signal through the array
    // to determine when the output is ready.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_shift <= 0; // Resets the shift register.
        end else begin
            valid_shift[0] <= valid_in; // Captures the main valid input.
            // Shifts the valid signal across the register.
            for (integer k = 0; k < 2*N_SIZE-1; k = k + 1) begin
                valid_shift[k+1] <= valid_shift[k];
            end
        end
    end

    // --- Extended Valid Output Generation ---
    // Controls the 'valid_out' signal to indicate when complete rows of
    // the result matrix are available.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out_shift <= 0; // Resets the output valid shift register.
        end else begin
            if (valid_out_start) begin
                // When the first valid output is ready, assert all bits for N_SIZE cycles.
                valid_out_shift <= {N_SIZE{1'b1}};
            end else begin
                // Shift right to keep valid for N_SIZE cycles.
                valid_out_shift <= valid_out_shift >> 1;
            end
        end
    end

    // --- Row Counter Logic ---
    // Keeps track of which row of the output matrix is currently available.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            row_counter <= 0; // Resets the row counter.
        end else if (|valid_out_shift) begin // If any bit in valid_out_shift is high
            if (row_counter < N_SIZE-1) begin
                row_counter <= row_counter + 1; // Increments to the next row.
            end else begin
                row_counter <= 0; // Resets to 0 after the last row.
            end
        end else begin
            row_counter <= 0; // Resets when no valid output is expected.
        end
    end

    // --- Valid Output Assignment ---
    // 'valid_out' is high as long as any bit in valid_out_shift is high,
    // indicating a valid output row is available.
    assign valid_out = |valid_out_shift;
    // --- Output Connection ---
    // Connects the output of the PEs to the main output 'matrix_c_out'
    // based on the current 'row_counter'.
    always @(*) begin
        for (integer j = 0; j < N_SIZE; j = j + 1) begin
            // Selects the correct row from the PE outputs and concatenates them
            // into the flattened output vector.
            matrix_c_out[j*2*DATAWIDTH +: 2*DATAWIDTH] = c_pe_out[row_counter][j];
        end
    end

endmodule

module processing_element #(
    // Defines the bit width of the input data.
    parameter DATAWIDTH = 16
) (
    // Clock and reset signals.
    input  wire clk,
    input  wire rst_n,
    // Input valid signal to this PE.
    input  wire valid_in,
    
    // Input 'a' data flowing horizontally.
    input  wire signed [DATAWIDTH-1:0] a_in_pe,
    // Input 'b' data flowing vertically.
    input  wire signed [DATAWIDTH-1:0] b_in_pe,
    // Output valid signal from this PE (propagates valid_in).
    output wire valid_out_pe,
    // Output 'a' data to the next PE.
    output wire signed [DATAWIDTH-1:0] a_out_pe,
    // Output 'b' data to the next PE.
    output wire signed [DATAWIDTH-1:0] b_out_pe,
    // Accumulated product result from this PE.
    output reg signed [2*DATAWIDTH-1:0] c_out_pe
);

    // Registers to hold input 'a' and 'b' values for one clock cycle.
    reg signed [DATAWIDTH-1:0] a_reg, b_reg;
    // Register to accumulate the sum of products (the 'c' value).
    reg signed [2*DATAWIDTH-1:0] c_accum_reg;
    // Register to hold the valid signal for one clock cycle.
    reg valid_reg;

    // Sequential logic for the processing element.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Resets all internal registers to 0.
            a_reg       <= 0;
            b_reg       <= 0;
            c_accum_reg <= 0;
            valid_reg   <= 1'b0;
        end else begin
            // Registers the input 'a' and 'b' values.
            a_reg <= a_in_pe;
            b_reg <= b_in_pe;
            // Registers the valid input signal.
            valid_reg <= valid_in;
            
            // If the input data is valid, perform multiply-accumulate.
            if (valid_in) begin
                c_accum_reg <= c_accum_reg + (a_in_pe * b_in_pe);
            end
        end
    end

    // Assigns outputs from the internal registers, effectively creating pipeline stages.
    assign a_out_pe     = a_reg;
    assign b_out_pe     = b_reg;
    assign c_out_pe     = c_accum_reg;
    assign valid_out_pe = valid_reg;

endmodule