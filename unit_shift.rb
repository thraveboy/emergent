require "readline"

$initial_being_path = ARGV[0]
$shifted_being_path = ARGV[1]
$shift_amount = ARGV[2]

$shift_value = 0

if $shift_amount.nil? || $shift_amount.to_i > 0
  $shift_value = $shift_amount.to_i
end

$i=1

$current_position_suffix = "position-#{$i}.being"

$shifted_to = $i + $shift_value

$shifted_position_suffix = "position-#{$shifted_to}.being"

$initial_being = "#{$initial_being_path}/#{$current_position_suffix}"
$shifted_to_being = "#{$shifted_being_path}/#{$shifted_position_suffix}"

$initial_being_exists = File.exists?($initial_being)

while ($initial_being_exists) do
  puts $initial_being
  puts $shifted_to_being
  system "cp #{$initial_being} #{$shifted_to_being}"

  $i += 1

  $shifted_to = $i + $shift_value

  $current_position_suffix = "position-#{$i}.being"
  $shifted_position_suffix = "position-#{$shifted_to}.being"

  $initial_being = "#{$initial_being_path}/#{$current_position_suffix}"
  $shifted_to_being = "#{$shifted_being_path}/#{$shifted_position_suffix}"

  $initial_being_exists = File.exists?($initial_being)
end
