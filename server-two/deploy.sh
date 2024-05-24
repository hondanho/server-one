#!/bin/bash


declare -A service_mapping
service_mapping["dl-video-api"]="localhost:8003"

check_up() {
  # URL to check
  url=$1

  echo "check $url"
  # Start time
  start_time=$(date +%s)

  echo "Checking service up at $url"
  # Loop until the time limit (check time) is reached
  while true; do
    # Send a HEAD request to the URL and get the status code
    status_code=$(curl -s -o /dev/null -I -w "%{http_code}" "$url")
    echo "checking status_code $status_code"

    # Check if the status code is greater than 200 and less than 500
    if (( status_code >= 200 && status_code < 500 )); then
      echo "ok"
      return 0
      break
    fi

    # Check if check time have elapsed
    current_time=$(date +%s)
    elapsed_time=$((current_time - start_time))
    if (( elapsed_time >= 60 )); then
      echo "failed"
      break
    fi

    # Wait for a short time before checking again
    sleep 1
  done
  return 1
}

# Function to restart Docker Compose services in a folder
deploy_service() {
  service_name=$1
  version=$2

  #tag current version as old version for rollback
  docker tag $service_name:latest $service_name:old
  #load docker image
  docker load -i /home/docker-image-temp/$service_name-$version.tar
  # Change directory to the specified folder by service_name
  cd "$service_name" || exit

  cat docker-compose.yaml
  # Restart Docker Compose services
  echo "stopping $service_name"
  docker compose stop
  echo "starting $service_name"
  docker compose up -d

  echo "sleep 10 sec to wait service up"

  
  sleep 10

  check_url="${service_mapping[$service_name]}"
  echo $check_url

  if check_up $check_url; then
    echo "deploy success"
  else
    echo "revert back to old image"
    docker tag $service_name:old $service_name:latest
    docker compose stop
    docker compose up -d
    echo "revert done"
    exit 1
  fi 

  # Change back to the original directory
  cd - || exit
}

# Check if the number of arguments 
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <service> <version>"
  exit 1
fi

# Assign the input variables to named variables
service="$1"
version="$2"

# Check if both variables are provided
if [ -z "$service" ] || [ -z "$version" ]; then
  echo "Both service and version must be provided"
  exit 1
fi

deploy_service $service $version
