#!/bin/bash
numberofiterations=$1
currentiteration=1
matchesperiteration=$2

./clean_match_raw.sh
./show_current_game_config.sh
./create_current_team_load_commands.sh
set_programs_team_1.sh programs/outputProgram/
set_programs_team_2.sh programs/currentBest/

while [ $currentiteration -le $numberofiterations ]
do
  let currentmatch=1
  echo "iteration $currentiteration";
  cat games/display_logs_off team_1_load_temp team_switch_load_temp team_2_load_temp games/currentGame games/reprogram-output-quit | ruby emergent.rb > /dev/null
  ./clean_match_raw.sh
  while [ $currentmatch -le $matchesperiteration ]
  do
    echo -n "."
    cat games/display_logs_off team_1_load_temp team_switch_load_temp team_2_load_temp games/currentGame games/move-15 games/move-15-quit | ruby emergent.rb > /dev/null
    let currentmatch=currentmatch+1
  done
  echo
  result=`ruby match_winner.rb match-team.results`
  if [ $result -eq 1 ]
    then
      echo "+new current best+"
      cat team_1_load_temp team_switch_load_temp team_2_load_temp games/currentGame games/move-15 games/move-15-quit | ruby emergent.rb > /dev/null
      cp programs/outputProgram/* programs/currentBest
  fi
  let currentiteration=currentiteration+1
done
