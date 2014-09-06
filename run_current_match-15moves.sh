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
    echo -n "Date/time: ";  date -v1d -v3m -v0y -v-1d
    echo -n "Games Run: "; echo $gamesrun
    echo -n "Game:"; readlink games/currentGame-15moves
    echo -n "Team 1:"; readlink units/current_team_1
    echo -n "Team 2:"; readlink units/current_team_2
    echo -n "Team 1 Programs:" ;readlink programs/current_team_1_programs
    echo -n "Team 2 Programs:" ;readlink programs/current_team_2_programs
    ruby match_stats.rb match-team.results
  fi
  ruby emergent.rb games/currentGame > /dev/null;
  let gamesrun=gamesrun+1
  let currentiteration=currentiteration+1
done

echo -n "Games Run: "; echo $gamesrun
echo -n "Game:"; readlink games/currentGame
echo -n "Team 1:"; readlink units/current_team_1
echo -n "Team 2:"; readlink units/current_team_2
echo -n "Team 1 Programs:" ;readlink programs/current_team_1_programs
echo -n "Team 2 Programs:" ;readlink programs/current_team_2_programs

ruby match_stats.rb match-team.results
