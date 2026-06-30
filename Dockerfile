# syntax=docker/dockerfile:1
###############################################################################
# Dockerfile: Geant4 (compilado desde fuente) + ROOT (binario precompilado)
#
#   Geant4:  v11.4.2  -> https://github.com/Geant4/geant4 (compilado)
#   ROOT:    v6.40.02 -> distribución binaria para Ubuntu 24.04 / gcc 13.3
#
#   Construir:   docker build -t geant4-root:11.4.2 .
#   Ejecutar:    docker run --rm -it geant4-root:11.4.2
#
#   Nota: la compilación de Geant4 es larga (~30-60 min) y la imagen pesa
#   varios GB (datasets de Geant4 + binarios de ROOT).
###############################################################################

FROM ubuntu:24.04

# --- Argumentos parametrizables (puedes cambiar la versión sin tocar el resto) ---
ARG G4_VERSION=11.4.2
ARG G4_SRC_URL=https://github.com/Geant4/geant4/archive/refs/tags/v${G4_VERSION}.zip

# --- Variables de entorno ---
ENV DEBIAN_FRONTEND=noninteractive \
    G4INSTALL=/opt/geant4

###############################################################################
# 1) Dependencias de compilación y de visualización
#    - build-essential, cmake, ninja : cadena de compilación
#    - expat, zlib, xerces-c          : librerías que Geant4 necesita (GDML usa xerces)
#    - OpenGL + X11 + Qt6             : drivers de visualización
###############################################################################
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        ninja-build \
        wget \
        unzip \
        ca-certificates \
        libexpat1-dev \
        zlib1g-dev \
        libxerces-c-dev \
        libgl1-mesa-dev \
        libglu1-mesa-dev \
        libx11-dev \
        libxmu-dev \
        libxi-dev \
        libxrender-dev \
        qt6-base-dev \
        libqt6opengl6-dev \
    && rm -rf /var/lib/apt/lists/*

###############################################################################
# 2) Descarga y descompresión del código fuente desde la etiqueta de GitHub
#    El ZIP se descomprime en una carpeta geant4-<versión>; la renombramos.
###############################################################################
WORKDIR /tmp
RUN wget -q "${G4_SRC_URL}" -O geant4.zip \
    && unzip -q geant4.zip \
    && mv "geant4-${G4_VERSION}" geant4-src \
    && rm geant4.zip

###############################################################################
# 3) Configuración con CMake y compilación
#    Opciones elegidas (todas modificables según tu curso):
#      GEANT4_INSTALL_DATA=ON       -> descarga los datasets físicos (autocontenido)
#      GEANT4_BUILD_MULTITHREADED   -> soporte multihilo
#      GEANT4_USE_GDML              -> geometría en GDML (XML)
#      GEANT4_USE_QT                -> interfaz Qt6 (por defecto en 11.4)
#      GEANT4_USE_OPENGL_X11        -> visualización OpenGL vía X11
###############################################################################
WORKDIR /tmp/geant4-build
RUN cmake -G Ninja /tmp/geant4-src \
        -DCMAKE_INSTALL_PREFIX="${G4INSTALL}" \
        -DCMAKE_BUILD_TYPE=Release \
        -DGEANT4_INSTALL_DATA=ON \
        -DGEANT4_BUILD_MULTITHREADED=ON \
        -DGEANT4_USE_GDML=ON \
        -DGEANT4_USE_QT=ON \
        -DGEANT4_USE_OPENGL_X11=ON \
        -DGEANT4_USE_RAYTRACER_X11=ON \
    && cmake --build . --parallel "$(nproc)" \
    && cmake --install . \
    && rm -rf /tmp/geant4-build /tmp/geant4-src


###############################################################################
# 3.5) Editores y utilidades de terminal
#      Capa ligera colocada DESPUÉS de compilar Geant4, para que reconstruir
#      no fuerce recompilar todo el toolkit (aprovecha la caché de capas).
###############################################################################
RUN apt-get update && apt-get install -y --no-install-recommends \
        vim \
        nano \
        less \
        libboost-all-dev \
        view3dscene \
    && rm -rf /var/lib/apt/lists/*

###############################################################################
# 3.6) ROOT (CERN) — distribución BINARIA precompilada
#      El tarball coincide con la plataforma de la imagen (Ubuntu 24.04 + gcc 13.3),
#      por eso NO se compila nada: se descarga y se descomprime.
#
#      Dependencias de ejecución del binario:
#        - python3        : PyROOT (Ubuntu 24.04 trae Python 3.12, que es la
#                           version con la que se compilo este binario)
#        - libssl-dev     : OpenSSL (red, certificados)
#        - libtbb12       : Intel TBB (libtbb.so.12), que ROOT usa para el
#                           multithreading implícito; imprescindible para arrancar
#        - libvdt-dev / nlohmann-json3-dev : dependencias que ROOTConfig.cmake
#                           resuelve vía find_dependency(); el binario las trae
#                           como "builtin" pero no las localiza, así que sin estos
#                           paquetes tu find_package(ROOT) falla al configurar
#        - libxpm/libxft/libxext : librerias X11 que ROOT usa para los graficos
#                                  (libX11/GL/GLU ya se instalaron en la capa 1)
###############################################################################
ARG ROOT_VERSION=6.40.02
ARG ROOT_URL=https://root.cern/download/root_v${ROOT_VERSION}.Linux-ubuntu24.04-x86_64-gcc13.3.tar.gz

RUN apt-get update && apt-get install -y --no-install-recommends \
        python3 \
        libssl-dev \
        libtbb12 \
        libvdt-dev \
        nlohmann-json3-dev \
        libxpm-dev \
        libxft-dev \
        libxext-dev \
    && rm -rf /var/lib/apt/lists/*

# Descarga y descompresion: el tarball crea el directorio /opt/root
RUN wget -q "${ROOT_URL}" -O /tmp/root.tar.gz \
    && tar -xzf /tmp/root.tar.gz -C /opt \
    && rm /tmp/root.tar.gz

###############################################################################
# 4) Entorno en tiempo de ejecución (Geant4 + ROOT)
#    - geant4.sh    : exporta las rutas de datos y librerías de Geant4
#    - thisroot.sh  : exporta PATH, ROOTSYS, LD_LIBRARY_PATH, PYTHONPATH, etc.
#    Se cargan de dos formas complementarias:
#      - en un entrypoint, para comandos no interactivos (docker run <cmd>)
#      - en el .bashrc de root, para shells interactivas, incluido docker exec
#        (que NO pasa por el entrypoint).
###############################################################################
RUN printf '#!/bin/bash\nsource %s/bin/geant4.sh\nsource /opt/root/bin/thisroot.sh\nexec "$@"\n' "${G4INSTALL}" \
        > /usr/local/bin/entrypoint.sh \
    && chmod +x /usr/local/bin/entrypoint.sh \
    && printf '\n# Entorno de Geant4 y ROOT\nsource %s/bin/geant4.sh\nsource /opt/root/bin/thisroot.sh\n' "${G4INSTALL}" \
        >> /root/.bashrc

# Carpeta de trabajo recomendada para montar tus simulaciones con -v
WORKDIR /work

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash"]
