#!/bin/bash
numberofiterations=1000
currentiteration=0

while [ $currentiteration -le $numberofiterations ]
do
  ruby emergent.rb games/currentGame;
  let currentiteration=currentiteration+1
done