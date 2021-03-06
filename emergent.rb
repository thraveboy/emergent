require "readline"
require "./emergent_constants"
require "./emergent_helpers"
require "./emergent_display"
require "./emergent_wordnik"

$dump_logs = TRUE
$current_step = 1

$location_allowed_types =["being", "programmarker", "activeflag"]
$output_team_stats_each_action = FALSE

$program_steps_to_show = 30

$team_number = 1
$objective_multiplier = 10

$map_log = File.new(MAP_LOG_FILE, 'w')
$battle_log = File.new(BATTLE_LOG_FILE, 'w')
$team_log = File.new(TEAM_LOG_FILE, 'w')

# Set sync = true so that writing to the display log files
# happens immediately (is not cached and stalled).
$map_log.sync = true
$battle_log.sync = true
$team_log.sync = true

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
  if $important_pause_switch && $dump_logs
    sleep IMPORTANT_PAUSE_LENGTH
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

def shortcut_everything?(command, input)
  (input.casecmp command) == 0 || (input.casecmp command[0]) == 0
end

class Object
  def metaclass
    class << self; self; end
  end
end

#    THING Land                                                           *

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
  rescue
  end

  def initialize(filename = nil)
    if filename == nil
      @initialized = true
      return
    end
    if File.exists?(filename)
      File.read(filename).each_line do |line|
        if !line.nil?
          self.addCharacteristic(line.rstrip)
        end
      end
      @initialized = true
      @filename = filename
    else
      putsl red("   file #{filename} does not exist__")
    end
  end

  def method_missing(m, *args, &block)
    return nil
  end

  def print_this_baby_out(omitted_variables = [], displays=[], output_file = nil)
    instance_variables.each do |iv|
      if !(omitted_variables.include? (iv[1..-1]))
        iv_value = instance_variable_get(iv)
        iv_jv_name = "#{iv}"
        iv_jv_name[0] = ''
        output_string = "#{iv_jv_name} #{iv_value}"
        putsl output_string
        if !output_file.nil?
          output_file.write("#{output_string}\n")
        end
      end
    end
  end
end


# What to call these things, and then go through the ARRRRaayyyy and
# pop out the info on these puppies...
def print_things_list(name, things, displays = [])
  i = 0
  putsl "#{name}s in existence..."
  for thing_instance in things
    i += 1
    printl "#{name} #{i} : "
    thing_instance.print_this_baby_out([], displays)
  end
end

#      ...`.'#.``      Being

class Being < Thing
  attr_accessor :facing
  attr_accessor :marked
  attr_accessor :objective_points
  attr_accessor :points
  attr_accessor :program
  attr_accessor :specialty
  attr_accessor :team
  attr_accessor :visibility_map

  def print_this_baby_out(omitted_variables = [], display = [], output_being_file = nil)
    being_omit = ['initialized', 'filename']
    being_omit.each do |bo|
      omitted_variables.push(bo)
    end
    super(omitted_variables, display, output_being_file)
    if !@visibility_map.nil?
      putsl "visibility_map(print_map):"
      @visibility_map.print_map(display)
    end
  end

  def initialize(filename = nil)
    super(filename)
    @facing = ''
    @marked = false
    @objective_points = 0
    @points = 1
    @program = ''
    @specialty = "standard"
    @team = $team_number
    @visibility_map = nil
    $buffable_stats.each do |buffable_stat|
      buff_instance_var = "@#{buffable_stat}_buffs"
      if self.instance_variable_defined?("#{buff_instance_var}")
        remove_instance_variable("#{buff_instance_var}")
      end
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

  def display_value(display)
    display_value = display.get(@specialty)
    if display_value != ''
      if @team.to_i == 1
        display_value = magneta(display_value)
      else
        display_value = yellow(display_value)
      end
      if @wounds.to_i > 2
         display_value = bold(display_value)
       end
    end
    return display_value
  end

  def get_points_including_objectives
    return @points + (@objective_points * $objective_multiplier)
  end

  def get_brief_stats
    current_points = get_points_including_objectives
    program_display = self.program[0..1]
    if self.marked
      program_display = blue_bg(program_display)
    end
    return_string = "#{self.name}\n   pt:#{current_points} (#{self.specialty})\n   w:#{self.wounds} a:#{self.armor} md:#{self.melee_damage} ms:#{self.melee_skill} bd:#{self.ballistic_damage} br:#{self.ballistic_range} bs:#{self.ballistic_skill} bds:#{self.ballistic_defense_skill}\n   mr:#{self.magic_range} ms:#{self.magic_skill} mv:#{self.move} d:#{self.facing} n:#{program_display}\n   m:#{self.magics}"
  end

  def apply_mutation(mutate_name = true)
    current_mutation = self.instance_variable_get("@mutation")
    @points = @points.to_i
    mutation_name_hash = Hash.new
    if !current_mutation.nil? && current_mutation.length > 0
      mutation_array = current_mutation.split(" ")
      x = 0
      x_max = mutation_array.size
      while x < x_max
        current_mutation = mutation_array[x]
        if mutation_name_hash["#{current_mutation}"].nil?
          mutation_name_hash["#{current_mutation}"] = 0
        end
        mutation_name_hash["#{current_mutation}"] += 1
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
      if !mutation_name_hash.nil?
        name_value = mutation_name_hash.max_by{ |k, v| v}
        if !name_value.nil?
          new_name = name_value[0]
          if !new_name.nil? && new_name != ''
            synonym_list_name = ''
            new_name.split("_").each do |i|
              added_string = find_synonym(i)
              synonym_list_name.concat("#{added_string}er ")
            end
            if mutate_name
              @name = "#{synonym_list_name}"
            end
            if @points >= 5
              @name = @name.split.map(&:capitalize).join(' ')
              new_name = new_name.capitalize
            end
            @specialty = new_name
          end
        end
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
  end
end

class ProgramMarker < Thing
  attr_accessor :program
  attr_accessor :move

  def display_value(display, starting_value = '')
    return yellow_bg(starting_value)
  end
end

class ActiveFlag < Thing
end

#                         ......^^%.....World.~~

class World < Thing
  def initialize(filename = nil)
    super(filename)
    @space = []
    if !filename.nil?
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
    else
      @space[0] = []
    end
  end

  def set_space(new_space)
    @space = new_space
    return self
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
      if !@blocks.nil?
        initial_location_strings = @space[y][x].get_objects_of_type(String)
        if initial_location_strings != nil
          if initial_location_strings[0] != nil
            if @blocks.include?(initial_location_strings[0])
              return false
            end
          end
        end
      end
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

  def objective_location?(world_location_symbol)
    if world_location_symbol.nil?
      return false
    end
    if !@objectives.nil? && @objectives.include?(world_location_symbol)
      return true
    end
    return false
  end

  def blocked_location?(world_location_symbol)
    if world_location_symbol.nil?
      return false
    end
    if !@blocks.nil? && @blocks.include?(world_location_symbol)
      return true
    end
    return false
  end

  def colorize_location(world_location_to_print)
    if world_location_to_print.nil?
      return world_location_to_print
    end
    if blocked_location?(world_location_to_print)
      return red(world_location_to_print)
    elsif objective_location?(world_location_to_print)
      return bold(white(world_location_to_print))
    end
    return green(world_location_to_print)
  end

  def print_map(displays = [])
    if $dump_logs
      if CLEAR_SCREEN_MAP_LOG
        clear_screen("map")
      end
      @space.each do |y_axis|
        y_axis.each do |location|
          if !location.nil?
            initial_location_strings = location.get_objects_of_type(String)
            beings_here = location.get_objects_of_type(Being)
            program_markers_here = location.get_objects_of_type(ProgramMarker)
            if $dump_logs
              active_here = location.remove("ActiveFlag")
            end
          end
          what_to_print = 'E'
          if beings_here != nil && beings_here != []
            displays.each do |current_display|
              what_to_print = ''
              current_being = beings_here[-1]
              what_to_print = current_being.display_value(current_display)
              if initial_location_strings != nil && initial_location_strings[0] != nil
                if objective_location?(initial_location_strings[0])
                  what_to_print = blue_bg(what_to_print)
                end
              end
            end
          else
            if initial_location_strings != nil && initial_location_strings[0] != nil
                world_location_to_print = colorize_location(initial_location_strings[0])
                what_to_print = world_location_to_print
            end
          end
          if !program_markers_here.nil? && program_markers_here.size > 0
            current_marker = program_markers_here[-1]
            what_to_print = current_marker.display_value(current_display, what_to_print)
          end
          if !active_here.nil?
            what_to_print = blink(what_to_print)
          end
          printl("#{what_to_print}", "map")
        end
       putsl("", "map")
      end
    end
  end

  def operate_over_space(operator, displays = [], beings = [], print_map_each_step = true)
    y=0
    world_dimensions = self.get_space_dimensions
    result_queue = []
    world_dimensions.each do |x_size|
      x=0
      while x < x_size do
        current_result_array = operator.execute(self, x, y)
        if (!current_result_array.nil?)
          current_result_array.each do |result_to_push|
           result_queue.push(result_to_push)
          end
        end
        x += 1
      end
      y += 1
    end

    result_queue.each do |queue_action|
      if $dump_logs
        sleep STEP_COMMAND_PAUSE_LENGTH
      end
      if CLEAR_SCREEN
       clear_screen
      end
      eval queue_action
      if $output_team_stats_each_action
        output_team_stats(beings, self)
      end
      if print_map_each_step
        self.print_map(displays)
      end
      do_important_pauses
    end
    if !print_map_each_step
      self.print_map(displays)
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
      return_value = instance_variable_get("@#{removed_class}s").pop
      instance_variable_set("@#{removed_class}s", [])
      return return_value
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
    allowed_types = $location_allowed_types
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

#                                    Operator(z)                       *

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
            num_mutations = $randomizer.rand([team_one_mutations_left, 9].min) + 1
            team_one_mutations_left -= num_mutations
          end
        else
          if team_others_mutations_left > 0
            num_mutations = $randomizer.rand([team_others_mutations_left, 9].min) + 1
            team_others_mutations_left -= num_mutations
          end
        end
puts num_mutations
        current_being.mutate(num_mutations)
      end
    end
  end
end

class TeamStats_BeingOperator < Thing
  def execute(beings, world, output_to_file = false, output_beings = false)
    team_stats = Hash.new
    team_stats["2"] = ''
    team_stats["1"] = ''
    team_1_points = 0
    team_others_points = 0
    team_being_number = Hash.new
    team_being_number["2"] = 0
    team_being_number["1"] = 0

    world.operate_over_space(ObjectivePointAssignBeings_WorldOperator.new)

    beings.each do |current_being|
      if !current_being.nil?
        current_team = current_being.team.to_i
        current_being_points = current_being.points.to_i
        if !current_team.nil?
          team_being_number["#{current_team}"] += 1
          position_number = team_being_number["#{current_team}"]
          if output_beings
            output_being_file = File.new("units/output_units/team-#{current_team}/position-#{position_number}.being" ,"w")
            current_being.print_this_baby_out([], [], output_being_file)
            output_being_file.close
          end
          current_being_team_stats =
              current_being.get_brief_stats.prepend("P:#{position_number} ")
          current_wounds = current_being.wounds
          if !current_wounds.nil?
            if current_wounds.to_i > 0
              current_being_team_stats = white(current_being_team_stats)
              if current_team == 1
                team_1_points += current_being.get_points_including_objectives
              else
                team_others_points += current_being.get_points_including_objectives
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
          if current_being.objective_points.to_i > 0 && current_wounds.to_i > 0
            current_being_team_stats = blue_bg(current_being_team_stats)
          end
          team_stats["#{current_team}"].concat("\n#{current_being_team_stats}     ")
        end
      end
    end

    team_stats["2 Points"] = team_others_points
    team_stats["1 Points"] = team_1_points
    if output_to_file
      team_results_file = File.new("match-team.results", "a")
      team_results_file.write("#{team_1_points} #{team_others_points}\n")
      team_results_file.close
    end
    return team_stats
  end
end

class ClearMarkers_BeingOperator < Thing
  def execute(beings)
    beings.each do |current_being|
      if !current_being.nil?
        current_being.marked = false
      end
    end
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

class ClearMarkers_WorldOperator < Thing
  def execute(world, x, y)
    world.remove('programmarker', x, y)
  end
end

class ComputeBeingVisbilityMaps_WorldOperator < Thing
  def initialize(visibility = DEFAULT_WORLD_VISIBILITY)
    @default_visibility = visibility
  end

  def initialized_vis_map(visibility)
    initialized_visibility_map = []
    map_width_height = 2 * visibility
    (0..map_width_height).each do |y_init|
      y_row_loc_array = []
      (0..map_width_height).each do |x_init|
        y_row_loc_array.push(Location.new())
      end
      initialized_visibility_map.push(y_row_loc_array)
    end
    return initialized_visibility_map
  end

  def execute(world, x, y)
    visibility = @default_visibility
    visibility_map = initialized_vis_map(visibility)
    location_beings = world.get('being', x, y)
    visibility_being = nil
    if (location_beings != nil) && (location_beings != [])
      visibility_being = location_beings.pop
      location_beings.push(visibility_being)
    end
    if visibility_being == nil
      return
    end
    x_min = x - visibility
    x_max = x + visibility
    y_min = y - visibility
    y_max = y + visibility
    x_step = 1
    y_step = 1
    y_insert_coord = 0
    y_min.step(y_max, y_step).each do |y_coord|
      x_insert_coord = 0
      x_min.step(x_max, x_step).each do |x_coord|
        original_x_coord = x_coord
        original_y_coord = y_coord
        if ns_ew_flip == true
          x_coord = original_y_coord
          y_coord = original_x_coord
        end
        current_location = world.get_location(x_coord, y_coord)
        visibility_map[y_insert_coord][x_insert_coord] =
          current_location;
        x_coord = original_x_coord
        y_coord = original_y_coord
        x_insert_coord += 1
      end
      y_insert_coord += 1
    end
    # Set being visibility map
    visibility_being.visibility_map = World.new.set_space(visibility_map)
    return nil
  end

end

class SetMarkers_WorldOperator < Thing
  def execute(world, x, y)
    location_markers = world.get('programmarker', x, y)
    location_beings = world.get('being', x, y)
    markers = []
    if !location_beings.nil? && location_beings != []
      current_being = location_beings[-1]
      if current_being.marked
        new_marker = ProgramMarker.new
        new_marker.program = current_being.program
        new_marker.move = current_being.move
        world.add(new_marker, x, y)
      end
    end
  end
end


class ObjCommand_WorldOperator
  def initialize(type = 'being', remove_on_add = true)
    @type = type
    @remove_on_add = remove_on_add
  end

  def execute(world, x, y)
    result = nil
    location_objs = world.get(@type, x, y)
    if (location_objs != nil) && (location_objs != [])
      result = []
      top_obj = location_objs.pop
      new_location =
        Command.new.execute_next_command(top_obj, world, x, y)
      location_objs.push(top_obj)
      retrieve_command = ''

      add_back_obj = ''
      if !@remove_on_add
        add_back_obj = "self.add(obj_to_move, #{x}, #{y});"
      end

      add_obj =
        "obj_to_move = self.remove('#{@type}', #{x}, #{y}); #{add_back_obj} if self.can_add?(obj_to_move, #{new_location['x']}, #{new_location['y']}) then self.add(obj_to_move, #{new_location['x']}, #{new_location['y']}) else self.add(obj_to_move, #{x}, #{y}) end"
      result.push(add_obj)
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

class ObjectivePointAssignBeings_WorldOperator

  def execute(world, x, y)
    result = []
    location_beings = world.get('being', x, y)
    if (location_beings != nil) && (location_beings != [])
      result = []
      current_being = location_beings.pop
      current_location_string = world.get('string', x, y)
      current_being.objective_points = 0
      if !current_location_string.nil? && !current_location_string[0].nil?
        if world.objective_location?(current_location_string[0])
          current_being.objective_points = 1
        end
      end
      location_beings.push(current_being)
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
                        if $dump_logs
                          world.add(ActiveFlag.new, x, y)
                          world.add(ActiveFlag.new, loop_x, loop_y)
                        end
                        wound_string = return_string.concat(yellow("#{attacking_being_name} damages #{def_being_name} for #{removed_wounds} wounds.."))
                        damage_result =
                          "putsl '#{wound_string}'; damaged_being = self.remove('Being', #{loop_x}, #{loop_y}); if (!damaged_being.nil?) then damaged_being.wounds = damaged_being.wounds.to_i - #{removed_wounds}; if (damaged_being.wounds.to_i > 0) then self.add(damaged_being, #{loop_x}, #{loop_y}) else damaged_being_name = (damaged_being.team.to_i == 1 ? bold(damaged_being.name) : damaged_being.name); printl red(damaged_being_name); printl '(#{loop_x},#{loop_y})'; putsl red(' is killed!'); end; important_pause; end;"
                        result.push(damage_result)
                      else
                        bounce_string = "The #{attacking_being_name} #{@type} attack bounces off #{def_being_name}(#{loop_x},#{loop_y}).."
                        bounce_result = "putsl '#{return_string}'; putsl white('#{bounce_string}');";
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
     current_program_popped = programs.pop
     if !current_program_popped.nil? && !current_being.nil?
       current_program = current_program_popped.program
       current_being_program = "#{current_program} "
       current_being.program = current_being_program
     else
       putsl "Could not assign program (#{current_program_popped}) to being (#{current_being})"
     end
     if !current_being.nil?
       beings.push current_being
     end
   end
  end
end

class Reprogram_BeingOperator < Thing
  def execute(beings, new_type = '.')
    command_processor = Command.new
    beings.each do |current_being|
      if !current_being.nil? && current_being.marked
        command_processor.reprogram_next_command(current_being, new_type)
      end
    end
  end
end

class MarkTeam_BeingOperator < Thing
  def execute(beings, team = 1, mark_on = true)
    beings.each do |current_being|
      if !current_being.nil? && !current_being.team.nil? && current_being.team == team
        current_being.marked = mark_on
      end
    end
  end
end

class MutatePrograms_BeingOperator < Thing
  def execute(beings, team = 1)
    mutation_types = 'news'
    beings.each do |current_being|
      if !current_being.nil? && !current_being.team.nil? && !current_being.program.nil?
        if current_being.team.to_i == team
          current_program = current_being.program
          current_program_array = current_being.program.split(" ")
          (1..PROGRAM_MUTATIONS).each do |i|
            mutation_position = $randomizer.rand(current_program_array.size)
            mutation_direction = mutation_types[$randomizer.rand(mutation_types.size)]
            mutation_size = $randomizer.rand(PROGRAM_MUTATION_MAX_SIZE)
            current_program_array[mutation_position] = "#{mutation_direction}#{mutation_size}"
          end
          current_being.program = current_program_array.join(" ")
        end
      end
    end
  end
end

class OutputPrograms_BeingOperator < Thing
  def execute(beings)
    current_position = 1
    shift_amount = 1 - $current_step
    beings.each do |current_being|
      if !current_being.nil? && !current_being.team.nil? && !current_being.program.nil?
         if current_being.team.to_i == 1 && current_being.wounds.to_i > 0
           position_name = "position-#{current_position}"
           new_program_file = File.new("programs/outputProgram/#{position_name}.program", "w")
           current_program = current_being.program
           if shift_amount < 0
             current_program_array = current_program.split(" ").rotate(shift_amount)
             current_program = current_program_array.join(" ")
           end
           new_program_file.write("name #{position_name}\n")
           new_program_file.write("program #{current_program}\n")
           new_program_file.close
         end
      end
      current_position += 1
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
            command_type = 'e'
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
          can_add_to_location = world.can_add?(obj, x_to_check, y_to_check)
          if can_add_to_location
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

  def reprogram_next_command(obj, new_command = '.')
    current_command = self.parse_next_command(obj)
    command_type = current_command["command"].downcase
    command_args = current_command["args"]
    new_move_amount = 1
    final_command = command_type
    if new_command == '.'
      new_move_amount = 0
      final_command = command_type
    elsif new_command == command_type
      new_move_amount = command_args.to_i + 1
      new_move_amount = [new_move_amount.to_i, obj.move.to_i].min
    else
      new_move_amount = 1
      final_command = new_command
    end
    reprogrammed_command = "#{final_command}#{new_move_amount}"
    program_string = obj.program
    program_array = program_string.split(" ")
    program_array.pop
    program_array.unshift(reprogrammed_command)
    obj.program = program_array.join(" ")
  end

end

#;; DISPLAY::O@

class Display < Thing
  def get(name)
    if instance_variable_get("@#{name}") != nil
      return instance_variable_get("@#{name}")
    elsif !name.nil?
      return name[0]
    end
    return ''
  rescue
    if !name.nil?
      return name[0]
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

def output_team_stats(beings, world, output_to_file=false, output_beings=false)
  if CLEAR_SCREEN_TEAM_LOG
    clear_screen("team", true)
  end
  if !$dump_logs && !output_to_file && !output_beings
    return
  end
  team_results = TeamStats_BeingOperator.new.execute(beings, world, output_to_file, output_beings)
  clear_screen("team")
  putsl("Current step: #{$current_step-1}     ", "team")
  team_results.each do |key, value|
    putsl("Team #{key}: #{value}     ", "team")
  end
end

def clear_markers(beings, world)
  clear_being_markers = ClearMarkers_BeingOperator.new
  clear_being_markers.execute(beings)
  clear_location_markers = ClearMarkers_WorldOperator.new
  world.operate_over_space(clear_location_markers)
end

def set_markers_do_iterations(beings, world, displays = [], current_step = 0, last_step = 1)
  world.operate_over_space(SetMarkers_WorldOperator.new, displays, beings)
  if last_step >= current_step then
    (current_step..last_step).each do |i|
      world.operate_over_space(ObjCommand_WorldOperator.new('programmarker'), displays,
        beings, false)
      printl("Step: #{i}", "map")
      sleep(PROGRAM_PREVIEW_PAUSE_LENGTH)
    end
  end
end

class LineOfCommand
  @being_selectors = '1234567890!@#$%^&*()'
  @reprogram_options = '[;\'/.'
  @reprogram_directions = 'nwes.'

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
    beings = instance_variable_get("@beings")
    programs = instance_variable_get("@programs")
    displays = instance_variable_get("@displays")
    world = instance_variable_get("@worlds")[-1]
    if !@being_selectors.index(guess[0]).nil?
      clear_markers(beings, world)
      guess.split("").each do |being_i|
        mark_being_number = @being_selectors.index(being_i).to_i
        if !beings.nil? && (mark_being_number < beings.size) && !beings[mark_being_number].nil?
          beings[mark_being_number].marked = !beings[mark_being_number].marked
        end
      end
      set_markers_do_iterations(beings, world, displays, $current_step, $current_step)
      output_team_stats(beings, world)
    elsif !@reprogram_options.index(guess[0]).nil?
      reprogrammed_direction = @reprogram_directions[@reprogram_options.index(guess[0])]
      if !reprogrammed_direction.nil?
        reprogrammer = Reprogram_BeingOperator.new
        reprogrammer.execute(beings, reprogrammed_direction)
        clear_location_markers = ClearMarkers_WorldOperator.new
        world.operate_over_space(clear_location_markers)
        set_markers_do_iterations(beings, world, displays, $current_step, $current_step)
        output_program_operator = OutputPrograms_BeingOperator.new
        output_program_operator.execute(beings)
      end
    elsif shortcut_everything?("-", guess)
      clear_markers(beings, world)
      mark_team_1 = MarkTeam_BeingOperator.new
      mark_team_1.execute(beings, 1, false)
      output_team_stats(beings, world)
    elsif shortcut_everything?("=", guess)
      clear_markers(beings, world)
      mark_team_1 = MarkTeam_BeingOperator.new
      mark_team_1.execute(beings)
      set_markers_do_iterations(beings, world, displays, $current_step, $current_step)
      output_team_stats(beings, world)
    elsif shortcut_everything?("assign", guess)
      putsl "Assigning program to being..."
      program_beings = Assign_Program_BeingOperator.new
      program_beings.execute(beings, programs)
    elsif shortcut_everything?("clear", guess)
      putsl "Clearing markers..."
      clear_markers(beings, world)
      output_team_stats(beings, world)
    elsif shortcut_everything?("dump", guess)
      putsl "Dumping living mutations.."
      team_results = DumpMutations_BeingOperator.new.execute(beings)
    elsif shortcut_everything?("emerge", guess)
      output_team_stats(beings, world, false, TRUE)
    elsif shortcut_everything?("increment", guess)
      $team_number += 1
      putsl "incrementing team number. new beings will now be on team #{$team_number}."
    elsif shortcut_everything?("list", guess)
      putsl "The Definitions and flows....."
      directory_string = Dir["*"].join("'\n'")
      putsl directory_string
      putsl "***Have flowed***"
    elsif shortcut_everything?("mutate", guess)
      mutate_beings = Mutate_Beings_BeingOperator.new
      mutate_beings.execute(beings, world)
    elsif shortcut_everything?("nologs", guess)
      $dump_logs = FALSE
      puts "turned off display logs"
    elsif shortcut_everything?("output", guess)
      putsl "output programs"
      output_program_operator = OutputPrograms_BeingOperator.new
      output_program_operator.execute(beings)
    elsif shortcut_everything?("populate", guess)
      populate_beings = Populate_Beings_BeingOperator.new
      populate_beings.execute(beings, world)
    elsif shortcut_everything?("quit", guess)
      if !beings.nil? && !world.nil?
        output_team_stats(beings, world, true)
      end
      exit
    elsif shortcut_everything?("reprogram", guess)
      putsl "reprogram"
      mutation_program = MutatePrograms_BeingOperator.new
      mutation_program.execute(beings)
    elsif shortcut_everything?("step", guess)
      if ($current_step <= MAX_STEPS)
        $current_step += 1
        # "=====movement"
        world.operate_over_space(ObjCommand_WorldOperator.new, displays, beings)
        if $dump_logs
          clear_markers([], world)
          world.operate_over_space(SetMarkers_WorldOperator.new, displays, beings)
        end
        world.print_map(displays)
        # "-----magic"
        world.operate_over_space(Magic_WorldOperator.new, displays, beings)
        # "-----ranged attacks"
        world.operate_over_space(Attack_WorldOperator.new('ranged'), displays,beings)
        # "+++++melee attacks"
        world.operate_over_space(Attack_WorldOperator.new('melee'), displays, beings)
        if $dump_logs
          set_markers_do_iterations(beings, world, displays, $current_step, $current_step)
          output_team_stats(beings, world)
        end
      end
    elsif shortcut_everything?("teams", guess)
      output_team_stats(beings, world)
    elsif shortcut_everything?("visbility", guess)
      world.operate_over_space(ComputeBeingVisbilityMaps_WorldOperator.new(), displays, beings)
    elsif self.is_list_objects_command?(@types, guess)
      list_type = self.get_list_type(@types, guess)
      if !list_type.nil?
        type_objs = instance_variable_get("@#{list_type}s")
        print_things_list(list_type, type_objs, displays)
      end
    else
      filename_ext = (File.extname guess)
      if (filename_ext != "") && (filename_ext[1..-1].capitalize)
        type = filename_ext[1..-1].capitalize
        if @types.include?(type.downcase)
          thing = Object.const_get("#{type}").new(guess)
          if (thing.initialized == true)
            if (defined? thing.name)
              putsl "...Thing #{thing.name} created and initialized"
              putsl " .."
              instance_variable_get("@#{filename_ext[1..-1]}s").push(thing)
            else
              putsl  "thing not created from #{guess} because  no 'name' "
              putsl  "  characteristic defined"
            end
          end
        else
          putsl ">err - reading unknown type (by file extension)"
          puts guess
          putsl "err<"
        end
      else
         putsl "> no op"
         putsl guess
         putsl "no op <"
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
          if $dump_logs
            sleep PAUSE_LENGTH
          end
          if CLEAR_SCREEN
            clear_screen
          end
         self.evaluate_command(line)
        end
      end
    end
  end

  last_guess = "s"

  # Main command line input->evaluate^pop-or->newLineandprintnewprompt
  while guess = Readline.readline("-Machine: ", true)
    if CLEAR_SCREEN
      clear_screen
    end
    if guess == "" || guess == "\n" || guess == "\r"
      guess = last_guess
    end
    if guess != ""
      self.evaluate_command(guess)
      last_guess = guess
    end
  end

  putsl "Reseting.... Done."
end
