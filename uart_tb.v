`timescale 1ns / 1ps

module uart_tb();

    parameter CLK_PERIOD    = 20; 
    parameter CLKS_PER_BIT  = 434;
    parameter BIT_PERIOD    = CLK_PERIOD * CLKS_PER_BIT;
    parameter NUM_TESTS     = 6;

    reg        clk         = 0;
    reg        tx_start    = 0;
    reg [7:0]  tx_data_in  = 0;
    wire       serial_line;
    wire [7:0] rx_data_out;
    wire       rx_valid;

    reg [7:0] test_patterns [0:NUM_TESTS-1];
    integer i;

    // --- Module Instantiations ---

    uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) tx_inst (
        .clk(clk),
        .tx_start(tx_start),
        .tx_data(tx_data_in),
        .tx_serial(serial_line)
    );

    uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) rx_inst (
        .clk(clk),
        .rx_serial(serial_line),
        .rx_dv(rx_valid),
        .rx_data(rx_data_out)
    );

    // --- Clock Generation ---
    always #(CLK_PERIOD/2) clk = ~clk;

    // --- Main Test Logic ---
    initial begin
        test_patterns[0] = 8'hA5; 
        test_patterns[1] = 8'h3C; 
        test_patterns[2] = 8'hFF; 
        test_patterns[3] = 8'h00; 
        test_patterns[4] = 8'h5A; 
        test_patterns[5] = 8'h81;

        tx_start = 0;
        tx_data_in = 8'h00;
        
        repeat(20) @(posedge clk);
        wait(serial_line === 1'b1);
        #(BIT_PERIOD); 

        for (i = 0; i < NUM_TESTS; i = i + 1) begin
            
            // Data Setup
            @(negedge clk);
            tx_data_in = test_patterns[i];
            repeat(434) @(negedge clk); 
            
            // Pulse Start
            tx_start = 1;
            @(negedge clk);
            tx_start = 0;
            
            // Wait for Completion
            @(posedge rx_valid);
            #(CLK_PERIOD);

            if (rx_data_out === test_patterns[i])
                $display("Test %0d PASSED | Sent: %h -> Received: %h", i, test_patterns[i], rx_data_out);
            else
                $display("Test %0d FAILED | Sent: %h -> Received: %h", i, test_patterns[i], rx_data_out);
                
            #(BIT_PERIOD * 2);
        end

        $display("Simulation Complete.");
        $finish;
    end

endmodule