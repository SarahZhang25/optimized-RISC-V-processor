import TwoWayCache;
import Beveren;

module TwoWayBeverenTest;
    //type of cache, number of ways, verbose = True
    Beveren#(TwoWayCache, 2) bt(True);
endmodule

module TwoWayBeverenAutograde;
    //type of cache, number of ways, verbose = False
    Beveren#(TwoWayCache, 2) bt(False);
endmodule
