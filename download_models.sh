#!/bin/bash
#
#  download_models.sh
#  RTSP Rotator
#
#  Helper script to download CoreML object detection models
#

set -e

echo "========================================="
echo "RTSP Rotator - Model Download Helper"
echo "========================================="
echo ""

# Create models directory
MODELS_DIR="$HOME/Documents/RTSP_Rotator_Models"
mkdir -p "$MODELS_DIR"

echo "Models will be saved to: $MODELS_DIR"
echo ""

# Function to download file
download_model() {
    local url=$1
    local filename=$2
    local description=$3

    echo "Downloading: $description"
    echo "URL: $url"

    if [ -f "$MODELS_DIR/$filename" ]; then
        echo "✓ Model already exists: $filename"
        return 0
    fi

    curl -L "$url" -o "$MODELS_DIR/$filename" --progress-bar

    if [ $? -eq 0 ]; then
        echo "✓ Successfully downloaded: $filename"
        ls -lh "$MODELS_DIR/$filename"
    else
        echo "✗ Failed to download: $filename"
        return 1
    fi
    echo ""
}

echo "Available Models:"
echo "1) YOLOv8-Nano (~6MB) - Fast, good for real-time"
echo "2) YOLOv8-Small (~22MB) - Balanced speed/accuracy"
echo "3) YOLOv8-Medium (~50MB) - Higher accuracy"
echo "4) YOLOv8-Large (~87MB) - Best accuracy, slower"
echo "5) Download all models"
echo "0) Exit"
echo ""
read -p "Select model to download (0-5): " choice

case $choice in
    1)
        echo ""
        echo "Downloading YOLOv8-Nano..."
        download_model \
            "https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8n.mlpackage" \
            "yolov8n.mlpackage" \
            "YOLOv8-Nano (Fast)"
        ;;
    2)
        echo ""
        echo "Downloading YOLOv8-Small..."
        download_model \
            "https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8s.mlpackage" \
            "yolov8s.mlpackage" \
            "YOLOv8-Small (Balanced)"
        ;;
    3)
        echo ""
        echo "Downloading YOLOv8-Medium..."
        download_model \
            "https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8m.mlpackage" \
            "yolov8m.mlpackage" \
            "YOLOv8-Medium (Accurate)"
        ;;
    4)
        echo ""
        echo "Downloading YOLOv8-Large..."
        download_model \
            "https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8l.mlpackage" \
            "yolov8l.mlpackage" \
            "YOLOv8-Large (Best)"
        ;;
    5)
        echo ""
        echo "Downloading all models..."
        download_model \
            "https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8n.mlpackage" \
            "yolov8n.mlpackage" \
            "YOLOv8-Nano"
        download_model \
            "https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8s.mlpackage" \
            "yolov8s.mlpackage" \
            "YOLOv8-Small"
        download_model \
            "https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8m.mlpackage" \
            "yolov8m.mlpackage" \
            "YOLOv8-Medium"
        download_model \
            "https://github.com/ultralytics/assets/releases/download/v0.0.0/yolov8l.mlpackage" \
            "yolov8l.mlpackage" \
            "YOLOv8-Large"
        ;;
    0)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "========================================="
echo "Download Complete!"
echo "========================================="
echo ""
echo "Models saved to: $MODELS_DIR"
echo ""
echo "Next steps:"
echo "1. Open Xcode project"
echo "2. Drag model file into project navigator"
echo "3. Check 'Copy items if needed'"
echo "4. Add to target: RTSP Rotator"
echo ""
echo "Model recommendations:"
echo "- Apple Silicon: yolov8s or yolov8m"
echo "- Intel Mac: yolov8n or yolov8s"
echo "- Multi-camera: yolov8n"
echo ""
echo "For more information, see MLX_OBJECT_DETECTION.md"
echo ""

# Open models directory
open "$MODELS_DIR"
