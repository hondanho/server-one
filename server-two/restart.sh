#!/bin/bash

# List of folders
folders=("blog" "dl-video-api" "nginx")

# Loop through each folder
for folder in "${folders[@]}"
do
  # Change directory to the folder
  cd "$folder" || exit

  # Run docker-compose down
  docker-compose down -v

  # Run docker-compose up -d
  docker-compose up -d

  # Change back to the original directory
  cd - || exit
done
