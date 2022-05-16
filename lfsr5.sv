// LFSR generator
// This function is useful in both encoder and decoder
// CSE140L

  /* the 6 possible maximal-length feedback tap patterns from which to choose
  assign LFSR_ptrn[0] = 5'h1E;          
  assign LFSR_ptrn[1] = 5'h1D;
  assign LFSR_ptrn[2] = 5'h1B;
  assign LFSR_ptrn[3] = 5'h17;
  assign LFSR_ptrn[4] = 5'h14;
  assign LFSR_ptrn[5] = 5'h12;
  */

/*****************************************
* Implement TODO
*****************************************/
//Check checkpoint for hints on what to code 

module lfsr5 #(parameter W=5)(
  input              clk,
                     en,        // 1: advance to next state; 0: hold current state
                     init,      // 1: force state to "start"
  input       [W-1:0]  taps,    // parity feedback pattern
                     start,     // initial state
  output logic[W-1:0]  state);  // current state

  logic[W-1:0] taptrn;        // or just use taps input, if it never changes
  always @(posedge clk)
  if(init) begin
    state  <= start;        // load starting state (should match data_mem[2])
    taptrn <= taps;         // load tap pattern (should match data_mem[1])
  end
  else if(en)               // advance to next state, update LFSR value
    //TODO

endmodule