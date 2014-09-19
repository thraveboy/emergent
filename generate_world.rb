require "readline"

$world_width = ARGV[0].to_i
$world_height = ARGV[1].to_i
$num_paths = ARGV[2].to_i
$density = ARGV[3].to_i

$y_paths = []

$blocks = '~!^><#$'
$objectives = '&?'

$new_map = File.new("worlds/generated_world.world", "w")
$randomizer = Random.new

(1..$num_paths).each do |i|
  $y_paths.push($randomizer.rand($world_width))
end


$new_map.write("name generated-#{$world_width}-#{$world_height}-#{$num_paths}-#{$density}\n")

(0..$world_height-1).each do |y_axis|
  $new_map.write("y#{y_axis} ")
  (0..$world_width-1).each do |x_axis|
    if $y_paths.include?(x_axis) || y_axis == 0 || y_axis == $world_height-1
      $new_map.write('.')
    else
      if $randomizer.rand(100) < $density
       if $randomizer.rand(100) < ($density / 20)
        $new_map.write($objectives[$randomizer.rand($objectives.size)])
       else
        $new_map.write($blocks[$randomizer.rand($blocks.size)])
       end
      else
        $new_map.write('.')
      end
    end
  end
  $new_map.write("\n")
end

$new_map.write("blocks #{$blocks}\n")
$new_map.write("objectives #{$objectives}\n")


