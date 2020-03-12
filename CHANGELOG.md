0.1.0
-----

* fixed issue with gwstartnextfft false-negatives
* selftest success at least up to n=120000 (for k<300)
* print LLR64 compatible residue
* automatic niceness 19 (not configurable)
* extra logging when errors happen (won't catch all)
* result output says 'maybe' if errors were seen
* speed still on par with LLR64

0.0.4
-----

* automatic comprehensive selftest
* usable commandline arguments
* check (and warn on) FFT overflow
* refactored code to smaller files
* readme has examples
* lots of other cleanup

0.0.3
-----

* threadcount = 0 performs benchmark to determine most optimal threadcount

0.0.2
-----

* as fast as LLR64
