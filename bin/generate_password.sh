#!/usr/bin/env bash

shuf -zer -n20  {a..z} {0..9} |
  tr -d '\0'
  # To avoid this warning: "command substitution: ignored null byte in input"
  # when using this script in others.
