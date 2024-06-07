# What do we need to fix?

- [ ] OpenMesh (REASON: Uses the wrong C++ standard and therefore errors on `emplace_back()`)
- [ ] Geogram (REASON: Falsely sets `fopen()` to `NULL`, which causes problems on Clang 18)
- [ ] SWIG (REASON: must further specify the BISON version to use, macOS only ships old ones) --> See [StackOverflow](https://stackoverflow.com/questions/53877344/cannot-configure-cmake-to-look-for-homebrew-installed-version-of-bison).
- [ ] libVPX (REASON: Adds Linux linker flags, which are treated as errors. Maybe we can disable that somehow without forking the whole thing.)

## Possible, but probably not neccessary
- [ ] LEMON (REASON: Uses `register` keyword from C++, which is hard-deprecated in C++17 [which in turn is used by the build right noe])