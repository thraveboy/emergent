require "readline"

$team_unit_path = ARGV[0]
$team_program_path = ARGV[1]

puts $team_unit_path
puts $team_program_path

$i=1

$unit_suffix = "position-#{$i}.being"
$program_suffix = "position-#{$i}.program"

$initial_unit = "#{$team_unit_path}/#{$unit_suffix}"
$initial_program = "#{$team_program_path}/#{$program_suffix}"

$unit_exists = File.exists?($initial_unit)
$program_exists = File.exists?($initial_program)

while ($unit_exists) do
  puts $initial_unit
  puts $initial_program
  puts "assign"

  $i += 1

  $unit_suffix = "position-#{$i}.being"
  $program_suffix = "position-#{$i}.program"

  $initial_unit = "#{$team_unit_path}/#{$unit_suffix}"
  $initial_program = "#{$team_program_path}/#{$program_suffix}"

  $unit_exists = File.exists?($initial_unit)
  $program_exists = File.exists?($initial_program)

end
