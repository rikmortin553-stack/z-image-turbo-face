# Используем стабильный образ RunPod
FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

# 1. Системные зависимости
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

# 3. Установка библиотек (Python Dependencies)
# Добавляем ВСЕ, что просили твои логи и скриншоты:
# - dill (для Impact Subpack)
# - pedalboard (для CRT Nodes)
# - GitPython (для Manager)
# - matrix-client (иногда нужен)
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
    sqlalchemy \
    spandrel \
    soundfile \
    jupyterlab \
    GitPython \
    dill \
    matrix-client \
    pedalboard

# Создаем рабочую папку
WORKDIR /comfy-cache

# 4. Установка ComfyUI и Нод
# Клонируем ComfyUI
RUN git clone https://github.com/comfyanonymous/ComfyUI.git . && \
    pip install --no-cache-dir -r requirements.txt

# 5. Установка ВСЕХ кастомных нод (включая те, что на скриншоте)
WORKDIR /comfy-cache/custom_nodes

RUN git clone https://github.com/ltdrdata/ComfyUI-Manager.git && \
    git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack.git && \
    git clone https://github.com/ltdrdata/ComfyUI-Impact-Subpack.git && \
    git clone https://github.com/ControlAltAI/ControlAltAI-Nodes.git && \
    git clone https://github.com/Tangshuang/CRT-Nodes.git && \
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
