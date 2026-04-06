#!/usr/bin/env python3
"""Generate the Flux Timer app icon at all required macOS sizes."""

from PIL import Image, ImageDraw, ImageFont, ImageFilter
import math
import os

SIZE = 1024  # Master size

def lerp_color(c1, c2, t):
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))

def draw_icon(size=SIZE):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Color palette (Solar Flare inspired)
    c_orange = (255, 107, 53)
    c_magenta = (247, 37, 133)
    c_purple = (114, 9, 183)
    c_deep = (72, 12, 168)

    # Draw gradient background (radial-ish via concentric rectangles)
    for y in range(size):
        for x in range(size):
            # Normalized coordinates
            nx = x / size
            ny = y / size

            # Radial distance from top-left offset center
            cx, cy = 0.3, 0.3
            dist = math.sqrt((nx - cx) ** 2 + (ny - cy) ** 2) / 1.0
            dist = min(1.0, dist)

            # Three-stop gradient
            if dist < 0.5:
                t = dist / 0.5
                color = lerp_color(c_orange, c_magenta, t)
            else:
                t = (dist - 0.5) / 0.5
                color = lerp_color(c_magenta, c_purple, t)

            img.putpixel((x, y), color + (255,))

    # Add a subtle darker vignette at bottom-right
    overlay = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    overlay_draw = ImageDraw.Draw(overlay)
    for r in range(size // 2, 0, -1):
        alpha = int(40 * (1 - r / (size // 2)))
        overlay_draw.ellipse(
            [size - r, size - r, size + r, size + r],
            fill=(30, 10, 60, alpha)
        )
    img = Image.alpha_composite(img, overlay)

    draw = ImageDraw.Draw(img)

    # --- Draw timer symbol ---
    # A stylized circular arc (partial ring) suggesting a countdown
    center = size // 2
    ring_radius = int(size * 0.32)
    ring_width = int(size * 0.055)

    # Outer glow
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    for i in range(20, 0, -1):
        alpha = int(8 * (20 - i))
        r = ring_radius + ring_width // 2 + i * 2
        glow_draw.ellipse(
            [center - r, center - r, center + r, center + r],
            outline=(255, 255, 255, alpha),
            width=2
        )
    img = Image.alpha_composite(img, glow)
    draw = ImageDraw.Draw(img)

    # Main ring (270-degree arc — leaves a gap at the top-right)
    # Draw as a thick white circle with a cut-out
    ring_img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ring_draw = ImageDraw.Draw(ring_img)

    # Full ring
    bbox_outer = [
        center - ring_radius - ring_width // 2,
        center - ring_radius - ring_width // 2,
        center + ring_radius + ring_width // 2,
        center + ring_radius + ring_width // 2,
    ]
    # Draw arc (270 degrees, starting from top, going clockwise)
    # PIL arc: 0° is 3 o'clock, angles go clockwise
    # We want gap at ~45° (top-right). Start at 45°, sweep 300°.
    ring_draw.arc(bbox_outer, start=-225, end=45, fill=(255, 255, 255, 240), width=ring_width)

    img = Image.alpha_composite(img, ring_img)
    draw = ImageDraw.Draw(img)

    # Small dot at the end of the arc (the "progress indicator")
    dot_angle = math.radians(45)  # End of arc
    dot_x = center + int(ring_radius * math.cos(dot_angle))
    dot_y = center + int(ring_radius * math.sin(dot_angle))
    dot_r = int(size * 0.035)

    # Dot glow
    for i in range(12, 0, -1):
        alpha = int(15 * (12 - i))
        draw.ellipse(
            [dot_x - dot_r - i * 2, dot_y - dot_r - i * 2,
             dot_x + dot_r + i * 2, dot_y + dot_r + i * 2],
            fill=(255, 200, 100, alpha)
        )
    # Solid dot
    draw.ellipse(
        [dot_x - dot_r, dot_y - dot_r, dot_x + dot_r, dot_y + dot_r],
        fill=(255, 255, 255, 255)
    )

    # Center time display: "F" letterform (the brand)
    # Use a large bold font-like shape
    # Draw a stylized "F" or just the time ":" colon dots as a minimal clock reference
    # Two dots (like a colon) in the center
    colon_gap = int(size * 0.06)
    colon_r = int(size * 0.028)
    # Top dot
    draw.ellipse(
        [center - colon_r, center - colon_gap - colon_r,
         center + colon_r, center - colon_gap + colon_r],
        fill=(255, 255, 255, 220)
    )
    # Bottom dot
    draw.ellipse(
        [center - colon_r, center + colon_gap - colon_r,
         center + colon_r, center + colon_gap + colon_r],
        fill=(255, 255, 255, 220)
    )

    # Horizontal lines flanking the colon (like -- : --)
    line_y_top = center - colon_gap
    line_y_bot = center + colon_gap
    line_len = int(size * 0.12)
    line_h = int(size * 0.022)
    line_gap = int(size * 0.05)

    # Left of colon - two "digit" bars
    for offset in [line_gap + line_len, line_gap]:
        x1 = center - offset
        x2 = center - offset + line_len - int(size * 0.02)
        draw.rounded_rectangle(
            [x1, center - line_h, x2, center + line_h],
            radius=line_h,
            fill=(255, 255, 255, 180)
        )

    # Right of colon - two "digit" bars
    for offset in [line_gap, line_gap + line_len]:
        x1 = center + offset - line_len + int(size * 0.02)
        x2 = center + offset
        draw.rounded_rectangle(
            [x1, center - line_h, x2, center + line_h],
            radius=line_h,
            fill=(255, 255, 255, 180)
        )

    return img


def main():
    master = draw_icon(SIZE)

    # Output directory
    base = os.path.dirname(os.path.abspath(__file__))
    iconset_dir = os.path.join(base, "FluxTimer", "Resources", "Assets.xcassets", "AppIcon.appiconset")
    os.makedirs(iconset_dir, exist_ok=True)

    # macOS icon sizes
    sizes = [
        (16, 1), (16, 2),
        (32, 1), (32, 2),
        (128, 1), (128, 2),
        (256, 1), (256, 2),
        (512, 1), (512, 2),
    ]

    images = []
    for base_size, scale in sizes:
        px = base_size * scale
        suffix = f"_{base_size}x{base_size}" + (f"@{scale}x" if scale > 1 else "")
        filename = f"icon{suffix}.png"
        resized = master.resize((px, px), Image.LANCZOS)
        resized.save(os.path.join(iconset_dir, filename), "PNG")
        images.append({
            "filename": filename,
            "idiom": "mac",
            "scale": f"{scale}x",
            "size": f"{base_size}x{base_size}"
        })
        print(f"  Generated {filename} ({px}x{px})")

    # Also save 1024 master
    master.save(os.path.join(iconset_dir, "icon_512x512@2x.png"), "PNG")

    # Write Contents.json
    import json
    contents = {
        "images": images,
        "info": {"author": "xcode", "version": 1}
    }
    with open(os.path.join(iconset_dir, "Contents.json"), "w") as f:
        json.dump(contents, f, indent=2)

    print(f"\n  Icon set written to {iconset_dir}")


if __name__ == "__main__":
    main()
