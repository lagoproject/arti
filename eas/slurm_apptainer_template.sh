#!/bin/bash
#SBATCH --job-name=arti_sim
#SBATCH --output=arti_%j.log
#SBATCH --error=arti_%j.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --time=24:00:00
# #SBATCH --partition=compute   # Descomentar y ajustar según el clúster

# ==============================================================================
# Plantilla SLURM para ejecutar ARTI (EAS + Analysis) sobre Apptainer
# ==============================================================================

# Load apptainer
module load apptainer

set -e

# 1. Rutas en el clúster (IMPORTANTE:Ajustar a tu entorno)
SIF_IMAGE="${HOME}/arti/arti.sif"
HOST_CORSIKA_RUN="/girg/amartinez/corsika-76400/run"
WORK_DIR="${PWD}/workdir_sim"

# 2. Parámetros físicos de la simulación
PROJECT="fluxBGA"
SITE="bga"
ALTITUDE=956
FLUX_TIME=3600
CORSIKA_VER="76400"
ATMOD="1"  # Modelo atmosférico (usar -c <ATMOD> si CORSIKA fue compilado sin ATMEXT/bernlohr)
USER_ID="${USER:-LAGO}"
NPROCS="${SLURM_CPUS_PER_TASK:-8}"

export ARTI_OFFLINE=1
export ARTI_NPROCS="${NPROCS}"

mkdir -p "${WORK_DIR}"

echo "=== [1/4] Generando configuración EAS con do_sims.sh ==="
apptainer exec \
    --bind "${HOST_CORSIKA_RUN}:/opt/corsika/run" \
    --bind "${WORK_DIR}:${WORK_DIR}" \
    "${SIF_IMAGE}" \
    do_sims.sh \
        -w "${WORK_DIR}" \
        -p "${PROJECT}" \
        -s "${SITE}" \
        -v "${CORSIKA_VER}" \
        -c "${ATMOD}" \
        -t "${FLUX_TIME}" \
        -j "${NPROCS}" \
        -u "${USER_ID}" \
        -y -x

FULL_PRJ=$(printf "%s_%06d" "${PROJECT}" "${FLUX_TIME}")

echo "=== [2/4] Ejecutando simulaciones CORSIKA en paralelo (${NPROCS} hilos) ==="
apptainer exec \
    --bind "${HOST_CORSIKA_RUN}:/opt/corsika/run" \
    --bind "${WORK_DIR}:${WORK_DIR}" \
    "${SIF_IMAGE}" \
    bash "${WORK_DIR}/go-apptainer-${FULL_PRJ}.sh"

echo "=== [3/4] Verificando integridad de la corrida S0 (do_test_S0.sh) ==="
apptainer exec \
    --bind "${WORK_DIR}:${WORK_DIR}" \
    "${SIF_IMAGE}" \
    bash -c "cd '${WORK_DIR}' && do_test_S0.sh -o '${WORK_DIR}/${FULL_PRJ}' -w '${WORK_DIR}' -m"

echo "=== [4/4] Ejecutando análisis de secundarias (do_showers.sh) ==="
apptainer exec \
    --bind "${WORK_DIR}:${WORK_DIR}" \
    "${SIF_IMAGE}" \
    do_showers.sh \
        -o "${WORK_DIR}/${FULL_PRJ}" \
        -w "${WORK_DIR}" \
        -p "S1_${FULL_PRJ}" \
        -k "${ALTITUDE}" \
        -t "${FLUX_TIME}" \
        -l

echo "=== Pipeline completado exitosamente en ${WORK_DIR} ==="

