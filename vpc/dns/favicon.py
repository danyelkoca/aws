from PIL import Image
import math

# Create a 16x16 image with a radial rainbow gradient
icon = Image.new("RGB", (16, 16))
pixels = icon.load()

# Define rainbow colors
colors = [
    (255, 0, 0),  # Red
    (255, 127, 0),  # Orange
    (255, 255, 0),  # Yellow
    (0, 255, 0),  # Green
    (0, 0, 255),  # Blue
    (75, 0, 130),  # Indigo
    (148, 0, 211),  # Violet
]

# Calculate the center of the image
center_x, center_y = 8, 8
max_distance = math.sqrt(center_x**2 + center_y**2)

# Generate radial gradient
for y in range(16):
    for x in range(16):
        # Calculate distance from the center
        distance = math.sqrt((x - center_x) ** 2 + (y - center_y) ** 2)
        t = distance / max_distance
        t = min(t, 1)  # Clamp t to [0, 1]

        # Interpolate between colors
        color_index = int(t * (len(colors) - 1))
        next_color_index = min(color_index + 1, len(colors) - 1)
        blend = t * (len(colors) - 1) - color_index

        r = int(
            colors[color_index][0] * (1 - blend) + colors[next_color_index][0] * blend
        )
        g = int(
            colors[color_index][1] * (1 - blend) + colors[next_color_index][1] * blend
        )
        b = int(
            colors[color_index][2] * (1 - blend) + colors[next_color_index][2] * blend
        )

        pixels[x, y] = (r, g, b)

# Save as favicon.ico
icon.save("favicon.ico", format="ICO")
