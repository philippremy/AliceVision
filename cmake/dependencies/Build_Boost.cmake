#
# Build_Boost.cmake
#
# Builds an embedded version of Boost

include(AV_ColoredMessage)

function(build_Boost)

  # AliceVision components
  set(AV_DEP_Boost_COMPONENTS
    accumulators algorithm
    container
    detail
    filesystem foreach format functional
    geometry graph
    headers
    json
    lexical_cast log
    math multi_array multi_index
    program_options property_tree ptr_container
    range regex
    system
    test
  )

  # CCTag components
  if(AV_USE_CCTAG)
    list(APPEND AV_DEP_Boost_COMPONENTS
      date_time
      serialization
      timer
      stacktrace
      # unit_test_framework # We do not build CCTag tests, so this is not needed
    )
  endif()

  # Components Boost requires transitively
  set(AV_DEP_Boost_TRANSITIVE_COMPONENTS
    align any array asio assert atomic
    bimap bind
    chrono circular_buffer compute concept_check config container_hash
    conversion core
    describe dynamic_bitset
    endian exception
    function function_types fusion
    integer interprocess intrusive io iterator
    lambda logic
    move mp11 mpl multiprecision
    numeric numeric_interval
    optional
    qvm
    parameter phoenix pool predef preprocessor property_map proto
    random range ratio rational
    scope spirit static_assert
    thread throw_exception tokenizer tti tuple type_index type_traits typeof
    unordered uuid utility
    winapi
    variant variant2
    xpressive
  )

  # PopSIFT technically also requires Boost, but only for its applications,
  # but we don't build them so do not add these.

  # Explicitly disable all remaining libraries
  # Reduces install size and compile time
  set(AV_DEP_Boost_COMPONENTS_DISABLED
    assign
    beast
    callable_traits charconv cobalt compat compatibility context contract
    convert coroutine coroutine2 crc
    decimal dll
    fiber flyweight
    gil graph_parallel
    hana heap histogram hof
    icl iostreams
    lambda2 leaf local_function locale lockfree
    metaparse mpi msm mysql
    nowide
    outcome
    parameter_python pfr poly_collection polygon process property_map_parallel
    python
    redis
    safe_numerics scope_exit signals2 smart_prt sort statechart static_string
    stl_interfaces
    type_erasure
    units url
    vmd
    wave
    yap
  )

  # Build lists with the EXTRA_CMAKE_FLAGS syntax
  list(JOIN AV_DEP_Boost_COMPONENTS "|" AV_DEP_Boost_COMPONENTS_JOINED)
  list(JOIN AV_DEP_Boost_COMPONENTS_DISABLED "|" AV_DEP_Boost_COMPONENTS_DISABLED_JOINED)

  set(AV_DEP_Boost_VERSION           "1.90.0")
  set(AV_DEP_Boost_URL               "https://github.com/boostorg/boost/releases/download/boost-${AV_DEP_Boost_VERSION}/boost-${AV_DEP_Boost_VERSION}-cmake.7z")
  set(AV_DEP_Boost_HASH              "SHA256=218e74c4aa362a994b7b7a23b2920f455a00205c656405fcf262cf60b8871921")
  set(AV_DEP_Boost_EXTRA_CMAKE_FLAGS
    -DBOOST_INCLUDE_LIBRARIES=${AV_DEP_Boost_COMPONENTS_JOINED}
    -DBOOST_EXCLUDE_LIBRARIES=${AV_DEP_Boost_COMPONENTS_DISABLED_JOINED}
  )

  # Return early if the dependency should not be built
  if(AV_DEP_Boost_BUILD_NO_BUILD)
    av_colored_message(PLAIN W "Skipping build of Boost...")
    return()
  endif()

  # Make the target available
  av_make_dependency_available(Boost URL ${AV_DEP_Boost_URL} URL_HASH "${AV_DEP_Boost_HASH}")

  # Build the dependency
  av_build_cmake_dependency(Boost
    EXTRA_CMAKE_ARGS ${AV_DEP_Boost_EXTRA_CMAKE_FLAGS}
  )

endfunction()

# Invoke the function automatically
build_Boost()
