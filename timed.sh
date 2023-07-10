#!/bin/bash

# Get the number of times to run the command
n=$1

# Get the command to run
shift
cmd="$@"

gray='\033[90m'  # ANSI escape code for gray color
reset='\033[0m'  # ANSI escape code to reset text color

echo -e "Running command \e[1;31m$n\e[0m times"
echo -e "\e[2m$cmd\e[0m"

# Function to format the time
format_time() {
    local time_in_ms=$1
    local minutes=$((time_in_ms / 60000))
    local seconds=$((time_in_ms / 1000 % 60))
    local milliseconds=$((time_in_ms % 1000))
    local formatted_time=""
    if [ $minutes -gt 0 ]; then
        formatted_time+="${minutes}m "
    fi
    formatted_time+="${seconds}s ${milliseconds}ms"
    echo "$formatted_time"
}

# Run the command n times and time each execution
total_time_ms=0
completed_runs=0
for ((i=1; i<=n; i++)); do
    start_time=$(date +%s%3N)
    $cmd >/dev/null 2>&1
    end_time=$(date +%s%3N)
    runtime_ms=$((end_time - start_time))
    total_time_ms=$((total_time_ms + runtime_ms))
    completed_runs=$((completed_runs + 1))
    message="Run $completed_runs took $(format_time $runtime_ms)"
    if [ $completed_runs -ge 2 ]; then
        avg_time_ms=$((total_time_ms / completed_runs))
        message+="${gray} (average $(format_time $avg_time_ms))${reset}"
    fi
    echo -e "$message"
done

# Calculate the final average time and print it
avg_time_ms=$((total_time_ms / completed_runs))
echo -e "Average time for $completed_runs runs: $(format_time $avg_time_ms)"
