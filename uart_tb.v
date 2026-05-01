`timescale 1ns / 1ps

module uart_tb();

    // Parameters
    parameter CLK_PERIOD = 20; // 50 MHz clock
    parameter CLKS_PER_BIT = 434;
    parameter BIT_PERIOD = CLK_PERIOD * CLKS_PER_BIT;
    parameter NUM_TESTS = 6;   // Number of patterns to send

    // Testbench Signals
    reg clk = 0;
    reg tx_start = 0;
    reg [7:0] tx_data_in = 0;
    
    wire serial_line;          // Connects TX to RX directly
    wire [7:0] rx_data_out;
    wire rx_valid;

    // Array to hold multiple test patterns
    reg [7:0] test_patterns [0:NUM_TESTS-1];
    integer i;

    // Instantiate the Transmitter directly
    uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) tx_inst (
        .clk(clk),
        .tx_start(tx_start),
        .tx_data(tx_data_in),
        .tx_serial(serial_line)
    );

    // Instantiate the Receiver directly
    uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) rx_inst (
        .clk(clk),
        .rx_serial(serial_line),
        .rx_dv(rx_valid),
        .rx_data(rx_data_out)
    );

    // Clock Generation
    always #(CLK_PERIOD/2) clk = ~clk;

    initial begin
        // Load test patterns
        test_patterns[0] = 8'hA5; // 10100101 (Alternating bits)
        test_patterns[1] = 8'h3C; // 00111100 
        test_patterns[2] = 8'hFF; // 11111111 (All 1s)
        test_patterns[3] = 8'h00; // 00000000 (All 0s)
        test_patterns[4] = 8'h5A; // 01011010 (Alternating bits inverted)
        test_patterns[5] = 8'h81; // 10000001 (Boundary bits)

        // Initialize signals
        tx_start = 0;
        tx_data_in = 8'h00;
        
        // Wait for global reset/stabilization
        #(CLK_PERIOD * 10);

        $display("Starting UART multi-pattern test...");
        $display("-----------------------------------");

        // Loop through all test patterns
 // Loop through all test patterns
        for (i = 0; i < NUM_TESTS; i = i + 1) begin
            
            // 1. Set data and trigger transmission on the falling edge
            @(negedge clk);
            tx_data_in = test_patterns[i];
            tx_start = 1;
            
            // Wait exactly one clock cycle, then deassert
            @(negedge clk);
            tx_start = 0;
            
            // 2. Wait dynamically for the receiver to assert Data Valid
            @(posedge rx_valid);
            
            // 3. Verify the received data immediately
            if (rx_data_out === test_patterns[i])
                $display("Test %0d PASSED | Sent: %h -> Received: %h", i, test_patterns[i], rx_data_out);
            else
                $display("Test %0d FAILED | Sent: %h -> Received: %h", i, test_patterns[i], rx_data_out);
                
            // 4. Wait a few bit periods before sending the next byte
            #(BIT_PERIOD * 2);
        end

        $display("-----------------------------------");
        $display("Simulation Complete.");
        $finish;
    end

endmodule