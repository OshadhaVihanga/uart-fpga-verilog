module uart_top (
    input        clk,        // PIN_R8
    input        key0_input, // PIN_J15 (Trigger)
    input [7:0]  sw_data,    // PIN_C9 to PIN_D11
    input        rx_pin,     // PIN_D3
    output       tx_pin,     // PIN_D12
    output [7:0] led_output, // PIN_L3 to PIN_A15
    output [6:0] seg_low,    // PIN_C6 to PIN_D5
    output [6:0] seg_high    // PIN_B5 to PIN_C3
);

    reg  key0_d1, key0_d2;
    wire tx_pulse;
    wire [7:0] rx_byte;
    wire rx_valid;

    // Monitor switches on LEDs
    assign led_output = rx_byte;

    // Enhanced Edge Detection (2-stage for stability)
    always @(posedge clk) begin
        key0_d1 <= key0_input;
        key0_d2 <= key0_d1;
    end
    assign tx_pulse = (key0_d2 == 1'b1 && key0_d1 == 1'b0);

    uart_tx #(.CLKS_PER_BIT(434)) tx_inst (
        .clk(clk),
        .tx_start(tx_pulse), 
        .tx_data(sw_data),
        .tx_serial(tx_pin)
    );

    uart_rx #(.CLKS_PER_BIT(434)) rx_inst (
        .clk(clk),
        .rx_serial(rx_pin),
        .rx_dv(rx_valid),
        .rx_data(rx_byte)
    );

    seven_seg seg_l (.hex_val(rx_byte[3:0]), .seg(seg_low));
    seven_seg seg_h (.hex_val(rx_byte[7:4]), .seg(seg_high));

endmodule