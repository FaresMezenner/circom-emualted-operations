

include "node_modules/circomlib/circuits/gates.circom";
include "node_modules/circomlib/circuits/comparators.circom";

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






template Emulator(bits){

    

    signal input in[2];
    signal output out[2];

    component add = EmulatedAdd(bits);
    component mul = EmulatedMul(bits);

    add.x <== in[0];
    add.y <== in[1];

    mul.x <== in[0];
    mul.y <== in[1];

    out[0] <== add.out;
    out[1] <== mul.out;




}


component main = Emulator(32);

/* INPUT = {
    "in": [2147483648, 2]
} */