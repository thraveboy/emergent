require "readline"

$initial_program_path = ARGV[0]
$flipped_program_path = ARGV[1]

$i = 1

$current_position_suffix = "position-#{$i}.program"

$initial_program = "#{$initial_program_path}/#{$current_position_suffix}"
$flipped_program = "#{$flipped_program_path}/#{$current_position_suffix}"

$initial_program_exists = File.exists?($initial_program)

while ($initial_program_exists) do
  flipped_program_file = File.new($flipped_program, "w")

  File.read($initial_program).each_line do |line|
    split_line = line.split(' ', 2)
    key = split_line[0]
    if key.downcase != "program"
      flipped_program_file.write("#{line}")
    else
      program_input = split_line[1]
      program_output = ""
      program_input.split("").each do |char|
        if char.downcase == 'w'
          program_output.concat('e')
        elsif char.downcase == 'e'
          program_output.concat('w')
        else
          program_output.concat("#{char}")
        end
      end
      flipped_program_file.write("#{key} #{program_output}")
    end
  end

  $i += 1

  $current_position_suffix = "position-#{$i}.program"

  $initial_program = "#{$initial_program_path}/#{$current_position_suffix}"
  $flipped_program = "#{$flipped_program_path}/#{$current_position_suffix}"

  $initial_program_exists = File.exists?($initial_program)
end
