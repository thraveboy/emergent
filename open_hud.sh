xterm -bg black -fg green -cr purple +cm +dc -geometry 45x25+900+0 -title "Map" -e tail -f display_logs/map_log &
xterm -bg black -fg green -cr purple +cm +dc -geometry 40x40+1175+0 -title "Team" -e tail -f display_logs/team_log  &
xterm -bg black -fg green -cr purple +cm +dc -geometry 80x20+900+525 -title "Battle Report" -e tail -f display_logs/battle_log  &