import ProcTypes;

// ALU
// Imports your ALU from Lab 4
import ALU;

// Branch ALU
// BrFunc defined in ProcTypes.ms
function Bool aluBr(Word a, Word b, BrFunc brFunc);
    Bool res = case (brFunc)
        Eq:     (a == b);
        Neq:    (a != b);
        Lt:     signedLT(a, b); // Built-in signed comparison
        Ltu:    (a < b);
        Ge:     signedGE(a, b); // Built-in signed comparison
        Geu:    (a >= b);
        default: False;
    endcase;
    return res;
endfunction

// Execute function
// ExecInst defined in ProcTypes.ms
function ExecInst execute( DecodedInst dInst, Word rVal1, Word rVal2, Word pc );
    let imm = dInst.imm;
    let brFunc = dInst.brFunc;
    let aluFunc = dInst.aluFunc;
    let aluVal2 = dInst.iType == OPIMM ? imm : rVal2;

    // TODO: Compute the correct value for data. For OP, OPIMM, LUI, JAL, JALR,
    // and AUIPC, data should be the value that will be stored in the
    // destination register; we have done AUIPC for you. (Reminder that for LUI
    // and AUIPC, your decoder should already have shifted the immediate, so
    // you don't need to do that here.) For STORE, data should be the value
    // that will be written to memory.
    Word data = case (dInst.iType)
        AUIPC:     pc + imm;
        LUI:       imm; // TODO Replace 0 with the correct expression
        OP, OPIMM: alu(rVal1, aluVal2, aluFunc); // TODO Replace 0 with the correct expression
        JAL, JALR: pc + 4; // TODO Replace 0 with the correct expression
        STORE:     rVal2; // TODO Replace 0 with the correct expression
        default:   0;
    endcase;

    // TODO: Compute the correct value for nextPc, that is, the address of the
    // next instruction to execute. We have done JALR for you.
    Word nextPc = case (dInst.iType)
        BRANCH: (aluBr(rVal1, rVal2, brFunc)) ? pc + imm : pc + 4; // TODO Replace 0 with the correct expression
        JAL:    pc + imm; // TODO Replace 0 with the correct expression
        JALR: (rVal1 + imm) & ~1; // "& ~1" clears the bottom bit.
        default: pc + 4;
    endcase;

    // TODO: Compute the correct value for addr. This should be the memory
    // address that LW loads from or that SW stores to.
    Word addr = rVal1 + imm; // TODO Replace 0 with the correct expression

    return ExecInst{iType: dInst.iType, dst: dInst.dst, data: data, addr: addr, nextPc: nextPc};
endfunction
