#!/bin/bash
numberofiterations=100000
currentiteration=0

while [ $currentiteration -le $numberofiterations ]
do
  ruby emergent.rb gameMutationMenElf1;
  let currentiteration=currentiteration+1
done