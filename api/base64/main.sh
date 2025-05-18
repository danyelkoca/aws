#!/bin/bash

# Function to encode a string to base64
encode_base64() {
    echo -n "$1" | base64
}

# Function to decode a base64 string
decode_base64() {
    echo -n "$1" | base64 --decode
}

# Default message
default_message="Secret message"

# Check if a message is passed as an argument
if [ $# -eq 0 ]; then
    text="$default_message"
else
    text="$1"
fi

# Encode the text
encoded=$(encode_base64 "$text")
echo "encoded"
echo "$encoded"

# Decode the encoded text
decoded=$(decode_base64 "$encoded")
echo "decoded"
echo "$decoded"