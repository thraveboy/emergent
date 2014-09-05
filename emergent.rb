require "readline"

VERBOSE_MACHINE = FALSE
CLEAR_SCREEN = FALSE
CLEAR_SCREEN_MAP_LOG = TRUE
CLEAR_SCREAN_TEAM_LOG = TRUE
STEP_COMMAND_PAUSE_LENGTH = 0
PAUSE_LENGTH = 0
IMPORTANT_MULTIPLIER = 0
SEED = 0
TOTAL_MUTATIONS = 20
MUTATION_MULTIPLIER = 3

MAP_LOG_FILE = "display_logs/map_log"
TEAM_LOG_FILE = "display_logs/team_log"
BATTLE_LOG_FILE = "display_logs/battle_log"

$map_log = File.new(MAP_LOG_FILE, 'w')
$battle_log = File.new(BATTLE_LOG_FILE, 'w')
$team_log = File.new(TEAM_LOG_FILE, 'w')

# Set sync = true so that writing to the display log files
# happens immediately (is not cached and stalled).
$map_log.sync = true
$battle_log.sync = true
$team_log.sync = true

def printl (text, log_file = "battle")
  print text
  if log_file == "battle"
    $battle_log.write text
  elsif log_file == "team"
    $team_log.write text
  else
    $map_log.write text
  end
end

def putsl (text, log_file = "battle")
  text_with_newline = text.dup.concat("\n")
  printl(text_with_newline, log_file)
end

$buffable_stats = ['armor', 'ballistic_skill', 'ballistic_range', 'ballistic_damage',
  'ballistic_defense_skill', 'melee_damage', 'melee_skill', 'move', 'magic_skill', 'magic_range']
$buffable_stats_and_stacks = $buffable_stats.dup

$mutatable_stats = []
$mutatable_stats.concat(['armor', 'ballistic_skill', 'ballistic_range', 'ballistic_damage',
  'ballistic_defense_skill', 'melee_damage', 'melee_skill', 'move', 'wounds', 'magic_skill', 'magic_range', 'magics'])

$important_pause_switch = false

def important_pause
  $important_pause_switch = true
end

def do_important_pauses
  if $important_pause_switch
    sleep IMPORTANT_MULTIPLIER * STEP_COMMAND_PAUSE_LENGTH
  end
  $important_pause_switch = false
end

def add_stacks_to_buffable_stat_list
  buff_stacks = []
  $buffable_stats.each do |buff_stat|
    buff_stacks.push("#{buff_stat}_buffs")
  end
  buff_stacks.each do |stack_to_add|
    $buffable_stats_and_stacks.push(stack_to_add)
  end
end

add_stacks_to_buffable_stat_list

if SEED != 0
  $randomizer = Random.new(SEED)
else
  $randomizer = Random.new
end

def verbose_machine(what_to_say)
  if VERBOSE_MACHINE
    puts what_to_say
  end
end

# Colored Output
def colorize(text, color_code)
  "\e[#{color_code}m#{text}\e[0m"
end

def red(text); colorize(text, 31); end
def green(text); colorize(text, 32); end
def yellow(text); colorize(text, 33); end
def blue(text); colorize(text, 34); end
def magneta(text); colorize(text, 35); end
def cyan(text); colorize(text, 36); end
def white(text); colorize(text, 37); end

def red_bg(text); colorize(text, 41); end
def green_bg(text); colorize(text, 42); end
def yellow_bg(text); colorize(text, 43); end
def blue_bg(text); colorize(text, 44); end
def magneta_bg(text); colorize(text, 45); end
def cyan_bg(text); colorize(text, 46); end
def white_bg(text); colorize(text, 47); end

def bold(text); colorize(text, 1); end
def blink(text); colorize(text, 5); end

def clear_screen(log = "")
  if (log == "map")
    $map_log.write("\e[2J\n")
  elsif (log == "team")
    $team_log.write("\e[2J\n")
  else
    print "\e[2J"
  end
end

def shortcut_everything?(command, input)
  (input.casecmp command) == 0 || (input.casecmp command[0]) == 0
end

class Object
  def metaclass
    class << self; self; end
  end
end

#*****======================================---------======================
#                                                                         *
#    THING Land                                                           *
#                                                                         *
#===========================---------------===========================*****


class Thing
  # Was this object already initialized?
  attr_accessor :initialized
  @initialized = false
  # Filename used to initialize the object
  @filename = nil

  def addCharacteristic (characteristic_line)
    split_line =  characteristic_line.split(' ',2)
    key = split_line[0]
    value = split_line[1]
    self.class.send(:attr_accessor, key)
    instance_variable_set("@#{key}", value)
    Object.send(:verbose_machine, "@#{key}")
  rescue
    Object.send(:verbose_machine,
      "Can not add characteristic from line #{characteristic_line}")
  end

  def initialize(filename = nil)
    if filename == nil
      @initialized = true
      return
    end
    Object.send(:verbose_machine, "Building Thing from " + filename)
    if File.exists?(filename)
      File.read(filename).each_line do |line|
        if !line.nil?
          self.addCharacteristic(line.rstrip)
        end
      end
      @initialized = true
      @filename = filename
    else
      putsl "..._"
      putsl "   file #{filename} does not exist__"
      putsl "                                    <<<."
    end
  end

  def method_missing(m, *args, &block)
    Object.send(:verbose_machine, "Method #{m} isn't defined.")
    return nil
  end

  def print_this_baby_out(omitted_variables = [], displays=[])
    putsl @name
    cray_cray = ""
    stuck_middle = ":"
    coo_coo   = ""
    instance_variables.each do |iv|
      if !(omitted_variables.include? (iv[1..-1]))
        iv_value = instance_variable_get(iv)
        iv_jv_name = "#{iv}"
        iv_jv_name[0] = ''
        putsl "#{cray_cray}#{iv_jv_name}#{stuck_middle}#{iv_value}#{coo_coo}"
      end
    end
  end
end


# What to call these things, and then go through the ARRRRaayyyy and
# pop out the info on these puppies...
#
#\/
#\/
def print_things_list(name, things, displays = [])
  i = 0
  putsl "#{name}s in existence..."
  putsl "-"
  putsl "_"
  for thing_instance in things
    i += 1
    printl "#{name} #{i} : "
    thing_instance.print_this_baby_out([], displays)
  end
  putsl "_"
  putsl "-"
end

#      `            
#      ...`.'#.``      Being
#       ,,,....``  


class Being < Thing
  attr_accessor :points

  def print_this_baby_out(omitted_variables = [], display = [])
    being_omit = ['initialized', 'filename']
    being_omit.each do |bo|
      omitted_variables.push(bo)
    end
    super omitted_variables
  end

  def initialize(filename = nil)
    @points = 1
    super(filename)
    $buffable_stats.each do |buffable_stat|
      metaclass.instance_eval do
        define_method(buffable_stat) {
          buff_value = 0
          buffs = instance_variable_get("@#{buffable_stat}_buffs")
          if !buffs.nil? && (buffs.size > 0)
            buff_value = buffs.pop.to_i
          end
          return instance_variable_get("@#{buffable_stat}").to_i + buff_value
        }
      end
    end
    self.apply_mutation
  end

  def get_brief_stats
    current_points = @points
    return_string = "#{current_points} Points -#{self.name}: wounds: #{self.wounds}"
  end

  def apply_mutation
    current_mutation = self.instance_variable_get("@mutation")
    if !current_mutation.nil? && current_mutation.length > 0
      mutation_array = current_mutation.split(" ")
      x = 0
      x_max = mutation_array.size
      while x < x_max
        current_mutation = mutation_array[x]
        if current_mutation != 'magics'
          self.instance_variable_set("@#{current_mutation}", self.instance_variable_get("@#{current_mutation}").to_i + 1)
        else
          x += 1
          magic_mutation = mutation_array[x]
          magic_list = self.instance_variable_get("@magics")
          if magic_list.nil?
            magic_list = ''
          end
          buff_amount_addition = (magic_mutation[-1].to_i - 1)
          if buff_amount_addition > 1
            @points += buff_amount_addition
          end
          magic_list.concat(" #{magic_mutation}")
          self.instance_variable_set("@magics", magic_list)
          self.class.send(:attr_accessor, 'magics')
        end
        @points += 1
        x += 1
      end
    end
  end

  def mutate(num_of_mutations = 5)
    current_mutation = []
    mutation_number = 0
    while mutation_number < num_of_mutations do
      rand_num = $randomizer.rand(100)
      stat_to_mutate = $mutatable_stats[rand_num % $mutatable_stats.size]
      if stat_to_mutate != 'magics'
        current_mutation.push(stat_to_mutate)
        new_stat_value = self.instance_variable_get("@#{stat_to_mutate}").to_i + 1
        mutation_number += 1
      else
        rand_num = $randomizer.rand(100)
        stat_to_buff = $buffable_stats[rand_num % $buffable_stats.size]
        putsl "stat_to_buff #{stat_to_buff}"
        new_stat_value = self.instance_variable_get("@#{stat_to_mutate}")
        if new_stat_value.nil?
          new_stat_value = ""
        end
        buff_type = "+"
        if rand(2) == 0
          buff_type = "-"
        end
        buff_amount = 1 + ($randomizer.rand(100) % (num_of_mutations - mutation_number))
        mutation_number += buff_amount
        mutation_string = " #{buff_type}#{stat_to_buff}#{buff_amount}"
        new_stat_value.concat(mutation_string)
        current_mutation.push("magics #{mutation_string}")
      end
    end
    self.instance_variable_set("@mutation", current_mutation.join(" "))
    self.apply_mutation
  end
end

#                         .......^^^%%%%...~~~~~
#                         ......^^%.....World.~~
#                         .....^%%%%%......~~~~~

class World < Thing
  def initialize(filename)
    super(filename)
    @space = []
    y_axis = 0
    while instance_variable_get("@y#{y_axis}") != nil
      x_as_string = instance_variable_get("@y#{y_axis}")
      x_max = x_as_string.length
      x_space = []
      if x_max > 0
        x_max -= 1
        for x_axis in 0..x_max
          current_space = Location.new
          current_space.add(x_as_string[x_axis])
          x_space[x_axis] = current_space
        end
      end
      @space[y_axis] = x_space
      y_axis += 1
    end
  end

  def get_space_dimensions
    returned_array = []
    x_current = 0
    @space.each do |x_axis|
      returned_array[x_current] = x_axis.length
      x_current += 1
    end
    returned_array
  end

  def get_location(x, y)
    unless (x < 0 || y < 0 ||
            @space[y].nil? || y >= @space.size ||
            @space[y][x].nil? || x >= @space[y].size)
      return @space[y][x]
    end
    return nil
  end

  def can_add?(what_to_add, x, y)
    unless (@space[y].nil? || y >= @space.size ||
            @space[y][x].nil? || x >= @space[y].size)
      return @space[y][x].can_add?(what_to_add)
    end
    return false
  end

  def get(type='being', x=0, y=0)
    location = self.get_location(x, y)
    unless location.nil? || (x < 0) || (y < 0)
      return location.get_objects_of_type(type)
    end
    return nil
  end

  def add(obj, x, y)
    location = self.get_location(x, y)
    unless location.nil?
      location.add(obj)
      return obj
    end
    return nil
  end

  def remove(type, x, y)
    location = self.get_location(x, y)
    unless location.nil?
      output_here = location.remove(type)
      return output_here
    end
    return nil
  end

  def print_map(displays = [])
    if CLEAR_SCREEN_MAP_LOG
      clear_screen("map")
    end
    @space.each do |y_axis|
      y_axis.each do |location|
        initial_location_strings = location.get_objects_of_type(String)
        beings_here = location.get_objects_of_type(Being)
        what_to_print = 'E'
        if beings_here != nil && beings_here != []
          displays.each do |current_display|
            display_value = ''
            current_being = beings_here[-1]
            display_value = current_display.get(current_being.name)
            being_wounds = current_being.wounds.to_i
            if current_being.team.to_i == 1
              display_value = bold(display_value)
            end
            if display_value != ''
              if being_wounds < 2
                what_to_print = red(display_value)
              elsif being_wounds < 3
                what_to_print = yellow(display_value)
              else
                what_to_print = white(display_value)
              end
            end
          end
          printl("#{what_to_print}", "map")
        else
          if initial_location_strings != nil
            if initial_location_strings[0] != nil
              printl(initial_location_strings[0], "map")
            end
          end
        end
      end
     putsl("", "map")
    end
  end

  def operate_over_space(operator, displays = [], simultaneous = true, beings = [])
    y=0
    world_dimensions = self.get_space_dimensions
    result_queue = []
    world_dimensions.each do |x_size|
      x=0
      while x < x_size do
        current_result_array = operator.execute(self, x, y)
        if (!current_result_array.nil?)
          current_result_array.each do |result_to_push|
            if simultaneous
              result_queue.push(result_to_push)
            else
              eval result_to_push
              output_team_stats(beings)
              self.print_map(displays)
            end
          end
        end
        x += 1
      end
      y += 1
    end
    if simultaneous
      result_queue.each do |queue_action|
        sleep STEP_COMMAND_PAUSE_LENGTH
         if CLEAR_SCREEN
          clear_screen
         end
         eval queue_action
         output_team_stats(beings)
         self.print_map(displays)
         do_important_pauses
      end
    end
  end

  def printl_this_baby_out(omitted_variables = [], displays = [])
    super omitted_variables.push('space')
    putsl " AMP MPA MAP"
    self.print_map(displays)
  end

end

#  .......Container... Container... Container....
class Container < Thing
  def add(what_to_add)
    if what_to_add.nil?
      return nil
    end
    added_class = what_to_add.class.name.downcase
    if instance_variable_get("@#{added_class}s") == nil
      instance_variable_set("@#{added_class}s", [])
    end
    instance_variable_get("@#{added_class}s").push(what_to_add)
    return what_to_add
  end

  def remove(type)
    removed_class = type.downcase
    if instance_variable_get("@#{removed_class}s") != nil
      return instance_variable_get("@#{removed_class}s").pop
    end
    return nil
  end

  def get_objects_of_type(type_to_retrieve)
    instance_variable_get("@#{type_to_retrieve}s".downcase)
  end
end

# .......Location..... location....ocation...
class Location < Container
  def can_add?(what_to_add)
    allowed_types = ["being"]
    obj_type = nil
    if !(what_to_add.nil?)
      if allowed_types.include?(what_to_add.class.name.downcase)
        obj_type = what_to_add.class.name.downcase
      end
    end
    if !(obj_type.nil?)
      current_objs = instance_variable_get("@#{obj_type}s")
      if (current_objs == nil) || (current_objs == [])
        return true
      end
    end
    return false
  end

  def can_remove?(what_to_remove)
    if !(what_to_remove.nil?)&&(what_to_remove.class.name.downcase == "being")
      current_beings = instance_variable_get("@beings")
    else
      return false
    end
  end
end

#===========================---------------===========================*****
#*****======================================---------======================
#                                    Operator(z)                       *
#                                                                       \
#*****======================================---------======================
#===========================---------------===========================*****


class Populate_Beings_BeingOperator < Thing
  def execute(beings, world)
    y_team_1 = 0
    y_team_others = 0
    size_team_1 = 0
    size_team_others = 0
    x_team_1 = 0
    x_team_others = 0
    if world != nil
      space_dimensions = world.get_space_dimensions
      if space_dimensions.length > 1
        y_team_1 = space_dimensions.length.to_i - 1
        putsl ".....Adding beings to world...."
        if beings != nil
          beings.each do |current_being|
            current_team = current_being.team.to_i
            if current_team == 1
              size_team_1 += 1
            else
              size_team_others += 1
            end
          end
          x_team_1 = ((space_dimensions[y_team_1] - size_team_1) / 2).to_i
          x_team_others = (space_dimensions[y_team_others] - 1) - ((space_dimensions[y_team_others] - size_team_others) / 2).to_i
          beings.each do |current_being|
            current_team = current_being.team.to_i
            printl current_team
            if current_team == 1
              y = y_team_1
              x = x_team_1
              x_team_1 += 1
            else
              y = y_team_others
              x = x_team_others
              x_team_others -= 1
            end
            world.add(current_being, x, y)
          end
          putsl " done populating...."
        end
      else
        putsl "No worlds exist yet..."
      end
    end
  end
end

class Mutate_Beings_BeingOperator < Thing
  def execute(beings, world)
    if beings != nil
      team_one_mutations_left = TOTAL_MUTATIONS
      team_others_mutations_left = TOTAL_MUTATIONS
      beings.each do |current_being|
        being_team = current_being.team.to_i
        num_mutations = 0
        if being_team == 1
          if team_one_mutations_left > 0
            num_mutations = $randomizer.rand(team_one_mutations_left) + 1
            team_one_mutations_left -= num_mutations
          end
        else
          if team_others_mutations_left > 0
            num_mutations = $randomizer.rand(team_others_mutations_left) + 1
            team_others_mutations_left -= num_mutations
          end
        end
        current_being.mutate(num_mutations)
      end
    end
  end
end

class TeamStats_BeingOperator < Thing
  def execute(beings, output_to_file = false)
    team_stats = Hash.new
    team_1_points = 0
    team_others_points = 0
    beings.each do |current_being|
      if !current_being.nil?
        current_team = current_being.team.to_i
        current_being_points = current_being.points.to_i
        if !current_team.nil?
          current_being_team_stats = current_being.get_brief_stats
          current_wounds = current_being.wounds
          if !current_wounds.nil?
            if current_wounds.to_i > 0
              current_being_team_stats = white(current_being_team_stats)
              if current_team == 1
                team_1_points += current_being_points
              else
                team_others_points += current_being_points
              end
            else
              current_being_team_stats = red(current_being_team_stats)
              if current_team == 1
                team_1_points -= current_being_points
              else
                team_others_points -= current_being_points
              end
            end
          end
          if team_stats["#{current_team}"].nil?
            team_stats["#{current_team}"] = ''
          end
          team_stats["#{current_team}"].concat("\n#{current_being_team_stats}")
        end
      end
    end
    team_stats["1 Points"] = team_1_points
    team_stats["2 Points"] = team_others_points
    if output_to_file
      team_results_file = File.new("match-team.results", "a")
      team_results_file.write("#{team_1_points} #{team_others_points}\n")
      team_results_file.close
    end
    return team_stats
  end
end

class DumpMutations_BeingOperator < Thing
  def execute(beings)
    living_mutation_team1_file = File.new("living_mutations_team1.mt", "a")
    living_mutation_teamothers_file = File.new("living_mutations_teamothers.mt", "a")
    dead_mutation_team1_file = File.new("dead_mutations_team1.mt", "a")
    dead_mutation_teamothers_file = File.new("dead_mutations_teamothers.mt", "a")
    beings.each do |current_being|
      if !current_being.nil? && (current_being.instance_variable_get("@wounds").to_i > 0)
        mutation = current_being.instance_variable_get('@mutation')
        if !mutation.nil? && mutation.length > 0
          if current_being.team.to_i == 1
            living_mutation_team1_file.write("#{mutation}\n")
          else
            living_mutation_teamothers_file.write("#{mutation}\n")
          end
        end
      elsif !current_being.nil?
        mutation = current_being.instance_variable_get('@mutation')
        if !mutation.nil? && mutation.length > 0
          if current_being.team.to_i == 1
            dead_mutation_team1_file.write("#{mutation}\n")
          else
            dead_mutation_teamothers_file.write("#{mutation}\n")
          end
        end
      end
    end
  end
end

class Being_Command_WorldOperator
  def execute(world, x, y)
    result = nil
    location_beings = world.get('being', x, y)
    if (location_beings != nil) && (location_beings != [])
      result = []
      top_being = location_beings.pop
      new_location =
        Command.new.execute_next_command(top_being, world, x, y)
      location_beings.push(top_being)
      add_being =
        "being_to_move = self.remove('Being', #{x}, #{y}); if self.can_add?(being_to_move, #{new_location['x']}, #{new_location['y']}) then self.add(being_to_move, #{new_location['x']}, #{new_location['y']}) else self.add(being_to_move, #{x}, #{y}) end"
      result.push(add_being)
    end
    return result
  end
end

class Magic_WorldOperator

  def execute(world, x, y)
    result = nil
    location_beings = world.get('being', x, y)
    if (location_beings != nil) && (location_beings != [])
      result = []
      magic_being = location_beings.pop
      location_beings.push(magic_being)
      if !magic_being.nil?
        range = 0
        if magic_being.magic_range.to_i > 0
          range = magic_being.magic_range.to_i
        end
        magic_power = magic_being.magic_power.to_i
        unless magic_being.magics.nil? || (magic_being.magics.length < 0)
          caster_magic_skill = magic_being.magic_skill.to_i
          caster_team = magic_being.team.to_i
          caster_name = magic_being.name
          if caster_team.to_i == 1
            caster_name = bold(caster_name)
          end
          magics = magic_being.magics.split
          magics.each do |the_magic|
            friendly_magic = true
            buffed_stat = the_magic
            buff_value = 1
            if the_magic[0] == '-'
              friendly_magic = false
              buffed_stat = the_magic[1..-1]
              buff_value = -1
            elsif the_magic[0] == '+'
              buffed_stat = the_magic[1..-1]
            end
            if buffed_stat[-1].to_i > 0
              buff_value *= buffed_stat[-1].to_i
              buffed_stat = buffed_stat[0..-2]
            end
            (x-range..x+range).each do |loop_x|
              (y-range..y+range).each do |loop_y|
                if ((loop_x >= 0) && (loop_y >= 0))
                  affected_being = nil
                  affected_beings = world.get('being', loop_x, loop_y)
                  unless affected_beings.nil? || affected_beings == []
                    affected_being = affected_beings.pop
                    if !affected_being.nil?
                      affected_beings.push(affected_being)
                      affected_being_buff_stack = affected_being.instance_variable_get("@#{buffed_stat}_buffs")
                      if affected_being_buff_stack.nil?
                        affected_being_buff_stack = []
                        affected_being.instance_variable_set("@#{buffed_stat}_buffs", affected_being_buff_stack)
                      end
                      affected_being_name = affected_being.name
                      affected_being_team = affected_being.team.to_i
                      if affected_being_team == 1
                        affected_being_name = bold(affected_being_name)
                      end
                      notification = "#{caster_name}(#{x},#{y}) attempts to buff #{affected_being_name}(#{loop_x},#{loop_y}) #{buffed_stat} by #{buff_value}"
                      if friendly_magic && (affected_being_team == caster_team)
                        affected_being_buff_stack.push(buff_value)
                        putsl white("#{notification} : Sucessful!")
                      elsif (affected_being.team.to_i != caster_team.to_i) && !friendly_magic
                        affected_being_magic_skill = affected_being.magic_skill.to_i
                        magic_skill_diff = caster_magic_skill - affected_being_magic_skill
                        if ($randomizer.rand(20) <= (10 + magic_skill_diff))
                          affected_being_buff_stack.push(buff_value)
                          putsl magneta("#{notification} : Succeeds.")
                        else
                          putsl cyan("#{notification} : Fails.")
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
    return result
  end

end

class Attack_WorldOperator

  def initialize(type = 'melee')
    @type = type
  end

  def execute(world, x, y)
    result = nil
    location_beings = world.get('being', x, y)
    if (location_beings != nil) && (location_beings != [])
      result = []
      attacking_being = location_beings.pop
      location_beings.push(attacking_being)
      if !attacking_being.nil?
        if @type == 'ranged'
          attacking_being_attack_skill = attacking_being.ballistic_skill
          attacking_being_attack_damage = attacking_being.ballistic_damage
        else
          attacking_being_attack_skill = attacking_being.melee_skill
          attacking_being_attack_damage = attacking_being.melee_damage
        end
        attacking_being_team = attacking_being.team
        if (attacking_being_attack_skill.nil? ||
            attacking_being_attack_damage.nil? ||
            attacking_being_team.nil?)
            return nil
        end
        range = 1
        x_min = x
        x_max = x
        x_step = 1
        y_min = y
        y_max = y
        y_step = 1
        ranged_shot = false
        if @type == 'ranged'
          range = attacking_being.ballistic_range.to_i
          facing = attacking_being.instance_variable_get('@facing')
          case facing
          when 'n'
            y_min = y
            y_max = y-range
            y_step = -1
          when 'e'
            x_min = x
            x_max = x+range
            x_step = 1
          when 's'
            y_min = y
            y_max = y+range
            y_step = 1
          when 'w'
            x_min = x
            x_max = x-range
            x_step = -1
          end
        else
          x_min = x-range
          x_max = x+range
          y_min = y-range
          y_max = y+range
        end
        x_min.step(x_max, x_step).each do |loop_x|
          y_min.step(y_max, y_step).each do |loop_y|
            def_being = nil
            def_beings = world.get('being', loop_x, loop_y)
            unless def_beings.nil? || def_beings == []
              def_being = def_beings.pop
              if !def_being.nil?
                def_beings.push(def_being)
                if (loop_x != x) || (loop_y != y) && ((loop_x >= 0) && (loop_y >= 0)) && !ranged_shot
                  def_being_combat_skill = 0
                  if @type == 'ranged'
                    def_being_combat_skill = def_being.ballistic_defense_skill
                  elsif @type == 'melee'
                    def_being_combat_skill = def_being.melee_skill
                  end
                  def_being_team = def_being.team
                  if (!def_being_combat_skill.nil? &&
                      def_being_team != attacking_being_team)
                    if @type == 'ranged'
                      ranged_shot = true
                    end
                    combat_skill_diff = (attacking_being_attack_skill.to_i -
                        def_being_combat_skill.to_i)
                    attacking_being_name = attacking_being.name
                    if attacking_being_team.to_i == 1
                      attacking_being_name = bold(attacking_being_name)
                    end
                    def_being_name = def_being.name
                    if def_being_team.to_i == 1
                      def_being_name = bold(def_being_name)
                    end
                    if ($randomizer.rand(20) <= (10 + combat_skill_diff))
                      return_string = "#{attacking_being_name}(#{x},#{y}) hit #{def_being_name}(#{loop_x},#{loop_y}) with a #{@type} attack. "
                      def_being_armor = def_being.armor
                      removed_wounds = (
                        (attacking_being_attack_damage.to_i + ($randomizer.rand(3)-1)) -
                         (def_being_armor.to_i + ($randomizer.rand(3)-1)))
                      if (removed_wounds > 0)
                        wound_string = return_string.concat(yellow("#{attacking_being_name} damages #{def_being_name} for #{removed_wounds} wounds.."))
                        damage_result =
                          "putsl '#{wound_string}'; damaged_being = self.remove('Being', #{loop_x}, #{loop_y}); if (!damaged_being.nil?) then damaged_being.wounds = damaged_being.wounds.to_i - #{removed_wounds}; if (damaged_being.wounds.to_i > 0) then self.add(damaged_being, #{loop_x}, #{loop_y}) else damaged_being_name = (damaged_being.team.to_i == 1 ? bold(damaged_being.name) : damaged_being.name); printl red(damaged_being_name); putsl red(' is killed!'); end; important_pause; end;"
                        result.push(damage_result)
                      else
                        bounce_string = "The #{attacking_being_name} #{@type} attack bounces off #{def_being_name}.."
                        bounce_result = "putsl '#{return_string}'; putsl white('#{bounce_string}'); important_pause";
                        result.push(bounce_result)
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
    return result
  end

end

class Assign_Program_BeingOperator < Thing
  def execute(beings, programs)
   if !beings.nil? && !programs.nil?
     current_being = beings.pop
     current_program = programs.pop
     current_being.program = current_program.program
     puts "Current Program: #{current_program}"
     beings.push current_being
   end
  end
end

#-----Commands---

class Command
  def parse_next_command(obj)
    returned_command = Hash.new
    returned_command["command"] = ''
    returned_command["args"] = ''
    program_string = obj.program
    if !(program_string.nil?) && (program_string != '')
      program_array = program_string.split(" ")
      current_command_string = program_array.shift
      program_array.push(current_command_string)
      obj.program = program_array.join(" ")
      if !(current_command_string.nil?) && (current_command_string != '')
        returned_command["command"] = current_command_string[0]
        returned_command["args"] = current_command_string[1..-1]
        if !obj.team.nil? && obj.team.to_i != 1
          command_type = returned_command["command"]
          case command_type
          when 'n'
            command_type = 's'
          when 's'
            command_type = 'n'
          when 'e'
            command_type = 'w'
          when 'w'
            commant_type = 'e'
          end
          returned_command["command"] = command_type
        end
      end
    end
    return returned_command
  end


  def execute_next_command(obj, world, start_x, start_y)
    new_location = { "x" => start_x, "y" => start_y }
    current_command = self.parse_next_command(obj)
    command_type = current_command["command"].downcase
    obj.instance_variable_set("@facing", command_type)
    command_args = current_command["args"]
    verbose_machine("#{obj.name} #{command_type} #{command_args}")
    if command_type != ''
      x_move_dir = 0
      y_move_dir = 0
      case command_type
      when 'n'
          y_move_dir = -1
      when 'e'
          x_move_dir = 1
      when 's'
          y_move_dir = 1
      when 'w'
          x_move_dir = -1
      end
      remaining_move = [command_args.to_i, obj.move.to_i].min
      if (x_move_dir != 0) || (y_move_dir != 0)
        x_to_check = new_location["x"]
        y_to_check = new_location["y"]
        while remaining_move > 0 do
          x_to_check += x_move_dir
          y_to_check += y_move_dir
          checked_location = world.get_location(x_to_check, y_to_check)
          if !checked_location.nil? && checked_location.can_add?(obj)
            new_location["x"] = x_to_check
            new_location["y"] = y_to_check
            remaining_move -= 1
          else
            remaining_move = 0
          end
        end
      end
    end
    return new_location
  end

end


#   :::::::::
#;;;:::   :::O@
#;;:::     :::O@
#;; DISPLAY::O@
#   :::::::::

class Display < Thing
  def get(name)
    if instance_variable_get("@#{name}") != nil
      return instance_variable_get("@#{name}")
    end
    return ''
  end
end

#"""""program

class Program < Thing
  attr_accessor :program
end

#-------
#----------------
#------------
#---
#----------------------
#----Line of Command-

def class_exists?(class_name)
  klass = Module.const_get(class_name)
  return klass.is_a?(Class)
rescue NameError
  return false
end

def output_team_stats(beings, output_to_file=false)
  team_results = TeamStats_BeingOperator.new.execute(beings, output_to_file)
  clear_screen("team")
  team_results.each do |key, value|
    putsl("Team #{key}: #{value}", "team")
    putsl("", "team")
  end
end

class LineOfCommand
  #Print very first command line prompt

  @types = ["being", "world", "display", "program"]

  @types.each do |current_type|
   instance_variable_set("@#{current_type}s", [])
  end

  def self.is_list_objects_command?(type_list, command)
    type_list.each do |type_to_check|
      if shortcut_everything?("#{type_to_check}s", command)
        return true
      end
    end
    return false
  end

  def self.get_list_type(type_list, command)
    type_list.each do |type_to_check|
      current_type_command_check = "#{type_to_check}s"
      if shortcut_everything?(current_type_command_check, command)
        return "#{type_to_check}"
      end
    end
    return nil
  end

  def self.evaluate_command(guess)
    guess.strip!
    if (shortcut_everything?("exit", guess) ||
      shortcut_everything?("quit", guess))
      beings = instance_variable_get("@beings")
      if !beings.nil?
        output_team_stats(beings, true)
      end
      exit
    elsif shortcut_everything?("list", guess)
      putsl "The Definitions and flows....."
      putsl Dir["*"]
      putsl "***Have flowed***"
    elsif shortcut_everything?("assign", guess)
      beings = instance_variable_get("@beings")
      programs = instance_variable_get("@programs")
      program_beings = Assign_Program_BeingOperator.new
      program_beings.execute(beings, programs)
    elsif shortcut_everything?("dump", guess)
      beings = instance_variable_get("@beings")
      displays = instance_variable_get("@displays")
      putsl "Dumping living mutations.."
      team_results = DumpMutations_BeingOperator.new.execute(beings)
    elsif shortcut_everything?("mutate", guess)
      beings = instance_variable_get("@beings")
      world = instance_variable_get("@worlds")[-1]
      mutate_beings = Mutate_Beings_BeingOperator.new
      mutate_beings.execute(beings, world)
    elsif shortcut_everything?("populate", guess)
      beings = instance_variable_get("@beings")
      world = instance_variable_get("@worlds")[-1]
      populate_beings = Populate_Beings_BeingOperator.new
      populate_beings.execute(beings, world)
    elsif shortcut_everything?("step", guess)
      world = instance_variable_get("@worlds")[-1]
      displays = instance_variable_get("@displays")
      beings = instance_variable_get("@beings")
      putsl "=====Movement"
      world.operate_over_space(Being_Command_WorldOperator.new, displays, true, beings)
      world.print_map(displays)
      putsl "-----Magic"
      world.operate_over_space(Magic_WorldOperator.new, displays, true, beings)
      putsl "-----Ranged attacks"
      world.operate_over_space(Attack_WorldOperator.new('ranged'), displays, true, beings)
      putsl "+++++Melee attacks"
      world.operate_over_space(Attack_WorldOperator.new('melee'), displays, true, beings)
    elsif shortcut_everything?("teams", guess)
      beings = instance_variable_get("@beings")
      displays = instance_variable_get("@displays")
      print_things_list('being', beings, displays)
      output_team_stats(beings)
    elsif self.is_list_objects_command?(@types, guess)
      list_type = self.get_list_type(@types, guess)
      if !list_type.nil?
        type_objs = instance_variable_get("@#{list_type}s")
        displays = instance_variable_get("@displays")
        print_things_list(list_type, type_objs, displays)
      end
    else
      filename_ext = (File.extname guess)
      if (filename_ext != "") && (filename_ext[1..-1].capitalize)
        type = filename_ext[1..-1].capitalize
        if @types.include?(type.downcase)
          thing = Object.const_get("#{type}").new(guess)
          Object.send(:verbose_machine, thing.instance_variables)
          if (thing.initialized == true)
            if (defined? thing.name)
              putsl "...Thing #{thing.name} created and initialized"
              Object.send(:verbose_machine, thing.instance_variables)
              putsl " .."
              instance_variable_get("@#{filename_ext[1..-1]}s").push(thing)
            else
              putsl  "    ||"
              putsl  "   \ ./"
              putsl  "  Thing not created"
              putsl  "    from #{guess} because"
              putsl  "       no 'name' "
              putsl  "  characteristic defined"
              putsl  "    |"
            end
          end
        else
          putsl ">ERR"
          putsl "ERR<"
        end
       end
    end

    worlds = instance_variable_get("@worlds")
    displays = instance_variable_get("@displays")
    if worlds != nil && worlds[-1] != nil
      worlds[-1].print_map(displays)
    end
  end

  ARGV.each do|a|
    if File.exists?(a)
      File.read(a).each_line do |line|
        if !line.nil?
          sleep PAUSE_LENGTH
           if CLEAR_SCREEN
             clear_screen
           end
          self.evaluate_command(line)
        end
      end
    end
  end

  # Main command line input->evaluate^pop-or->newLineandprintnewprompt
  last_guess = ""
  while guess = Readline.readline("-Machine: ", true)
    if CLEAR_SCREEN
      clear_screen
    end
    if guess == ""
      guess = last_guess
    end
    self.evaluate_command(guess)
    last_guess = guess
  end

  putsl "Reseting.... Done."
end
