import FIFO::*;
import FIFOF::*;

typedef FIFOF#(dataT) Queue#(type dataT);

module mkQueue#(Integer n)(Queue#(dataT)) provisos (Bits#(dataT, dataSz));
    FIFOF#(dataT) fifo <- mkUGSizedFIFOF(n);
    return fifo;
endmodule

