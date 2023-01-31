// BSV glue code for single-ported, non-loaded/loaded BRAM memories
import BRAMCore::*;

typedef BRAM_PORT#(Bit#(addrSz), dataT) SRAMArray#(numeric type addrSz, type dataT);

module mkSRAMArray(SRAMArray#(addrSz, dataT) ) provisos (Bits#(dataT, dataSz));
    Integer memSz = valueOf(TExp#(addrSz));
    Bool hasOutputRegister = False;
    BRAM_PORT#(Bit#(addrSz), dataT) bram <- mkBRAMCore1(memSz, hasOutputRegister);
    return bram;
endmodule

typedef BRAM_PORT#(Bit#(addrSz), dataT) SRAMArrayLoad#(numeric type addrSz, type dataT);

module mkSRAMArrayLoad#(String file)(SRAMArrayLoad#(addrSz, dataT)) provisos (Bits#(dataT, dataSz));
    Integer memSz = valueOf(TExp#(addrSz));
    Bool hasOutputRegister = False;
    BRAM_PORT#(Bit#(addrSz), dataT) bram <- mkBRAMCore1Load(memSz, hasOutputRegister, file, False);
    return bram;
endmodule
