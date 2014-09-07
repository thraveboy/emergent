require "readline"

$initial_program_path = ARGV[0]
$added_program_path = ARGV[1]
$destination_program_path = ARGV[2]

$i=1

$current_position_suffix = "position-#{$i}.program"

$initial_program = "#{$initial_program_path}/#{$current_position_suffix}"
$added_program = "#{$added_program_path}/#{$current_position_suffix}"
$destination_program = "#{$destination_program_path}/#{$current_position_suffix}"

$initial_program_exists = File.exists?($initial_program)
$added_program_exists = File.exists?($added_program)

while ($initial_program_exists) do
  initial_program_file = File.new($initial_program, "r")

  destination_program_text = ''

  initial_program_file.each_line do |line|
    split_line = line.split(' ', 2)
    if split_line[0] == 'program'
      initial_text = split_line[1]
      destination_program_text.concat("#{initial_text} ")
    end
  end

  if $added_program_exists
    added_program_file = File.new($added_program, "r")
    added_program_file.each_line do |line|
      split_line = line.split(' ', 2)
      if split_line[0] == 'program'
        added_text = split_line[1]
        destination_program_text.concat("#{added_text} ")
      end
    end
  end

  destination_program_file = File.new($destination_program, "w")
  destination_program_file.write("#{$current_position_suffix}\nname program #{destination_program_text}")
  destination_program_file.close

  $i += 1

  $current_position_suffix = "position-#{$i}.program"

  $initial_program = "#{$initial_program_path}/#{$current_position_suffix}"
  $added_program = "#{$added_program_path}/#{$current_position_suffix}"
  $destination_program = "#{$destination_program_path}/#{$current_position_suffix}"

  $initial_program_exists = File.exists?($initial_program)
  $added_program_exists = File.exists?($added_program)

end
