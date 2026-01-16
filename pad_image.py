import sys
import subprocess

def install_pillow():
    subprocess.check_call([sys.executable, "-m", "pip", "install", "Pillow"])

try:
    from PIL import Image
except ImportError:
    print("Pillow not found, installing...")
    install_pillow()
    from PIL import Image

def pad_image_to_ratio(input_path, output_path, target_ratio=2.5):
    img = Image.open(input_path)
    width, height = img.size
    print(f"Original size: {width}x{height}")
    
    current_ratio = width / height
    
    if current_ratio > target_ratio:
        # Image is wider than target. Pad vertically.
        new_width = width
        new_height = int(width / target_ratio)
    else:
        # Image is taller/narrower than target. Pad horizontally.
        new_height = height
        new_width = int(height * target_ratio)
        
    print(f"New canvas size: {new_width}x{new_height}")
    
    new_img = Image.new("RGBA", (new_width, new_height), (0, 0, 0, 0))
    
    # Calculate position to center
    x_pos = (new_width - width) // 2
    y_pos = (new_height - height) // 2
    
    new_img.paste(img, (x_pos, y_pos))
    new_img.save(output_path)
    print(f"Saved padded image to {output_path}")

if __name__ == "__main__":
    input_file = "assets/images/konbu.tokyo2-touka.png"
    output_file = "assets/images/konbu_branding_padded.png"
    try:
        pad_image_to_ratio(input_file, output_file)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)
