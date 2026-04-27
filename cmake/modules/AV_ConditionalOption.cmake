#
# AV_ConditionalOption.cmake
#
# A helper function which allows setting a regular CMake option conditionally
#
# Why would I want this? Because cmake_dependent_option *hard* disables the
# option, even if the user has a legitimate reason to manually overwrite it.
# This function sets a reasonable default based on the given conditions, but
# allows the user to overwrite it using the CLI/TUI/GUI.
#
# Call signature:
# av_conditional_option(<OPTION> <DOC_STRING> IF <cond1> <cond2> ... THEN <TRUE_VALUE> ELSE <FALSE_VALUE>)

function(av_conditional_option option doc)
  if(ARGC LESS 6)
    message(FATAL_ERROR "av_conditional_option requires: <OPTION> <DOC_STRING> IF ... THEN <TRUE_VALUE> ELSE <FALSE_VALUE>")
  endif()

  # Check if user already set it (CLI/cache)
  set(_user_set FALSE)
  if(DEFINED CACHE{${option}})
    set(_user_set TRUE)
  endif()

  # Parse args
  set(_idx 2)
  list(GET ARGV ${_idx} _if_kw)
  if(NOT _if_kw STREQUAL "IF")
    message(FATAL_ERROR "Expected IF at argument ${_idx}, got '${_if_kw}'")
  endif()
  math(EXPR _idx "${_idx}+1")

  # Collect tokens until THEN
  set(_tokens "")
  while(_idx LESS ARGC)
    list(GET ARGV ${_idx} _tok)
    if(_tok STREQUAL "THEN")
      break()
    endif()
    list(APPEND _tokens "${_tok}")
    math(EXPR _idx "${_idx}+1")
  endwhile()

  if(_idx GREATER_EQUAL ARGC)
    message(FATAL_ERROR "Missing THEN in conditional_option call.")
  endif()

  # Skip THEN
  math(EXPR _idx "${_idx}+1")
  if(_idx GREATER_EQUAL ARGC)
    message(FATAL_ERROR "Missing <TRUE_VALUE> after THEN.")
  endif()
  list(GET ARGV ${_idx} _true_val)
  math(EXPR _idx "${_idx}+1")

  if(_idx GREATER_EQUAL ARGC)
    message(FATAL_ERROR "Missing ELSE after <TRUE_VALUE>.")
  endif()
  list(GET ARGV ${_idx} _else_kw)
  if(NOT _else_kw STREQUAL "ELSE")
    message(FATAL_ERROR "Expected ELSE after <TRUE_VALUE>, got '${_else_kw}'")
  endif()
  math(EXPR _idx "${_idx}+1")

  if(_idx GREATER_EQUAL ARGC)
    message(FATAL_ERROR "Missing <FALSE_VALUE> after ELSE.")
  endif()
  list(GET ARGV ${_idx} _false_val)

  # Build conditions/operators by grouping tokens until AND/OR
  set(_conds "")
  set(_ops "")
  set(_current "")

  foreach(_t IN LISTS _tokens)
    if(_t STREQUAL "AND" OR _t STREQUAL "OR")
      if(_current STREQUAL "")
        message(FATAL_ERROR "Operator '${_t}' without a preceding condition.")
      endif()
      list(APPEND _conds "${_current}")
      list(APPEND _ops "${_t}")
      set(_current "")
    else()
      if(_current STREQUAL "")
        set(_current "${_t}")
      else()
        set(_current "${_current} ${_t}")
      endif()
    endif()
  endforeach()

  if(NOT _current STREQUAL "")
    list(APPEND _conds "${_current}")
  endif()

  list(LENGTH _conds _cond_len)
  list(LENGTH _ops _op_len)
  if(_cond_len EQUAL 0)
    message(FATAL_ERROR "No conditions provided after IF.")
  endif()

  # Evaluate each condition
  set(_cond_results "")
  foreach(_c IN LISTS _conds)

    if(AV_CONDITIONAL_OPTION_VERBOSE)
      message(STATUS "Evaluating: ${_c} for option ${option}...")
    endif()

    set(_cond_result FALSE)
    cmake_language(EVAL CODE "
      if(${_c})
        set(_cond_result TRUE)
      else()
        set(_cond_result FALSE)
      endif()
    ")

    if(AV_CONDITIONAL_OPTION_VERBOSE)
      message(STATUS "Evaluated to: ${_cond_result}.")
    endif()

    list(APPEND _cond_results "${_cond_result}")
  endforeach()

  # Evaluate with AND precedence
  set(_group_results "")
  set(_group_fail_reasons "")
  set(_current_group_ok TRUE)
  set(_current_group_fail "")

  set(_i 0)
  while(_i LESS _cond_len)
    list(GET _cond_results ${_i} _r)
    list(GET _conds ${_i} _c)

    if(NOT _r AND _current_group_ok)
      set(_current_group_ok FALSE)
      set(_current_group_fail "${_c}")
    endif()

    if(_i LESS _op_len)
      list(GET _ops ${_i} _op)
      if(_op STREQUAL "OR")
        list(APPEND _group_results "${_current_group_ok}")
        list(APPEND _group_fail_reasons "${_current_group_fail}")
        set(_current_group_ok TRUE)
        set(_current_group_fail "")
      endif()
    endif()

    math(EXPR _i "${_i}+1")
  endwhile()

  list(APPEND _group_results "${_current_group_ok}")
  list(APPEND _group_fail_reasons "${_current_group_fail}")

  set(_overall FALSE)
  set(_reason "")
  list(LENGTH _group_results _grp_len)
  set(_gi 0)
  while(_gi LESS _grp_len)
    list(GET _group_results ${_gi} _g)
    if(_g)
      set(_overall TRUE)
      break()
    endif()
    if(_reason STREQUAL "")
      list(GET _group_fail_reasons ${_gi} _r)
      set(_reason "${_r}")
    endif()
    math(EXPR _gi "${_gi}+1")
  endwhile()

  if(_overall)
    set(_default "${_true_val}")
  else()
    set(_default "${_false_val}")
  endif()

  if(NOT _user_set)
    set(${option} "${_default}" CACHE BOOL "${doc}")
  else()
    set(${option} "${${option}}" CACHE BOOL "${doc}" FORCE)
    if(NOT ${option} AND NOT DEFINED ${option}_DISABLED_REASON)
      set(${option}_DISABLED_REASON "option manually disabled by the user" CACHE INTERNAL "Reason why ${option} is disabled" FORCE)
      return()
    endif()
  endif()

  if("${${option}}" STREQUAL "${_false_val}")
    if(_reason STREQUAL "")
      set(_reason "unsatisfied condition caused evaluation to ${_false_val}")
    else()
      set(_reason "unsatisfied condition \"${_reason}\" caused evaluation to ${_false_val}")
    endif()
    set(${option}_DISABLED_REASON "disabled because ${_reason}" CACHE INTERNAL "Reason why ${option} is disabled" FORCE)
  else()
    if(DEFINED CACHE{${option}_DISABLED_REASON})
      set(${option}_DISABLED_REASON "" CACHE INTERNAL "Reason why ${option} is disabled" FORCE)
    endif()
  endif()
endfunction()
