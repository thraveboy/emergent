xterm -bg black -fg green -cr purple +cm +dc -geometry 20x12+900+0 -title "Map" -e tail -f display_logs/map_log &
xterm -bg black -fg green -cr purple +cm +dc -geometry 80x30+1040+0 -title "Team" -e tail -f display_logs/team_log  &
xterm -bg black -fg green -cr purple +cm +dc -geometry 100x30+900+425 -title "Battle Report" -e tail -f display_logs/battle_log  &