THRESHOLD=2

$the_hash = Hash.new

ARGV.each do|a|
  if File.exists?(a)
    $the_hash[a] = Hash.new
    File.read(a).each_line do |line|
      if !line.nil? && line != ""
        hash_entry =  line.strip.split(" ", 2)
        $the_hash[a]["#{hash_entry[1]}"] = hash_entry[0].to_i
      end
    end
  end
end

keys = $the_hash.keys
key = keys[0]
value = $the_hash[key]
second_value = $the_hash[keys[1]]
base_line = (value.size.to_f * 100.0) / (value.size.to_f + second_value.size.to_f)
puts
puts "Base line: #{base_line}"
puts "#{key}"; value.each_pair { |key2, value2| sum_dim =0;  $the_hash.each_value {|value3| sum_dim += value3["#{key2}"].to_i};  tage = ((value2 * 100) / sum_dim.to_f);  if tage >= base_line.to_f  && value2 > THRESHOLD then if tage > base_line.to_f * 1.5 then print "\e[37m +++ \e[0m"; print "#{key2}: #{value2} of #{sum_dim} is "; print tage.round(2); puts "\%"; end;  end;}
