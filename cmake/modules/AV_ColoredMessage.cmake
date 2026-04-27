#
# AV_ColoredMessage.cmake
#
# This file provides a function to print colored messages in a structured way

function(av_colored_message MSG_KIND)

  if(MSG_KIND STREQUAL "PLAIN")
    set(MSG_KIND "")
  endif()

  # ANSI color codes
  string (ASCII 27 _CLR_ESC)
  set(_CLR_BLACK "${_CLR_ESC}[30m")
  set(_CLR_RESET "${_CLR_ESC}[m")

  # Non-bold colors
  set(_CLR_RED   "${_CLR_ESC}[31m")
  set(_CLR_GREEN "${_CLR_ESC}[32m")
  set(_CLR_YELLOW "${_CLR_ESC}[33m")
  set(_CLR_BLUE  "${_CLR_ESC}[34m")
  set(_CLR_WHITE "${_CLR_ESC}[37m")

  # Bold colors
  set(_BOLD_RED   "${_CLR_ESC}[1;31m")
  set(_BOLD_GREEN "${_CLR_ESC}[1;32m")
  set(_BOLD_YELLOW "${_CLR_ESC}[1;33m")
  set(_BOLD_BLUE  "${_CLR_ESC}[1;34m")
  set(_BOLD_WHITE "${_CLR_ESC}[1;37m")

  # Default color if no code is given between strings
  set(_cur_color "${_CLR_BLACK}")
  set(_out "")

  foreach(_arg IN LISTS ARGN)
    if(_arg MATCHES "^B[RGBYW]$")
      # Bold color tokens: BR, BG, BY, BW, BB
      if(_arg STREQUAL "BR")
        set(_cur_color "${_BOLD_RED}")
      elseif(_arg STREQUAL "BG")
        set(_cur_color "${_BOLD_GREEN}")
      elseif(_arg STREQUAL "BY")
        set(_cur_color "${_BOLD_YELLOW}")
      elseif(_arg STREQUAL "BW")
        set(_cur_color "${_BOLD_WHITE}")
      elseif(_arg STREQUAL "BB")
        set(_cur_color "${_BOLD_BLUE}")
      endif()
    elseif(_arg MATCHES "^[RGBYW!]$")
      # Normal color tokens: R, G, Y, W, B
      if(_arg STREQUAL "R")
        set(_cur_color "${_CLR_RED}")
      elseif(_arg STREQUAL "G")
        set(_cur_color "${_CLR_GREEN}")
      elseif(_arg STREQUAL "Y")
        set(_cur_color "${_CLR_YELLOW}")
      elseif(_arg STREQUAL "W")
        set(_cur_color "${_CLR_WHITE}")
      elseif(_arg STREQUAL "B")
        set(_cur_color "${_CLR_BLUE}")
      elseif(_arg STREQUAL "!")
        set(_cur_color "${_CLR_BLACK}")
      endif()
    else()
      # Append colored text, reset after each fragment
      string(APPEND _out "${_cur_color}${_arg}${_CLR_RESET}")
    endif()
  endforeach()

  message(${MSG_KIND} "${_out}")
endfunction()
