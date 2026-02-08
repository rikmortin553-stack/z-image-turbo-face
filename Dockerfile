# Используем стабильный образ RunPod
FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

# 1. Системные зависимости
# build-essential и python3-dev ОБЯЗАТЕЛЬНЫ для сборки C++ частей библиотек
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

# 3. Установка "капризных" библиотек (ЭТАП 1)
# Сначала ставим ТОЛЬКО numpy и Cython, чтобы они точно были готовы к моменту сборки pycocotools
RUN pip install --no-cache-dir numpy Cython

# 4. Установка pycocotools (ЭТАП 2)
# Ставим отдельно, теперь он гарантированно найдет numpy
RUN pip install --no-cache-dir pycocotools

# 5. Установка ВСЕХ остальных библиотек (ЭТАП 3)
# Здесь мы ставим всё, что нужно для ComfyUI, Impact Pack и других нод.
# Мы используем opencv-python-headless, чтобы избежать краша графики.
RUN pip install --no-cache-dir \
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

# 6. Установка ComfyUI
RUN git clone https://github.com/comfyanonymous/ComfyUI.git .

# 7. Установка ComfyUI Manager
WORKDIR /comfy-cache/custom_nodes
RUN git clone https://github.com/ltdrdata/ComfyUI-Manager.git

# 8. Клонирование кастомных нод (БЕЗ pip install)
# Мы уже установили все их зависимости выше вручную, поэтому просто клонируем.
# Это исключает ошибки сборки внутри requirements.txt.

RUN git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack.git
RUN git clone https://github.com/kijai/ComfyUI-KJNodes.git
RUN git clone https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes.git
RUN git clone https://github.com/rgthree/rgthree-comfy.git

# Возвращаемся в корень
WORKDIR /

# Копируем скрипт запуска
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Команда запуска
CMD ["/start.sh"]
