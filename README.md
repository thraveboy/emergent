emergent
========

An emergent programmable gaming system

To run type this in the base directory:

emergent

To create generate a new map, and two teams:

emergent 40 20 10 50

and then automatically evolve them

time evolve_both_programs.sh 200 100 10 50

-----

Show current game configuration:

./show_current_game_config.sh


To open the HUD:

./open_hud.sh


To run a match:

./run_current_match-interactive.sh

To run a match lots of times:

time ./run_current_match-15moves.sh 100

 
To clean the raw match results:

./clean_match_raw.sh

To run a match lots of times (like above)

time ./run_current_match-15moves.sh 10 

To analyze match results:

 ruby match_stats.rb match-team.results


To concat a program to another:

ruby program_concat.rb programs/straight_single-north-1-10 programs/wide_wall-north-15-10 programs/currentProgram

To shift a units positions:

ruby unit_shift.rb units/base_man_5 units/base_man_15 5

To shift a program positions:

ruby program_shift.rb programs/vertical_wall_march_north_3-15-5 programs/currentProgramShifted 5;


To clean raw results, run a match many times, analyze results, and output the results to a file:

time ./run_clean_match.sh | tee results/test_1.results



The shell that will run a mutation  lots of times

 time ./mutation_run.sh > /dev/null


To show the mutation analysis:

 sort living_mutations.mt | uniq -c | sort | tail > living_mutation_summary; sort dead_mutations.mt | uniq -c | sort | tail > dead_mutation_summary
 ruby mutation_stats.rb living_mutation_summary dead_mutation_summary 



To run match analysis

wc -l match-team.results ; ruby team_stats.rb match-team.results 


To generate a new map (overwriting last generated map) saved as worlds/generated_world.world

ruby generate_world.rb 40 10 10 50; more worlds/generated_world.world


Generate a new map (overwriting last generated map) and fire up an interactive game session:

ruby generate_world.rb 40 10 30 50; more worlds/generated_world.world ; emergent

To mutate team 1's program to be optimal against itself (ie: 30 configurations, 10 test matches)

time mutate_program.sh 30 10


To have it reset the program, mutate 100 times and says it succeeds if it wins 20 times.

Reids-MacBook-Air:emergent thraveboy$ show_current_game_config.sh
Game:gameStandardCurrent
World:../worlds/generated_world.world
Display:beings-men-elves.display
Team 1:../campaigns/mountains_of_the_mist/units/orc_unit/
Team 2:../campaigns/mountains_of_the_mist/units/party_of_three/
Team 1 Programs:../programs/outputProgram/
Team 2 Programs:../programs/currentAttempt/
Date/time: Tue Feb 29 02:21:38 PST 2000
Reids-MacBook-Air:emergent thraveboy$ reset_mutation_programs.sh 
Reids-MacBook-Air:emergent thraveboy$ time mutate_program.sh 100 20


To run two unit/programs against each other and evolve the programs (20 times switching sides, 100 mutations to see if you can win, 20 times to test before full test, full test number is 100)

evolve_both_programs.sh 20 100 20 100
