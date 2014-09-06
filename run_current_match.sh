#!/bin/bash
numberofiterations=10000
currentiteration=0
moditer=0

while [ $currentiteration -le $numberofiterations ]
do
  ruby emergent.rb games/currentGame > /dev/null;
  let moditer=currentiteration%50
  if [ $moditer -eq 0 ] ; 
   then
    echo $currentiteration
    ruby match_stats.rb match-team.results
  fi
  let currentiteration=currentiteration+1
done