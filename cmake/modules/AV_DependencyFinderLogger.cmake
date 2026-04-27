# ---- Helper: print one dependency line ----
function(_av_print_dep_line DEP_NAME WIDTH)

  if(AV_DEP_${DEP_NAME}_FOUND)
    set(state_color "G")
    set(state_icon  "☑")
  else()
    set(state_color "Y")
    set(state_icon  "☒")
  endif()

  # padding for compact alignment
  string(LENGTH "${DEP_NAME}" name_len)
  math(EXPR pad "${WIDTH} - ${name_len}")
  if(pad LESS 1)
    set(pad 1)
  endif()
  string(REPEAT " " ${pad} spacing)

  if(AV_DEP_${DEP_NAME}_FOUND)

    # We want to find out if this is an embedded dependency. For this, we
    # check if this is an INTERFACE_LIBRARY (then include headers must live
    # inside the CMAKE_INSTALL_PREFIX) or another type of library (then the
    # library file must live in CMAKE_INSTALL_PREFIX)
    set(AV_DEP_${DEP_NAME}_IS_EMBEDDED YES)
    foreach(AV_DEP_${DEP_NAME}_TARGET IN LISTS AV_DEP_${DEP_NAME}_ALL_LINK_TARGETS)
      get_target_property(AV_DEP_${DEP_NAME}_TARGET_TYPE ${AV_DEP_${DEP_NAME}_TARGET} TYPE)
      if(AV_DEP_${DEP_NAME}_TARGET_TYPE STREQUAL "INTERFACE_LIBRARY")
        get_target_property(AV_DEP_${DEP_NAME}_TARGET_INCLUDE_DIRS ${AV_DEP_${DEP_NAME}_TARGET} INTERFACE_INCLUDE_DIRECTORIES)
        string(FIND "${AV_DEP_${DEP_NAME}_TARGET_INCLUDE_DIRS}" "${CMAKE_INSTALL_PREFIX}" AV_DEP_${DEP_NAME}_TARGET_INCLUDE_DIRS_IN_PREFIX)
        if(AV_DEP_${DEP_NAME}_TARGET_INCLUDE_DIRS_IN_PREFIX EQUAL -1)
          set(AV_DEP_${DEP_NAME}_IS_EMBEDDED NO)
          break()
        endif()
      else()
        get_target_property(AV_DEP_${DEP_NAME}_TARGET_LOCATION ${AV_DEP_${DEP_NAME}_TARGET} LOCATION)
        string(FIND "${AV_DEP_${DEP_NAME}_TARGET_LOCATION}" "${CMAKE_INSTALL_PREFIX}" AV_DEP_${DEP_NAME}_TARGET_LOCATION_IN_PREFIX)
        if(AV_DEP_${DEP_NAME}_TARGET_LOCATION_IN_PREFIX EQUAL -1)
          set(AV_DEP_${DEP_NAME}_IS_EMBEDDED NO)
          break()
        endif()
      endif()
    endforeach()

    # padding for compact alignment
    string(LENGTH "${AV_DEP_${DEP_NAME}_VERSION}" version_len)
    math(EXPR pad "10 - ${version_len}")
    if(pad LESS 1)
      set(pad 1)
    endif()
    string(REPEAT " " ${pad} spacing_version)

    if(AV_DEP_${DEP_NAME}_IS_EMBEDDED)
      av_colored_message(PLAIN ${state_color} "  ${state_icon}" ! " ${DEP_NAME}${spacing}" W "(${AV_DEP_${DEP_NAME}_VERSION},${spacing_version} embedded)")
    else()
      av_colored_message(PLAIN ${state_color} "  ${state_icon}" ! " ${DEP_NAME}${spacing}" W "(${AV_DEP_${DEP_NAME}_VERSION},${spacing_version} external)")
    endif()
  else()
    av_colored_message(PLAIN ${state_color} "  ${state_icon}" ! " ${DEP_NAME}${spacing}")
  endif()
endfunction()

# ---- Print one dependency group ----
function(av_print_dependency_group GROUP_TITLE GROUP_LIST)
  if(GROUP_LIST)
    set(width 30)
    av_colored_message(PLAIN W "===" B " ${GROUP_TITLE} " W "===")
    av_colored_message(PLAIN "")

    foreach(dep IN LISTS ${GROUP_LIST})
      _av_print_dep_line("${dep}" ${width})
    endforeach()

    av_colored_message(PLAIN "")
  endif()
endfunction()

# ---- Summary entry point ----
av_colored_message(PLAIN Y "============ Dependency Findings ============")
av_colored_message(PLAIN "")

av_print_dependency_group("Found"                      AV_DEP_ALL_FOUND)
av_print_dependency_group("Not found"                  AV_DEP_ALL_NOTFOUND)

av_colored_message(PLAIN Y "=============================================")
