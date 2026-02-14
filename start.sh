#!/bin/bash

# Останавливаем скрипт при ошибках
set -e

echo "--- Starting ComfyUI Initialization ---"

WORK_DIR="/workspace/ComfyUI"
CACHE_DIR="/comfy-cache"

# 1. Проверка наличия ComfyUI в workspace
if [ ! -d "$WORK_DIR" ]; then
    echo "ComfyUI not found in workspace. Copying from cache..."
    cp -r $CACHE_DIR $WORK_DIR
else
    echo "ComfyUI found in workspace. Using existing installation."
fi

cd $WORK_DIR

# 2. Структура папок и скачивание моделей
# Используем aria2c с 16 потоками для скорости

# Функция для скачивания (URL, Папка, ИмяФайла)
download_model() {
    local url=$1
    local dir=$2
    local file=$3
    
    mkdir -p "$dir"
    if [ ! -f "$dir/$file" ]; then
        echo "Downloading $file..."
        aria2c -x 16 -s 16 -k 1M --console-log-level=error -o "$file" -d "$dir" "$url"
    else
        echo "$file already exists. Skipping."
    fi
}

echo "--- Checking Models for Z-Image Turbo & Upscalers ---"

# --- Z-Image Turbo Components ---

# UNET / Diffusion Model
# Кладем в models/diffusion_models, так как это split-file (UNET), но UNETLoader увидит его и там, и в checkpoints.
download_model \
    "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/diffusion_models/z_image_turbo_bf16.safetensors?download=true" \
    "models/diffusion_models" \
    "z_image_turbo_bf16.safetensors"

# LoRA
download_model \
    "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/loras/z_image_turbo_distill_patch_lora_bf16.safetensors?download=true" \
    "models/loras" \
    "z_image_turbo_distill_patch_lora_bf16.safetensors"

# Text Encoder (Qwen)
download_model \
    "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/text_encoders/qwen_3_4b.safetensors?download=true" \
    "models/text_encoders" \
    "qwen_3_4b.safetensors"

# VAE
download_model \
    "https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/vae/ae.safetensors?download=true" \
    "models/vae" \
    "ae.safetensors"

# --- Upscalers ---

# 4x_foolhardy_Remacri.pth
download_model \
    "https://huggingface.co/FacehugmanIII/4x_foolhardy_Remacri/resolve/main/4x_foolhardy_Remacri.pth" \
    "models/upscale_models" \
    "4x_foolhardy_Remacri.pth"

# 4x_NMKD-Siax_200k.pth
download_model \
    "https://huggingface.co/gemasai/4x_NMKD-Siax_200k/resolve/main/4x_NMKD-Siax_200k.pth" \
    "models/upscale_models" \
    "4x_NMKD-Siax_200k.pth"

# --- BBOX Detector for Impact Pack (FaceDetailer) ---
# Обычно Impact Pack качает сам, но лучше предзагрузить
download_model \
    "https://huggingface.co/Bingsu/adetailer/resolve/main/face_yolov8m.pt" \
    "models/ultralytics/bbox" \
    "face_yolov8m.pt"

# SAM Model for Impact Pack
download_model \
    "https://dl.fbaipublicfiles.com/segment_anything/sam_vit_b_01ec64.pth" \
    "models/sams" \
    "sam_vit_b_01ec64.pth"


echo "--- Starting JupyterLab & ComfyUI ---"

# Запуск JupyterLab в фоновом режиме на порту 8888 (без пароля для удобства внутри RunPod)
jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --ServerApp.token='' --ServerApp.password='' --ServerApp.allow_origin='*' --ServerApp.allow_remote_access=True --ServerApp.root_dir='/workspace' &

# Запуск ComfyUI (основной процесс)
python main.py --listen 0.0.0.0 --port 3000 --disable-auto-launch
