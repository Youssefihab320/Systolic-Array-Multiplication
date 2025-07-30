# Systolic-Array-Multiplication
This project implements a N×N systolic array architecture for matrix multiplication using SystemVerilog. The design leverages a grid of processing elements (PEs) that perform parallel multiply-accumulate operations, enabling high-throughput matrix computations suitable for AI accelerators and hardware pipelines.

# Features
✅ Parameterized 5×5 matrix multiplication    
✅ Fully synthesizable RTL (systolic_array.sv)    
✅ Testbench with multiple test cases (systolic_array_tb.sv)    
✅ Valid control and data input/output ports    
✅ Matches digital hardware lab specifications    

# 🚀 How It Works:
- Matrix A is streamed row-wise from the left   
- Matrix B is streamed column-wise from the top   
- Each PE multiplies inputs and accumulates partial sums   
- Final matrix C is output row-by-row after N cycles   

# Test Cases:
- Multiple test scenarios for verification   
- Output results printed to console   
- Easily extendable for larger matrices   
