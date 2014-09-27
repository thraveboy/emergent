#!/bin/bash
show_current_game_config.sh
team1=`readlink units/current_team_1 | cut -c 4-`
team2=`readlink units/current_team_2 | cut -c 4-`
program1=`readlink programs/current_team_2_programs`
set_team_1.sh $team2
set_team_2.sh $team1
cp programs/outputProgram/* programs/currentBest/
cp programs/currentAttempt/* programs/outputProgram/
cp programs/currentBest/* programs/currentAttempt/
show_current_game_config.sh