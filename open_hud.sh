xterm -bg black -fg green -cr purple -fa impact -fs 10 -cr black +cm +dc -geometry 21x12+800+0 -title "Map" -e tail -f display_logs/map_log &
xterm -bg black -fg green -cr purple +cm +dc -geometry 60x45+1080+0 -title "Team" -e tail -f display_logs/team_log  &
xterm -bg black -fg green -cr purple +cm +dc -geometry 110x10+800+620 -title "Battle Report" -e tail -f display_logs/battle_log  &