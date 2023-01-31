import DirectMappedCache;
import Beveren;

module DirectMappedBeverenTest;
    //type of cache, number of ways, verbose = True
    Beveren#(DirectMappedCache, 1) bt(True);
endmodule

module DirectMappedBeverenAutograde;
    //type of cache, number of ways, verbose = False
    Beveren#(DirectMappedCache, 1) bt(False);
endmodule
