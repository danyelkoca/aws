import requests
import os

# Image URL
url = "https://picsum.photos/1200/800"

# Download image
response = requests.get(url)
response.raise_for_status()

# Save image in the same folder as this script
output_path = os.path.join(os.path.dirname(__file__), "image.png")
with open(output_path, "wb") as f:
    f.write(response.content)
