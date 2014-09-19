xterm -bg black -fg green -cr purple +cm +dc -geometry 45x22+800+0 -title "Map" -e tail -f display_logs/map_log &
xterm -bg black -fg green -cr purple +cm +dc -geometry 60x40+1075+0 -title "Team" -e tail -f display_logs/team_log  &
xterm -bg black -fg green -cr purple +cm +dc -geometry 100x20+800+525 -title "Battle Report" -e tail -f display_logs/battle_log  &