#!/bin/bash
numberofiterations=10000
currentiteration=0

while [ $currentiteration -le $numberofiterations ]
do
  ruby emergent.rb games/gameDarkElves1-15moves;
  let currentiteration=currentiteration+1
done