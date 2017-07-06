#!/bin/bash

CMD_NAME=$(basename $0)
FILES=( "$@" )

echo "${CMD_NAME}: Waiting for ${FILES[@]}"
while true
do

  for i in "${!FILES[@]}"
  do

    file=${FILES[i]}

    if [ -f $file ]
    then
      echo "${CMD_NAME}: Found $file"
      unset FILES[i]
    fi

    if [ ${#FILES[@]} -eq 0 ]
    then
      echo "${CMD_NAME}: All files found, moving on."
      exit 0
    fi


  done

  sleep 1

done
