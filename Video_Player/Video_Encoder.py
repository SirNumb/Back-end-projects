import sys
import time
import math
import os, os.path
import json
from PIL import Image

key_table = {
    0  : "0",
    1  : "1",
    2  : "2",
    3  : "3",
    4  : "4",
    5  : "5",
    6  : "6",
    7  : "7",
    8  : "8",
    9  : "9",
    10 : "A",
    11 : "B",
    12 : "C",
    13 : "D",
    14 : "E",
    15 : "F",
    16 : "G",
    17 : "H",
    18 : "I",
    19 : "J",
    20 : "K",
    21 : "L",
    22 : "M",
    23 : "N",
    24 : "O",
    25 : "P",
    26 : "Q",
    27 : "R",
    28 : "S",
    29 : "T",
    30 : "x", ##skip frame
    31 : "*", ##instruction sequence modification
}

binary_table = {
    "0" : b"00000",
    "1" : b"00001",
    "2" : b"00010",
    "3" : b"00011",
    "4" : b"00100",
    "5" : b"00101",
    "6" : b"00110",
    "7" : b"00111",
    "8" : b"01000",
    "9" : b"01001",
    "A" : b"10000",
    "B" : b"01010",
    "C" : b"01011",
    "D" : b"01100",
    "E" : b"01101",
    "F" : b"01110",
    "G" : b"01111",
    "H" : b"10001",
    "I" : b"10010",
    "J" : b"10011",
    "K" : b"10100",
    "L" : b"10101",
    "M" : b"10110",
    "N" : b"10111",
    "O" : b"11000",
    "P" : b"11001",
    "Q" : b"11010",
    "R" : b"11011",
    "S" : b"11100",
    "T" : b"11101",
    "x" : b"11110", ##skip frame
    "*" : b"11111", ##instruction sequence modification
}

## location of the script file
script_path = os.path.dirname(__file__)

## video data
video_data = {
    "res_x" : 128,
    "res_y" : 72,
    "fpses" : 15,
    "format" : ".png",
    "name" : "Output.numb",
    "input" : script_path + "\Images",
    "output" : script_path + "\Output",
    "images" : [],
    "frames" : [],
    "optimized_video" : [],
    "compressed_video" : [],
    "binary_video" : b"",
}

start_import_time = time.time() #execution start
loaded = 0 #images loaded;
frames = 0 #frames loaded;
optimized = 0 #frames optimized;
compressed = 0 #frames compressed;
baked = 0 #frames baked;

## transforms the data into bytes
def _to_Bytes(data):
  b = bytearray()
  for i in range(0, len(data), 8):
    b.append(int(data[i:i+8], 2))
  return bytes(b)

## //gets all images from the import document
for f in os.listdir(video_data["input"]):

    current_format = os.path.splitext(f)[1]
    if current_format.lower() not in video_data["format"]: # checks if the images got the .png format
        continue

    video_data["images"].append(Image.open(os.path.join(video_data["input"],f)))
    loaded = loaded + 1

finish_import_time = time.time()
print("finished importing images in %s seconds" % (finish_import_time - start_import_time))
print("loaded %s images" % loaded)

start_prep_time = time.time()

## //prepares the images
for i in video_data["images"]:
    frames = frames + 1

    frame_data = []

    max_x = video_data["res_x"]
    max_y = video_data["res_y"]

    processed_pixels = 0 # pixels processed in this frame, should be equal to max_x * max_y

    current_image = i
    image_rgb = current_image.convert("RGB")
    width, height = current_image.size

    downscale_x = math.floor(width / max_x)
    downscale_y = math.floor(height / max_y)
    
    current_x = 0
    while (current_x < max_x):
        current_x += 1

        current_y = 0
        while (current_y < max_y):
            current_y += 1
            processed_pixels = processed_pixels + 1

            pixels = ""

            r, g, b = image_rgb.getpixel(((current_x * downscale_x - (downscale_x/2)),(current_y * downscale_y - (downscale_y/2))))   

            f_r = key_table[math.floor(r/8.75)]
            f_g = key_table[math.floor(g/8.75)]
            f_b = key_table[math.floor(b/8.75)]

            pixels = f_r + f_g + f_b

            frame_data.append(pixels)

    video_data["frames"].append(frame_data) 

    text = " [◔] -finished frame %s"%(frames) + " out of %s"%(loaded)
    print("\r", text ,end="")

print("    done!")

finish_prep_time = time.time()
print("  [✓] -finished preparing images in %s seconds" % (finish_prep_time - start_prep_time))

## optimizes the repeating frames of a video
last_frame = []
for frame in video_data["frames"]:
    optimized_frame = []

    ## checks if it is the first frame, it will be skipped as it cannot be optimized
    if optimized == 0 :
        optimized += 1
        last_frame = frame
        video_data["optimized_video"].append(frame)
    else:
        line = 0
        for pixel in frame:
            if last_frame[line] == pixel :
                optimized_frame.append(key_table[30])
                line += 1
            else:
                optimized_frame.append(pixel)
                line += 1

        optimized += 1
        last_frame = frame
        video_data["optimized_video"].append(optimized_frame)
        
        text = " [◔] -optimized frame %s"%(optimized) + " out of %s"%(loaded)
        print("\r", text ,end="")

print("    done!")

finish_optimize_time = time.time()
print("  [✓] -finished optimizing images in %s seconds" % (finish_optimize_time - finish_prep_time))

# converts the repetitive frames into commands.
for frame in video_data["optimized_video"]:
    pixel_string = ""

    for pixel in frame:
        pixel_string += pixel

    string = pixel_string

    for key1 in key_table :
        replace = 30
        while replace >= 3:
            string_format = (key_table[key1] + key_table[key1] + key_table[key1]) * replace
            instrunction_format = key_table[31] + key_table[31] + key_table[replace - 1] + key_table[key1] + key_table[key1] + key_table[key1]
            string = string.replace(string_format,"(" + instrunction_format + ")")
            replace = replace - 1

    ## first round of skip pixel instructions *x == 30 pixels
    replace = 30
    while replace >= 2:
        string_format = key_table[30] * replace
        instrunction_format = key_table[31] + key_table[replace - 1]
        if replace == 30 :
            instrunction_format = key_table[31] + key_table[30]
        string = string.replace(string_format,instrunction_format)
        replace = replace - 1

    ## second round of skip pixel instructions *T*x == 900 pixels
    replace = 30
    while replace >= 2:
        string_format = (key_table[31] + key_table[30]) * replace
        instrunction_format =( key_table[31] + key_table[replace - 1] ) + ( key_table[31] + key_table[30] )
        string = string.replace(string_format,"(" + instrunction_format + ")")
        replace = replace - 1

    ## removes all the reservation purposes symbols
    string = string.replace("(","")
    string = string.replace(")","")

    compressed += 1
    video_data["compressed_video"].append(string)

    text = " [◔] -compressed frame %s"%(compressed) + " out of %s"%(loaded)
    print("\r", text ,end="")

print("    done!")

finish_compress_time = time.time()
print("  [✓] -finished compressing images in %s seconds" % (finish_compress_time - finish_optimize_time))

## transforms processed video into binary data
for frame in video_data["compressed_video"]:
    binary_string = b""

    for element in frame:
        ##print(pixel)
        binary_string += binary_table[element]
    
    video_data["binary_video"] += binary_string
    baked += 1
    
    text = " [◔] -baked frame %s"%(baked) + " out of %s"%(loaded)
    print("\r", text ,end="")

print("    done!")

finish_encoding_time = time.time()
print("  [✓] -finished baking into binary in %s seconds" % (finish_encoding_time - finish_compress_time))

## writes the video
output_video = open(video_data["name"], "xb+") 
output_video.write(_to_Bytes(video_data["binary_video"]))
print("video file exported!")

## writes the readable text video
output_text = open("Output_Readable.txt", "w") 
doc = json.dumps(video_data["compressed_video"],ensure_ascii=True,separators=(',', ':'))
output_text.write(doc)
print("text file exported!")

finish_job_time = time.time()
print("~~//~~ finished converting the video in %s seconds ~~//~~" % (finish_job_time - start_import_time))


