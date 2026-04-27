#! /usr/bin/env bash

function dispatch {
  # shellcheck disable=SC2145
  hyprctl --batch \
    "dispatch $@ ;" \
    "dispatch movecursortocorner 1"
}

function new_monitor_desc {
  g_or_l=$1
  monitors=$(hyprctl monitors -j)
  cur_ws=$(echo "$monitors" | jq -r '.[] | select(.focused) | .activeWorkspace | .id')

  echo "$monitors" | jq -r "[.[] | select(.activeWorkspace.id $g_or_l $cur_ws)] | first | .description"
}

function focus_monitor {
  dir=$1
  new_monitor=''
  case $dir in
    "l")
      new_monitor=$(new_monitor_desc '<')
      ;;
    "u")
      new_monitor=$(new_monitor_desc '<')
      ;;
    "r")
      new_monitor=$(new_monitor_desc '>')
      ;;
    "d")
      new_monitor=$(new_monitor_desc '>')
      ;;
  esac

  dispatch focusmonitor "desc:$new_monitor"
}

function direction {
  dir="$1"
  fullscreen=$(hyprctl activeworkspace -j | jq -r '.hasfullscreen')

  if [[ "$fullscreen" == "true" ]]; then
    focus_monitor "$dir"
  else
    dispatch movefocus "$dir"
  fi
}

direction "$1"
