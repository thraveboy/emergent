echo -n "Date/time: ";  date -v1d -v3m -v0y -v-1d
echo -n "Game:"; readlink games/currentGame
echo -n "Team 1:"; readlink units/current_team_1
echo -n "Team 2:"; readlink units/current_team_2
echo -n "Team 1 Programs:" ;readlink programs/current_team_1_programs
echo -n "Team 2 Programs:" ;readlink programs/current_team_2_programs
