import ProcTypes;

import RegisterFile;
import Decode;
import Execute;

// MainMemory includes the MainMemory port
// and the SingleCycleMemory modules
import MainMemory;

// import caches
import DirectMappedCache;
import TwoWayCache;

// Types associated with the fetch stage
typedef enum {
    Dequeue, // Consume instruction at the f2d output, if any
    Stall, // Do not consume instruction at f2d
    Redirect  // Redirect fetch to another PC, annulling any fetched instructions
} FetchAction;

typedef struct {
    FetchAction fetchAction;
    Word redirectPC;  // PC to fetch from, used only if fetchAction is Redirect
} FetchInput;


typedef struct {
    Word pc;
    Word inst;
} F2D;

typedef struct {
    Word pc;
    DecodedInst dInst;
    Word rVal1;
    Word rVal2;
} D2E;

typedef struct {
    Word pc;
    IType iType;
    Maybe#(RIndx) dst;
    Word data;
} E2W;


// Fetch stage, including pc and instruction memory/cache
module Fetch;
    Reg#(Word) pc(0);
    Reg#(Bool) flag(False); // true when ignoring fetch data

    // Single-cycle Instruction Memory
    //SingleCycleMemory iMem;
    
    // Line-based Main Memory to use with caches
    MainMemory iMem;

    // Milestone 2: choose which type of iCache to use
    DirectMappedCache iCache(iMem);

    input FetchInput in default = FetchInput{fetchAction: Stall, redirectPC: ?};


    method Maybe#(F2D) f2d = isValid(iCache.data) && !flag ?
        Valid(F2D{pc: pc, inst: fromMaybe(?, iCache.data)}) : Invalid;


    rule fetch;
        // Fetch instructions from iMem/iCache and update PC according to in.
        //////////////////////////
        // TODO: //
	let nextPc = pc;

	if (in.fetchAction == Dequeue) begin
	    nextPc = pc + 4;
	end else if (in.fetchAction == Redirect) begin
	    nextPc = in.redirectPC;	   
	end
		
	if (iCache.reqEnabled == True) begin
	    iCache.req = Valid(MemReq{op: Ld, addr: nextPc, data: ?});
	    flag <= False;
        end else begin
	    if (in.fetchAction == Redirect) begin
		flag <= True;
	    end
	end
	pc <= nextPc;
       
        //////////////////////////

    endrule

    // Used only for pipeline debugging; you should not use this method
    // elsewhere in your code (assume the fetch stage can run ahead)
    method Word getPc = pc; 
endmodule


module Processor;
    Fetch fetch;

    RegisterFile rf;

    // Single-cycle data memory
//    SingleCycleMemory dMem;

    // Line-based Main Memory to use with caches
    MainMemory dMem;

    // Milestone 2: 
    CacheWrapper#(TwoWayCache) dCache(dMem);

    // Pipeline Registers
    Reg#(Maybe#(D2E)) d2e(Invalid);
    Reg#(Maybe#(E2W)) e2w(Invalid);
    
    // Performance counters
    // These are used in the processor rule for debugging help, by tracking the
    // cycles and instructions completed. They are not needed for correctness
    // and you may remove them, but doing so is unlikely to reduce cycle time.
    Reg#(Bit#(32)) cycle(0);
    Reg#(Bit#(32)) instrs(0);

    rule tick;
	$display("");//newline
        //////////////////////
        // Debugging Helper //
        //////////////////////
        cycle <= cycle + 1;
        // Uncomment the code below to print pipeline state each cycle
        begin
            $write("[%d] F|D|E|W PCs: ", cycle);
            $write("%x|", fetch.getPc);
            if (isValid(fetch.f2d)) $write("%x|", fromMaybe(?, fetch.f2d).pc); else $write("%8s|", "NOP");
            if (isValid(d2e)) $write("%x|", fromMaybe(?, d2e).pc); else $write("%8s|", "NOP");
            if (isValid(e2w)) $write("%x", fromMaybe(?, e2w).pc); else $write("%8s", "NOP");
            $display("  instrs: %d", instrs);
        end

        /////////////////////
        // Writeback Stage //
        /////////////////////
        // Signals used by decode to handle data hazards
        Maybe#(RIndx) dstW = Invalid;
        Word dataW = ?;

        // Signal for dCache-induced stalls
        Bool dStall = False;

        if (isValid(e2w)) begin
            let e2w_v = fromMaybe(?, e2w);
            //////////////////////////
            // TODO: //

	    dstW = e2w_v.dst;

        // Write to a register if the instruction requires it
	    if (e2w_v.iType == LOAD) begin // LOAD inst
		dStall = ! isValid(dCache.data);

		if (!dStall) begin
		    rf.wr = Valid(RegWriteArgs{index: fromMaybe(?, e2w_v.dst), data: fromMaybe(?, dCache.data)});
		end

	    end else if (isValid(e2w_v.dst) == False) begin // PASS WHEN DST DNE
		// do nothing

	    end else begin // general
	        rf.wr = Valid(RegWriteArgs{index: fromMaybe(?, e2w_v.dst), data: e2w_v.data});
	    end

            //////////////////////////

            // Count every instruction that leaves the writeback stage
            // (for debugging help)
            instrs <= instrs + 1;

            // BEGIN: DO NOT REMOVE OR MODIFY THIS CODE
            // If unsupported instruction, stops simulation and print the state of the processor
            if (e2w_v.iType == Unsupported) begin
                $display("Reached unsupported instruction");
                $display("Dumping the state of the processor");
                $display("pc = 0x%x", e2w_v.pc);
                $display(rf.fshow);
                $display("Quitting simulation.");
                $finish;
            end
            // END: DO NOT REMOVE OR MODIFY THIS CODE
        end
	

        ///////////////////
        // Execute Stage //
        ///////////////////
        // Signals used to handle mispredictions
        Bool annul = False;
        Word redirectPC = ?;


        // Signals used by decode to handle data hazards
        Maybe#(RIndx) dstE = Invalid;
        Maybe#(Word) dataE = Invalid;

	if (dStall) begin
        //pass

        end else 
	if (isValid(d2e)) begin
            let d2e_v = fromMaybe(?, d2e);
	    
            //////////////////////////
            // TODO: //	
            ExecInst eInst = execute(d2e_v.dInst, d2e_v.rVal1, d2e_v.rVal2, d2e_v.pc);

	    dstE = eInst.dst;
	    dataE = Valid(eInst.data);
	    
	    annul = eInst.nextPc != d2e_v.pc + 4;
	    redirectPC = eInst.nextPc;

		// do load/store

        if (eInst.iType == LOAD) begin
		dataE = Invalid;
		if (dCache.reqEnabled) begin 
		    dCache.req = Valid(MemReq{op: Ld, addr: d2e_v.rVal1 + d2e_v.dInst.imm, data: ?});
            	end else begin
		    dStall = True;
		end
	    end else if (eInst.iType == STORE) begin
		if (dCache.reqEnabled) begin
		    $display("EXE: doing STORE");
                    dCache.req = Valid(MemReq{op: St, addr: d2e_v.rVal1 + d2e_v.dInst.imm, data: d2e_v.rVal2});
		end else begin
		    dStall = True;
		end
	    end 

		
	    if (dStall) begin
		e2w <= Invalid;
	    end 
	    else  begin
		e2w <= Valid(E2W{pc: d2e_v.pc, iType: eInst.iType, dst: eInst.dst, data: eInst.data});
	    end		    
	end
            //////////////////////////
	
	else begin
        e2w <= Invalid;
    end

        //////////////////
        // Decode Stage //
        //////////////////
        // Signal for decode stalls
	Bool stall = False;
	Bool bypass = False;
	Word rs1 = ?; Word rs2 = ?;


	if (dStall) begin
        //pass
	end else if (isValid(fetch.f2d)) begin
        let f2d_v = fromMaybe(?, fetch.f2d);

        //////////////////////////
        // TODO: //
	    DecodedInst dInst = decode(f2d_v.inst);
	    
            if (annul) begin
                d2e <= Invalid;

            end else begin
		stall =  isValid(dstW) && ((dInst.src1 == fromMaybe(?, dstW)) || (dInst.src2 == fromMaybe(?, dstW))); 


		if (isValid(dstE) && (dInst.src1 == fromMaybe(?, dstE)) && (fromMaybe(?, dstE) != 0)) begin
		    if (isValid(dataE)) begin // bypass
			rs1 =  fromMaybe(?, dataE);
		    end else begin
			stall = True;
		    end
                end else begin
		    rs1 = rf.rd1(dInst.src1);
		end

		if (isValid(dstE) && (dInst.src2 == fromMaybe(?, dstE)) && (fromMaybe(?, dstE) != 0)) begin
            if (isValid(dataE)) begin // bypass
                rs2 =  fromMaybe(?, dataE);
            end else begin
                stall = True;
		    end
                end else begin
                    rs2 = rf.rd2(dInst.src2);
                end


		if (!stall) begin // proceed
            d2e <= Valid(D2E{pc: f2d_v.pc, dInst: dInst, rVal1: rs1, rVal2: rs2});
        end else begin // stall
            d2e <= Invalid; 
		end
	    end

            //////////////////////////
        end else begin
            d2e <= Invalid;
        end

        ///////////////////////
        // Drive fetch stage //
        ///////////////////////

        // TODO: Change to implement correct stall/annul behavior. You may find
        // it easier to set fetch.in from the decode stage.

        if (annul) begin
            fetch.in = FetchInput{fetchAction: Redirect, redirectPC: redirectPC};
        end else if (dStall) begin
            fetch.in = FetchInput{fetchAction: Stall, redirectPC: ?};
        end else begin
            if (!stall && isValid(fetch.f2d)) begin // proceed
                fetch.in = FetchInput{fetchAction: Dequeue, redirectPC: ?};
            end else begin // stall
                fetch.in = FetchInput{fetchAction: Stall, redirectPC: ?};
            end        
        end

	//end
    endrule

    // This method gives a non-trivial output that depends on execution so that
    // synth doesn't optimize out the whole processor :)
    method Word getPc = fetch.getPc;
endmodule

