#
# AV_DependencyUtils.cmake
#
# This file contains helper functions for dependency declaration and ordering
#
# The following variables will be set if used like this:
# av_dep_define()...
# av_dep_finalize()
#
# AV_ALL_DEPS --> All dependencies
# AV_ALL_DIRECT_DEPS --> All direct dependencies
# AV_DEPS_ORDERED -> All dependencies to be built, ordered sequentially

# ===============================================
# Helper which evaluates a simple condition
#
# - overall TRUE => disable
# - reason = first OR-group that evaluated TRUE
# ===============================================
function(av_dep_eval_disable_if out_disable out_reason)
  set(_tokens "${ARGN}")

  # Split into conditions + operators (AND/OR)
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

  # Evaluate each condition
  set(_cond_results "")
  foreach(_c IN LISTS _conds)
    set(_cond_result FALSE)
    cmake_language(EVAL CODE "
      if(${_c})
        set(_cond_result TRUE)
      endif()
    ")
    list(APPEND _cond_results "${_cond_result}")
  endforeach()

  # AND precedence: build OR-groups
  set(_group_results "")
  set(_group_reasons "")
  set(_current_group_ok TRUE)
  set(_current_group_reason "")

  list(LENGTH _conds _cond_len)
  list(LENGTH _ops _op_len)
  set(_i 0)

  while(_i LESS _cond_len)
    list(GET _cond_results ${_i} _r)
    list(GET _conds ${_i} _c)

    if(_r)
      if(_current_group_reason STREQUAL "")
        set(_current_group_reason "${_c}")
      else()
        set(_current_group_reason "${_current_group_reason} AND ${_c}")
      endif()
    else()
      set(_current_group_ok FALSE)
    endif()

    if(_i LESS _op_len)
      list(GET _ops ${_i} _op)
      if(_op STREQUAL "OR")
        list(APPEND _group_results "${_current_group_ok}")
        list(APPEND _group_reasons "${_current_group_reason}")
        set(_current_group_ok TRUE)
        set(_current_group_reason "")
      endif()
    endif()
    math(EXPR _i "${_i}+1")
  endwhile()

  list(APPEND _group_results "${_current_group_ok}")
  list(APPEND _group_reasons "${_current_group_reason}")

  # Overall: if any OR-group TRUE => disable
  set(_disable FALSE)
  set(_reason "")
  list(LENGTH _group_results _glen)
  set(_gi 0)
  while(_gi LESS _glen)
    list(GET _group_results ${_gi} _g)
    if(_g)
      set(_disable TRUE)
      list(LENGTH _group_reasons _rlen)
      math(EXPR _rlenm1 "${_rlen}-1")
      if(_rlenm1 LESS _gi)
        set(_gi ${_rlenm1})
      endif()
      list(GET _group_reasons ${_gi} _reason)
      break()
    endif()
    math(EXPR _gi "${_gi}+1")
  endwhile()

  set(${out_disable} "${_disable}" PARENT_SCOPE)
  set(${out_reason} "${_reason}" PARENT_SCOPE)
endfunction()

# returns: out_ok (TRUE/FALSE), out_reason (first failed condition)
function(av_dep_eval_build_only_if out_ok out_reason)
  # reuse your splitting logic (same as av_dep_eval_disable_if)
  set(_tokens "${ARGN}")

  # Split into conditions + operators (AND/OR)
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

  # Evaluate each condition
  set(_cond_results "")
  foreach(_c IN LISTS _conds)
    set(_cond_result FALSE)
    cmake_language(EVAL CODE "
      if(${_c})
        set(_cond_result TRUE)
      endif()
    ")
    list(APPEND _cond_results "${_cond_result}")
  endforeach()

  # AND precedence, OR groups (same as before)
  # For BUILD_ONLY_IF:
  #   if ANY group TRUE => build OK
  #   else => reason = first group's failed condition
  set(_group_results "")
  set(_group_fail_reason "")
  set(_current_group_ok TRUE)
  set(_current_group_fail "")

  list(LENGTH _conds _cond_len)
  list(LENGTH _ops _op_len)
  set(_i 0)

  while(_i LESS _cond_len)
    list(GET _cond_results ${_i} _r)
    list(GET _conds ${_i} _c)

    if(NOT _r AND _current_group_fail STREQUAL "")
      set(_current_group_fail "${_c}")
    endif()
    if(NOT _r)
      set(_current_group_ok FALSE)
    endif()

    if(_i LESS _op_len)
      list(GET _ops ${_i} _op)
      if(_op STREQUAL "OR")
        list(APPEND _group_results "${_current_group_ok}")
        list(APPEND _group_fail_reason "${_current_group_fail}")
        set(_current_group_ok TRUE)
        set(_current_group_fail "")
      endif()
    endif()
    math(EXPR _i "${_i}+1")
  endwhile()

  list(APPEND _group_results "${_current_group_ok}")
  list(APPEND _group_fail_reason "${_current_group_fail}")

  set(_ok FALSE)
  set(_reason "")
  list(LENGTH _group_results _glen)
  set(_gi 0)
  while(_gi LESS _glen)
    list(GET _group_results ${_gi} _g)
    if(_g)
      set(_ok TRUE)
      break()
    endif()
    if(_reason STREQUAL "")
      list(GET _group_fail_reason ${_gi} _r)
      set(_reason "${_r}")
    endif()
    math(EXPR _gi "${_gi}+1")
  endwhile()

  set(${out_ok} "${_ok}" PARENT_SCOPE)
  set(${out_reason} "${_reason}" PARENT_SCOPE)
endfunction()

# ===============================================
# Helper which defines a dependency
#
# TRANSITIVE    --> Not directly used, may be
#                   discarded
# REQUIRES      --> Any subdependencies required
#                   to build it
# DISABLE_IF    --> A simple condition on when to
#                   disable it
# BUILD_ONLY_IF --> A simple condition to build
#                   the dependency if true
# OPTIONAL_REQUIRES --> Optional dependencies,
#                       based on a condition
# ===============================================
function(av_define_dependency name)
  set(options TRANSITIVE NEVER_BUILD)
  set(oneValueArgs)
  set(multiValueArgs REQUIRES DISABLE_IF BUILD_ONLY_IF OPTIONAL_REQUIRES)
  cmake_parse_arguments(AV_DEP "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  set(AV_DEP_${name}_REQUIRES "${AV_DEP_REQUIRES}" PARENT_SCOPE)
  set(AV_DEP_${name}_TRANSITIVE "${AV_DEP_TRANSITIVE}" PARENT_SCOPE)

  list(APPEND AV_ALL_DEPS "${name}")
  list(REMOVE_DUPLICATES AV_ALL_DEPS)
  set(AV_ALL_DEPS "${AV_ALL_DEPS}" PARENT_SCOPE)

  # Add to direct dependency list if required
  if(NOT AV_DEP_TRANSITIVE)
    list(APPEND AV_ALL_DIRECT_DEPS "${name}")
    set(AV_ALL_DIRECT_DEPS "${AV_ALL_DIRECT_DEPS}" PARENT_SCOPE)
  endif()

  # --- OPTIONAL_REQUIRES parsing ---
  if(AV_DEP_OPTIONAL_REQUIRES)
    foreach(_opt IN LISTS AV_DEP_OPTIONAL_REQUIRES)
      # Split "<DEP> IF <cond...>"
      string(REGEX MATCH "^([^ ]+)[ ]+IF[ ]+(.+)$" _m "${_opt}")
      if(NOT _m)
        message(FATAL_ERROR "OPTIONAL_REQUIRES entry must be '<DEP> IF <condition...>': '${_opt}'")
      endif()

      set(_dep "${CMAKE_MATCH_1}")
      set(_cond "${CMAKE_MATCH_2}")

      # Evaluate condition
      set(_ok FALSE)
      cmake_language(EVAL CODE "
        if(${_cond})
          set(_ok TRUE)
        endif()
      ")

      if(_ok)
        list(APPEND AV_DEP_REQUIRES "${_dep}")
      endif()
    endforeach()
  endif()

  # re‑export REQUIRES (in case optional ones were appended)
  set(AV_DEP_${name}_REQUIRES "${AV_DEP_REQUIRES}" PARENT_SCOPE)

  if(AV_DEP_DISABLE_IF)
    av_dep_eval_disable_if(_disable _reason ${AV_DEP_DISABLE_IF})
    if(_disable)
      set(AV_DEP_${name}_DISABLED TRUE PARENT_SCOPE)
      if(_reason STREQUAL "")
        set(_reason "the DISABLE_IF condition")
      endif()
      set(AV_DEP_${name}_DISABLED_REASON
          "disabled because ${_reason} evaluated to TRUE" PARENT_SCOPE)
    endif()
  endif()

  if(AV_DEP_NEVER_BUILD)
    set(AV_DEP_${name}_NEVER_BUILD TRUE PARENT_SCOPE)
    set(AV_DEP_${name}_NO_BUILD TRUE PARENT_SCOPE)
    set(AV_DEP_${name}_NO_BUILD_REASON
        "will be used, but not built because NEVER_BUILD is set" PARENT_SCOPE
    )
  endif()

  if(AV_DEP_BUILD_ONLY_IF)
    av_dep_eval_build_only_if(_build _build_reason ${AV_DEP_BUILD_ONLY_IF})
    if(NOT _build)
      set(AV_DEP_${name}_NO_BUILD TRUE PARENT_SCOPE)
      set(AV_DEP_${name}_NO_BUILD_REASON
          "will be used, but not built because ${_build_reason} evaluated to FALSE" PARENT_SCOPE
      )
    endif()
  endif()
endfunction()


# ===============================================
# Helper which creates a finalized dependency
# list which is ordered sequentially, with all
# non-needed dependencies removed
# ===============================================
function(av_finalize_dependencies)
  # ---------- 1) collect direct deps ----------
  set(_direct "")
  foreach(d IN LISTS AV_ALL_DEPS)
    if(NOT AV_DEP_${d}_TRANSITIVE)
      list(APPEND _direct "${d}")
    endif()
  endforeach()

  # ---------- 2) compute reachable deps from each direct dep ----------
  foreach(dd IN LISTS _direct)
    set(AV_DEP_REACH_FROM_${dd} "")
  endforeach()

  macro(_collect_from direct n)
    list(FIND AV_DEP_REACH_FROM_${direct} "${n}" _i)
    list(APPEND AV_DEP_REACH_FROM_${direct} "${n}")
    foreach(r IN LISTS AV_DEP_${n}_REQUIRES)
      _collect_from("${direct}" "${r}")
    endforeach()
  endmacro()

  foreach(dd IN LISTS _direct)
    _collect_from("${dd}" "${dd}")
  endforeach()

  # ---------- 3) build global reachable set from enabled direct deps ----------
  set(_reachable "")
  foreach(dd IN LISTS _direct)
    if(AV_DEP_${dd}_DISABLED)
      continue()
    endif()
    foreach(r IN LISTS AV_DEP_REACH_FROM_${dd})
      list(APPEND _reachable "${r}")
    endforeach()
  endforeach()
  list(REMOVE_DUPLICATES _reachable)

  # ---------- 4) disable transitives not needed, with reasons ----------
  foreach(dep IN LISTS AV_ALL_DEPS)
    if(NOT AV_DEP_${dep}_TRANSITIVE)
      continue()
    endif()

    list(FIND _reachable "${dep}" _i)
    if(_i GREATER -1)
      continue()
    endif()

    # build list of disabled direct deps that would have required it
    set(_blocked_by "")
    foreach(dd IN LISTS _direct)
      if(NOT AV_DEP_${dd}_DISABLED)
        continue()
      endif()
      list(FIND AV_DEP_REACH_FROM_${dd} "${dep}" _ri)
      if(_ri GREATER -1)
        list(APPEND _blocked_by "${dd}")
      endif()
    endforeach()

    # set locally (important!)
    set(AV_DEP_${dep}_DISABLED TRUE)

    if(_blocked_by)
      list(JOIN _blocked_by ", " _blocked_by_str)
      set(AV_DEP_${dep}_DISABLED_REASON
          "disabled because it is only required by ${_blocked_by_str}, which will not be built")
    else()
      set(AV_DEP_${dep}_DISABLED_REASON
          "disabled because no enabled direct dependency requires it")
    endif()
  endforeach()

  # ---------- 5) topo sort enabled deps ----------
  set(_enabled "")
  foreach(d IN LISTS AV_ALL_DEPS)
    if(NOT AV_DEP_${d}_DISABLED)
      list(APPEND _enabled "${d}")
    endif()
  endforeach()

  set(_ordered "")
  set(_temp "")
  set(_perm "")

  macro(_visit n)
    list(FIND _perm "${n}" _p)
    list(FIND _temp "${n}" _t)
    if(_t GREATER -1)
      message(FATAL_ERROR "Cyclic dependency detected at ${n}")
    endif()

    list(APPEND _temp "${n}")
    foreach(r IN LISTS AV_DEP_${n}_REQUIRES)
      if(AV_DEP_${r}_DISABLED)
        continue()
      endif()
      _visit("${r}")
    endforeach()

    list(REMOVE_ITEM _temp "${n}")
    list(APPEND _perm "${n}")
    list(APPEND _ordered "${n}")
  endmacro()

  foreach(n IN LISTS _enabled)
    _visit("${n}")
  endforeach()

  list(REMOVE_DUPLICATES _ordered)
  set(AV_DEPS_ORDERED "${_ordered}" PARENT_SCOPE)

  # propagate disabled flags/reasons to caller
  foreach(dep IN LISTS AV_ALL_DEPS)
    if(DEFINED AV_DEP_${dep}_DISABLED)
      set(AV_DEP_${dep}_DISABLED "${AV_DEP_${dep}_DISABLED}" PARENT_SCOPE)
    endif()
    if(DEFINED AV_DEP_${dep}_DISABLED_REASON)
      set(AV_DEP_${dep}_DISABLED_REASON "${AV_DEP_${dep}_DISABLED_REASON}" PARENT_SCOPE)
    endif()
  endforeach()
endfunction()
