#!/bin/bash

# Always anchor the execution to the directory it is in, so we can run this bash script from anywhere
SCRIPT_DIR=$(python3 -c "import os; print(os.path.dirname(os.path.realpath('$0')))")

# Set BUILD_CONTEXT as the parent directory of SCRIPT_DIR
BUILD_CONTEXT=$(dirname "$SCRIPT_DIR")

# Check if arguments are passed, otherwise prompt
if [ "$#" -eq 3 ]; then
    image_tag="$1"
    mode="$2"
    ecr_repo="$3"
else
    read -p "Enter the custom image tag name: " image_tag
    read -p "Select one of preprocess, train, or serve: " mode
    read -p "Enter the ECR repository name: " ecr_repo
fi

# Check if the image tag is provided where [-z string]: True if the string is null (an empty string)
if [ -z "$image_tag" ] || [ -z "$ecr_repo" ]; then
  echo "Please provide both the custom image tag name and the ECR repository name."
  exit 1
fi

# Choose Dockerfile based on mode
if [ "$mode" == "serve" ]; then
    DOCKERFILE_PATH="$SCRIPT_DIR/$mode.Dockerfile"
elif [ "$mode" == "preprocess" ]; then
    DOCKERFILE_PATH="$SCRIPT_DIR/$mode.Dockerfile"
elif [ "$mode" == "train" ]; then
    DOCKERFILE_PATH="$SCRIPT_DIR/$mode.Dockerfile"
else
    echo "Invalid mode specified, which must either be 'train', 'serve' or 'preprocess'."
    exit 1
fi

# Variables
account_id=$(aws sts get-caller-identity --query Account --output text)
region=$(aws configure get region)
image_name="$account_id.dkr.ecr.$region.amazonaws.com/$ecr_repo:$image_tag"

# Login to ECR based on 'https://docs.aws.amazon.com/AmazonECR/latest/userguide/registry_auth.html'
aws ecr get-login-password --region "$region" | docker login --username AWS --password-stdin "$account_id.dkr.ecr.$region.amazonaws.com"

# Docker buildkit is required to use dockerfile specific ignore files
DOCKER_BUILDKIT=1 docker build \
    -f "$DOCKERFILE_PATH" \
    -t "$image_name" \
    "$BUILD_CONTEXT"

docker push "$image_name"