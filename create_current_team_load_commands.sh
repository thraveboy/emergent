rm team_1_load_temp
rm team_2_load_temp
ruby load_unit_programs.rb units/current_team_1 programs/current_team_1_programs > team_1_load_temp
echo "i" > team_switch_load_temp
ruby load_unit_programs.rb units/current_team_2 programs/current_team_2_programs > team_2_load_temp
