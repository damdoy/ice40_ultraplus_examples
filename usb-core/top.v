`include "usb.v"

module top(input P10, P11);

    wire usb_dp, usb_dm, clk;

    assign usb_dp = P10;
    assign usb_dm = P11;

    SB_HFOSC SB_HFOSC_inst(
        .CLKHFEN(1),
        .CLKHFPU(1),
        .CLKHF(clk)
    );

    usb usb()

endmodule