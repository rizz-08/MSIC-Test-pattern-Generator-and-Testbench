// ============================================================
//  MSIC TEST PATTERN GENERATOR - Full Verilog Implementation
//  Based on: "Design and Verification of MSIC Test Pattern
//  Generator" - Parvathy Chandra, Vishnu V.S. (IJournals 2015)
//
//  Hierarchy:
//    msic_tpg_top            (top-level, test-per-clock)
//      ├── lfsr_seed_gen     (m-bit LFSR, clocked by CLK1)
//      ├── reconfig_johnson  (l-bit reconfigurable Johnson counter, CLK2)
//      ├── xor_network       (XOR of seed bits and Johnson bits)
//      ├── reversible_verify (reversible technique - re-compute and compare)
//      └── lut_verify        (Look-Up-Table comparator)
// ============================================================


// -----------------------------------------------------------
// 1.  LFSR SEED GENERATOR  (8-bit, primitive poly x^8+x^6+x^5+x^4+1)
// -----------------------------------------------------------
module lfsr_seed_gen #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst,
    output reg  [WIDTH-1:0] seed
);
    wire feedback = seed[7] ^ seed[5] ^ seed[4] ^ seed[3];

    always @(posedge clk or posedge rst) begin
        if (rst)
            seed <= 8'b0000_0001;
        else
            seed <= {seed[WIDTH-2:0], feedback};
    end
endmodule


// -----------------------------------------------------------
// 2.  RECONFIGURABLE JOHNSON COUNTER  (8-bit)
//     Modes:
//       Init=0, RJ_Mode=1  →  Initialization (shift 0 in from MSB side)
//       Init=1, RJ_Mode=1  →  Circular shift register
//       Init=x, RJ_Mode=0  →  Normal Johnson counter (2l unique SIC vectors)
// -----------------------------------------------------------
module reconfig_johnson #(
    parameter WIDTH = 8
)(
    input  wire             clk2,
    input  wire             rst,
    input  wire             init,
    input  wire             rj_mode,
    output reg  [WIDTH-1:0] jc_out
);
    wire feedback_normal   = ~jc_out[WIDTH-1]; // Inverted MSB feeds LSB
    wire feedback_circular =  jc_out[WIDTH-1]; // MSB wraps to LSB

    always @(posedge clk2 or posedge rst) begin
        if (rst)
            jc_out <= {WIDTH{1'b0}};
        else begin
            if (!init && rj_mode)
                // Initialization: shift 0 into MSB repeatedly → all-zero
                jc_out <= {1'b0, jc_out[WIDTH-1:1]};
            else if (init && rj_mode)
                // Circular shift register: rotate left
                jc_out <= {jc_out[WIDTH-2:0], feedback_circular};
            else
                // Normal Johnson: shift left, ~MSB into LSB
                jc_out <= {jc_out[WIDTH-2:0], feedback_normal};
        end
    end
endmodule


// -----------------------------------------------------------
// 3.  XOR NETWORK  (decompressor: X = S XOR J)
// -----------------------------------------------------------
module xor_network #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] seed,
    input  wire [WIDTH-1:0] jc_out,
    output wire [WIDTH-1:0] tpg_out
);
    assign tpg_out = seed ^ jc_out;
endmodule


// -----------------------------------------------------------
// 4.  CIRCUIT UNDER TEST (CUT)
//     out[3:0] = in[3:0] + in[7:4]   (4-bit adder, truncated)
//     out[7:4] = in[7:4] ^ in[3:0]   (4-bit XOR)
// -----------------------------------------------------------
module circuit_under_test (
    input  wire [7:0] test_in,
    output wire [7:0] comb_out
);
    assign comb_out[3:0] = test_in[3:0] + test_in[7:4];
    assign comb_out[7:4] = test_in[7:4] ^ test_in[3:0];
endmodule


// -----------------------------------------------------------
// 5.  REVERSIBLE TECHNIQUE VERIFIER  (Section 3.1)
//     Re-derives expected CUT output from test_in and
//     compares against the actual comb_out.
//     Pass → no error in the test response.
// -----------------------------------------------------------
module reversible_verify (
    input  wire [7:0] test_in,
    input  wire [7:0] comb_out,
    output wire       rev_pass
);
    wire [3:0] exp_lo = test_in[3:0] + test_in[7:4];
    wire [3:0] exp_hi = test_in[7:4] ^ test_in[3:0];
    assign rev_pass   = (comb_out == {exp_hi, exp_lo});
endmodule


// -----------------------------------------------------------
// 6.  LUT VERIFIER  (Section 3.2)
//     Pre-computed golden response addressed by test_in.
// -----------------------------------------------------------
module lut_verify (
    input  wire [7:0] test_in,
    input  wire [7:0] comb_out,
    output wire       lut_pass
);
    wire [3:0] golden_lo = test_in[3:0] + test_in[7:4];
    wire [3:0] golden_hi = test_in[7:4] ^ test_in[3:0];
    assign lut_pass      = (comb_out == {golden_hi, golden_lo});
endmodule


// -----------------------------------------------------------
// 7.  TOP-LEVEL  (Test-per-clock, Figure 4)
// -----------------------------------------------------------
module msic_tpg_top #(
    parameter WIDTH = 8
)(
    input  wire             clk1,
    input  wire             clk2,
    input  wire             rst,
    input  wire             init,
    input  wire             rj_mode,
    output wire [WIDTH-1:0] seed_out,
    output wire [WIDTH-1:0] jc_out,
    output wire [WIDTH-1:0] tpg_out,
    output wire [WIDTH-1:0] comb_out,
    output wire             rev_pass,
    output wire             lut_pass
);
    lfsr_seed_gen    #(.WIDTH(WIDTH)) U_SEED (.clk(clk1),  .rst(rst), .seed(seed_out));
    reconfig_johnson #(.WIDTH(WIDTH)) U_JC   (.clk2(clk2), .rst(rst), .init(init),
                                              .rj_mode(rj_mode), .jc_out(jc_out));
    xor_network      #(.WIDTH(WIDTH)) U_XOR  (.seed(seed_out), .jc_out(jc_out), .tpg_out(tpg_out));
    circuit_under_test                U_CUT  (.test_in(tpg_out), .comb_out(comb_out));
    reversible_verify                 U_REV  (.test_in(tpg_out), .comb_out(comb_out), .rev_pass(rev_pass));
    lut_verify                        U_LUT  (.test_in(tpg_out), .comb_out(comb_out), .lut_pass(lut_pass));
endmodule
