bsvimport SRAMArray;
bsvimport BRAMCore;

typedef struct {
    Bit#(addrSz) addr;
    Bool write;
    DataT data;
} SRAMReq#(Integer addrSz, type DataT);

module SRAM#(Integer addrSz, type DataT);
    SRAMArray#(addrSz, DataT) array;  // BSV array
    Reg#(Bool) arrayHasData(False);

    input Maybe#(SRAMReq#(addrSz, DataT)) req default = Invalid;

    rule tick;
        if (isValid(req)) begin
            let r = fromMaybe(?, req);
            array.put(r.write, r.addr, r.data);
            arrayHasData <= !r.write;
        end else arrayHasData <= False;
    endrule

    method Maybe#(DataT) data = arrayHasData? Valid(array.read) : Invalid;
endmodule

module SRAMLoad#(Integer addrSz, type DataT)(String file);
    SRAMArrayLoad#(addrSz, DataT) array(file);  // BSV array
    Reg#(Bool) arrayHasData(False);

    input Maybe#(SRAMReq#(addrSz, DataT)) req default = Invalid;

    rule tick;
        if (isValid(req)) begin
            let r = fromMaybe(?, req);
            array.put(r.write, r.addr, r.data);
            arrayHasData <= !r.write;
        end else arrayHasData <= False;
    endrule

    method Maybe#(DataT) data = arrayHasData? Valid(array.read) : Invalid;
endmodule
