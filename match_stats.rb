total_matches = 0
team_1_wins = 0
team_1_points = 0
team_2_wins = 0
team_2_points = 0
ties = 0
ARGV.each do|a|
  if File.exists?(a)
    File.read(a).each_line do |line|
      total_matches += 1
      line_array = line.split
      team_1 = line_array[0].to_i
      team_2 = line_array[1].to_i
      team_1_points += team_1
      team_2_points += team_2
      if team_1 > team_2
        team_1_wins += 1
      elsif team_2 > team_1
        team_2_wins += 1
      else
        ties += 1
      end
    end
  end
end

total_matches = total_matches.to_f
team_1_avg_pts = team_1_points / total_matches
team_2_avg_pts = team_2_points / total_matches
team_1_avg_wins = (team_1_wins * 100.0) / total_matches
team_2_avg_wins = (team_2_wins * 100.0) / total_matches
ties_avg = (ties * 100.0) / total_matches

team_1_avg_pts = team_1_avg_pts.round(3)
team_2_avg_pts = team_2_avg_pts.round(3)
team_1_avg_wins = team_1_avg_wins.round(1)
team_2_avg_wins = team_2_avg_wins.round(1)
ties_avg = ties_avg.round(1)

puts "Wins T1:#{team_1_wins} T2:#{team_2_wins} T:#{ties} AvgWins T1:#{team_1_avg_wins}%  T2:#{team_2_avg_wins}% T:#{ties_avg}%"
puts "Pts T1:#{team_1_points} T2:#{team_2_points} AvgPts T1:#{team_1_avg_pts} T2:#{team_2_avg_pts}"

