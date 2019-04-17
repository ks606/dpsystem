`timescale 1 ns/1 ns
module fifo_1clk # (parameter BITS = 8, SIZE = 4)
  (
  input clk,
  input rst,
  input [BITS-1:0] wdata,
  input wr, rd,
  output reg [BITS-1:0] rdata,
  output empty, full
  );
  
  reg [BITS-1:0] array_reg [2**SIZE-1:0]; 
  reg [SIZE-1:0] wptr_reg, wptr_next , wptr_succ;
  reg [SIZE-1:0] rptr_reg , rptr_next , rptr_succ;
  reg full_reg, empty_reg, full_next, empty_next;  
  wire wr_en;

  always @(posedge clk)
    begin
      if (wr_en) begin array_reg [wptr_reg] <= wdata; end
    end
        
  always @ (*)
    begin
      if (rd) begin rdata = array_reg [rptr_reg]; end
      else begin rdata = 0; end
    end
    
  assign wr_en = wr & ~full_reg;
  
  always @ (posedge clk or negedge rst)
    begin
      if (!rst)
        begin
          wptr_reg <= 0;
          rptr_reg <= 0;
          empty_reg <= 1'b1;
          full_reg <= 1'b0;
        end
      else
        begin
          wptr_reg <= wptr_next;
          rptr_reg <= rptr_next;
          empty_reg <= empty_next;
          full_reg <= full_next;
        end
    end

  always @ (*)
    begin
      // successive pointer values
      wptr_succ = wptr_reg + 1;
      rptr_succ = rptr_reg + 1;
      // default keep old values
      wptr_next  = wptr_reg;
      rptr_next  = rptr_reg;
      empty_next = empty_reg;
      full_next  = full_reg;
      case ({wr, rd})
        2'b01: // read operation
          if (~empty_reg) // not empty
            begin
              rptr_next = rptr_succ ;
              full_next = 1'b0;
              if (rptr_succ == wptr_reg)
                empty_next = 1'b1;
            end
        2'b10: // write operation
          if (~full_reg) // not full
            begin
              wptr_next = wptr_succ;
              empty_next = 1'b0;
              if (wptr_succ == rptr_reg)
                full_next = 1'b1;
            end
        2'b11: // write and read operation
            begin
              wptr_next = wptr_succ;
              rptr_next = rptr_succ;
            end
      endcase
    end
    
// Fifo status
  assign full = full_reg;
  assign empty = empty_reg;

endmodule