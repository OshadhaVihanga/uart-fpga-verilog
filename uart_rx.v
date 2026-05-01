module uart_rx #(parameter CLKS_PER_BIT = 434) (
    input clk, 
    input rx_serial, 
    output reg rx_dv, 
    output reg [7:0] rx_data
);
    localparam IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;
    
    reg [1:0] state = IDLE;
    reg [15:0] clk_count = 0;
    reg [2:0] bit_idx = 0;
    reg [7:0] data_reg = 0;
    
    // 3-Stage Synchronizer to prevent metastability/noise lockup
    reg [2:0] rx_sync = 3'b111;
    always @(posedge clk) rx_sync <= {rx_sync[1:0], rx_serial};
    
    wire rx_clean = rx_sync[2]; // Use the synchronized signal

    always @(posedge clk) begin
        rx_dv <= 1'b0;
        
        case (state)
            IDLE: begin
                clk_count <= 0;
                bit_idx   <= 0;
                if (rx_clean == 1'b0) state <= START;
            end

            START: begin
                // Check middle of start bit to verify it's not a glitch
                if (clk_count == (CLKS_PER_BIT-1)/2) begin
                    if (rx_clean == 1'b0) begin
                        clk_count <= 0;
                        state     <= DATA;
                    end else state <= IDLE;
                end else clk_count <= clk_count + 1;
            end

            DATA: begin
                if (clk_count < CLKS_PER_BIT-1) begin
                    clk_count <= clk_count + 1;
                end else begin
                    clk_count <= 0;
                    data_reg[bit_idx] <= rx_clean;
                    if (bit_idx < 7) bit_idx <= bit_idx + 1;
                    else begin
                        bit_idx <= 0;
                        state   <= STOP;
                    end
                end
            end

            STOP: begin
                if (clk_count < CLKS_PER_BIT-1) begin
                    clk_count <= clk_count + 1;
                end else begin
                    // Success: Output data and return to IDLE
                    rx_data <= data_reg;
                    rx_dv   <= 1'b1;
                    state   <= IDLE;
                    clk_count <= 0;
                end
            end
            
            default: state <= IDLE;
        endcase
    end
endmodule