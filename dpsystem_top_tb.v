`timescale 1 ns/1 ns
module dpsystem_top_tb #(parameter n = 8, m = 10, j = 5, k = 12)
  (); 
  reg Clock;                    // input frequency 100 MHz
  reg nReset;                   // asynchronous reset
  
  reg CycleStart;               // 1 kHz
  
  reg signed [n-1:0] data_in;      // signed binary data
  wire signed [n-1:0] SampleData;      // offset binary data
  assign SampleData = data_in - 2**(n-1);
  
  reg [m-1:0] WindowDelay;      // 
  reg [j-1:0] WindowSizePow;    // 

  reg ReadEna;
  wire [m+n+n+k-1:0] ReadData;  // 
  wire FifoState_empty, FifoState_full;
  
  
  
  dpsystem_top dpsystem (.Clock(Clock),.nReset(nReset),.CycleStart(CycleStart),.SampleData(SampleData),.WindowDelay(WindowDelay),
                         .WindowSizePow(WindowSizePow),.ReadEna(ReadEna),.ReadData(ReadData),.FifoState_empty(FifoState_empty),.FifoState_full(FifoState_full));
   
  initial 
    begin
      Clock = 0;
      CycleStart = 0;
      nReset = 0;
    end
  always #5 Clock = ! Clock;
  always #2 nReset = 1;
    
  initial
    begin
      {CycleStart,data_in,WindowDelay,WindowSizePow} = 0;
      @ (negedge Clock)
      CycleStart = 1;
      WindowDelay = 15;
      WindowSizePow = 10;
      @ (negedge Clock)
      CycleStart = 0;
      WindowDelay = 0;
      WindowSizePow = 0;
      repeat (15) begin @ (posedge Clock); end
      data_in = -10;
      @ (posedge Clock) data_in = 20;
      @ (posedge Clock) data_in = -30;
      @ (posedge Clock) data_in = 40;
      @ (posedge Clock) data_in = -50;
      @ (posedge Clock) data_in = 60;
      @ (posedge Clock) data_in = -70;
      @ (posedge Clock) data_in = 80;
      @ (posedge Clock) data_in = -90;
      @ (posedge Clock) data_in = 99;
      @ (posedge Clock) data_in = 1'h1;
    end
    
endmodule