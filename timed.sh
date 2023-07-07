#!/bin/bash

# Get the number of times to run the command
n=$1

# Get the command to run
shift
cmd="$@"

echo -e "Running command \e[1;31m$n\e[0m times"
echo -e "\e[2m$cmd\e[0m"

# Function to format the time
format_time() {
    local time_in_seconds=$(echo "$1" | awk -F'.' '{print $1}')
    local milliseconds=$(echo "$1" | awk -F'.' '{print $2}')
    local minutes=$((time_in_seconds / 60))
    local seconds=$((time_in_seconds % 60))
    local formatted_time=""
    if [ $minutes -gt 0 ]; then
        formatted_time+="${minutes}m "
    fi
    formatted_time+="${seconds}s ${milliseconds}ms"
    echo "$formatted_time"
}

# Run the command n times and time each execution
total_time=0
for ((i=1; i<=n; i++)); do
    runtime=$( { time -p $cmd >/dev/null; } 2>&1 | awk '/^real/ {print $2}' )
    echo "Run $i took $(format_time $runtime)"
    total_time=$(awk -v t1="$total_time" -v t2="$runtime" 'BEGIN{print t1+t2}')
done

# Calculate the average time and print it
avg_time=$(awk -v t="$total_time" -v n="$n" 'BEGIN{print t/n}')
echo "Average time for $n runs: $(format_time $avg_time)"
