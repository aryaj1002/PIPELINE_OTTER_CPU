`timescale 1ns / 1ps

module MCU_TB();

logic CLK, RST, INTR;
logic [31:0] IOBUS_IN;
logic IOBUS_WR;
logic [31:0] IOBUS_OUT, IOBUS_ADDR;

OTTER_pipeline UUT (
    .CLK(CLK),
    .RST(RST),
    .INTR(INTR),
    .IOBUS_IN(IOBUS_IN),
    .IOBUS_OUT(IOBUS_OUT),
    .IOBUS_ADDR(IOBUS_ADDR),
    .IOBUS_WR(IOBUS_WR)
);

// 20ns clock, 50MHz
always begin
    CLK = 0; #10;
    CLK = 1; #10;
end

initial begin
    RST = 1'b1;
    INTR = 1'b0;
    IOBUS_IN = 32'b0;

    #20
    RST = 0;

    #100000; // let it run, watch waveform for PC hitting the jal x0,0 halt loop
    $finish;
end 

endmodule