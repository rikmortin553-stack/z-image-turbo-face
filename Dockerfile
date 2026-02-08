# Используем стабильный образ RunPod с PyTorch 2.4, Python 3.11 и CUDA 12.4.1
FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

# Установка системных зависимостей (aria2 для быстрой загрузки, libgl1 для OpenCV)
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    aria2 \
    git \
    wget \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Установка Python-библиотек, запрошенных в ТЗ + зависимостей для нод
# sageattention, kornia, onnxruntime-gpu (для Impact Pack)
RUN pip install --no-cache-dir \
    opencv-python \
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

# 3. Установка кастомных нод из ТЗ
# Impact Pack (FaceDetailer, SAMLoader)
RUN git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack.git && \
    cd ComfyUI-Impact-Pack && \
    pip install -r requirements.txt

# KJNodes (PatchSageAttentionKJ)
RUN git clone https://github.com/kijai/ComfyUI-KJNodes.git && \
    cd ComfyUI-KJNodes && \
    pip install -r requirements.txt

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
