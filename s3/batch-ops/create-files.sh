#!/bin/bash

# Set locale to C to avoid illegal byte sequence errors
export LC_ALL=C

# Create the files directory if it doesn't exist
mkdir -p files

# Loop to create 20 files with different sizes
for i in {1..20}; do
    # Calculate random size between 1 and 1000 bytes
    size=$((RANDOM % 1000 + 1))
    
    # Create a file with random readable content
    < /dev/urandom tr -dc 'a-zA-Z0-9 \n' | head -c $size > "files/file_${i}_${size}bytes.txt"
    
    echo "Created file_${i}_${size}bytes.txt with size $size bytes"
done