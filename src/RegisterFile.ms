import ProcTypes;

module RegisterFile;
    Vector#(32, Reg#(Word)) regs(0);

    method Word rd1(RIndx rindx) = regs[rindx];
    method Word rd2(RIndx rindx) = regs[rindx];

    input Maybe#(RegWriteArgs) wr default = Invalid;

    rule rfWrite;
        if (isValid(wr)) begin
            RegWriteArgs rwd = fromMaybe(?, wr);
            if (rwd.index != 0)
                regs[rwd.index] <= rwd.data;
        end
    endrule

    // Simulation-only debugging method
    // IMPORTANT: Do not modify this code! The microtests depend on this.
    method Fmt fshow;
        Fmt f = $format;
        for (Integer i = 0; i < 32; i = i+1) begin
            f = f + $format("x%0d = 0x%x", i, regs[i]);
            if (i < 31) f = f + $format("\n");
        end
        return f;
    endmethod
endmodule
