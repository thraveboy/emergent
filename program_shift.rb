require "readline"

$initial_program_path = ARGV[0]
$shifted_program_path = ARGV[1]
$shift_amount = ARGV[2]

$shift_value = 0

if $shift_amount.nil? || $shift_amount.to_i > 0
  $shift_value = $shift_amount.to_i
end

$i=1

$current_position_suffix = "position-#{$i}.program"

$shifted_to = $i + $shift_value

puts $shifted_to
puts $i
puts $shift_value

$shifted_position_suffix = "position-#{$shifted_to}.program"

$initial_program = "#{$initial_program_path}/#{$current_position_suffix}"
$shifted_to_program = "#{$shifted_program_path}/#{$shifted_position_suffix}"

$initial_program_exists = File.exists?($initial_program)

while ($initial_program_exists) do
  puts $initial_program
  puts $shifted_to_program
  system "cp #{$initial_program} #{$shifted_to_program}"

  $i += 1

  $shifted_to = $i + $shift_value

  $current_position_suffix = "position-#{$i}.program"
  $shifted_position_suffix = "position-#{$shifted_to}.program"

  $initial_program = "#{$initial_program_path}/#{$current_position_suffix}"
  $shifted_to_program = "#{$shifted_program_path}/#{$shifted_position_suffix}"

  $initial_program_exists = File.exists?($initial_program)
end
