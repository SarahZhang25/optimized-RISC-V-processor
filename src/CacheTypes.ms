// Types used in the Cache
////////////////////////////////////////
import SRAM;

// typedef Bit#(32) Word; // Defined in ProcTypes.ms

//// Memory Request (for cache's req input)
typedef enum { Ld, St } MemOp;

typedef struct {
    MemOp op;
    Word addr;
    Word data;
} MemReq;

//// Cache Geometry
Integer cacheSets = 64;  // must be a power of 2
Integer wordsPerLine = 16;  // must be a power of 2; 16 means 16*32 = 512-bit cache lines

// Since we often need the log2 of these constants (e.g., for the number of
// bits needed to encode the index), define additional constants
Integer logCacheSets = log2(cacheSets);
Integer logWordsPerLine = log2(wordsPerLine);

//// Data Types

typedef Vector#(wordsPerLine, Word) Line;

//// Address Types

// The cache index is used to index into the cache lines
typedef Bit#(logCacheSets) CacheIndex;

// There are 16 words per line, so the word offset is log_2(16) = 4 bits wide
typedef Bit#(logWordsPerLine) WordOffset;

// tag size + index size + word offset size + byte offset size = 32
// With the default values, the tag size is 32 - 6 (index size) - 4 (word offset size) - 2 (byte offset size) = 20
typedef Bit#(32 - logCacheSets - logWordsPerLine - 2) CacheTag;

// The line address is just the portion of the byte address used to select lines from main memory.
// The line address is equal to the tag and index concatenated together
typedef Bit#(32 - logWordsPerLine - 2) LineAddr;

//// Additional Cache types

// Status for each cache line:
//  NotValid - the current line is invalid.
//  Clean - the current line is valid, and the value hasn't changed since it was read from main memory.
//  Dirty - the current line is valid, but has been written to since it was read from main memory.
// NOTE: Don't change label values; encoding ensures lines start NotValid on reset
// (in a real SRAM, we'd have circuitry to initialize the status array to NotValid over cacheSets cycles)
typedef enum { NotValid = 2'b10, Clean = 2'b00, Dirty = 2'b01 } CacheStatus;

// TaggedLine is a combination of the data, the tag, and the status of the cache line
typedef struct {
    Line        line;
    CacheStatus status;
    CacheTag    tag;
} TaggedLine;

// ReqStatus is used to keep track of the state of the current request
typedef enum {
    Ready,         // The cache is ready for a new request
    Lookup,        // Issued a lookup to tag/data arrays
    Writeback,     // In main memory access for dirty writeback
    Fill           // In main memory access for requested data
} ReqStatus;

// Cache SRAM type synonyms
// You may find the following synonyms helpful for accessing the tag/data/status arrays
typedef SRAMReq#(logCacheSets, CacheTag) TagReq;
typedef SRAMReq#(logCacheSets, Line) DataReq;
typedef SRAMReq#(logCacheSets, CacheStatus) StatusReq;

// Memory Request Types
////////////////////////////////////////

// LineReq is a line-based memory request. Addresses are all line addresses and
// the data is a line.
typedef struct {
    MemOp    op;
    LineAddr lineAddr;
    Line     data;
} LineReq;
