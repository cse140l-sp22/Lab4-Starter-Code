// Lab 4
// CSE140L
/*****************************************
* Implement TODO
*****************************************/

module top_level #(parameter DW=8, AW=8, byte_count=2**AW, lfsr_bitwidth=5)(
  input        clk, 
               init,
  output logic done);

// dat_mem interface
// you will need this to talk to the data memory
logic         write_en;        // data memory write enable        
logic[AW-1:0] raddr,           // read address pointer
              waddr;           // write address pointer
logic[DW-1:0] data_in;         // to dat_mem
wire [DW-1:0] data_out;        // from dat_mem
// LFSR control input and data output
logic         LFSR_en;         // 1: advance LFSR; 0: hold 

//Registers
// taps, start, pre_len are constants loaded from dat_mem [0:2]
logic[   lfsr_bitwidth-1:0] taps,            // LFSR feedback pattern temp register
              start;                         // LFSR initial state temp register
logic[   DW-1:0] pre_len;                    // preamble (~) length  register   

//Enables      
logic         taps_en,                       // 1: load taps register; 0: hold
              start_en,                      // 1: load start temp register; 0 : hold
              prelen_en;                     // 1: load preamble length temp register; 0 : hold
logic         load_LFSR;                     // copy taps and start into LFSR

wire [   lfsr_bitwidth-1:0] LFSR;            // LFSR current value            
logic[   DW-1:0] scram;           // encrypted message
logic[   DW-1:0] ct_inc = 'd1;    // prog count step (default = +1)

// instantiate the data memory 
dat_mem dm1(.clk, .write_en, .raddr, .waddr,
            .data_in, .data_out);

// instantiate the LFSR core
// need one for Lab 4; may want 6 for Lab 5
lfsr5 l5(.clk , 
         .en   (LFSR_en),      // 1: advance LFSR on rising clk
         .init (load_LFSR),    // 1: initialize LFSR
         .taps  ,              // tap pattern
         .start ,              // starting state for LFSR
         .state(LFSR));        // LFSR state = LFSR output 

//Encode the Data read from Memory using the Padding and LFSR output every cycle
//TODO XORing logic

logic[DW-1:0] ct;                  // your program counter

// this can act as a program counter
always @(posedge clk)
  if(init)
    ct <= 0;
  else 
  ct <= ct + ct_inc;     // default: next_ct = ct+1

// control decode logic (does work of instr. mem and control decode)
always_comb begin
// list defaults here; case needs list only exceptions
  write_en  = 'b0;         // data memory write enable        
  LFSR_en   = 'b0;         // 1: advance LFSR; 0: hold    
// enables to load control constants read from dat_mem[61:63] 
  prelen_en = 'b0;         // 1: load pre_len temp register; 0: hold
  taps_en   = 'b0;         // 1: load taps temp register; 0: hold
  start_en  = 'b0;         // 1: load start temp register; 0: hold
  load_LFSR = 'b0;         // copy taps and start into LFSR
// time to quit
  done      = 'b0;
// PC normally advances by 1
// override to go back in a subroutine or forward/back in a branch 
  ct_inc    = 'b1;         // PC normally advances by 1
  case(ct)
    0,1: begin 
           raddr      = 'd3;   // memory read address pointer
           waddr      = 'd128;  // memory write address pointer
         end       // no op to wait for things to settle from init

//TODO See comments below to help
/*
-----------------------------------------------------------------------------------------------------
|  Cycle           |    Operation                                           |  Addr to read from Mem|
-----------------------------------------------------------------------------------------------------
|    0             |    NOP                                                 |    3                  |
-----------------------------------------------------------------------------------------------------
|    1             |    NOP                                                 |    3                  |
-----------------------------------------------------------------------------------------------------
|    2             |    Read Preamble Length                                |    0                  |
-----------------------------------------------------------------------------------------------------
|    3             |    Read LFSR Tap value                                 |    1                  |
-----------------------------------------------------------------------------------------------------
|    4             |    Read LFSR Start Value                               |    2                  |
-----------------------------------------------------------------------------------------------------
|    5             |    Copy Start and Taps into LFSR                       |    -                  |
-----------------------------------------------------------------------------------------------------
|    ???           |    Read Preamble (pre_len times), Encode, Write to Mem |    3                  |
-----------------------------------------------------------------------------------------------------
|    ???           |    Read String  , Encode, Write to Mem                 |    4 onwards          |
-----------------------------------------------------------------------------------------------------
|    ???           |    Output Done signal = 1                              |    -                  |
-----------------------------------------------------------------------------------------------------
*/    

/* 
1)  for pre_len cycles, bitwise XOR ASCII ~ = 0x7E with current
 LFSR state; prepend LFSR state with 3'b00 to pad to 8 bits
 write each successive result into dat_mem[128], dat_mem[129], etc.
 advance LFSR to next state while writing result  
2) after pre_len operations, start reading data from dat_mem[4], [5], ...
 bitwise XOR each value w/ current LFLSR state
 store successively in dat_mem[128+pre_len+j], where j = 0, 1, ..., 49
 advance LFSR to next state while writing each result
     
You may want some sort of memory address counter or an adder that creates
an offset from the prog_counter.

Watch how the testbench performs Prog. 4. You will be doing the same 
operation, but at a more detailed, hardware level, instead of at the 
higher level the testbench uses.       
*/
  endcase
end 


// load control registers from dat_mem 
// TODO Implement Preamble Length Register, Taps Register and Start Register Here
// copy from data_mem[0] to pre_len reg.
// copy from data_mem[1] to taps reg.
// copy from data_mem[2] to start reg.  

/* My done flag goes high once after 64 byte encryptions
   Yours should go high at the completion of your encryption operation.
   Test bench waits for a done flag, so generate one at some time.
*/

//TODO Done logic

endmodule