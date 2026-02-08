# Используем стабильный образ RunPod
FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

# 1. Системные зависимости
# Удаляем кэш apt сразу после установки в том же слое
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

# 2. Подготовка pip
RUN pip install --no-cache-dir --upgrade pip wheel setuptools

# 3. Установка библиотек (Сначала тяжелые, чтобы закэшировались)
# Объединяем в один RUN для экономии места
RUN pip install --no-cache-dir numpy Cython && \
    pip install --no-cache-dir pycocotools && \
    pip install --no-cache-dir \
    opencv-python-headless \
    imageio \
    kornia \
    sageattention \
    onnxruntime-gpu \
    ultralytics \
    scikit-image \
    piexif \
    pandas \
    matplotlib \
    pillow \
    scipy \
    segment-anything \
    jupyterlab

# Создаем рабочую папку
WORKDIR /comfy-cache

# 4. Установка ComfyUI и Нод
# Объединяем клонирование в один слой. 
# Это критично для уменьшения размера образа.
RUN git clone https://github.com/comfyanonymous/ComfyUI.git . && \
    cd custom_nodes && \
    git clone https://github.com/ltdrdata/ComfyUI-Manager.git && \
    git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack.git && \
    git clone https://github.com/kijai/ComfyUI-KJNodes.git && \
    git clone https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes.git && \
    git clone https://github.com/rgthree/rgthree-comfy.git

# Возвращаемся в корень
WORKDIR /

# Копируем скрипт запуска
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Команда запуска
CMD ["/start.sh"]
