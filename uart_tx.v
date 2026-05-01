module uart_tx #(parameter CLKS_PER_BIT = 434) (
    input clk, input tx_start, input [7:0] tx_data, output reg tx_serial
);
    localparam IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;
    reg [1:0] state = IDLE;
    reg [15:0] clk_count = 0;
    reg [2:0] bit_idx = 0;
    reg [7:0] data_reg = 0;

    always @(posedge clk) begin
        case (state)
            IDLE: begin
                tx_serial <= 1'b1;
                clk_count <= 0;
                bit_idx   <= 0;
                if (tx_start) begin
                    data_reg <= tx_data;
                    state    <= START;
                end
            end
            START: begin
                tx_serial <= 1'b0;
                if (clk_count < CLKS_PER_BIT-1) clk_count <= clk_count + 1;
                else begin clk_count <= 0; state <= DATA; end
            end
            DATA: begin
                tx_serial <= data_reg[bit_idx];
                if (clk_count < CLKS_PER_BIT-1) clk_count <= clk_count + 1;
                else begin
                    clk_count <= 0;
                    if (bit_idx < 7) bit_idx <= bit_idx + 1;
                    else state <= STOP;
                end
            end
            STOP: begin
                tx_serial <= 1'b1;
                if (clk_count < CLKS_PER_BIT-1) clk_count <= clk_count + 1;
                else state <= IDLE;
            end
            default: state <= IDLE;
        endcase
    end
endmodule