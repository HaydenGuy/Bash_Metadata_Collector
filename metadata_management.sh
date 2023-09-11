#!/bin/bash

target_directory="${1:-.}"

# List all files (not subdirectories) in the target directory.
files_list=($(find "$target_directory" -maxdepth 1 -type f))

# Define the metadata file and its path.
metadata_file="metadata.txt"
metadata_file_path="$target_directory/$metadata_file"

# Define an array of allowed file types for filtering.
allowed_file_types=("jpg" "png" "exr" "tiff" "mp4" "mov" "avi" "mkv")

# Create the metadata file if it doesn't exist.
if [ ! -e "$metadata_file_path" ]; then
    touch "$metadata_file_path"
fi

# Loop through the list of files in the target directory.
for file in "${files_list[@]}"; do
    # Extract all metadata information for the current file.
    all_metadata=$(exiftool "$file")

    # Extract specific metadata fields.
    file_name=$(echo "$all_metadata" | awk -F ": " '/File Name/ {print $NF}')
    directory=$(echo "$all_metadata" | awk -F ": " '/Directory/ {print $NF}')
    file_size=$(echo "$all_metadata" | awk -F ": " '/File Size/ {print $NF}')
    file_extension=$(echo "$all_metadata" | awk -F ": " '/File Type Extension/ {print $NF}')
    duration=$(echo "$all_metadata" | grep "^Duration " | awk -F ": " '{print $NF}')
    image_width=$(echo "$all_metadata" | grep "^Image Width " | awk -F ": " '{print $NF}')
    image_height=$(echo "$all_metadata" | grep "^Image Height " | awk -F ": " '{print $NF}')

    # Initialize aspect_ratio with a default value of "N/A."
    aspect_ratio="N/A"

    # Check if both image_width and image_height are non-empty and numeric.
    if [[ -n "$image_width" && -n "$image_height" && "$image_width" =~ ^[0-9]+$ && "$image_height" =~ ^[0-9]+$ && "$image_height" -ne 0 ]]; then
        # Calculate the aspect ratio and format it to two decimal places.
        aspect_ratio=$(awk -v width="$image_width" -v height="$image_height" 'BEGIN { printf "%.2f", width / height }')
    fi

    # Check if the file extension is in the list of allowed file types.
    if [[ " ${allowed_file_types[*]} " =~ " $file_extension " ]]; then
        # Append metadata information to the metadata file using a here document (cat <<EOF >>).
        cat <<EOF >> $metadata_file_path

File Name      : $file_name
Directory      : $directory
File Size      : $file_size
File Extension : $file_extension
Duration       : $duration
Image Width    : $image_width
Image Height   : $image_height
Aspect Ratio   : $aspect_ratio

EOF
    fi
done