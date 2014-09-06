#!/bin/bash
numberofiterations=1000
currentiteration=0
gamesrun=0
moditer=0

while [ $currentiteration -le $numberofiterations ]
do
  let moditer=currentiteration%50
  if [ $moditer -eq 0 ] ; 
   then
    echo -n "Games Run: "; echo $gamesrun
    show_current_game_config.sh
    ruby match_stats.rb match-team.results
  fi
  ruby emergent.rb games/currentGame < games/moves-15 > /dev/null;
  let gamesrun=gamesrun+1
  let currentiteration=currentiteration+1
done

echo -n "Games Run: "; echo $gamesrun
show_current_game_config.sh

ruby match_stats.rb match-team.results
