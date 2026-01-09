

include "node_modules/circomlib/circuits/gates.circom";
include "node_modules/circomlib/circuits/comparators.circom";
include "node_modules/circomlib/circuits/multiplexer.circom";

template RangeCheck(bits) {
    signal input in;
    // we use Num2Bits because internally it checks if the final result fits within the number of the bits
    component n2b = Num2Bits(bits);
    n2b.in <== in;
}

template EmulatedAdd(bits){
    signal input x;
    signal input y;
    signal output out;

    // range checking
    component rangeCheckX = RangeCheck(bits);
    component rangeCheckY = RangeCheck(bits);
    rangeCheckX.in <== x;
    rangeCheckY.in <== y;


    // adding the numbers and turning them into {bits+1} bits, why? so we can remove the extra bit late, hence emulating the overflow
    component n2b = Num2Bits(bits+1);
    n2b.in <== x+y;

    component b2n = Bits2Num(bits);

    for (var i = 0; i<bits; i++) {
        b2n.in[i] <== n2b.out[i];
    }

    out <== b2n.out;


}



template EmulatedMul(bits) {


    // asserting that we can handle the emulation in circom
    assert(bits\2<=254\2);

    signal input x;
    signal input y;
    signal output out;


    // range checking
    component rangeCheckX = RangeCheck(bits);
    component rangeCheckY = RangeCheck(bits);
    rangeCheckX.in <== x;
    rangeCheckY.in <== y;

    // multiplying the numbers and turning them into {bits*2} bits, why? so we can remove the extra bits late, hence emulating the overflow
    component n2b = Num2Bits(2*bits);
    n2b.in <== x*y;



    component b2n = Bits2Num(bits);

    for (var i = 0; i<bits; i++) {
        b2n.in[i] <== n2b.out[i];
    }

    out <== b2n.out;


}





template EmulatedBitShifting(bits) {

    assert(bits<=254);

    signal input in;
    signal input shift;
    signal output out;


    component rangeCheckIn = RangeCheck(bits);
    rangeCheckIn.in <== in;

    // pre compute all values of 2^{bits-1}, and for powers above bits-1, we just replace it with zero, because shifting with that amount will give zero amyways
    component powerSelector = Multiplexer(1, 254);
    powerSelector.inp[0][0] <== 1;
    var currentPower = 1;
    for (var i = 1; i <bits; i++) {
        currentPower = currentPower << 1;
        powerSelector.inp[i][0] <== currentPower;
    }
    for (var i = bits; i <254; i++) {
        powerSelector.inp[i][0] <== 0;
    }

    // the selector of what power of two to use
    powerSelector.sel <== shift;
    out <== powerSelector.out[0]*in;

}




template EmulatedBitwiseAnd(bits) {

    assert(bits<=254);


    signal input x;
    signal input y;
    signal output out;

    // range checking
    component n2bX = Num2Bits(bits);
    component n2bY = Num2Bits(bits);
    n2bX.in <== x;
    n2bY.in <== y;

    // doing AND bit by bit
    component b2n = Bits2Num(bits);
    component ands[bits];
    for (var i = 0; i<bits; i++) {
        ands[i] = AND();
        ands[i].a <== n2bX.out[i];
        ands[i].b <== n2bY.out[i];
        b2n.in[i] <== ands[i].out;
    }

    out <== b2n.out;

}





template Emulator(bits){

    

    signal input in[2];
    // signal output out[2];
    // signal output divOut[2];
    // signal output bitShiftingOut;
    signal output bitWiseAndOut;

    // component add = EmulatedAdd(bits);
    // component mul = EmulatedMul(bits);
    // component div = EmulatedDivMod(bits);
    // component bitShifting = EmulatedBitShifting(bits);
    component bitWiseAnd = EmulatedBitwiseAnd(bits);

    // add.x <== in[0];
    // add.y <== in[1];

    // mul.x <== in[0];
    // mul.y <== in[1];

    // div.x <== in[0];
    // div.y <== in[1];

    // bitShifting.in <== in[0];
    // bitShifting.shift <== in[1];

    bitWiseAnd.x <== in[0];
    bitWiseAnd.y <== in[1];

    // out[0] <== add.out;
    // out[1] <== mul.out;
    // divOut[0] <== div.q;
    // divOut[1] <== div.r;
    bitWiseAndOut <== bitWiseAnd.out;




}


component main = Emulator(32);

/* INPUT = {
    "in": [6, 5]
} */