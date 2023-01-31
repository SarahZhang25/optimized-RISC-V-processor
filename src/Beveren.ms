import MainMemory;
import CacheTypes;
bsvimport LFSR;
bsvimport FeedLFSR;
bsvimport FIFOF;
bsvimport Queue;

Integer testCount = 50000;
typedef enum { Running, Fail, Check } TermState;

// Original Beveren test can't cover pipelined cache behavior
// since it won't issue consecutive requests to the cache
// BeverenPair test tries to implement it
module Beveren#(type CacheType, Integer wayNum)(Bool verbose);
    Bit#(65) feed = 0;
    feed[64] = 1;
    feed[46] = 1;
    feed[0] = 1;
    FeedLFSR#(Bit#(65)) randomMem(feed);

    MainMemory realMainMem;
    CacheType cache(realMainMem);
    WordMem mem;
    Reg#(Bit#(32)) cycle(0); 
    Reg#(Bit#(32)) counterIn(0); 
    Reg#(Bit#(32)) counterOut(0);
    Reg#(Bool) doinit(True);
    Reg#(TermState) termState(Running);

    Queue#(Bit#(32)) loadTime(1000);
    Queue#(Word)    responses(1000);
    Queue#(MemReq)  requests(1000);

    rule tick;
        cycle <= cycle + 1;
        if (termState == Fail) $finish;
        if (termState == Check) begin
            let hit = cache.getHits;
            let miss = cache.getMisses;
            if (verbose) $display("hit = %d, miss = %d, total = %d", hit, miss, hit+miss);
            if (wayNum == 1) begin
                // NOTE(dsm): In the original (BSV) Beveren, counts were 24887/75139 b/c the cache was mis-initialized
                // (we initialize all arrays to invalid, which causes no hits on the initial cache values)
                if (hit == 24886 && miss == 75139)begin
                    Bit#(32) expectedCycles= 32'd6216520;
                    Bit#(32) toleranceError= 32'd621652;//=10%
                    let cycleBound = expectedCycles + toleranceError;
                    if (cycle >= cycleBound) begin
                        if (cacheSets != 64 || wordsPerLine != 16) begin
                            $display("Your cache outputs the correct values but the cycle counts cannot be confirmed:  please set cacheSets=64, wordsPerLine=16 in CacheTypes.ms for this test");
                        end
                        else if (verbose) $display("Your cache outputs the correct values but takes too many cycles. You currently take %d cycles, but to pass it must be under %d. You are probably making extra requests to main memory.", cycle, cycleBound);
                        $display("FAILED - Too many cycles");
                    end else $display("PASSED\n");
                    
                end
                else begin
                    if (cacheSets != 64 || wordsPerLine != 16) begin
                            $display("Your cache outputs the correct values but the hit/miss counts cannot be confirmed:  please set cacheSets=64, wordsPerLine=16 in CacheTypes.ms for this test");
                    end
                    else if (verbose) $display("Your direct-mapped cache has correct responses but incorrect hit/miss count.\n{hit, miss} = {%d, %d} instead of expected {24886, 75139}\n", hit, miss, "You probably did not implement a miss-allocate cache");
                    $display("FAILED - Incorrect hit and/or miss count");
                end
            end else if (wayNum == 2) begin
                if (hit == 49646 && miss == 50379)begin
                    Bit#(32) expectedCycles= 32'd4474106;
                    Bit#(32) toleranceError= 32'd447410;//=10%
                    let cycleBound = expectedCycles + toleranceError;
                    if (cycle >= cycleBound) begin
                        if (cacheSets != 64 || wordsPerLine != 16) begin
                            $display("Your cache outputs the correct values but the cycle counts cannot be confirmed:  please set cacheSets=64, wordsPerLine=16 in CacheTypes.ms for this test");
                        end
                        else if (verbose) $display("Your cache outputs the correct values but takes too many cycles. You currently take %d cycles, but to pass it must be under %d. You are probably making extra requests to main memory.", cycle, cycleBound);
                        $display("FAILED - Too many cycles");
                    end else $display("PASSED\n");
                end
                else begin
                    if (cacheSets != 64 || wordsPerLine != 16) begin
                            $display("Your cache outputs the correct values but the hit/miss counts cannot be confirmed:  please set cacheSets=64, wordsPerLine=16 in CacheTypes.ms for this test");
                    end
                    else if (verbose) $display("Your two-way set-associative cache has correct responses but incorrect hit/miss count.\n{hit, miss} = {%d, %d} instead of expected {49646, 50379}\n", hit, miss, "You probably did not implement LRU replacement policy correctly");
                    $display("FAILED - Incorrect hit and/or miss count");
                end
            end else $display("Microtests wayNum %d has not been defined.", wayNum);
            $finish;
        end

        if (doinit) begin
            randomMem.seed(signExtend(64'hdeadbeefdeadbeef));
            doinit <= False;
        end else begin
            // requestGen
            let readyForNewReq = (cache.reqEnabled && counterIn <= testCount);
            // if (verbose) $display("[%d] reqEnabled ", cycle, fshow(cache.reqEnabled));
            if (readyForNewReq) begin
                let newrand = randomMem.value;
                randomMem.next;
                MemReq newreq = unpack(newrand);
                newreq.addr = {0, newreq.addr[13:2],2'b0};
                
                if (newreq.op == Ld) begin
                    // waitingOnLoad <= True;
                    loadTime.enq(cycle);
                    requests.enq(newreq);
                    counterIn <= counterIn + 1;
                end

                cache.req = Valid(newreq);
                mem.req = Valid(newreq);
                if (verbose) $display("[%d] Request ", cycle, fshow(newreq));
            end

            // responseChk
            MemReq curReq = loadTime.notEmpty ? requests.first : unpack(0);

            if (curReq.op == Ld && loadTime.notEmpty) begin
                // check if last Ld times out
                if (cycle - loadTime.first > 200) begin // arbitrary timeout
                    $display("FAILED - Cache takes too long to return a result for a Ld instruction. You probably have a problem with your data method.");
                    $finish;
                end
            end

            if (isValid(mem.data)) begin
                if (!isValid(cache.data) || responses.notEmpty) begin
                    // put mem.data into queue if it's not instantly consumed
                    responses.enq(fromMaybe(?, mem.data));
                end
            end

            if (isValid(cache.data)) begin
                // compare cache.data with ref data
                counterOut <= counterOut + 1;
                if (verbose) $display("[%d] Got response %d for ", cycle, counterOut, fshow(curReq));
                let respCache = fromMaybe(?, cache.data);
                let respRef = ?;
                if (!isValid(mem.data) && !responses.notEmpty) begin
                    $display("FAILED - Valid cache data but invalid data from reference memory model!");
                    $finish;
                end else if (responses.notEmpty) begin
                    respRef = responses.first;
                    responses.deq;
                end else if (isValid(mem.data)) begin
                    respRef = fromMaybe(?, mem.data);
                end

                if (respCache != respRef) begin
                    if (verbose) $display("The cache answered %x instead of %x\n", respCache, respRef);
                    $display("FAILED - Cache returned incorrect value\n");
                    termState <= Fail;
                end else if (counterOut == testCount-1) begin
                    // Do final hit/miss check and finish
                    termState <= Check;
                end

                if (loadTime.notEmpty) begin
                    loadTime.deq;
                    requests.deq;
                end
            end

        end
    endrule

endmodule

