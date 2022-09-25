pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/mux1.circom";

template CheckRoot(n) {
    signal input leaves[2**n];
    signal output root;

    component lines[n];
    for(var i = n-1; i >= 0; i--) {
        lines[i] = NextLine(i);
        for(var j = 0; j < 2**(i+1); j++) {
            lines[i].leaves[j] <== i == n - 1 ? leaves[j] : lines[j + 1].next_leaves[j];
        }
    }

    root <== n > 0 ? lines[0].next_leaves[0] : leaves[0];
}

template NextLine(m) {
    signal input leaves[2**m];
    signal output next_leaves[2**(m-1)];

    component hashes[2**(m-1)];

    for(var i = 0; i < 2**(m-1); i++) {
        hashes[i] = Poseidon(2);
        hashes[i].inputs[0] <== leaves[i*2];
        hashes[i].inputs[1] <== leaves[i*2 + 1];
        hashes[i].out ==> next_leaves[i];
    }
}

template MerkleTreeInclusionProof(n) {
    signal input leaf;
    signal input path_elements[n];
    signal input path_index[n]; // path index are 0's and 1's indicating whether the current element is on the left or right
    signal output root; // note that this is an OUTPUT signal

    //[assignment] insert your code here to compute the root from a leaf and elements along the path
    component ps[n];
    component mux[n];

    for (var i = 0; i < n; i++) {
        ps[i] = Poseidon(2);
        mux[i] = MultiMux1(2);
        mux[i].c[0][0] <== i == 0 ? leaf :  ps[i-1].out;
        mux[i].c[0][1] <== path_elements[i];
        mux[i].c[1][0] <== path_elements[i];
        mux[i].c[1][1] <== i == 0 ? leaf :  ps[i-1].out;
        mux[i].s <== path_index[i];

        ps[i].inputs[0] <== mux[i].out[0];
        ps[i].inputs[1] <== mux[i].out[1];
    }

    root === ps[n-1].out;
}