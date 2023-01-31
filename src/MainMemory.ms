import ProcTypes;
import CacheTypes;
import SRAM;
bsvimport Assert;

module /*msc_pragma:nosynth*/ WordMem;
    Integer memBytes = 1 << 17;  // 128 KB
    Integer memWords = memBytes / 4;
    Integer addrBits = log2(memWords);
    SRAMLoad#(addrBits, Word) ram("mem.vmh");

    input Maybe#(MemReq) req default = Invalid;
    method Maybe#(Word) data = ram.data;


    rule tick;
        if (isValid(req)) begin
            let r = fromMaybe(?, req);
            ram.req = Valid(SRAMReq#(addrBits, Word){
                addr: truncate(r.addr >> 2), write: r.op == St, data: r.data
            });
        end
    endrule
endmodule

// To emulate DRAM technology, MainMemory uses a word-based memory and adds some delay
module /*msc_pragma:nosynth*/ MainMemory;
    WordMem wordMem;
    Integer latency = wordsPerLine + 16;

    Reg#(Bit#(log2(latency) + 1)) cyclesLeft(0);
    RegU#(MemOp) curOp;
    RegU#(Word) curAddr;
    Reg#(Bool) validOut(False);
    Vector#(wordsPerLine, RegU#(Word)) dataRegs;

    method Bool reqEnabled = (cyclesLeft == 0);
    input Maybe#(LineReq) req default = Invalid;

    method Maybe#(Line) data;
        Line res;
        for (Integer i = 0; i < wordsPerLine; i = i + 1)
            res[i] = dataRegs[i];
        return validOut? Valid(res) : Invalid;
    endmethod

    rule tick;
        // dsm: Check that wordsPerLine is a reasonable value
        if (wordsPerLine != 4 && wordsPerLine != 8 && wordsPerLine != 16) begin
            $display("ERROR: MainMemory requires wordsPerLine to be 4, 8, or 16");
            $finish;
        end

        dynamicAssert(!((cyclesLeft != 0) && isValid(req)), "MainMemory received request while not ready!\n\n");
        if (cyclesLeft != 0) cyclesLeft <= cyclesLeft - 1;
        if (cyclesLeft == 0 && isValid(req)) begin
            cyclesLeft <= latency;
            let r = fromMaybe(?, req);
            curAddr <= {r.lineAddr, 0};
            curOp <= r.op;
            for (Integer i = 0; i < wordsPerLine; i = i + 1)
                dataRegs[i] <= r.data[i];
            if (r.op == Ld)
                wordMem.req = Valid(MemReq{addr: {r.lineAddr, 0}, op: Ld, data: ?});
        end else if (cyclesLeft > latency - wordsPerLine) begin
            Bit#(logWordsPerLine) idx = truncate(curAddr >> 2);
            curAddr <= curAddr + 4;
            if (curOp == Ld) begin
                dataRegs[idx] <= fromMaybe(?, wordMem.data);
                wordMem.req = Valid(MemReq{addr: curAddr + 4, op: Ld, data: ?});
            end else wordMem.req = Valid(MemReq{addr: curAddr, op: St, data: dataRegs[idx]});
        end
        validOut <= (cyclesLeft == 1);
    endrule
endmodule

// Single-cycle word memory, used as ideal memory by the tests
module /*msc_pragma:nosynth*/ SingleCycleMemory;
    WordMem wordMem;

    Reg#(Bit#(64)) cycles(0);

    input Maybe#(MemReq) req default = Invalid;
    method Maybe#(Word) data = wordMem.data;

    // For detecting timeouts
    rule doCycle;
        cycles <= cycles + 1;
        if (cycles > 10000000) begin
            $display("FAILED: Your processor timed out");
            $finish;
        end
    endrule

    rule tick;
        if (isValid(req)) begin
            let r = fromMaybe(?, req);

            // MMIO and program termination
            if (r.op == St) begin
                if (r.addr == 'h4000_0000) begin
                    // Write character to stdout
                    $write("%c", r.data[7:0]);
                end else if (r.addr == 'h4000_0004) begin
                    // Write integer to stdout
                    $write("%0d", r.data);
                end else if (r.addr == 'h4000_1000) begin
                    // Exit simulation
                    $display("Total Clock Cycles = %d\n", cycles);
                    if (r.data == 0) begin
                        $display("PASSED");
                    end else begin
                        $display("FAILED %0d", r.data);
                    end
                    $finish;
                end
            end
        end
        wordMem.req = req;
    endrule
endmodule

module CacheWrapper#(type T)(MainMemory mainMem);
    T cache(mainMem);

    Reg#(Bit#(64)) cycles(0);

    input Maybe#(MemReq) req default = Invalid;
    method Maybe#(Word) data = cache.data;

    method Bool reqEnabled = cache.reqEnabled;

    // For detecting timeouts
    rule doCycle;
        cycles <= cycles + 1;
        if (cycles > 10000000) begin
            $display("FAILED: Your processor timed out");
            $finish;
        end
    endrule

    rule tick;
        if (isValid(req)) begin
            // MMIO and program termination
            let curReq = fromMaybe(?, req);
            if (curReq.op == St) begin
                if (curReq.addr == 'h4000_0000) begin
                    // Write character to stdout
                    $write("%c", curReq.data[7:0]);
                end else if (curReq.addr == 'h4000_0004) begin
                    // Write integer to stdout
                    $write("%0d", curReq.data);
                end else if (curReq.addr == 'h4000_1000) begin
                    // Exit simulation
                    $display("Total Clock Cycles = %d\n", cycles);
                    if (curReq.data == 0) begin
                        $display("PASSED");
                    end else begin
                        $display("FAILED %0d", curReq.data);
                    end
                    $finish;
                end
            end
        end
        cache.req = req;
    endrule
endmodule
