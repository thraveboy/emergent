#!/bin/bash
numberofiterations=$1
currentiteration=1
matchesperiteration=$2
stepsthorough=$3

rm defeated

./clean_match_raw.sh
./show_current_game_config.sh
./create_current_team_load_commands.sh
set_programs_team_1.sh programs/outputProgram/

let halfway=$matchesperiteration
let halfway=$halfway/2

while [ $currentiteration -le $numberofiterations ]
do
  let currentmatch=1
  echo "iteration $currentiteration";
  ./clean_match_raw.sh

  cat games/display_logs_off team_1_load_temp team_switch_load_temp team_2_load_temp games/currentGame games/move-15 games/move-15-quit | ruby emergent.rb > /dev/null

  ruby match_stats.rb match-team.results
  result=`ruby match_winner.rb match-team.results`
  if [ $result -eq 1 ]
    then
      let team2wins=0
      while [ $currentmatch -le $matchesperiteration ]
      do
        echo -n "."
        cat games/display_logs_off team_1_load_temp team_switch_load_temp team_2_load_temp games/currentGame games/move-15 games/move-15-quit | ruby emergent.rb > /dev/null
        resultmany=`ruby match_winner.rb match-team.results`
        if [ $resultmany -eq 2 ]
          then
            let team2wins=$team2wins+1
            if [ $team2wins -ge $halfway ]
              then
              let currentmatch=$matchesperiteration+1
            else 
              let currentmatch=$currentmatch+1
            fi 
        else
          let currentmatch=$currentmatch+1
        fi
        echo -n $resultmany
      done
      ruby match_stats.rb match-team.results
      resultmany=`ruby match_winner.rb match-team.results`
      if [ $resultmany -eq 1 ]
        then
          run_clean_match.sh $stepsthorough
          resultthorough=`ruby match_winner.rb match-team.results`
          if [ $resultthorough -eq 1 ]  
            then
              cat team_1_load_temp team_switch_load_temp team_2_load_temp games/currentGame games/move-15 games/move-15-quit | ruby emergent.rb > /dev/null
              cp programs/outputProgram/* programs/currentBest
              echo "+new current best+ BEAT YOU now in programs/currentBest"
              exit
          fi
      fi
  fi

  cat games/display_logs_off team_1_load_temp team_switch_load_temp team_2_load_temp games/currentGame games/reprogram-output-quit | ruby emergent.rb > /dev/null

  let currentiteration=currentiteration+1
done

touch defeated
echo "could not defeat you. :("