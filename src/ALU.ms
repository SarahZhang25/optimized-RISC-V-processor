// Don't change signature of existing functions. You may write additional helper functions if you want.


// Description: 32-bit right barrel shifter
// Arguments: in (value to be shifted); sftSz (shift size); sft_in (the bit shifted in)
// Return: {sft_in's, in[31:sftSz]}
function Bit#(32) barrelRShift(Bit#(32) in, Bit#(5) sftSz, Bit#(1) sft_in);
    Bit #(32) ret = in;
    for (Integer i=4; i>=0; i = i - 1) begin
        Integer  amt_to_extend = 2**(i);
	Bit#(amt_to_extend) extension = signExtend(sft_in);
	ret = (sftSz[i] == 0) ? ret : {extension, ret[31: amt_to_extend ]};
    end
    return ret;
endfunction

// Description: 32-bit arithmetic/logic right shifter
// Arguments: in (value to be shifted); sftSz (shift size); arith (1 = arithmetic, 0 = logic)
// Return: in >> sftSz
function Bit#(32) sr32(Bit#(32) in, Bit#(5) sftSz, Bit#(1) arith);
    Bit#(1) sft_in = (arith == 0) ? 0 : in[31];
    return barrelRShift(in, sftSz, sft_in); 

endfunction


// Description: 32-bit logic left shifter
// Arguments: in (values to be shifted); sftSz (shift size)
// Return: a << b
function Bit#(32) sll32(Bit#(32) in, Bit#(5) sftSz);
    Bit #(32) ret = reverseBits(in);
    ret = barrelRShift(ret, sftSz, 0);
    return reverseBits(ret);
endfunction


// Description: 32-bit FULL shifter
// Arguments: in (value to be shifted); sftSz (shift size);
// ShiftTypes:
// LogicalRightShift
// ArithmeticRightShift
// LeftShift
//
// Return: in >> sftSz when right shift; in << sftSz otherwise
typedef enum {LogicalRightShift, ArithmeticRightShift, LeftShift} ShiftType;

function Bit#(32) sft32(Bit#(32) in, Bit#(5) sftSz, ShiftType shiftType);
    in = (shiftType == LeftShift) ? reverseBits(in) : in;
    Bit#(1) sft_in = (shiftType == ArithmeticRightShift) ? in[31] : 0;
    Bit#(32) ret = barrelRShift(in, sftSz, sft_in);
    if (shiftType == LeftShift) ret = reverseBits(ret); 
    return ret;
endfunction



// Description: one-bit less-than comparator
// Arguments: a, b (1-bit values), eq, lt (eq and lt from previous comparator)
// Return: {eq_i, lt_i}
function Bit#(2) cmp(Bit#(1) a, Bit#(1) b, Bit#(1) eq, Bit#(1) lt);
    Bit#(2) ret = 2'b00;
    if (1'b1 == (eq & ~lt & ((a & b) | (~a & ~b)))) ret[1] = 1; // true condition for eq
    if (1'b1 == ((~eq & lt) | (eq & ~lt & ~a & b))) ret[0] = 1; // true condition for lt
    return ret;
endfunction


function Bit#(2) cmp32#(Integer w)(Bit#(w) a, Bit#(w) b, Bit#(1) eq, Bit#(1) lt); 
    Bit#(2) upper = cmp32#(w-w/2)(a[w-1:w/2], b[w-1:w/2], 1, 0);
    Bit#(2) lower = cmp32#(w/2)(a[w/2-1:0], b[w/2-1:0], eq, lt);
    return {
		upper[1] & lower[1], // equal condition
		upper[0] | (upper[1] & lower[0]) // lt condition
    	    }; 
    //return res;
endfunction

function Bit#(2) cmp32#(1)(Bit#(1) a, Bit#(1) b, Bit#(1) eq, Bit#(1) lt);
    return cmp(a, b, eq, lt);
endfunction

// Description: unsigned 32-bit less-than comparator
// Arguments: a, b unsigned 32-bit values
// Return: 1 if a < b
function Bit#(1) ltu32(Bit#(32) a, Bit#(32) b);
    Bit#(1) ret = cmp32#(32)(a, b, 1, 0)[0];
    return ret;
endfunction

// Description: Signed/Unsigned 32-bit less-than comparator
// Arguments: a b (32-bit values); isSigned (signed comparator when 1, unsigned otherwise)
// Return: 1 if a < b
function Bit#(1) lt32(Bit#(32) a, Bit#(32) b, Bit#(1) isSigned);
    Bit#(1) ret = 0;
    a = (isSigned == 1) ? {~a[31], a[30:0]} : a;
    b = (isSigned == 1) ? {~b[31], b[30:0]} : b;
    //return (a < b) ? 1 : 0;
    return ltu32(a, b); 
endfunction


// Description: one-bit full adder
// Arguments: a, b, carry in
// Return: {carry out, sum}
function Bit#(2) fullAdder(Bit#(1) a, Bit#(1) b, Bit#(1) carryIn);
    Bit #(1) sum = carryIn ^ (a ^ b);
    Bit #(1) cout = (a & b) | (a & carryIn) | (b & carryIn);
    return {cout, sum};
endfunction


// Description: n-bit ripple-carry adder with a carry-in
// Arguments: a, b, carryIn
// Return: sum of a, b, and carryIn

// base case
function Bit#(2) rca_helper#(1)(Bit#(1) a, Bit#(1) b, Bit#(1) carryIn);
    return fullAdder(a, b, carryIn);
endfunction

// general case
function Bit#(n+1) rca_helper#(Integer n)(Bit#(n) a, Bit#(n) b, Bit#(1) carryIn);
    Bit#(n) lower = rca_helper#(n-1)(a[n-2:0], b[n-2:0], carryIn);
    Bit#(2) upper = fullAdder(a[n-1], b[n-1], lower[n-1]);
    return {upper, lower[n-2:0]};
endfunction

function Bit#(n) rca#(Integer n)(Bit#(n) a, Bit#(n) b, Bit#(1) carryIn);
    return rca_helper#(n)(a, b, carryIn)[n-1:0];
endfunction


// Description: n-bit ripple-carry adder/subractor
// Arguments: a, b (n-bit operands); isSub (1 => subtract, 0 => add)
// Return: isSub == 0 ? a + b : a - b
function Bit#(n) addSub#(Integer n)(Bit#(n) a, Bit#(n) b, Bit#(1) isSub);
    b = (isSub == 1) ? ~b : b;
    Bit#(1) carryIn = (isSub == 1) ? 1'b1 : 0;

    return fastAdd#(n)(a, b, carryIn); 
    //return rca#(n)(a, b, carryIn);
endfunction


// Alu Functions:
// Add: 32-bit Addition         (a + b)
// Sub: 32-bit Subtraction      (a - b)
// And: 32-bit Bitwise And      (a & b)
// Or: 32-bit Bitwise Or        (a | b)
// Xor: 32-bit Bitwise Xor      (a ^ b)
// Slt: Set less than           (a <u b ? 1 : 0)
// Sltu: Set less than unsigned (a <s b ? 1:0)
// Sll: Left logic shfit        (a << b)
// Srl: Right logic shift       (a >>u b)
// Sra: Right arithmetic shift  (a >>s b)
typedef enum {Add, Sub, And, Or, Xor, Slt, Sltu, Sll, Srl, Sra} AluFunc;

// Description: Arithmetic Logic Unit (ALU)
// Arguments: a, operand a; b, operand b; func, ALU operation
// Return: output of ALU
function Bit#(32) alu(Bit#(32) a, Bit#(32) b, AluFunc func);
    //Bit#(32) ret = 0;

    return case (func)
	Add : addSub#(32)(a, b, 0);
	Sub : addSub#(32)(a, b, 1);
	And : (a & b);
	Or  : (a | b);
	Xor : (a ^ b);
	Slt : zeroExtend(lt32(a, b, 1));
	Sltu: zeroExtend(lt32(a, b, 0));
	default : sft32(a, b[4:0], (func == Sra) ? ArithmeticRightShift : ((func == Srl) ? LogicalRightShift : LeftShift));
    endcase;

/*
    if (func == Add || func == Sub) begin
	Bit#(1) isSub = (func == Sub) ? 1 : 0;
	ret = addSub#(32)(a, b, isSub);
    end
    else if (func == And) ret = (a & b);
    else if (func == Or)  ret = (a | b);
    else if (func == Xor) ret = (a ^ b);
    else if (func == Slt || func == Sltu) begin
	Bit#(1) isSigned = (func == Slt) ? 1 : 0;
	ret = zeroExtend(lt32(a, b, isSigned));
    end
    else begin // func == Sll, Srl, or Sra
	ShiftType shiftType = (func == Sra) ? ArithmeticRightShift : ((func == Srl) ? LogicalRightShift : LeftShift);
	ret = sft32(a, b[4:0], shiftType);
    end
    return ret; */
endfunction


// Description: Alternative shifter implementation (Discussion Question)
function Bit#(32) sft32_alt(Bit#(32) in, Bit#(5) sftSz, ShiftType shiftType);
    return (shiftType == LeftShift) ? sft32(in, sftSz, LeftShift) : ((shiftType == ArithmeticRightShift)? sft32(in, sftSz, ArithmeticRightShift) : sft32(in, sftSz, LogicalRightShift));
endfunction


// Description: N-bit fast adder with a carry-in (Design Exercise)
// Arguments: a, b, carryIn
// Return: sum of a, b, and carryIn

function Bit#(2) fastAdd_helper#(1)(Bit#(1) a, Bit#(1) b, Bit#(1) carryIn);
    return fullAdder(a, b, carryIn);
endfunction

function Bit#(n+1) fastAdd_helper#(Integer n)(Bit#(n) a, Bit#(n) b, Bit#(1) carryIn);
    Bit#(n/2+1) lower = fastAdd_helper#(n/2)(a[n/2-1:0], b[n/2-1:0], carryIn);
    Bit#(n/2+1) upper_0 = fastAdd_helper#(n/2)(a[n-1:n/2], b[n-1:n/2], 0);
    Bit#(n/2+1) upper_1 = fastAdd_helper#(n/2)(a[n-1:n/2], b[n-1:n/2], 1);
    return {(lower[n/2] == 1) ? upper_1 : upper_0, lower[n/2-1:0]};
endfunction

function Bit#(n) fastAdd#(Integer n)(Bit#(n) a, Bit#(n) b, Bit#(1) carryIn);
    return fastAdd_helper#(n)(a, b, carryIn)[n-1:0];
endfunction
