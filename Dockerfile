# Используем стабильный образ RunPod с PyTorch 2.4, Python 3.11 и CUDA 12.4.1
FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

# Установка системных зависимостей (build-essential нужен для компиляции pycocotools)
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    aria2 \
    git \
    wget \
    libgl1-mesa-glx \
    libglib2.0-0 \
    build-essential \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Установка Python-библиотек + JupyterLab
# Ставим wheel и setuptools первыми, чтобы избежать ошибок сборки
RUN pip install --no-cache-dir --upgrade pip wheel setuptools && \
    pip install --no-cache-dir \
    opencv-python-headless \
    imageio \
    kornia \
    sageattention \
    onnxruntime-gpu \
    ultralytics \
    scikit-image \
    pandas \
    matplotlib \
    pillow \
    jupyterlab

# Создаем папку для кэша ComfyUI
WORKDIR /comfy-cache

# 1. Установка ComfyUI
RUN git clone https://github.com/comfyanonymous/ComfyUI.git .

# 2. Установка ComfyUI Manager
WORKDIR /comfy-cache/custom_nodes
RUN git clone https://github.com/ltdrdata/ComfyUI-Manager.git

# 3. Установка кастомных нод
# Impact Pack FIX:
# - Удаляем opencv-python (используем headless, который уже поставили)
# - Удаляем onnxruntime (используем onnxruntime-gpu, который уже поставили)
# - Ставим pycocotools отдельно
RUN git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack.git && \
    cd ComfyUI-Impact-Pack && \
    sed -i '/opencv-python/d' requirements.txt && \
    sed -i '/onnxruntime/d' requirements.txt && \
    pip install --no-cache-dir pycocotools && \
    pip install --no-cache-dir -r requirements.txt

# KJNodes (PatchSageAttentionKJ)
RUN git clone https://github.com/kijai/ComfyUI-KJNodes.git && \
    cd ComfyUI-KJNodes && \
    pip install --no-cache-dir --prefer-binary -r requirements.txt

# Comfyroll (CR Upscale, Post-Process)
RUN git clone https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes.git

# rgthree (Image Comparer)
RUN git clone https://github.com/rgthree/rgthree-comfy.git

# Возвращаемся в корень
WORKDIR /

# Копируем скрипт запуска
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Команда запуска
CMD ["/start.sh"]
