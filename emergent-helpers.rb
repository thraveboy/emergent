def printl (text, log_file = "battle")
  if $dump_logs
    print text
    if log_file == "battle"
      $battle_log.write text
    elsif log_file == "team"
     $team_log.write text
    else
      $map_log.write text
    end
  end
end

def putsl (text, log_file = "battle")
  if $dump_logs
    text_with_newline = text.dup.concat("\n")
    printl(text_with_newline, log_file)
  end
end

