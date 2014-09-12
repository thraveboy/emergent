#!/bin/bash
numberofiterations=$1
currentiteration=0
gamesrun=0
moditer=0

while [ $currentiteration -le $numberofiterations ]
do
  let moditer=currentiteration%10
  if [ $moditer -eq 0 ] ; 
   then
    ./show_current_game_config.sh
    echo -n "Games Run: "; echo $gamesrun
    ruby match_stats.rb match-team.results
  fi 
  let popafive=currentiteration%5
  if [ $popafive -eq 0 ] ;
   then
     echo -n "+"
   else
     echo -n "."
  fi

  cat games/move-15 games/move-15-quit | ruby emergent.rb games/display_logs_off games/currentGame > /dev/null;
  let gamesrun=gamesrun+1
  let currentiteration=currentiteration+1
done

./show_current_game_config.sh

echo -n "Games Run: "; echo $gamesrun

ruby match_stats.rb match-team.results
