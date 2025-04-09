#!/bin/bash

set -e

function usage()
{
cat << EOF

Usage: run_fastsurfer_containerized.sh --t1 <input_t1w_volume> --output <output_directory> [OPTIONS]

run_fastsurfer_containerized.sh takes a T1 full head image and runs the FastSurfer pipeline.

FLAGS:

Required arguments:
  --t1 <t1_image>
      Path to the input T1w volume
  --output <output_directory>
      Path to the output directory (includes subject ID)

Optional arguments:
  --fs_license <license_file>
      Path to FreeSurfer license file (optional, will use default locations if not provided)
  --gpus <gpus>
      GPUs to use. Default: 0
  --singularity
      Use Singularity instead of Docker
    
Other arguments are passed to FastSurfer (see run_fastsurfer.sh for details)

Examples:
  ./run_fastsurfer_containerized.sh --t1 t1w.nii.gz --output ./output
  ./run_fastsurfer_containerized.sh --t1 t1w.nii.gz --output ./output --gpus 1 --singularity

REFERENCES:

If you use FastSurfer for research publications, please cite:

Henschel L, Conjeti S, Estrada S, Diers K, Fischl B, Reuter M, FastSurfer - A fast and accurate deep 
learning based neuroimaging pipeline, NeuroImage 219 (2020), 117012. 
https://doi.org/10.1016/j.neuroimage.2020.117012
EOF
}

# Validate required parameters
if [[ $# -eq 0 ]]; then
  usage
  exit 1
fi

# Initialize USE_SINGULARITY to false by default
USE_SINGULARITY=false
# Default GPU is 0
GPUS="0"

while [[ $# -gt 0 ]]; do
  case $1 in
    --gpus)
        GPUS="$2"
        shift # past argument
        shift # past value
        ;;
    --t1)
      T1_IMAGE="$2"
      shift # past argument
      shift # past value
      ;;
    --output)
      OUT_DIR="$2"
      shift # past argument
      shift # past value
      ;;
    --fs_license)
      FS_LICENSE="$2"
      shift # past argument
      shift # past value
      ;;
    --singularity)
      USE_SINGULARITY=true
      shift # past value
      ;;
    -h|--help)
      usage
      exit
      ;;
    *)
      # Pass remaining arguments to FastSurfer
      FASTSURFER_ARGS+=("$1")
      shift # past argument
      ;;
  esac
done

# Validate required parameters and files
if [ -z "$T1_IMAGE" ] || [ -z "$OUT_DIR" ]; then
  echo "Error: t1 and output are required parameters"
  usage
  exit 1
fi

if [ ! -f "$T1_IMAGE" ]; then
  echo "Error: T1 image not found: $T1_IMAGE"
  exit 1
fi

mkdir -p "$OUT_DIR"

# Make all inputs absolute paths
T1_IMAGE=$(realpath "$T1_IMAGE")
OUT_DIR=$(realpath "$OUT_DIR")

# Derive output directory and subject ID from the output path
SUBJECT_DIR=$(basename "$OUT_DIR")
SUBJECTS_DIR=$(dirname "$OUT
_DIR")
# Check that t1w image is a file
if [ ! -f "$T1_IMAGE" ]; then
  echo "Error: T1 image not found: $T1_IMAGE"
  exit 1
fi

# Find FreeSurfer license file
fs_license=""

# Try to find license file, using default locations
if [ -z "$FS_LICENSE" ]; then
  for license_path in \
    "$HOME/.freesurfer.txt" \
    "/fs_license/license.txt" \
    "$FREESURFER_HOME/license.txt" \
    "$FREESURFER_HOME/.license"; do
    if [ -f "$license_path" ]; then
      fs_license="$license_path"
      break
    fi
  done
  if [ -z "$fs_license" ]; then
    echo "Warning: FreeSurfer license file not found. Please specify with --fs_license."
    echo "For information on how to obtain a FreeSurfer license, visit: https://surfer.nmr.mgh.harvard.edu/registration.html"
    exit 1
  fi
else
  fs_license="$FS_LICENSE"
  if [ ! -f "$fs_license" ]; then
    echo "Error: Specified FreeSurfer license file not found: $fs_license"
    exit 1
  fi
fi

# Define basic FastSurfer arguments
COMMON_ARGS=(
  "--t1" "${T1_IMAGE}"
  "--sid" "${SUBJECT_DIR}"
  "--sd" "${SUBJECTS_DIR}"
  "--fs_license" "/fs_license/license.txt"
)

# Run command based on the containerization tool
if [ "$USE_SINGULARITY" = true ]; then
  singularity_img="fastsurfer.simg"
  
  # Check if singularity image exists locally
  if [ ! -f "$singularity_img" ]; then
    echo "Singularity image not found locally. Will attempt to use directly from Docker Hub."
    singularity_img="docker://deepmi/fastsurfer:latest"
  fi

  echo "Running FastSurfer with Singularity..."
  singularity exec --nv \
    -B "${T1_IMAGE}":"${T1_IMAGE}":ro \
    -B "${SUBJECTS_DIR}":"${SUBJECTS_DIR}" \
    -B "${fs_license}":/fs_license/license.txt:ro \
    "$singularity_img" \
    /fastsurfer/run_fastsurfer.sh "${COMMON_ARGS[@]}" "${FASTSURFER_ARGS[@]}"
else
  echo "Running FastSurfer with Docker..."
  docker run --gpus "device=$GPUS" --rm \
    -v "${T1_IMAGE}":"${T1_IMAGE}":ro \
    -v "${SUBJECTS_DIR}":"${SUBJECTS_DIR}" \
    -u "$(id -u):$(id -g)" \
    -v "${fs_license}":/fs_license/license.txt:ro \
    deepmi/fastsurfer:latest "${COMMON_ARGS[@]}" "${FASTSURFER_ARGS[@]}"
fi

echo "FastSurfer processing complete. Results are in $OUT_DIR" 