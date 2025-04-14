#!/bin/bash

TEST_NAME="upsampling_recombination_tests_01"
GPU_ID=0  # Use a single GPU for all tests

# Create the main output directory
mkdir -p test_outputs/$TEST_NAME

# Base input files
IMAGE_PATH="/groups/ag-reuter/projects/fastsurfer-tumor/data/UPENN_GBM/NIfTI-files/images_structural_unstripped/UPENN-GBM-00002_11/UPENN-GBM-00002_11_T1_unstripped.nii.gz"
MASK_PATH="/groups/ag-reuter/projects/fastsurfer-tumor/data/UPENN_GBM/NIfTI-files/images_segm/UPENN-GBM-00002_11_segm.nii.gz"

echo "Starting tests with different configurations..."

# Configuration 1: Skip 100 recombination steps
echo "Running test with 100 skipped recombination steps..."
./run_lit_containerized.sh \
    -i $IMAGE_PATH \
    -m $MASK_PATH \
    -o test_outputs/$TEST_NAME/skip_100_steps \
    --dilate 5 \
    --gpus $GPU_ID \
    --skip_recombination_steps 100

# Configuration 2: Skip 1 recombination step  
echo "Running test with 1 skipped recombination step..."
./run_lit_containerized.sh \
    -i $IMAGE_PATH \
    -m $MASK_PATH \
    -o test_outputs/$TEST_NAME/skip_1_step \
    --dilate 5 \
    --gpus $GPU_ID \
    --skip_recombination_steps 1

# Configuration 3: Skip 10 recombination steps
echo "Running test with 10 skipped recombination steps..."
./run_lit_containerized.sh \
    -i $IMAGE_PATH \
    -m $MASK_PATH \
    -o test_outputs/$TEST_NAME/skip_10_steps \
    --dilate 5 \
    --gpus $GPU_ID \
    --skip_recombination_steps 10

# Configuration 4: Upsampling by factor 2 in all dimensions
echo "Running test with upsampling factor 2 in all dimensions..."
./run_lit_containerized.sh \
    -i data/HCP_110613_downsampled.nii.gz \
    -m /groups/ag-reuter/projects/fastsurfer-tumor/experiments/HCP_110613_defo_test_inpainting_FSVdocker/inpainting_volumes/inpainting_mask.nii.gz \
    -o test_outputs/$TEST_NAME/upsample_2x1x1 \
    --dilate 5 \
    --gpus $GPU_ID \
    --upsample_factor 2 1 1 \
    --skip_recombination_steps 100

echo "All tests completed. Results are in test_outputs/$TEST_NAME/" 