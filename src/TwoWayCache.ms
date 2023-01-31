import CacheTypes;
import CacheHelpers;
import MainMemory;

// ReqStatus (defined in CacheTypes.ms) is used to keep track of the state of the current request
//typedef enum {
//    Ready,         // The cache is ready for a new request
//    Lookup,        // Issued a lookup to tag/data arrays
//    Writeback,     // In main memory access for dirty writeback
//    Fill           // In main memory access for requested data
//} ReqStatus;
//
// Possible flows:
//   HIT: Ready -> Lookup -> Ready
//   MISS, line is clean: Ready -> Lookup -> Fill
//   MISS, line is dirty: Ready -> Lookup -> Writeback -> Fill

// Cache SRAM Synonyms (defined in CacheTypes.ms)
// You may find the following type synonyms helpful to access the tag/data/status arrays
// typedef SRAMReq#(logCacheSets, CacheTag) TagReq;
// typedef SRAMReq#(logCacheSets, Line) DataReq;
// typedef SRAMReq#(logCacheSets, CacheStatus) StatusReq;

// TODO: Complete the implementation of TwoWayCache
// NOTE: Implementing this module requires about 20 new lines of code from DirectMappedCache
module TwoWayCache(MainMemory mainMem);
    // SRAM arrays, one element per way (e.g., dataArrays[0] is the data array of way 0).
    Vector#(2, SRAM#(logCacheSets, Line)) dataArrays;
    Vector#(2, SRAM#(logCacheSets, CacheTag)) tagArrays;
    Vector#(2, SRAM#(logCacheSets, CacheStatus)) statusArrays;

    // LRU bits, one per set. We implement it as registers instead of an SRAM
    // array, because with small caches this is just a few bits (e.g., 64), and
    // SRAMs make sense only for larger memories. This also makes the code
    // simpler, and will make the cache easier to pipeline in the future.
    Vector#(cacheSets, RegU#(Bit#(1))) lru;

    // Registers for holding the current state of the cache and how far along
    // it is in processing a request.
    RegU#(MemReq) curReq;
    Reg#(ReqStatus) state(Ready);

    // Hit/miss counters
//    Reg#(Word) hits(0);
//    Reg#(Word) misses(0);
    
    input Maybe#(MemReq) req default = Invalid;
    
    // TODO return True if the cache can accept a new request
    method Bool reqEnabled;
        return (state == Ready || state == Lookup && curReq.op == Ld && (isHit(0) || isHit(1)));
    endmethod


    // TODO return True if the cache is in lookup and it is a hit in this way.
    function Bool isHit(Integer way); // hit = status is not NotValid and tag matches request tag
        return (state == Lookup && fromMaybe(?, statusArrays[way].data) != NotValid && fromMaybe(?, tagArrays[way].data) == getTag(curReq.addr));
    endfunction

    rule tick;
        if (state == Ready && isValid(req)) begin
            // request a read to the SRAM arrays

            let req_uw = fromMaybe(?, req); // req unwrapped from maybe type
            let cacheInd = getIndex(req_uw.addr);

            dataArrays[0].req = Valid(DataReq{addr: cacheInd, write: False, data: ?});
            tagArrays[0].req = Valid(TagReq{addr: cacheInd, write: False, data: ?});
            statusArrays[0].req = Valid(StatusReq{addr: cacheInd, write: False, data: ?});

            dataArrays[1].req = Valid(DataReq{addr: cacheInd, write: False, data: ?});
            tagArrays[1].req = Valid(TagReq{addr: cacheInd, write: False, data: ?});
            statusArrays[1].req = Valid(StatusReq{addr: cacheInd, write: False, data: ?});

            // update state
            state <= Lookup;
            curReq <= req_uw;

        end else if (state == Lookup) begin
            // get data
	    Vector#(2, Line) cachedata;
	    Vector#(2, CacheTag) cachetags;
	    Vector#(2, CacheStatus) cachestatuses;	 

	    for (Integer i=0; i<2; i=i+1) begin
                cachedata[i] = fromMaybe(?, dataArrays[i].data);//, fromMaybe(?, dataArrays[0].data)};
                cachetags[i] = fromMaybe(?, tagArrays[i].data);//, fromMaybe(?, tagArrays[0].data)};
                cachestatuses[i] = fromMaybe(?, statusArrays[i].data);//, fromMaybe(?, statusArrays[0].data)};
            end
	    let cacheInd = getIndex(curReq.addr);

            // determine if hit, clean miss, or dirty miss
            if (isHit(0) || isHit(1)) begin // hit
		$display("HIT ", fshow(curReq.op));
		let hitInd = isHit(0) ? 0 : 1; // the way that had a hit

                if (curReq.op == Ld) begin // load

		    $display("LOAD HIT");

		    if (isValid(req)) begin
			$display("processing NEXT REQ");
	            let req_uw = fromMaybe(?, req); // req unwrapped from maybe type
        	    let newcacheInd = getIndex(req_uw.addr);

            	    dataArrays[0].req = Valid(DataReq{addr: newcacheInd, write: False, data: ?});
            	    tagArrays[0].req = Valid(TagReq{addr: newcacheInd, write: False, data: ?});
            	    statusArrays[0].req = Valid(StatusReq{addr: newcacheInd, write: False, data: ?});

	            dataArrays[1].req = Valid(DataReq{addr: newcacheInd, write: False, data: ?});
	            tagArrays[1].req = Valid(TagReq{addr: newcacheInd, write: False, data: ?});
	            statusArrays[1].req = Valid(StatusReq{addr: newcacheInd, write: False, data: ?});

        	    // update state
	            state <= Lookup;
	            curReq <= req_uw;

		    end else begin
                    // update state
			$display("invalid req, back to ready");
                    	state <= Ready;
		    end
                end else if (curReq.op == St) begin // store
			$display("STORE HIT");
                    // update relevant data
                    let new_data = fromMaybe(?, dataArrays[hitInd].data);
                    new_data[ getWordOffset(curReq.addr) ] = curReq.data;

                    dataArrays[hitInd].req = Valid(DataReq{addr: cacheInd, write: True, data: new_data});
                    tagArrays[hitInd].req = Valid(TagReq{addr: cacheInd, write: True, data: getTag(curReq.addr)});
                    statusArrays[hitInd].req = Valid(StatusReq{addr: cacheInd, write: True, data: Dirty});
                    state <= Ready;
		end

		lru[cacheInd] <= ~ hitInd; // update LRU for this access
  //              hits <= hits + 1;

            end else begin // miss
		let lruInd = lru[cacheInd];

                if (cachestatuses[lruInd] == Clean || cachestatuses[lruInd] == NotValid) begin // clean miss
                    // send request to main memory
                    mainMem.req = Valid(LineReq{op: Ld, lineAddr: getLineAddr(curReq.addr), data: ?});

                    // update state
                    state <= Fill;

                end else if (cachestatuses[lruInd] == Dirty) begin // dirty miss
                    // writeback replaced line to main mem
                    mainMem.req = Valid(LineReq{op: St, lineAddr: {cachetags[lruInd], cacheInd}, data: cachedata[lruInd]});

                    // update state
                    state <= Writeback;
                end

    //            misses <= misses + 1;
            end

        end else if (state == Writeback && mainMem.reqEnabled) begin
            mainMem.req = Valid(LineReq{op: Ld, lineAddr: getLineAddr(curReq.addr), data: ?});
            state <= Fill;

        end else if (state == Fill && isValid(mainMem.data)) begin
            let memdata = fromMaybe(?, mainMem.data);
	    let cacheInd = getIndex(curReq.addr);
	    let lruInd = lru[cacheInd];

            if (curReq.op == Ld) begin // load
                dataArrays[lruInd].req = Valid(DataReq{addr: getIndex(curReq.addr), write: True, data: memdata});
                tagArrays[lruInd].req = Valid(TagReq{addr: getIndex(curReq.addr), write: True, data: getTag(curReq.addr)});
                statusArrays[lruInd].req = Valid(StatusReq{addr: getIndex(curReq.addr), write: True, data: Clean});
                state <= Ready;

            end else if (curReq.op == St) begin // store
                let new_data = memdata;
                new_data[ getWordOffset(curReq.addr) ] = curReq.data;

                dataArrays[lruInd].req = Valid(DataReq{addr: getIndex(curReq.addr), write: True, data: new_data});
                tagArrays[lruInd].req = Valid(TagReq{addr: getIndex(curReq.addr), write: True, data: getTag(curReq.addr)});
                statusArrays[lruInd].req = Valid(StatusReq{addr: getIndex(curReq.addr), write: True, data: Dirty});
                state <= Ready;
            end

            lru[cacheInd] <= ~ lruInd; // update LRU for this access
        end

    endrule

    method Maybe#(Word) data;
        // This method should return a Valid output in only two cases:
        // 1. On a load hit (we're in the Lookup state, there's a hit, and
        //    curReq.op == Ld).
        // 2. On a fill for a load request (we're in the Fill state,
        //    mainMem.data is valid, and curReq.op == Ld).
        // In all other cases, the output should be Invalid
        //
        // NOTE: You should be checking the above conditions explicitly in
        //    THIS method so you can return data as soon as possible.
        //    DO NOT place your output into a register in the rule and then
        //    simply return that register here.

        // This function should take about 5-20 lines of code to implement.
        // TODO Your code here
        if ((isHit(0) || isHit(1)) && curReq.op == Ld) begin
	    let hitInd = isHit(0) ? 0 : 1;
            return Valid(fromMaybe(?, dataArrays[hitInd].data)[getWordOffset(curReq.addr)]);
        end else if (state == Fill && isValid(mainMem.data) == True && curReq.op == Ld) begin
            return Valid(fromMaybe(?, mainMem.data)[getWordOffset(curReq.addr)]);
        end else begin
	    return Invalid;
	end

    endmethod

//    method Bit#(32) getHits = hits;
  //  method Bit#(32) getMisses = misses;
endmodule
