#!/bin/bash
numberofiterations=10000
currentiteration=0
gamesrun=0
moditer=0

while [ $currentiteration -le $numberofiterations ]
do
  ruby emergent.rb games/currentGame > /dev/null;
  let gamesrun=gamesrun+1
  let moditer=currentiteration%50
  if [ $moditer -eq 0 ] ; 
   then
    echo -n "Games Run: "; echo $gamesrun
    echo -n "Game:"; readlink games/currentGame
    echo -n "Team 1:"; readlink units/current_team_1
    echo -n "Team 2:"; readlink units/current_team_2
    echo -n "Team 1 Programs:" ;readlink programs/current_team_1_programs
    echo -n "Team 2 Programs:" ;readlink programs/current_team_2_programs
    ruby match_stats.rb match-team.results
  fi
  let currentiteration=currentiteration+1
done

readlink games/currentGame
readlink units/current_team_1
readlink units/current_team_2
readlink programs/current_team_1_programs
readlink programs/current_team_2_programs
ruby match_stats.rb match-team.results
