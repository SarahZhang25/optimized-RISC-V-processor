import Processor;

bsvimport LFSR;
bsvimport FeedLFSR;
bsvimport FIFOF;

Vector#(4, Integer) cmdsPerTest = cons(  16*1024,
                                  cons(  16*1024,
                                  cons(  64*1024,
                                  cons(  256*1024,
                                  nil))));

// Testbench for Fetch module 
module FetchTB;
    // Tests, in sequence, progressively harder cases
    // - Test 0: Fetching a long run of instructions with no stalls
    // - Test 1: Fetching and stalling
    // - Test 2: Fetching and annuling
    // - Test 3: Fetching, stalling, and annulling

    // Initialize test randomizer: generate stall or annul
    Bit#(65) feed = 0;
    feed[64] = 1;
    feed[46] = 1;
    feed[0] = 1;
    FeedLFSR#(Bit#(65)) random(feed);
    Reg#(Bool) init(False);
    Reg#(Bit#(32)) simCycle(0);
    rule initRand;
        simCycle <= simCycle+1;
        if (!init) begin
            init <= True;
            random.seed(signExtend(64'hbeefdeadbeefdead));
        end
        else random.next;
    endrule

    // Initialize test suite
    Fetch fetch;
    SingleCycleMemory iMemRef; // used as a reference to check if mem[pc] == fetch.d2d.inst
                               // loads the same mem.vmh as a iMem in Fetch

    Reg#(Bit#(2)) testNum(0);
    Reg#(Bit#(20)) genTimer(0);
    Vector#(4, Reg#(Bool)) testStarted(False);
    Vector#(4, Reg#(Bit#(32))) cmdsSent(0);
    Reg#(Word) nextPcReg(0);
    Reg#(Bool) lastCase(False);
    Reg#(Bool) annulSent(False);

    // generate tests
    rule gen_test;
        Bool verbose = False;

        let fetch_input = FetchInput{fetchAction: Stall, redirectPC: ?};
        Maybe#(Word) nextPc = Invalid;
        Bool isLast = False;

        case(testNum)
            // Test 0: Fetching a long run of instructions with no stalls
            //  When fetch.f2d == Invalid, FetchInput: Stall
            //  When fetch.f2d == Valid, FetchInput: Dequeue -> run 'cmdsPerTest' times
            // NOTE: This does not test Dequeue on fetch.f2d == Invalid,
            // which is considered out-of-bounds behavior.
            0: begin
                if (!testStarted[testNum]) begin
                    testStarted[testNum] <= True;
                    $display("Project.Fetch0: Starting Test 0: Fetching a long run of instructions...");
                end

                if (isValid(fetch.f2d) && cmdsSent[testNum] < fromInteger(cmdsPerTest[testNum])) begin 
                    // GENERATING INPUT & EXPECTED PC
                    fetch_input = FetchInput{fetchAction: Dequeue, redirectPC: ?};
                    nextPc = Valid( fromMaybe(?, fetch.f2d).pc + 4 ); // We expect nextPC = pc + 4

                    cmdsSent[testNum] <= cmdsSent[testNum] + 1;
                    if (cmdsSent[testNum] == fromInteger(cmdsPerTest[testNum]-1)) isLast = True;
                end
                else if(cmdsSent[testNum] == fromInteger(cmdsPerTest[testNum])) begin
                    if (genTimer >= 1024) begin // wait 1024 cycles and move on to the next test
                        genTimer <= 0;
                        testNum <= testNum + 1;
                    end
                    else genTimer <= genTimer + 1;
                end
            end

            // Test 1: Fetching and stalling
            //  When fetch.f2d == Invalid, FetchInput: Stall
            //  When fetch.f2d == Valid, FetchInput: Dequeue or Stall (8:2 ratio)
            1: begin
                if (!testStarted[testNum]) begin
                    testStarted[testNum] <= True;
                    $display("Project.Fetch1: Starting Test 1: Fetching and stalling");
                end

                if (isValid(fetch.f2d) && cmdsSent[testNum] < fromInteger(cmdsPerTest[testNum])) begin 
                    let newrand = random.value;
                    Bool doStall = False;
                    if(newrand[9:0] > 800) begin // stall chance: 225/1024
                        doStall = True;
                    end

                    // GENERATING INPUT & EXPECTED PC
                    if (doStall) begin
                        fetch_input = FetchInput{fetchAction: Stall, redirectPC: ?};
                        nextPc = Valid( fromMaybe(?, fetch.f2d).pc );

                        if(verbose) $display("test1: sending Stall when fetch.f2d is valid");
                    end
                    else begin
                        fetch_input = FetchInput{fetchAction: Dequeue, redirectPC: ?};
                        nextPc = Valid( fromMaybe(?, fetch.f2d).pc + 4 );
                    end

                    cmdsSent[testNum] <= cmdsSent[testNum] + 1;
                    if (cmdsSent[testNum] == fromInteger(cmdsPerTest[testNum]-1)) isLast = True;
                end
                else if(cmdsSent[testNum] == fromInteger(cmdsPerTest[testNum])) begin
                    if (genTimer >= 1024) begin // wait 1024 cycles and move on to the next test
                        genTimer <= 0;
                        testNum <= testNum + 1;
                    end
                    else genTimer <= genTimer + 1;
                end
            end
            
            // Test 2: Fetching and annuling
            //  When fetch.f2d == Invalid, FetchInput: Stall or Annul
            //  When fetch.f2d == Valid, FetchInput: Dequeue or Annul
            // NOTE: This does not issue multiple ANNULs before the next valid output, because simple pipelines annul only once.
            2: begin
                if (!testStarted[testNum]) begin
                    testStarted[testNum] <= True;
                    $display("Project.Fetch2: Starting Test 2: Fetching and annuling");
                end

                // generate redirection signal
                let newrand = random.value;
                Word redirectPC = {0, newrand[23:10], 2'b0};
                Bool doAnnul = False;
                if(newrand[9:0] > 819) begin
                    doAnnul = True;
                end

                if (cmdsSent[testNum] < fromInteger(cmdsPerTest[testNum])) begin 
                    // GENERATING INPUT & EXPECTED PC
                    if (doAnnul) begin
                        // prevent consecutive annuls if not seen the output
                        if (isValid(fetch.f2d) || !annulSent) begin
                            fetch_input = FetchInput{fetchAction: Redirect, redirectPC: redirectPC};
                            nextPc = Valid( redirectPC );
                            cmdsSent[testNum] <= cmdsSent[testNum] + 1;
                            if (cmdsSent[testNum] == fromInteger(cmdsPerTest[testNum]-1)) isLast = True;
                            annulSent <= True;
                            if(verbose) $display("test2: annul generated: pc=%x", redirectPC);
                        end
                    end
                    else begin
                        if (isValid(fetch.f2d)) begin
                            fetch_input = FetchInput{fetchAction: Dequeue, redirectPC: ?};
                            nextPc = Valid( fromMaybe(?, fetch.f2d).pc + 4 );
                            cmdsSent[testNum] <= cmdsSent[testNum] + 1;
                            if (cmdsSent[testNum] == fromInteger(cmdsPerTest[testNum]-1)) isLast = True;
                            annulSent <= False;
                        end
                        else begin
                            fetch_input = FetchInput{fetchAction: Stall, redirectPC: ?};
                            // when fetch.f2d is invalid, nextPc should also be Invalid
                            // nextPc = Valid( fromMaybe(?, fetch.f2d).pc );
                        end
                    end
                end
                else if(cmdsSent[testNum] == fromInteger(cmdsPerTest[testNum])) begin
                    if (genTimer >= 1024) begin // wait 1024 cycles and move on to the next test
                        genTimer <= 0;
                        testNum <= testNum + 1;
                    end
                    else genTimer <= genTimer + 1;
                end
            end

            // Test 3: Fetching, stalling, and annulling
            //  When fetch.f2d == Invalid, FetchInput: Stall or Annul
            //  When fetch.f2d == Valid, FetchInput: Dequeue or Stall or Annul
            // NOTE: Like above, only one annul before the next valid output
            3: begin
                if (!testStarted[testNum]) begin
                    testStarted[testNum] <= True;
                    $display("Project.Fetch3: Starting Test 3: Fetching, stalling, and annuling");
                end

                // generate redirection/stall signal
                let newrand = random.value;
                Word redirectPC = {0, newrand[23:10], 2'b0};
                Bool doAnnul = False;
                Bool doStall = False;
                if(newrand[9:0] > 921) begin
                    doAnnul = True;
                end
                else if(newrand[9:0] > 614) begin
                    doStall = True;
                end

                if (cmdsSent[testNum] < fromInteger(cmdsPerTest[testNum])) begin 
                    // GENERATING INPUT & EXPECTED PC
                    if (doAnnul) begin
                        // prevent consecutive annuls if not seen the output
                        if (isValid(fetch.f2d) || !annulSent) begin
                            fetch_input = FetchInput{fetchAction: Redirect, redirectPC: redirectPC};
                            nextPc = Valid( redirectPC );
                            cmdsSent[testNum] <= cmdsSent[testNum] + 1;
                            if (cmdsSent[testNum] == fromInteger(cmdsPerTest[testNum]-1)) isLast = True;
                            annulSent <= True;
                            if(verbose) $display("test3: annul generated: pc=%x", redirectPC);
                        end
                    end
                    else begin
                        if (isValid(fetch.f2d)) begin
                            if(doStall) begin
                                fetch_input = FetchInput{fetchAction: Stall, redirectPC: ?};
                                nextPc = Valid( fromMaybe(?, fetch.f2d).pc );
                                if(verbose) $display("test3: stall generated");
                            end
                            else begin
                                fetch_input = FetchInput{fetchAction: Dequeue, redirectPC: ?};
                                nextPc = Valid( fromMaybe(?, fetch.f2d).pc + 4 );
                            end

                            cmdsSent[testNum] <= cmdsSent[testNum] + 1;
                            if (cmdsSent[testNum] == fromInteger(cmdsPerTest[testNum]-1)) isLast = True;
                            annulSent <= False;
                        end
                        else begin
                            fetch_input = FetchInput{fetchAction: Stall, redirectPC: ?};
                            // when fetch.f2d is invalid, nextPc should also be Invalid
                            // nextPc = Valid( fromMaybe(?, fetch.f2d).pc );
                        end
                    end
                end
                else if(cmdsSent[testNum] == fromInteger(cmdsPerTest[testNum])) begin
                    if (genTimer >= 1024) begin // wait 1024 cycles and move on to the next test
                        genTimer <= 0;
                        testNum <= testNum + 1;
                    end
                    else genTimer <= genTimer + 1;
                end
            end
            default: begin
                $display("TEST TIMED OUT..........   FAILED");
            end
        endcase


        if(isValid(nextPc)) nextPcReg <= fromMaybe(?, nextPc);
        lastCase <= isLast? isLast: (isValid(fetch.f2d)? False: lastCase);
        fetch.in = fetch_input;
    endrule

    Reg#(Maybe#(F2D)) fetchedF2D(Invalid); // In sync with iMemRef req/resp
    RegU#(Word) expectedPc;                // In sync with iMemRef req/resp
    RegU#(Bool) endOfTest;

    rule query_iMemRef;
        let f2d_v = isValid(fetch.f2d);
        let f2d_d = fromMaybe(?, fetch.f2d);
        if (f2d_v) begin
            iMemRef.req = Valid(MemReq{addr: f2d_d.pc, op: Ld, data: ?});

            fetchedF2D <= Valid(f2d_d);
            expectedPc <= nextPcReg;
            endOfTest <= lastCase;
        end
        else fetchedF2D <= Invalid;
    endrule

    Vector#(4, Reg#(Bit#(32))) instsSeen(0);
    Reg#(Bit#(10)) test0fetched(0);
    Reg#(Bit#(10)) invalCnt(0);
    Reg#(Word) lastPc(0);

    Reg#(Bool) checkAnnulledInst(False);
    RegU#(Word) fetchedInst;
    SingleCycleMemory iMemRef2; // another copy to avoid conflict

    rule check_test;
        let f2d_v = isValid(fetchedF2D);
        let f2d_d = fromMaybe(?, fetchedF2D);

        // Checking if the output of fetch is invalid for a long time
        if (f2d_v) begin
            invalCnt <= 0;
            lastPc <= f2d_d.pc;
        end
        else invalCnt <= invalCnt+1;

        if (invalCnt >= 256) begin
            $display("Project.Fetch%d: FAILED: fetch.f2d has been invalid for %d cycles (should output something valid)", testNum, invalCnt);
            $finish;
        end

        // Checking if the PC sequence is correct: by default, use expectedPC
        Bit#(32) expected = expectedPc;
        Bool isEndOfTest = endOfTest;

        if (f2d_v) begin
            // At the beginning of the test0, the first valid PC should be pc = 0 even without any Dequeue;
            if (testNum==0 && instsSeen[testNum]==0) expected = 0;

            // TEST: f2d.pc == expectedPc ?
            if (f2d_d.pc != expected) begin
                $display("Project.Fetch%d: FAILED f2d.pc=0x%x; Expected pc=0x%x, Previous f2d.pc=0x%x", testNum, f2d_d.pc, expected, lastPc);

                if (expected == lastPc) $display("Stall expected... (lastPc)");
                else if (expected == lastPc+4) $display("Dequeue expected... (lastPc+4)");
                else begin
                    $display("Annul expected... (0x%x)", expected);
                    if (f2d_d.pc == lastPc + 4) $display("Looks like fetch returned pc+4 when it should have been annulled.");
                end

                $finish;
            end

            // TEST: insctruction fetched is correct, i.e., f2d.inst == mem[f2d.pc]
            if (!isValid(iMemRef.data)) begin
                $display("This cannot happen -- Single Cycle Memory not responding in a cycle");
                $finish;
            end
            else if (f2d_d.inst != fromMaybe(?, iMemRef.data)) begin
                $display("Project.Fetch%d: FAILED at f2d.pc=0x%x (pc is correct), f2d.inst != mem[f2d.pc] (0x%x != 0x%x)"
                         , testNum, f2d_d.pc, f2d_d.inst, fromMaybe(?, iMemRef.data));
                
                // check if the returned inst was from the annulled one
                iMemRef2.req = Valid(MemReq{addr: lastPc+4,  op: Ld, data: ?});
                checkAnnulledInst <= True;
                fetchedInst <= f2d_d.inst;
            end

            if(isEndOfTest && !checkAnnulledInst) begin
                $display("Project.Fetch%d: PASSED", testNum);
                if(testNum==3) begin
                    $display("Project.Fetch: PASSED");
                    $finish;
                end
            end

            instsSeen[testNum] <= instsSeen[testNum]+1;
        end
    endrule

    rule check_annulled_inst;
        if (checkAnnulledInst && isValid(iMemRef2.data)) begin
            if(fetchedInst == fromMaybe(?, iMemRef2.data)) begin
                $display("f2d.inst == mem[annulled pc] detected"); 
                $display("Make sure you discard the output from the cache for the request made on the annulled PC."); 
            end
            else begin
                $display("f2d is returning instruction that is not consistent with the memory");
                $display("Make sure your fetch module keeps the f2d instruction and pc in sync");
            end
            $finish;
        end
    endrule
endmodule
