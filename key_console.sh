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
  if str[0] != "\r"
    print "\n"
  end
  if str == 'q'
    quit = true
  end
end
