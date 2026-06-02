`timescale 1ns/1ps
`default_nettype none

module tt_um_hardware_anomaly_detection (
    input  wire [7:0] ui_in,
    output reg  [7:0] uo_out,
    input  wire [7:0] uio_in,
    output reg  [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    // Inputs
    wire serial_bit = ui_in[0];
    wire bit_valid  = ui_in[1];
    wire mode_sel   = ui_in[2];
    wire start      = ui_in[3];

    // Packet Receiver
    reg [63:0] packet;
    reg [5:0]  bit_count;

    // Features
    reg signed [7:0] feature_x;
    reg signed [7:0] feature_y;

    // Neural MAC
    reg signed [17:0] mac_result;

    // Output Score
    reg [7:0] score;

    // Status Signals
    reg irq;
    reg done;
    reg tx_pin;

    assign uio_oe = 8'b0000_0111;

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            packet      <= 64'd0;
            bit_count   <= 6'd0;

            feature_x   <= 8'd0;
            feature_y   <= 8'd0;

            mac_result  <= 18'd0;
            score       <= 8'd0;

            irq         <= 1'b0;
            done        <= 1'b0;
            tx_pin      <= 1'b0;

            uo_out      <= 8'h00;
            uio_out     <= 8'h00;

        end
        else begin

            // Default done pulse low
            done <= 1'b0;
            uio_out[0] <= 1'b1;

            //------------------------------------------------
            // SERIAL PACKET RECEIVER
            //------------------------------------------------
            if (bit_valid) begin

                packet <= {packet[62:0], serial_bit};

                if (bit_count == 6'd62) begin

                    bit_count <= 6'd0;

                    //------------------------------------------------
                    // FEATURE EXTRACTION
                    //------------------------------------------------
                    feature_x <= packet[31:24];
                    feature_y <= packet[23:16];

                    //------------------------------------------------
                    // MAC ENGINE
                    //------------------------------------------------
                    mac_result <=
                        ($signed(packet[31:24]) * 12) +
                        ($signed(packet[23:16]) * 88);

                    //------------------------------------------------
                    // THREAT SCORING
                    //------------------------------------------------
                    if (
                        (($signed(packet[31:24]) * 12) +
                         ($signed(packet[23:16]) * 88))
                        > 18'd1500
                    ) begin

                        score  <= 8'hFF;
                        irq    <= 1'b1;
                        uo_out <= 8'hFF;

                    end
                    else begin

                        score  <= 8'h00;
                        irq    <= 1'b0;
                        uo_out <= 8'h00;

                    end

                    //------------------------------------------------
                    // ALERT MANAGER
                    //------------------------------------------------
                    done   <= 1'b1;
                    tx_pin <= score[0];

                    uio_out[0] <= 1'b1;      // done
                    uio_out[1] <= irq;       // irq
                    uio_out[2] <= tx_pin;    // telemetry
                    uio_out[7:3] <= 5'b00000;

                end
                else begin

                    bit_count <= bit_count + 1'b1;

                end
            end
        end
    end

    wire _unused = &{ena, mode_sel, start, uio_in};

endmodule

`default_nettype wire
