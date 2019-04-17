//========================
// Data processing system
//
//========================

`timescale 1 ns/1 ns
module dpsystem_top #(parameter n = 8, m = 10, j = 5, k = 12)
  (
  input Clock,                    // input frequency, Fclock = 100 MHz
  input nReset,                   // asynchronous reset, active - LOW
  
  input CycleStart,               // periodic pulse - start a new cycle of data processing, Fcycle = 1 kHz, lenght = 1/Fclock
  input signed [n-1:0] SampleData,// data in offset binary code
  input [m-1:0] WindowDelay,      // delay from new pulse of CycleStart to start of data processing window
  input [j-1:0] WindowSizePow,    // size of data processing window

  input ReadEna,                  // read enable signal for FIFO buffer
  output [m+n+n+k-1:0] ReadData,  // data thatreading from FIFO
  output FifoState_empty,
         FifoState_full           // flags of FIFO status
  );

// Internal wires/registers 
  reg [k-1:0] CycleNumber;        // current cycle number
  reg signed [n-1:0] ZeroOffset;  // average value of signal in data processing window
  reg signed [n-1:0] MaxAmpl;     // maximal amplitude of signal in data processing window
  reg [m-1:0] MaxTime;            // number of count that contain MaxAmpl
  reg WriteEna;                   // write enable signal for FIFO buffer
  wire [m+n+n+k-1:0] WriteData;   // data that writing in FIFO
  wire signed [n-1:0] data_bin;   // data in signed binary code
  reg signed [n-1:0] data_mod;    // modulus data
  
  reg count_start;                // strobe - start of data processing window

  reg [m-1:0] delay_cnt;          // delay counter from new CycleStart pulse to start of data processing window
  reg [j-1:0] winsize_cnt,        // counter from start to stop of data processing window
              sample_cnt,         // data sample counter
              winsize;            // size of data processing window
              
// Finite state machine (FSM) parameters        
  reg [3:0] current_state,  // FSM's current state
            next_state;     // FSM's next state          
// 
  localparam idle = 0;      // idle state, DPsystem awaiting for a new pulse of CycleStart
  localparam delay = 1;     // delay state, DPsystem awaiting for a start of data processing window
  localparam dp_window = 2; // data processing state 
//
// FSM description
  always @ (posedge Clock or negedge nReset)
    begin // FSM sequential block
      if (!nReset) begin current_state <= 0; end
      else begin current_state <= next_state; end
    end
  
  always @ (*)
    begin // FSM combinational block
      case (current_state)
        idle     : if (CycleStart) begin next_state = delay; end
                   else begin next_state = idle; end
        delay    : if (delay_cnt == 1) begin next_state = dp_window; end
        dp_window: if (winsize_cnt == 1) begin next_state = idle; end
        default  : begin next_state = idle; end
      endcase
    end
//    
// Counters description    
  always @ (posedge Clock or negedge nReset)
    begin // Cycle number counter
      if (!nReset) begin CycleNumber <= 0; end
      else if (CycleStart) begin CycleNumber <= CycleNumber + 1'b1; end
    end

  always @ (posedge Clock or negedge nReset)
    begin // Delay counter
      if (!nReset) begin delay_cnt <= 10; end
      else if (CycleStart) begin delay_cnt <= WindowDelay; end
      else if (current_state == delay) begin delay_cnt <= delay_cnt - 1'b1; end // counter starts counting when FSM's state = delay
    end

  always @ (posedge Clock or negedge nReset)
    begin // Window size counter
      if (!nReset) begin winsize_cnt <= 10; end
      else if (CycleStart) begin winsize_cnt <= WindowSizePow; end
      else if (current_state == dp_window) begin winsize_cnt <= winsize_cnt - 1'b1; end // counter starts counting when FSM's state = data processing window
    end
      
  always @ (posedge Clock or negedge nReset)
    begin // Sample counter
      if (!nReset) begin sample_cnt <= 0; end
      else if (next_state == dp_window) begin sample_cnt <= sample_cnt + 1; end // counter starts counting when the data processing window starts
      else if (next_state == idle) begin sample_cnt <= 0; end
    end   
//    
// Window size buffer for data processing
  always @ (posedge Clock or negedge nReset)
    begin
      if (!nReset) begin winsize <= 0; end
      else if (CycleStart) begin winsize <= WindowSizePow; end // 
      else if (current_state == idle) begin winsize <= 0; end
    end
//================    
// Data processing
//================
  assign data_bin = {!SampleData [n-1],SampleData [n-2:0]}; // converting offset code to signed
  
  always @ (*)
    begin // modulus of signed code 
      if (data_bin < 0) begin data_mod = data_bin * (-1); end
      else begin data_mod = data_bin; end 
    end
  
  always @ (posedge Clock or negedge nReset)
    begin // count start strobe
      if (!nReset) begin count_start <= 0; end
      else if (current_state == 1 && next_state == 2) begin count_start <= 1; end
      else begin count_start <= 0; end
    end

  always @ (posedge Clock or negedge nReset)
    begin // ZeroOffset calculation
      if (!nReset) begin ZeroOffset <= 0; end
      else if (count_start) begin ZeroOffset <= data_bin/$signed(winsize); end
      else if (current_state == 2) begin ZeroOffset <= ZeroOffset + data_bin/$signed(winsize); end
      else begin ZeroOffset <= 0; end
    end
    
  always @ (posedge Clock or negedge nReset)
    begin // MaxAmpl &  MaxTime calculation
      if (!nReset) begin MaxAmpl <= 0; MaxTime <= 0; end
      else if (current_state == 2)
        begin
          if (data_mod > MaxAmpl) // if input amplitude value > amplitude value in MaxAmpl buffer
            begin MaxAmpl <= data_bin; MaxTime <= sample_cnt; end // then data_bin writing in MaxAmpl buffer
        end
      else begin MaxAmpl <= 0; MaxTime <= 0; end
    end
//
// sending counted data to FIFO
  always @ (posedge Clock or negedge nReset)
    begin // generating of FIFO write strobe
      if (!nReset) begin WriteEna <= 0; end
      else if (winsize_cnt == 1) begin WriteEna <= 1; end // FIFO write strobe generated when data processing window ends
      else begin WriteEna <= 0; end
    end
  
  assign WriteData = {MaxTime, MaxAmpl, ZeroOffset, CycleNumber};
    
  
// Fifo example   
  fifo_1clk #(.BITS(m+n+n+k),.SIZE(5)) 
        fifo (.clk(Clock),.rst(nReset),.wdata(WriteData),.rdata(ReadData),
       	      .wr(WriteEna),.rd(ReadEna),.empty(FifoState_empty),.full(FifoState_full)); 

endmodule