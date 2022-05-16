// CSE140L  Spring 2022   
// Lab4_tb
// full testbench for programmable message encryption
// the 6 possible maximal-length feedback tap patterns from which to choose
  /* the 6 possible maximal-length feedback tap patterns from which to choose
  assign LFSR_ptrn[0] = 5'h1E;          
  assign LFSR_ptrn[1] = 5'h1D;
  assign LFSR_ptrn[2] = 5'h1B;
  assign LFSR_ptrn[3] = 5'h17;
  assign LFSR_ptrn[4] = 5'h14;
  assign LFSR_ptrn[5] = 5'h12;
  */
module Lab4_tb  #(parameter lfsr_bitwidth=5, test_vector_len=64)               ;
  bit        clk               ;     // advances simulation step-by-step
  bit        init = 1          ;         // init (reset, start) command to DUT
  wire       done              ;         // done flag returned by DUT
  bit  [7:0] message[52]       ,     // original message, in binary
             msg_padded[test_vector_len]    ,    // original message, plus pre- and post-padding
             msg_crypto[test_vector_len]    ,    // encrypted message to test against DUT
       pre_length        ;         // encrypted space bytes before first character in message
  bit  [lfsr_bitwidth-1:0] lfsr_ptrn         ,         // one of 6 maximal length 6-tap shift reg. ptrns
       lfsr_state        ;         // initial state of encrypting LFSR         
  bit  [lfsr_bitwidth-1:0] LFSR              ;     // linear feedback shift register, makes PN code
  bit  [7:0] ind               ;     // index counter -- increments on each clock cycle

// ***** select your original message string to be encrypted *****
// note in practice your design should be able to handle ANY ASCII string
//   whose characters are chosen from ASCII vales of 0x40 through 0x7F
// our original American Standard Code for Information Interchange message follows
// A-Z   a-z  @ ' [] {} | \ ^ ~ _
//  string     str  = "Mr_Watson_come_here_I_want_to_see_you";
//  string  str = "Hello_their_xor_is_^_";
  string           str = "`@``@@```@@@````@@@@`````@@@@@`````@@@@@@``````@@@@@";
  int str_len                  ;     // length of string (character count)
//  initial #10ns $display("string length = %0d  %0d",str_len,str.len);
// displayed encrypted string will go here:
  string     str_enc[test_vector_len]       ;    

// this assumes the top level module of your design is called top_level
// change my test bench to match your own top level module name
  top_level dut(.clk  (clk),         // your top level design goes here
                .init (init),            // request from test bench  
                .done (done)) ;          // acknowledge from DUT

// ***** choose one of the 6 feedback TAP patterns *****
  int i = 2;                             // choose the LFSR_ptrn; legal values = 0 to 5; 
  int j = 9;                             // preamble length
  logic[lfsr_bitwidth-1:0] LFSR_ptrn[6];               // testbench will automatically apply whichever is chosen
  assign LFSR_ptrn[0] = 5'h1E;           //  and check for correct results from your DUT
  assign LFSR_ptrn[1] = 5'h1D;
  assign LFSR_ptrn[2] = 5'h1B;
  assign LFSR_ptrn[3] = 5'h17;
  assign LFSR_ptrn[4] = 5'h14;
  assign LFSR_ptrn[5] = 5'h12;

  initial begin
// ***** select your desired preamble length *****  
    if(j<7)  j  =  7;                // minimum preamble length
    if(j>12) j  = 12;                  // maximum preamble length
    pre_length  = j;                     // set preamble length
    if(i>5) begin 
      i   = 5            ;               // restricts to legal
      $display("illegal tap pattern chosen, force to 5'h12");        
    end
    else $display("tap pattern selected = %d",LFSR_ptrn[i]);
    lfsr_ptrn   = LFSR_ptrn[i] ;         // selects one of 6 permitted
  
    // ***** choose any nonzero 5-bit starting state for the LFSR ******
    lfsr_state  = 5'h01        ;         // any nonzero value will do; something simple facilitates debug
    if(!lfsr_state) lfsr_state = 5'h10;  // prevents nonzero lfsr_state by substituting 5'b1_0000
    LFSR        = lfsr_state   ;         // initalize test bench's LFSR
    $display("initial LFSR_state = %h",lfsr_state);
    $display("%s",str)         ;         // print original message in transcript window

    if(str.len > 52)
      str_len = 52;                      //Trimming characters to write into Memory
    else 
      str_len = str.len;                      //Trimming characters to write into Memory
       
    for(int j=0; j<test_vector_len; j++)       // pre-fill message_padded with ASCII ~ characters
      msg_padded[j] = 8'h7E;           //    as placeholders: see next line  

    for(int l=0; l<str_len; l++)       // overwrite up to 52 of these spaces w/ message itself
    msg_padded[pre_length+l] = str[l]; // leaves pre_length ASCII ~ in front of the message itself

    for(int n=0; n<test_vector_len; n++)
    dut.dm1.core[n] = 8'h7E;           // prefill data mem with ASCII ~

    for(int m=0; m<str_len; m++)  
    dut.dm1.core[m+4] = str[m];          // copy original string into device's data memory[4:55]

    $display("preamble_length = %d",pre_length);
    dut.dm1.core[0] = pre_length;//-1;     // number of bytes preceding message 
    dut.dm1.core[1] = lfsr_ptrn;     // LFSR feedback tap positions (8 possible ptrns)
    dut.dm1.core[2] = lfsr_state;    // LFSR starting state (nonzero)

    #20ns init = 0             ;
    #60ns;    
    for(int ij=0; ij<test_vector_len; ij++) begin
      msg_crypto[ij]        = msg_padded[ij] ^ {3'b0,LFSR}; // encrypt 5 LSBs
      LFSR                 = (LFSR<<1)+(^(LFSR&lfsr_ptrn));//{LFSR[4:0],feedback};       // roll the rolling code
      str_enc[ij]           = string'(msg_crypto[ij]);
    end
    $write  ("Starting to wait for done signal now ");
                               // wait for 6 clock cycles of nominal 10ns each
    wait(done);                // wait for DUT's done flag to go high

    for(int n=0; n<test_vector_len; n++)  begin
      $write("%d bench msg: %s %h %h %s dut msg: %h",n, msg_padded[n],msg_padded[n],msg_crypto[n],msg_crypto[n],dut.dm1.core[n+128]);   
      if(msg_crypto[n]==dut.dm1.core[n+128]) 
        $display("    very nice!");
    else 
        $display("      oops!");
    end
    $display("original message  = %s",string'(msg_padded));
    $write  ("encrypted message = ");
    for(int kk=0; kk<test_vector_len; kk++)
      $write("%s",string'(msg_crypto[kk]));//msg_crypto);
    $display(); 
    $stop;
  end

always begin               // continuous loop
  #5ns clk = 1;              // clock tick
  #5ns clk = 0;              // clock tock
// print count, message, padded message, encrypted message, ASCII of message and encrypted
end                    // continue

endmodule