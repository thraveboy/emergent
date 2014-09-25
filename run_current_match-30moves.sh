#!/bin/bash
numberofiterations=$1
currentiteration=0
gamesrun=0
moditer=0

./create_current_team_load_commands.sh

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
  
cat games/display_logs_off team_1_load_temp team_switch_load_temp team_2_load_temp games/currentGame  games/move-15 games/move-15-quit | ruby-prof emergent.rb;

  resultmany=`ruby match_winner.rb match-team.results`
  echo -n $resultmany
  let gamesrun=gamesrun+1
  let currentiteration=currentiteration+1
done

./show_current_game_config.sh

echo -n "Games Run: "; echo $gamesrun

ruby match_stats.rb match-team.results
