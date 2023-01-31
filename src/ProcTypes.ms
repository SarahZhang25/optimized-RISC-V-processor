import ALU;
typedef Bit#(32) Word;

// ALU function enumeration is provided by imported ALU.ms

// Branch function enumeration
typedef enum {Eq, Neq, Lt, Ltu, Ge, Geu, Dbr} BrFunc;

// AUIPC added for this lab - Add Upper Immediate to PC
typedef enum {OP, OPIMM, BRANCH, LUI, JAL, JALR, LOAD, STORE, AUIPC, Unsupported} IType;

// Return type for Decode function
typedef struct {
    IType iType;
    AluFunc aluFunc;
    BrFunc brFunc;
    Maybe#(RIndx) dst;
    RIndx src1;
    RIndx src2;
    Word imm;
} DecodedInst;

// Register File
typedef Bit#(5) RIndx;

typedef struct {
    RIndx index;
    Word data;
} RegWriteArgs;

// Opcode
Bit#(7) opOpImm  = 7'b0010011;
Bit#(7) opOp     = 7'b0110011;
Bit#(7) opLui    = 7'b0110111;
Bit#(7) opJal    = 7'b1101111;
Bit#(7) opJalr   = 7'b1100111;
Bit#(7) opBranch = 7'b1100011;
Bit#(7) opLoad   = 7'b0000011;
Bit#(7) opStore  = 7'b0100011;
Bit#(7) opAuipc  = 7'b0010111;

// funct3 - ALU
Bit#(3) fnADD   = 3'b000;
Bit#(3) fnSLL   = 3'b001;
Bit#(3) fnSLT   = 3'b010;
Bit#(3) fnSLTU  = 3'b011;
Bit#(3) fnXOR   = 3'b100;
Bit#(3) fnSR    = 3'b101;
Bit#(3) fnOR    = 3'b110;
Bit#(3) fnAND   = 3'b111;
// funct3 - Branch
Bit#(3) fnBEQ   = 3'b000;
Bit#(3) fnBNE   = 3'b001;
Bit#(3) fnBLT   = 3'b100;
Bit#(3) fnBGE   = 3'b101;
Bit#(3) fnBLTU  = 3'b110;
Bit#(3) fnBGEU  = 3'b111;
// funct3 - Load
Bit#(3) fnLW    = 3'b010;
Bit#(3) fnLB    = 3'b000;
Bit#(3) fnLH    = 3'b001;
Bit#(3) fnLBU   = 3'b100;
Bit#(3) fnLHU   = 3'b101;
// funct3 - Store
Bit#(3) fnSW    = 3'b010;
Bit#(3) fnSB    = 3'b000;
Bit#(3) fnSH    = 3'b001;
// funct3 - JALR
Bit#(3) fnJALR  = 3'b000;

// Return type for Execute function
typedef struct {
    IType iType;
    Maybe#(RIndx) dst;
    Word data;
    Word addr;
    Word nextPc;
} ExecInst;

// Memory writes
typedef struct {
    Word addr;
    Word data;
} MemWriteReq;
