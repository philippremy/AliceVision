# What do we need to fix?

- [x] OpenMesh (REASON: Uses the wrong C++ standard and therefore errors on `emplace_back()`)
    - [x] OpenMesh cmake-library (idk but it needs the submodule)
- [x] Geogram (REASON: Falsely sets `fopen()` to `NULL`, which causes problems on Clang 18)
- [x] SWIG (REASON: must further specify the BISON version to use, macOS only ships old ones) --> See [StackOverflow](https://stackoverflow.com/questions/53877344/cannot-configure-cmake-to-look-for-homebrew-installed-version-of-bison).
- [x] libVPX (REASON: Adds Linux linker flags, which are treated as errors. Maybe we can disable that somehow without forking the whole thing.)
- [x] CCTag (REASON: Has `using namespace boost::numeric`, which does not exist)
- [ ] libONNXRuntime (REASON: Gets build for the wrong architecture. On my machine [Intel MBP Late 2017], libONNXRuntime gets build for aarch64 instead of x86_64. Need to investigate CMakeLists.txt, I think there is a download bug)

## Possible, but probably not neccessary
- [ ] LEMON (REASON: Uses `register` keyword from C++, which is hard-deprecated in C++17 [which in turn is used by the build right noe])