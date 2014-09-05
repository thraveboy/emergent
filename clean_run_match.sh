./clean_match_raw.sh
time ./run_current_match.sh > /dev/null
ruby match_stats.rb match-team.results
