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

// TODO: Complete the implementation of DirectMappedCache
// NOTE: Implementing this module requires about 50 lines of additional code
// (~40 lines in rule tick, ~5-10 lines in method data, 1 line in method reqEnabled, 1 line in function isHit)
module DirectMappedCache(MainMemory mainMem);
    // SRAM arrays. Note that, for a direct-mapped cache,
    // number of cache sets == number of cache lines
    SRAM#(logCacheSets, Line) dataArray;
    SRAM#(logCacheSets, CacheTag) tagArray;
    SRAM#(logCacheSets, CacheStatus) statusArray;
    
    // Registers for holding the current state of the cache and how far along
    // it is in processing a request.
    RegU#(MemReq) curReq;
    Reg#(ReqStatus) state(Ready);
    
    // Hit/miss counters
 //   Reg#(Word) hits(0);
 //   Reg#(Word) misses(0);

    input Maybe#(MemReq) req default = Invalid;
    
    // TODO return True if the cache can accept a new request
    method Bool reqEnabled;
	return (state == Ready || state == Lookup && curReq.op == Ld && isHit);
    endmethod

    // TODO return True if the cache is in lookup and it is a hit
    function Bool isHit; // hit = status is not NotValid and tag matches request tag
        return (state == Lookup && fromMaybe(?, statusArray.data) != NotValid && fromMaybe(?, tagArray.data) == getTag(curReq.addr));
    endfunction

    rule tick;
	if (state == Ready && isValid(req)) begin
	    // request a read to the SRAM arrays
	    
	    let req_uw = fromMaybe(?, req); // req unwrapped from maybe type
	    let cacheInd = getIndex(req_uw.addr);

	    dataArray.req = Valid(DataReq{addr: cacheInd, write: False, data: ?});
	    tagArray.req = Valid(TagReq{addr: cacheInd, write: False, data: ?});
	    statusArray.req = Valid(StatusReq{addr: cacheInd, write: False, data: ?});

	    // update state
	    state <= Lookup;
	    curReq <= req_uw;

        end else if (state == Lookup) begin
	    // get data
            let cachedata = fromMaybe(?, dataArray.data);
            let cachetag = fromMaybe(?, tagArray.data);
            let cachestatus = fromMaybe(?, statusArray.data);
            let cacheInd = getIndex(curReq.addr);

            // determine if hit, clean miss, or dirty miss
	    if (isHit) begin // hit
		if (curReq.op == Ld) begin // load

		if (isValid(req)) begin
            	// request a read to the SRAM arrays
            	let req_uw = fromMaybe(?, req); // req unwrapped from maybe type
            	let newcacheInd = getIndex(req_uw.addr);

            	dataArray.req = Valid(DataReq{addr: newcacheInd, write: False, data: ?});
            	tagArray.req = Valid(TagReq{addr: newcacheInd, write: False, data: ?});
            	statusArray.req = Valid(StatusReq{addr: newcacheInd, write: False, data: ?});

            	// update state
            	state <= Lookup;
            	curReq <= req_uw;

		end else begin
		    state <= Ready;
		end


		end /*else if (curReq.op == St) begin // store
		    // update relevant data
		    let new_data = fromMaybe(?, dataArray.data);
		    new_data[ getWordOffset(curReq.addr) ] = curReq.data;

		    dataArray.req = Valid(DataReq{addr: cacheInd, write: True, data: new_data});
		    tagArray.req = Valid(TagReq{addr: cacheInd, write: True, data: getTag(curReq.addr)});
		    statusArray.req = Valid(StatusReq{addr: cacheInd, write: True, data: Dirty});
		
		    state <= Ready;
		end*/

//		hits <= hits + 1;

	    end else begin // miss
		if (cachestatus == Clean || cachestatus==NotValid) begin // clean miss
		    // send request to main memory
		    mainMem.req = Valid(LineReq{op: Ld, lineAddr: getLineAddr(curReq.addr), data: ?});

		    // update state
		    state <= Fill;

		end /*else if (cachestatus == Dirty) begin // dirty miss
		    // writeback replaced line to main mem
		    mainMem.req = Valid(LineReq{op: St, lineAddr: {cachetag, cacheInd}, data: cachedata});

		    // update state
		    state <= Writeback;
		end*/

//		misses <= misses + 1;
	    end
/*
        end else if (state == Writeback && mainMem.reqEnabled) begin
	    mainMem.req = Valid(LineReq{op: Ld, lineAddr: getLineAddr(curReq.addr), data: ?}); 
	    state <= Fill;
*/
        end else if (state == Fill && isValid(mainMem.data)) begin
	    let memdata = fromMaybe(?, mainMem.data);

	    if (curReq.op == Ld) begin // load
		dataArray.req = Valid(DataReq{addr: getIndex(curReq.addr), write: True, data: memdata});
		tagArray.req = Valid(TagReq{addr: getIndex(curReq.addr), write: True, data: getTag(curReq.addr)});
		statusArray.req = Valid(StatusReq{addr: getIndex(curReq.addr), write: True, data: Clean});
		state <= Ready;		    

	    end else if (curReq.op == St) begin // store
                let new_data = memdata;
		new_data[ getWordOffset(curReq.addr) ] = curReq.data;
	
		dataArray.req = Valid(DataReq{addr: getIndex(curReq.addr), write: True, data: new_data});
		tagArray.req = Valid(TagReq{addr: getIndex(curReq.addr), write: True, data: getTag(curReq.addr)});
		statusArray.req = Valid(StatusReq{addr: getIndex(curReq.addr), write: True, data: Dirty});
		state <= Ready;
	    end
        end
    endrule

    method Maybe#(Word) data;
        // This method should return a Valid output in only two cases:
        // 1. On a load hit (it is a hit, and curReq.op == Ld).
        // 2. On a fill for a load request (we're in the Fill state,
        //    mainMem.data is valid, and curReq.op == Ld).
        // In all other cases, the output should be Invalid
        //
        // NOTE: You should be checking the above conditions explicitly in
        //    THIS method so you can return data as soon as possible.
        //    DO NOT place your output into a register in the rule and then
        //    simply return that register here.

        // This function should take about 4-8 lines of code to implement.
        // TODO Your code here.
	if (isHit == True && curReq.op == Ld) begin
	    return Valid(fromMaybe(?, dataArray.data)[getWordOffset(curReq.addr)]); 
        end else if (state == Fill && isValid(mainMem.data) == True && curReq.op == Ld) begin
	    return Valid(fromMaybe(?, mainMem.data)[getWordOffset(curReq.addr)]);
	end else begin
	    return Invalid;
	end
    endmethod

//    method Bit#(32) getHits = hits;
  //  method Bit#(32) getMisses = misses;
endmodule
