require "readline"

$initial_program_path = ARGV[0]
$flipped_program_path = ARGV[1]

$i = 1

$current_position_suffix = "position-#{$i}.program"

$initial_program = "#{$initial_program_path}/#{$current_position_suffix}"
$flipped_program = "#{$flipped_program_path}/#{$current_position_suffix}"

$initial_program_exists = File.exists?($initial_program)

while ($initial_program_exists) do


  $i += 1

  $shifted_to = $i + $shift_value

  $current_position_suffix = "position-#{$i}.program"
  $shifted_position_suffix = "position-#{$shifted_to}.program"

  $initial_program = "#{$initial_program_path}/#{$current_position_suffix}"
  $shifted_to_program = "#{$shifted_program_path}/#{$shifted_position_suffix}"

  $initial_program_exists = File.exists?($initial_program)
end
