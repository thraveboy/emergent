#!/bin/bash
numberofiterations=$1
currentiteration=1

while [ $currentiteration -le $numberofiterations ]
do
  echo "Team switch " $currentiteration " of " $numberofiterations
  switch_teams_best.sh
  mutate_program.sh $2 $3 $4 $currentiteration
  if [ -f defeated ]
    then 
      switch_teams_best.sh;
      exit
    else
     let currentiteration=$currentiteration+1
  fi
done