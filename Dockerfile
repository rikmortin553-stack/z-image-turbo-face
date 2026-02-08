# Используем стабильный образ RunPod
FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

# 1. Системные зависимости
# build-essential и python3-dev критичны для сборки pycocotools
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

# 2. Python библиотеки (Global)
# ВАЖНО: Порядок установки имеет значение!
# 1. Обновляем pip/wheel.
# 2. Ставим Cython и numpy (нужны для сборки других пакетов).
# 3. Ставим pycocotools отдельно (чтобы он увидел numpy и Cython).
# 4. Ставим остальные библиотеки.
RUN pip install --no-cache-dir --upgrade pip wheel setuptools && \
    pip install --no-cache-dir Cython numpy && \
    pip install --no-cache-dir pycocotools && \
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

# 3. Установка ComfyUI
RUN git clone https://github.com/comfyanonymous/ComfyUI.git .

# 4. Установка ComfyUI Manager
WORKDIR /comfy-cache/custom_nodes
RUN git clone https://github.com/ltdrdata/ComfyUI-Manager.git

# 5. Установка кастомных нод
# Impact Pack FIX:
# Удаляем из requirements.txt всё, что может вызвать конфликт или уже установлено.
# opencv-python -> конфликтует с headless (удаляем)
# onnxruntime -> конфликтует с gpu версией (удаляем)
# pycocotools -> уже установили выше (удаляем, чтобы не пытался пересобрать)
# numpy -> уже установили (удаляем)
RUN git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack.git && \
    cd ComfyUI-Impact-Pack && \
    sed -i '/opencv-python/d' requirements.txt && \
    sed -i '/onnxruntime/d' requirements.txt && \
    sed -i '/pycocotools/d' requirements.txt && \
    sed -i '/numpy/d' requirements.txt && \
    pip install --no-cache-dir -r requirements.txt

# KJNodes (PatchSageAttentionKJ)
RUN git clone https://github.com/kijai/ComfyUI-KJNodes.git && \
    cd ComfyUI-KJNodes && \
    pip install --no-cache-dir --prefer-binary -r requirements.txt

# Comfyroll
RUN git clone https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes.git

# rgthree
RUN git clone https://github.com/rgthree/rgthree-comfy.git

# Возвращаемся в корень
WORKDIR /

# Копируем скрипт запуска
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Команда запуска
CMD ["/start.sh"]
