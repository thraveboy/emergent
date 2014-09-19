require "readline"

$world_width = ARGV[0].to_i
$world_height = ARGV[1].to_i
$num_paths = ARGV[2].to_i
$density = ARGV[3].to_i

$y_paths = []

$map_hash = Hash.new

$blocks = '~!^><#$'
$objectives = '&?'

$new_map = File.new("worlds/generated_world.world", "w")
$randomizer = Random.new

$blocks_distribution = ''

$blocks.split("").each do |i|
  distribution = $randomizer.rand(100)
  (0..distribution).each do |iter|
    $blocks_distribution.concat(i)
  end
end

(1..$num_paths).each do |i|
  $y_paths.push($randomizer.rand($world_width))
end


$new_map.write("name generated-#{$world_width}-#{$world_height}-#{$num_paths}-#{$density}\n")

$half_height = ($world_height / 2) - 1
$width_minus_1 = $world_width  - 1

(0..$half_height).each do |y_axis|
  flipped_y = ($world_height - 1) - y_axis
  (0..$width_minus_1).each do |x_axis|
    flipped_x = ($world_width - 1) - x_axis
    current_hash_position = "#{y_axis}-#{x_axis}"
    flipped_hash_position = "#{flipped_y}-#{flipped_x}"
    value = '.'
    if ($y_paths.include?(x_axis) || $y_paths.include?(flipped_x)) ||
       ( y_axis == 0 || y_axis == $world_height-1)
      value = '.'
    else
      if $randomizer.rand(100) < $density
       if $randomizer.rand(100) < [($density / 20), 10].max
        value = $objectives[$randomizer.rand($objectives.size)]
       else
        value = $blocks_distribution[$randomizer.rand($blocks_distribution.size)]
       end
      else
        value = '.'
      end
    end
    $map_hash[current_hash_position] = value
    $map_hash[flipped_hash_position] = value
  end
end

$world_height_indexed = $world_height - 1
$world_width_indexed = $world_width - 1

(0..$world_height_indexed).each do |y_axis|
  $new_map.write("y#{y_axis} ")
  (0..$world_width_indexed).each do |x_axis|
    current_hash_position = "#{y_axis}-#{x_axis}"
    $new_map.write($map_hash[current_hash_position])
  end
  $new_map.write("\n")
end

$new_map.write("blocks #{$blocks}\n")
$new_map.write("objectives #{$objectives}\n")


