import CacheTypes;

// Address Helper Functions
// NOTE: Each of these functions can be implemented with a single line.
// Use the constants logCacheSets and logWordsPerLine, defined in CacheTypes.ms
////////////////////////////////////////

// Extract the Cache Line Index from a given memory address
function CacheIndex getIndex(Word byteAddress);
    return byteAddress[1 + logWordsPerLine + logCacheSets : 2 + logWordsPerLine];
endfunction

// Extract the Cache Line Tag from a given memory address
function CacheTag getTag(Word byteAddress);
    return byteAddress[31 : logWordsPerLine + logCacheSets + 2];
endfunction

// Extract the Cache Line Word Offset from a given memory address
function WordOffset getWordOffset(Word byteAddress);
    return byteAddress[1 + logWordsPerLine : 2];
endfunction

//Extract the line address (tag + index) from a given memory address
function LineAddr getLineAddr(Word byteAddress);
    return byteAddress[31 : 2 + logWordsPerLine];
endfunction
