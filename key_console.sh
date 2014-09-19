#!/usr/bin/ruby

quit = false

while !quit
  begin
    system("stty raw -echo")
    str = STDIN.getc
  ensure 
    system("stty -raw echo")
  end
  print str[0]
  print "\n"
  if str == 'q'
    quit = true
  end
end
