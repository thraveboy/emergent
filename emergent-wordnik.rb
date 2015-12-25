%w(rubygems wordnik).each {|lib| require lib}

Wordnik.configure do |config|
    config.api_key = '998ae573b71f710d940080a44b401386ba5b536b5d7e95faf'
    config.logger = Logger.new('/dev/null')
end

def find_synonym(word)
  word = word.strip
  if word[-1] == 's'
    word = word[0..-2]
  end
  if $synonym_api_cache_hash["#{word}"].nil? && $dump_logs
    related_hash = Wordnik.word.get_related("#{word}", :type => 'synonym')
    related_array= related_hash[0]["words"]
    $synonym_api_cache_hash["#{word}"] = related_array
  elsif !$synonym_api_cache_hash["#{word}"].nil?
    related_array = $synonym_api_cache_hash["#{word}"]
  else
    related_array = ["#{word}"]
  end
  rand_word = related_array[$randomizer.rand(related_array.size)]
  return rand_word
rescue
  if !$synonym_api_cache_hash.nil? && !word.nil? && $synonym_api_cache_hash["#{word}"].nil?
    $synonym_api_cache_hash["#{word}"] = ["#{word}"]
  end
  return word
end


if SEED != 0
  $randomizer = Random.new(SEED)
else
  $randomizer = Random.new
end

$synonym_api_cache_hash = Hash.new

