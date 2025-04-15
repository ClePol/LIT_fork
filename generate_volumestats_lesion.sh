#!/bin/bash

# Script to process volumetric statistics with input validation
# Usage: ./test_volumestats.sh -sid SUBJECT_ID -sd SUBJECTS_DIR

set -e

# Default values
SUBJECTS_DIR=""
SID=""

# Function to display usage information
usage() {
    echo "Usage: $0 -sid SUBJECT_ID -sd SUBJECTS_DIR"
    echo "  -sid SUBJECT_ID    : Subject ID"
    echo "  -sd SUBJECTS_DIR   : Subjects directory"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -sid)
            SID="$2"
            shift 2
            ;;
        -sd)
            SUBJECTS_DIR="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Check if required arguments are provided
if [[ -z "$SID" || -z "$SUBJECTS_DIR" ]]; then
    echo "Error: Subject ID and Subjects directory are required."
    usage
fi

# Check if required input files exist
echo "Checking for required input files..."
required_files=(
    "$SUBJECTS_DIR/$SID/mri/aparc.DKTatlas+aseg.deep.mgz"
    "$SUBJECTS_DIR/$SID/inpainting_volumes/inpainting_mask.nii.gz"
    "$SUBJECTS_DIR/$SID/mri/orig_nu.mgz"
    "$SUBJECTS_DIR/$SID/mri/mask.mgz"
)

for file in "${required_files[@]}"; do
    if [[ ! -f "$file" ]]; then
        echo "Error: Required file not found: $file"
        exit 1
    fi
done

echo "All required files found. Proceeding with processing..."

# Create output directories if they don't exist
mkdir -p "$SUBJECTS_DIR/$SID/stats"

# Run lesion to segmentation
echo "Running lesion to segmentation..."
docker run -u $(id -u):$(id -g) --rm -v "$SUBJECTS_DIR/$SID/:/fastsurfer_output/" --entrypoint "/bin/bash" deepmi/lit:0.5.0 -c \
    "python3 /inpainting/postprocessing/lesion_to_segmentation.py \
        -i '/fastsurfer_output/mri/aparc.DKTatlas+aseg.deep.mgz' \
        -m '/fastsurfer_output/inpainting_volumes/inpainting_mask.nii.gz' \
        -o '/fastsurfer_output/mri/aparc.DKTatlas+aseg+lesion.deep.nii.gz'"

# Check if the previous command was successful
if [[ $? -ne 0 ]]; then
    echo "Error: Lesion to segmentation failed."
    exit 1
fi

# Run volumetric statistics
echo "Running volumetric statistics..."
docker run -u $(id -u):$(id -g) --rm -v "$SUBJECTS_DIR/$SID/:/fastsurfer_output/" --entrypoint "/bin/bash" deepmi/fastsurfer:cpu-v2.4.2 -c \
    "python3.10 -s /fastsurfer/FastSurferCNN/segstats.py \
        --segfile /fastsurfer_output/mri/aparc.DKTatlas+aseg+lesion.deep.mgz \
        --segstatsfile /fastsurfer_output/stats/aseg+DKT+lesion.stats \
        --normfile /fastsurfer_output/mri/orig_nu.mgz \
        --threads 1 --empty --excludeid 0 --sd /fastsurfer_output --sid $SID \
        --ids 2 4 5 7 8 10 11 12 13 14 15 16 17 18 24 26 28 31 41 43 44 46 47 49 50 51 52 53 54 58 60 63 77 99 251 252 253 254 255 1002 1003 1005 1006 1007 1008 1009 1010 1011 1012 1013 1014 1015 1016 1017 1018 1019 1020 1021 1022 1023 1024 1025 1026 1027 1028 1029 1030 1031 1034 1035 2002 2003 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021 2022 2023 2024 2025 2026 2027 2028 2029 2030 2031 2034 2035 \
        --lut /fastsurfer/FastSurferCNN/config/FreeSurferColorLUT.txt measures \
        --compute Mask\(/fastsurfer_output/mri/mask.mgz\) BrainSeg BrainSegNotVent SupraTentorial SupraTentorialNotVent SubCortGray rhCerebralWhiteMatter lhCerebralWhiteMatter CerebralWhiteMatter"

# Check if the previous command was successful
if [[ $? -ne 0 ]]; then
    echo "Error: Volumetric statistics calculation failed."
    exit 1
fi

echo "Processing completed successfully."
echo "Output statistics file: $SUBJECTS_DIR/$SID/stats/aseg+DKT+lesion.stats"
