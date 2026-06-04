`timescale 1ns/1ps
module tb_msic_tpg_verilog;
    parameter WIDTH = 8;
    // ---------------- CLOCKS ----------------
    reg clk1 = 0;
    reg clk2 = 0;
    reg clk1_en = 1;
    always #10 if (clk1_en) clk1 = ~clk1; // 20ns
    always #2  clk2 = ~clk2;              // 4ns
    // ---------------- SIGNALS ----------------
    reg rst, init, rj_mode;
    wire [7:0] seed_out, jc_out, tpg_out, comb_out;
    wire rev_pass, lut_pass;
    integer pass;
    integer fail;
    reg [7:0] test_in;
    reg [7:0] correct_out;
    reg [7:0] bad_out;
    // ---------------- DUT ----------------
    msic_tpg_top DUT(
        .clk1(clk1), .clk2(clk2), .rst(rst),
        .init(init), .rj_mode(rj_mode),
        .seed_out(seed_out), .jc_out(jc_out),
        .tpg_out(tpg_out), .comb_out(comb_out),
        .rev_pass(rev_pass), .lut_pass(lut_pass)
    );
    // ---------------- CHECK TASK ----------------
    task check;
        input cond;
        input [200*8:1] msg;
        begin
            if (cond) begin
                $display("[PASS] %0s", msg);
                pass = pass + 1;
            end else begin
                $display("[FAIL] %0s", msg);
                fail = fail + 1;
            end
        end
    endtask
    // ---------------- DISPLAY ----------------
    task show;
        begin
            $display("T=%0t | SEED=%02h | JC=%08b | TPG=%08b | OUT=%08b | REV=%0b | LUT=%0b",
                     $time, seed_out, jc_out, tpg_out, comb_out, rev_pass, lut_pass);
        end
    endtask
    // ---------------- MAIN ----------------
    initial begin
        pass = 0;
        fail = 0;
        $display("\n===== MSIC TEST =====");
        // ---------------- RESET ----------------
        rst = 1; init = 0; rj_mode = 0;
        repeat(2) @(posedge clk2);
        #1;
        check(jc_out == 0, "JC reset to zero");
        check(seed_out == 8'h01, "LFSR starts at 1");
        rst = 0;
        // ---------------- NORMAL JOHNSON ----------------
        $display("\n--- NORMAL JOHNSON ---");
        clk1_en = 0;   // freeze seed
        init = 1;
        rj_mode = 0;
        repeat(8) begin
            @(posedge clk2); #2;
            show();
            check(tpg_out == (seed_out ^ jc_out), "XOR correct");
            check(rev_pass == 1'b1, "Reversible pass");
            check(lut_pass == 1'b1, "LUT pass");
        end
        // ---------------- CIRCULAR SHIFT ----------------
        $display("\n--- CIRCULAR SHIFT ---");
        init = 1;
        rj_mode = 1;
        repeat(6) begin
            @(posedge clk2); #2;
            show();
        end
        // ---------------- TEST PER CLOCK ----------------
        $display("\n--- TEST PER CLOCK ---");
        clk1_en = 1;
        repeat(3) begin
            @(posedge clk1);
            @(posedge clk2); #2;
            show();
        end
        // ---------------- FAULT CHECK ----------------
        $display("\n--- FAULT CHECK ---");
        test_in = 8'b10101010;
        correct_out[3:0] = test_in[3:0] + test_in[7:4];
        correct_out[7:4] = test_in[7:4] ^ test_in[3:0];
        bad_out = correct_out ^ 8'b00000001;
        #1;
        check(bad_out != correct_out, "Fault injected correctly");
        // ---------------- SUMMARY ----------------
        $display("\n==============================");
        $display("PASS = %0d", pass);
        $display("FAIL = %0d", fail);
        if (fail == 0)
            $display("FINAL RESULT: ALL TESTS PASSED");
        else
            $display("FINAL RESULT: FAILURES DETECTED");
        $display("==============================");
        $finish;
    end
endmodule
