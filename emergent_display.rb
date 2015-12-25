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

def clear_screen(log = "", full_wipe = false)
  if $dump_logs
    if (log == "map")
      if full_wipe
        $map_log.print("\e[2J")
      else
        # go to top left corner instead of clear
        $map_log.print("\e[2H")
      end
    elsif (log == "team")
      if full_wipe
        $team_log.print("\e[2J")
      else
        # go to top left corner instead of clear
        $team_log.print("\e[2H")
      end
    else
      print "\e[2J"
    end
  end
end
