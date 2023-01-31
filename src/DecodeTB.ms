import ProcTypes;
import Decode;
import ALU;

typedef struct {
    Bit#(32) word;
    IType iType;
    Maybe#(AluFunc) aluFunc;
    Maybe#(BrFunc) brFunc;
    Maybe#(Maybe#(RIndx)) dst;
    Maybe#(RIndx) src1;
    Maybe#(RIndx) src2;
    Maybe#(Word) imm;
} DecodedInstSpec;

/*
Vector#(10, DecodedInstSpec) tests = {
endfunction
};
*/

function Maybe#(Maybe#(RIndx)) vDst(Bit#(5) index) = Valid(Valid(index));

Maybe#(Maybe#(RIndx)) noDst = Valid(Invalid);

Vector#(106, DecodedInstSpec) tests =
    cons(DecodedInstSpec { word: 32'hc0001073, iType: Unsupported, aluFunc: Invalid    , brFunc: Invalid,    dst: Invalid , src1: Invalid  , src2: Invalid  , imm: Invalid           },
    cons(DecodedInstSpec { word: 32'h00000000, iType: Unsupported, aluFunc: Invalid    , brFunc: Invalid,    dst: Invalid , src1: Invalid  , src2: Invalid  , imm: Invalid           },
    cons(DecodedInstSpec { word: 32'hdb8d9ce7, iType: Unsupported, aluFunc: Invalid    , brFunc: Invalid,    dst: Invalid , src1: Invalid  , src2: Invalid  , imm: Invalid           },
    cons(DecodedInstSpec { word: 32'haaaaaaaa, iType: Unsupported, aluFunc: Invalid    , brFunc: Invalid,    dst: Invalid , src1: Invalid  , src2: Invalid  , imm: Invalid           },
    cons(DecodedInstSpec { word: 32'h80000033, iType: Unsupported, aluFunc: Invalid    , brFunc: Invalid,    dst: Invalid , src1: Invalid  , src2: Invalid  , imm: Invalid           },
    cons(DecodedInstSpec { word: 32'h00002063, iType: Unsupported, aluFunc: Invalid    , brFunc: Invalid,    dst: Invalid , src1: Invalid  , src2: Invalid  , imm: Invalid           },
    cons(DecodedInstSpec { word: 32'h00000083, iType: Unsupported, aluFunc: Invalid    , brFunc: Invalid,    dst: Invalid , src1: Invalid  , src2: Invalid  , imm: Invalid           },
    cons(DecodedInstSpec { word: 32'h00006023, iType: Unsupported, aluFunc: Invalid    , brFunc: Invalid,    dst: Invalid , src1: Invalid  , src2: Invalid  , imm: Invalid           },
    cons(DecodedInstSpec { word: 32'h40109093, iType: Unsupported, aluFunc: Invalid    , brFunc: Invalid,    dst: Invalid , src1: Invalid  , src2: Invalid  , imm: Invalid           },
    cons(DecodedInstSpec { word: 32'h8010d093, iType: Unsupported, aluFunc: Invalid    , brFunc: Invalid,    dst: Invalid , src1: Invalid  , src2: Invalid  , imm: Invalid           },
    cons(DecodedInstSpec { word: 32'h801080b3, iType: Unsupported, aluFunc: Invalid    , brFunc: Invalid,    dst: Invalid , src1: Invalid  , src2: Invalid  , imm: Invalid           }, // Test for invalid funct7 bits
    cons(DecodedInstSpec { word: 32'h801090b3, iType: Unsupported, aluFunc: Invalid    , brFunc: Invalid,    dst: Invalid , src1: Invalid  , src2: Invalid  , imm: Invalid           }, // Test for invalid funct7 bits
    cons(DecodedInstSpec { word: 32'h8010a0b3, iType: Unsupported, aluFunc: Invalid    , brFunc: Invalid,    dst: Invalid , src1: Invalid  , src2: Invalid  , imm: Invalid           }, // Test for invalid funct7 bits
    cons(DecodedInstSpec { word: 32'h8010b0b3, iType: Unsupported, aluFunc: Invalid    , brFunc: Invalid,    dst: Invalid , src1: Invalid  , src2: Invalid  , imm: Invalid           }, // Test for invalid funct7 bits
    cons(DecodedInstSpec { word: 32'h8010c0b3, iType: Unsupported, aluFunc: Invalid    , brFunc: Invalid,    dst: Invalid , src1: Invalid  , src2: Invalid  , imm: Invalid           }, // Test for invalid funct7 bits
    cons(DecodedInstSpec { word: 32'h8010d0b3, iType: Unsupported, aluFunc: Invalid    , brFunc: Invalid,    dst: Invalid , src1: Invalid  , src2: Invalid  , imm: Invalid           }, // Test for invalid funct7 bits
    cons(DecodedInstSpec { word: 32'h8010e0b3, iType: Unsupported, aluFunc: Invalid    , brFunc: Invalid,    dst: Invalid , src1: Invalid  , src2: Invalid  , imm: Invalid           }, // Test for invalid funct7 bits
    cons(DecodedInstSpec { word: 32'h8010f0b3, iType: Unsupported, aluFunc: Invalid    , brFunc: Invalid,    dst: Invalid , src1: Invalid  , src2: Invalid  , imm: Invalid           }, // Test for invalid funct7 bits
    cons(DecodedInstSpec { word: 32'h401171b3, iType: Unsupported, aluFunc: Invalid    , brFunc: Invalid,    dst: Invalid , src1: Invalid  , src2: Invalid  , imm: Invalid           }, // Test for invalid funct3 bits
    cons(DecodedInstSpec { word: 32'h000010b7, iType: LUI        , aluFunc: Invalid    , brFunc: Invalid,    dst: vDst( 1), src1: Invalid  , src2: Invalid  , imm: Valid('h00001000) },
    cons(DecodedInstSpec { word: 32'h00001137, iType: LUI        , aluFunc: Invalid    , brFunc: Invalid,    dst: vDst( 2), src1: Invalid  , src2: Invalid  , imm: Valid('h00001000) },
    cons(DecodedInstSpec { word: 32'h000011b7, iType: LUI        , aluFunc: Invalid    , brFunc: Invalid,    dst: vDst( 3), src1: Invalid  , src2: Invalid  , imm: Valid('h00001000) },
    cons(DecodedInstSpec { word: 32'h00001fb7, iType: LUI        , aluFunc: Invalid    , brFunc: Invalid,    dst: vDst(31), src1: Invalid  , src2: Invalid  , imm: Valid('h00001000) },
    cons(DecodedInstSpec { word: 32'h123450b7, iType: LUI        , aluFunc: Invalid    , brFunc: Invalid,    dst: vDst( 1), src1: Invalid  , src2: Invalid  , imm: Valid('h12345000) },
    cons(DecodedInstSpec { word: 32'habcde0b7, iType: LUI        , aluFunc: Invalid    , brFunc: Invalid,    dst: vDst( 1), src1: Invalid  , src2: Invalid  , imm: Valid('habcde000) },
    cons(DecodedInstSpec { word: 32'h7ffff2b7, iType: LUI        , aluFunc: Invalid    , brFunc: Invalid,    dst: vDst( 5), src1: Invalid  , src2: Invalid  , imm: Valid('h7ffff000) },
    cons(DecodedInstSpec { word: 32'hfffff3b7, iType: LUI        , aluFunc: Invalid    , brFunc: Invalid,    dst: vDst( 7), src1: Invalid  , src2: Invalid  , imm: Valid('hfffff000) },
    cons(DecodedInstSpec { word: 32'h00100093, iType: OPIMM      , aluFunc: Valid(Add ), brFunc: Invalid,    dst: vDst( 1), src1: Valid( 0), src2: Invalid  , imm: Valid(1)          },
    cons(DecodedInstSpec { word: 32'hffe00513, iType: OPIMM      , aluFunc: Valid(Add ), brFunc: Invalid,    dst: vDst(10), src1: Valid( 0), src2: Invalid  , imm: Valid(-2)         },
    cons(DecodedInstSpec { word: 32'h12308093, iType: OPIMM      , aluFunc: Valid(Add ), brFunc: Invalid,    dst: vDst( 1), src1: Valid( 1), src2: Invalid  , imm: Valid('h00000123) },
    cons(DecodedInstSpec { word: 32'h28190d93, iType: OPIMM      , aluFunc: Valid(Add ), brFunc: Invalid,    dst: vDst(27), src1: Valid(18), src2: Invalid  , imm: Valid('h00000281) },
    cons(DecodedInstSpec { word: 32'h4561f113, iType: OPIMM      , aluFunc: Valid(And ), brFunc: Invalid,    dst: vDst( 2), src1: Valid( 3), src2: Invalid  , imm: Valid('h00000456) },
    cons(DecodedInstSpec { word: 32'hf5517193, iType: OPIMM      , aluFunc: Valid(And ), brFunc: Invalid,    dst: vDst( 3), src1: Valid( 2), src2: Invalid  , imm: Valid('hffffff55) },
    cons(DecodedInstSpec { word: 32'h0f01e213, iType: OPIMM      , aluFunc: Valid(Or  ), brFunc: Invalid,    dst: vDst( 4), src1: Valid( 3), src2: Invalid  , imm: Valid('h000000f0) },
    cons(DecodedInstSpec { word: 32'h7892e213, iType: OPIMM      , aluFunc: Valid(Or  ), brFunc: Invalid,    dst: vDst( 4), src1: Valid( 5), src2: Invalid  , imm: Valid('h00000789) },
    cons(DecodedInstSpec { word: 32'h0cd24293, iType: OPIMM      , aluFunc: Valid(Xor ), brFunc: Invalid,    dst: vDst( 5), src1: Valid( 4), src2: Invalid  , imm: Valid('h000000cd) },
    cons(DecodedInstSpec { word: 32'habc3c313, iType: OPIMM      , aluFunc: Valid(Xor ), brFunc: Invalid,    dst: vDst( 6), src1: Valid( 7), src2: Invalid  , imm: Valid('hfffffabc) },
    cons(DecodedInstSpec { word: 32'h00329313, iType: OPIMM      , aluFunc: Valid(Sll ), brFunc: Invalid,    dst: vDst( 6), src1: Valid( 5), src2: Invalid  , imm: Valid(3)          },
    cons(DecodedInstSpec { word: 32'h01d49413, iType: OPIMM      , aluFunc: Valid(Sll ), brFunc: Invalid,    dst: vDst( 8), src1: Valid( 9), src2: Invalid  , imm: Valid('h1d)       },
    cons(DecodedInstSpec { word: 32'h41f6d613, iType: OPIMM      , aluFunc: Valid(Sra ), brFunc: Invalid,    dst: vDst(12), src1: Valid(13), src2: Invalid  , imm: Valid('h1f)       },
    cons(DecodedInstSpec { word: 32'h40435393, iType: OPIMM      , aluFunc: Valid(Sra ), brFunc: Invalid,    dst: vDst( 7), src1: Valid( 6), src2: Invalid  , imm: Valid(4)          },
    cons(DecodedInstSpec { word: 32'h01e5d513, iType: OPIMM      , aluFunc: Valid(Srl ), brFunc: Invalid,    dst: vDst(10), src1: Valid(11), src2: Invalid  , imm: Valid('h1e)       },
    cons(DecodedInstSpec { word: 32'h0053d413, iType: OPIMM      , aluFunc: Valid(Srl ), brFunc: Invalid,    dst: vDst( 8), src1: Valid( 7), src2: Invalid  , imm: Valid(5)          },
    cons(DecodedInstSpec { word: 32'h0003a493, iType: OPIMM      , aluFunc: Valid(Slt ), brFunc: Invalid,    dst: vDst( 9), src1: Valid( 7), src2: Invalid  , imm: Valid(0)          },
    cons(DecodedInstSpec { word: 32'h9ab92893, iType: OPIMM      , aluFunc: Valid(Slt ), brFunc: Invalid,    dst: vDst(17), src1: Valid(18), src2: Invalid  , imm: Valid('hfffff9ab) },
    cons(DecodedInstSpec { word: 32'h0003b513, iType: OPIMM      , aluFunc: Valid(Sltu), brFunc: Invalid,    dst: vDst(10), src1: Valid( 7), src2: Invalid  , imm: Valid(0)          },
    cons(DecodedInstSpec { word: 32'hcdea3993, iType: OPIMM      , aluFunc: Valid(Sltu), brFunc: Invalid,    dst: vDst(19), src1: Valid(20), src2: Invalid  , imm: Valid('hfffffcde) },
    cons(DecodedInstSpec { word: 32'h00008133, iType: OP         , aluFunc: Valid(Add ), brFunc: Invalid,    dst: vDst( 2), src1: Valid( 1), src2: Valid( 0), imm: Invalid           },
    cons(DecodedInstSpec { word: 32'h00428333, iType: OP         , aluFunc: Valid(Add ), brFunc: Invalid,    dst: vDst( 6), src1: Valid( 5), src2: Valid( 4), imm: Invalid           },
    cons(DecodedInstSpec { word: 32'h01df0fb3, iType: OP         , aluFunc: Valid(Add ), brFunc: Invalid,    dst: vDst(31), src1: Valid(30), src2: Valid(29), imm: Invalid           },
    cons(DecodedInstSpec { word: 32'h40208233, iType: OP         , aluFunc: Valid(Sub ), brFunc: Invalid,    dst: vDst( 4), src1: Valid( 1), src2: Valid( 2), imm: Invalid           },
    cons(DecodedInstSpec { word: 32'h41ce8f33, iType: OP         , aluFunc: Valid(Sub ), brFunc: Invalid,    dst: vDst(30), src1: Valid(29), src2: Valid(28), imm: Invalid           },
    cons(DecodedInstSpec { word: 32'h0020a2b3, iType: OP         , aluFunc: Valid(Slt ), brFunc: Invalid,    dst: vDst( 5), src1: Valid( 1), src2: Valid( 2), imm: Invalid           },
    cons(DecodedInstSpec { word: 32'h015b2bb3, iType: OP         , aluFunc: Valid(Slt ), brFunc: Invalid,    dst: vDst(23), src1: Valid(22), src2: Valid(21), imm: Invalid           },
    cons(DecodedInstSpec { word: 32'h0020b333, iType: OP         , aluFunc: Valid(Sltu), brFunc: Invalid,    dst: vDst( 6), src1: Valid( 1), src2: Valid( 2), imm: Invalid           },
    cons(DecodedInstSpec { word: 32'h014abb33, iType: OP         , aluFunc: Valid(Sltu), brFunc: Invalid,    dst: vDst(22), src1: Valid(21), src2: Valid(20), imm: Invalid           },
    cons(DecodedInstSpec { word: 32'h002094b3, iType: OP         , aluFunc: Valid(Sll ), brFunc: Invalid,    dst: vDst( 9), src1: Valid( 1), src2: Valid( 2), imm: Invalid           },
    cons(DecodedInstSpec { word: 32'h018c9d33, iType: OP         , aluFunc: Valid(Sll ), brFunc: Invalid,    dst: vDst(26), src1: Valid(25), src2: Valid(24), imm: Invalid           },
    cons(DecodedInstSpec { word: 32'h0020d533, iType: OP         , aluFunc: Valid(Srl ), brFunc: Invalid,    dst: vDst(10), src1: Valid( 1), src2: Valid( 2), imm: Invalid           },
    cons(DecodedInstSpec { word: 32'h017c5cb3, iType: OP         , aluFunc: Valid(Srl ), brFunc: Invalid,    dst: vDst(25), src1: Valid(24), src2: Valid(23), imm: Invalid           },
    cons(DecodedInstSpec { word: 32'h4020d5b3, iType: OP         , aluFunc: Valid(Sra ), brFunc: Invalid,    dst: vDst(11), src1: Valid( 1), src2: Valid( 2), imm: Invalid           },
    cons(DecodedInstSpec { word: 32'h416bdc33, iType: OP         , aluFunc: Valid(Sra ), brFunc: Invalid,    dst: vDst(24), src1: Valid(23), src2: Valid(22), imm: Invalid           },
    cons(DecodedInstSpec { word: 32'h0020f633, iType: OP         , aluFunc: Valid(And ), brFunc: Invalid,    dst: vDst(12), src1: Valid( 1), src2: Valid( 2), imm: Invalid           },
    cons(DecodedInstSpec { word: 32'h01be7eb3, iType: OP         , aluFunc: Valid(And ), brFunc: Invalid,    dst: vDst(29), src1: Valid(28), src2: Valid(27), imm: Invalid           },
    cons(DecodedInstSpec { word: 32'h0020e6b3, iType: OP         , aluFunc: Valid(Or  ), brFunc: Invalid,    dst: vDst(13), src1: Valid( 1), src2: Valid( 2), imm: Invalid           },
    cons(DecodedInstSpec { word: 32'h01adee33, iType: OP         , aluFunc: Valid(Or  ), brFunc: Invalid,    dst: vDst(28), src1: Valid(27), src2: Valid(26), imm: Invalid           },
    cons(DecodedInstSpec { word: 32'h0020c733, iType: OP         , aluFunc: Valid(Xor ), brFunc: Invalid,    dst: vDst(14), src1: Valid( 1), src2: Valid( 2), imm: Invalid           },
    cons(DecodedInstSpec { word: 32'h019d4db3, iType: OP         , aluFunc: Valid(Xor ), brFunc: Invalid,    dst: vDst(27), src1: Valid(26), src2: Valid(25), imm: Invalid           },
    cons(DecodedInstSpec { word: 32'h0e208663, iType: BRANCH     , aluFunc: Invalid    , brFunc: Valid(Eq ), dst: noDst   , src1: Valid( 1), src2: Valid( 2), imm: Valid('hec)       },
    cons(DecodedInstSpec { word: 32'h01288c63, iType: BRANCH     , aluFunc: Invalid    , brFunc: Valid(Eq ), dst: noDst   , src1: Valid(17), src2: Valid(18), imm: Valid(  24)       },
    cons(DecodedInstSpec { word: 32'hff180ee3, iType: BRANCH     , aluFunc: Invalid    , brFunc: Valid(Eq ), dst: noDst   , src1: Valid(16), src2: Valid(17), imm: Valid(  -4)       },
    cons(DecodedInstSpec { word: 32'hfe009ce3, iType: BRANCH     , aluFunc: Invalid    , brFunc: Valid(Neq), dst: noDst   , src1: Valid( 1), src2: Valid( 0), imm: Valid(  -8)       },
    cons(DecodedInstSpec { word: 32'h01499a63, iType: BRANCH     , aluFunc: Invalid    , brFunc: Valid(Neq), dst: noDst   , src1: Valid(19), src2: Valid(20), imm: Valid(  20)       },
    cons(DecodedInstSpec { word: 32'hff391ce3, iType: BRANCH     , aluFunc: Invalid    , brFunc: Valid(Neq), dst: noDst   , src1: Valid(18), src2: Valid(19), imm: Valid(  -8)       },
    cons(DecodedInstSpec { word: 32'h0e10c263, iType: BRANCH     , aluFunc: Invalid    , brFunc: Valid(Lt ), dst: noDst   , src1: Valid( 1), src2: Valid( 1), imm: Valid('he4)       },
    cons(DecodedInstSpec { word: 32'h016ac863, iType: BRANCH     , aluFunc: Invalid    , brFunc: Valid(Lt ), dst: noDst   , src1: Valid(21), src2: Valid(22), imm: Valid(  16)       },
    cons(DecodedInstSpec { word: 32'hff5a4ae3, iType: BRANCH     , aluFunc: Invalid    , brFunc: Valid(Lt ), dst: noDst   , src1: Valid(20), src2: Valid(21), imm: Valid( -12)       },
    cons(DecodedInstSpec { word: 32'h0c20d663, iType: BRANCH     , aluFunc: Invalid    , brFunc: Valid(Ge ), dst: noDst   , src1: Valid( 1), src2: Valid( 2), imm: Valid('hcc)       },
    cons(DecodedInstSpec { word: 32'h018bd663, iType: BRANCH     , aluFunc: Invalid    , brFunc: Valid(Ge ), dst: noDst   , src1: Valid(23), src2: Valid(24), imm: Valid(  12)       },
    cons(DecodedInstSpec { word: 32'hff7b58e3, iType: BRANCH     , aluFunc: Invalid    , brFunc: Valid(Ge ), dst: noDst   , src1: Valid(22), src2: Valid(23), imm: Valid( -16)       },
    cons(DecodedInstSpec { word: 32'h0a10ee63, iType: BRANCH     , aluFunc: Invalid    , brFunc: Valid(Ltu), dst: noDst   , src1: Valid( 1), src2: Valid( 1), imm: Valid('hbc)       },
    cons(DecodedInstSpec { word: 32'h01ace463, iType: BRANCH     , aluFunc: Invalid    , brFunc: Valid(Ltu), dst: noDst   , src1: Valid(25), src2: Valid(26), imm: Valid(   8)       },
    cons(DecodedInstSpec { word: 32'hff9c66e3, iType: BRANCH     , aluFunc: Invalid    , brFunc: Valid(Ltu), dst: noDst   , src1: Valid(24), src2: Valid(25), imm: Valid( -20)       },
    cons(DecodedInstSpec { word: 32'h0a20f263, iType: BRANCH     , aluFunc: Invalid    , brFunc: Valid(Geu), dst: noDst   , src1: Valid( 1), src2: Valid( 2), imm: Valid('ha4)       },
    cons(DecodedInstSpec { word: 32'hffbd74e3, iType: BRANCH     , aluFunc: Invalid    , brFunc: Valid(Geu), dst: noDst   , src1: Valid(26), src2: Valid(27), imm: Valid( -24)       },
    cons(DecodedInstSpec { word: 32'h01cdf263, iType: BRANCH     , aluFunc: Invalid    , brFunc: Valid(Geu), dst: noDst   , src1: Valid(27), src2: Valid(28), imm: Valid(   4)       },
    cons(DecodedInstSpec { word: 32'h008000ef, iType: JAL        , aluFunc: Invalid    , brFunc: Invalid,    dst: vDst( 1), src1: Invalid  , src2: Invalid  , imm: Valid( 8)         },
    cons(DecodedInstSpec { word: 32'hffdfffef, iType: JAL        , aluFunc: Invalid    , brFunc: Invalid,    dst: vDst(31), src1: Invalid  , src2: Invalid  , imm: Valid(-4)         },
    cons(DecodedInstSpec { word: 32'hff9ff8ef, iType: JAL        , aluFunc: Invalid    , brFunc: Invalid,    dst: vDst(17), src1: Invalid  , src2: Invalid  , imm: Valid(-8)         },
    cons(DecodedInstSpec { word: 32'h008008ef, iType: JAL        , aluFunc: Invalid    , brFunc: Invalid,    dst: vDst(17), src1: Invalid  , src2: Invalid  , imm: Valid( 8)         },
    cons(DecodedInstSpec { word: 32'h00400fef, iType: JAL        , aluFunc: Invalid    , brFunc: Invalid,    dst: vDst(31), src1: Invalid  , src2: Invalid  , imm: Valid( 4)         },
    cons(DecodedInstSpec { word: 32'h00001097, iType: AUIPC      , aluFunc: Invalid    , brFunc: Invalid,    dst: vDst( 1), src1: Invalid  , src2: Invalid  , imm: Valid('h00001000) },
    cons(DecodedInstSpec { word: 32'hfffff197, iType: AUIPC      , aluFunc: Invalid    , brFunc: Invalid,    dst: vDst( 3), src1: Invalid  , src2: Invalid  , imm: Valid('hfffff000) },
    cons(DecodedInstSpec { word: 32'h12345b17, iType: AUIPC      , aluFunc: Invalid    , brFunc: Invalid,    dst: vDst(22), src1: Invalid  , src2: Invalid  , imm: Valid('h12345000) },
    cons(DecodedInstSpec { word: 32'habcdeb97, iType: AUIPC      , aluFunc: Invalid    , brFunc: Invalid,    dst: vDst(23), src1: Invalid  , src2: Invalid  , imm: Valid('habcde000) },
    cons(DecodedInstSpec { word: 32'h0000a103, iType: LOAD       , aluFunc: Invalid    , brFunc: Invalid,    dst: vDst( 2), src1: Valid( 1), src2: Invalid  , imm: Valid(0)          },
    cons(DecodedInstSpec { word: 32'h00c0a283, iType: LOAD       , aluFunc: Invalid    , brFunc: Invalid,    dst: vDst( 5), src1: Valid( 1), src2: Invalid  , imm: Valid(12)         },
    cons(DecodedInstSpec { word: 32'hff40a403, iType: LOAD       , aluFunc: Invalid    , brFunc: Invalid,    dst: vDst( 8), src1: Valid( 1), src2: Invalid  , imm: Valid(-12)        },
    cons(DecodedInstSpec { word: 32'h7f052583, iType: LOAD       , aluFunc: Invalid    , brFunc: Invalid,    dst: vDst(11), src1: Valid(10), src2: Invalid  , imm: Valid(2032)       },
    cons(DecodedInstSpec { word: 32'h0020a023, iType: STORE      , aluFunc: Invalid    , brFunc: Invalid,    dst: noDst   , src1: Valid( 1), src2: Valid( 2), imm: Valid(0)          },
    cons(DecodedInstSpec { word: 32'hfe20ae23, iType: STORE      , aluFunc: Invalid    , brFunc: Invalid,    dst: noDst   , src1: Valid( 1), src2: Valid( 2), imm: Valid(-4)         },
    cons(DecodedInstSpec { word: 32'h7e21a823, iType: STORE      , aluFunc: Invalid    , brFunc: Invalid,    dst: noDst   , src1: Valid( 3), src2: Valid( 2), imm: Valid(2032)       },
    cons(DecodedInstSpec { word: 32'h00008167, iType: JALR       , aluFunc: Invalid    , brFunc: Invalid,    dst: vDst( 2), src1: Valid( 1), src2: Invalid  , imm: Valid(0)          },
    cons(DecodedInstSpec { word: 32'h99210767, iType: JALR       , aluFunc: Invalid    , brFunc: Invalid,    dst: vDst(14), src1: Valid( 2), src2: Invalid  , imm: Valid(-1646)      },
    cons(DecodedInstSpec { word: 32'h248d0c67, iType: JALR       , aluFunc: Invalid    , brFunc: Invalid,    dst: vDst(24), src1: Valid(26), src2: Invalid  , imm: Valid(584)        },
    cons(DecodedInstSpec { word: 32'hdb8d8ce7, iType: JALR       , aluFunc: Invalid    , brFunc: Invalid,    dst: vDst(25), src1: Valid(27), src2: Invalid  , imm: Valid(-584)       },
    nil))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))));

module DecodeTB;
    Reg#(Bit#(9)) cycle(0);
    Reg#(IType) lastIType(Unsupported);
    Reg#(Bit#(9)) iTypeCount(0);
    rule test;
        if (cycle == 106) begin
            $display("Passed decoding %d tests of iType ", iTypeCount, fshow(lastIType));
            $display("PASSED");
            $finish;
        end

        DecodedInstSpec spec = tests[cycle];
        DecodedInst d = decode(spec.word);

        // Print message after testing one particular iType
        if (lastIType != spec.iType) begin
            $display("Passed decoding %d tests of iType ", iTypeCount, fshow(lastIType));
        end


        if (spec.iType == Unsupported) begin
            // If the iType is Unsupported, we do not want to enforce restrictions on any other fields
            if (d.iType != Unsupported) begin
                if (d.iType == OP || d.iType == OPIMM || d.iType == LOAD || d.iType == STORE) begin
                    // Special case to catch the common mistake of forgetting to check for valid funct7 bits.
                    $display("Make sure you are checking for valid funct3 and/or funct7 bits in the relevant OP/OPIMM/LOAD/STORE iTypes!");
                end
                $display("FAILED: decode(0x%x) iType was ", spec.word, fshow(d.iType), ", should be ", fshow(spec.iType));
                $finish;
            end
        end else begin

            if (spec.iType != d.iType) begin
                $display("FAILED: decode(0x%x) iType was ", spec.word, fshow(d.iType), ", should be ", fshow(spec.iType));
                $finish;
            end
            if (isValid(spec.aluFunc) && fromMaybe(?, spec.aluFunc) != d.aluFunc) begin
                $display("FAILED: decode(0x%x) aluFunc was ", spec.word, fshow(d.aluFunc), ", should be ", fshow(fromMaybe(?, spec.aluFunc)));
                $finish;
            end
            if (isValid(spec.brFunc) && fromMaybe(?, spec.brFunc) != d.brFunc) begin
                $display("FAILED: decode(0x%x) brFunc was ", spec.word, fshow(d.brFunc), ", should be ", fshow(fromMaybe(?, spec.brFunc)));
                $finish;
            end
            // handle specially because if valid is False, index mismatch is not an error
            if (isValid(spec.dst)) begin
                Maybe#(RIndx) sDst = fromMaybe(?, spec.dst);
                if (isValid(sDst) != isValid(d.dst) || (isValid(sDst) && fromMaybe(?, sDst) != fromMaybe(?, d.dst))) begin
                    $display("FAILED: decode(0x%x) dst was ", spec.word, fshow(d.dst), ", should be ", fshow(fromMaybe(?, spec.dst)));
                    $finish;
                end
            end
            if (isValid(spec.src1) && fromMaybe(?, spec.src1) != d.src1) begin
                $display("FAILED: decode(0x%x) src1 was ", spec.word, fshow(d.src1), ", should be ", fshow(fromMaybe(?, spec.src1)));
                $finish;
            end
            if (isValid(spec.src2) && fromMaybe(?, spec.src2) != d.src2) begin
                $display("FAILED: decode(0x%x) src2 was ", spec.word, fshow(d.src2), ", should be ", fshow(fromMaybe(?, spec.src2)));
                $finish;
            end
            // handle specially: if we're shifting by the immediate, only the last 5 bits should match
            // and reasonable processors can produce spurious higher bits
            if (isValid(spec.imm)) begin
                Bool isShift = spec.aluFunc == Valid(Sll) || spec.aluFunc == Valid(Srl) || spec.aluFunc == Valid(Sra);
                if ((isShift ? (fromMaybe(?, spec.imm)[4:0] != d.imm[4:0]) : (fromMaybe(?, spec.imm) != d.imm))) begin
                    $display("FAILED: decode(0x%x) imm was ", spec.word, fshow(d.imm), ", should be ", fshow(fromMaybe(?, spec.imm)));
                    $finish;
                end
            end
        end

        // $display("PASSED decoding 0x%x as ", spec.word, fshow(spec.iType));

        cycle <= cycle + 1;
        if (lastIType == spec.iType) begin
            iTypeCount <= iTypeCount + 1;
        end else begin
            iTypeCount <= 1;
        end
        lastIType <= spec.iType;
    endrule
endmodule
