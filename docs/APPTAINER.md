# Ejecución de ARTI en Clústeres HPC con Apptainer / Singularity

Esta guía describe cómo construir y ejecutar el contenedor ligero de **ARTI** (`eas` + `analysis`) sobre **Apptainer / Singularity**, inyectando **CORSIKA 7** desde el sistema anfitrión mediante `--bind`.

---

## 1. Construcción de la Imagen `.sif`

En una máquina donde tengas permisos de construcción (`sudo` o `--fakeroot`), ejecuta desde la raíz del repositorio:

```bash
sudo apptainer build arti.sif arti.def
```

Para verificar los binarios internos y las utilidades del contenedor:

```bash
apptainer test arti.sif
apptainer run-help arti.sif
```

> **Nota para clústeres sin `squashfuse`:** Si el clúster muestra el aviso `INFO: squashfuse not found... Converting SIF file to temporary sandbox...`, puedes convertir la imagen una sola vez a un directorio *sandbox* en el clúster para eliminar el tiempo de extracción inicial:
> ```bash
> apptainer build --sandbox arti_box arti.sif
> ```
> y usar `arti_box` en lugar de `arti.sif` en todos los comandos.

---

## 2. Compilación de CORSIKA 7 para ARTI

ARTI está diseñado para trabajar con **CORSIKA 7** (p. ej. `v76400`, `v77402`, etc.). Debido a la licencia institucional del KIT, los fuentes o binarios de CORSIKA residen en el sistema anfitrión y se montan en el contenedor en `/opt/corsika/run`.

### 2.1. Opciones de `./coconut` requeridas por ARTI

Al ejecutar `./coconut` dentro del directorio raíz de CORSIKA (`corsika-XXXXX/`), selecciona las siguientes opciones en el asistente interactivo:

1. **Arquitectura del compilador (32/64 bits):**
   - `[2]` **Compile in 64bit mode** (`-m64`, por defecto).
2. **Modelo hadrónico de alta energía:**
   - `[2]` **QGSJET-II-04** *(produce el sufijo `_QGSII` esperado por defecto en ARTI)*.
3. **Modelo hadrónico de baja energía:**
   - `[1]` **GHEISHA 2002d** *(produce el sufijo `_gheisha` esperado por defecto en ARTI)*.
4. **Geometría del detector:**
   - `[2]` **Non-flat (volume) detector geometry (`VOLUMEDET`)**: recomendado para simulaciones LAGO con detectores Cherenkov de agua (`-y` en `do_sims.sh`), **o**
   - `[1]` **Horizontal flat detector array**: geometría plana estándar.
5. **Opciones adicionales del programa (para producción en ARTI):**
   Introduce las claves separadas por espacios (por ejemplo: `1a 6 7b`) antes de terminar con `x`:
   - `1a` (**LPM**): Efecto Landau-Pomeranchuk-Migdal a altas energías.
   - `6` (**CURVED**): Atmósfera curva (permite ángulos cenitales hasta $89^\circ$).
   - `7b` (**ATMEXT**): Funciones de atmósfera externa (`bernlohr`).
     > **Nota importante sobre `ATMEXT` vs `ATMOD`:**
     > - Si compilas **con** `7b (ATMEXT)`, CORSIKA acepta la tarjeta `ATMOSPHERE <N> Y` que ARTI genera por defecto para perfiles atmosféricos externos o tabulados.
     > - Si compilas **sin** `7b (ATMEXT)`, CORSIKA rechazará la palabra clave `ATMOSPHERE` con `STOP BAD DATA CARDS / UNKNOWN KEYWORD: ATMOSPHERE`. En ese caso, **debes pasar la opción `-c <N>` a `do_sims.sh`** (por ejemplo `-c 1` o `-c 19`) para que ARTI escriba la tarjeta estándar `ATMOD <N>`.
   - `5` (**EFIELD**, opcional): Campos eléctricos atmosféricos.
   - *(Evita activar `PLOTSH`, `PLOTSH2` o `CHERENKOV`, ya que degradan el rendimiento en producción).*
6. **Finalizar y compilar:**
   - `[f]` **Compile and create executable**.

### 2.2. Compilar CORSIKA 7 usando el propio contenedor `arti.sif` (Recomendado)

Para garantizar compatibilidad total de librerías dinámicas (`glibc`, `libgfortran`, `zlib`) entre el binario de CORSIKA y el entorno interno del contenedor —e independientemente de qué versión de GCC tenga instalada el clúster—, puedes ejecutar `./coconut` directamente **dentro** de `arti.sif`:

```bash
apptainer exec \
    --bind /girg/amartinez/corsika-76400:/girg/amartinez/corsika-76400 \
    arti.sif \
    bash -c "cd /girg/amartinez/corsika-76400 && ./coconut"
```

### 2.3. Nombre del ejecutable esperado en `run/`

Al terminar la compilación, verifica que en `corsika-<VER>/run/` exista el binario con el nombre estándar que busca `rain.pl`:

```
corsika<VER>Linux_<HE>_<LE>
```

Por ejemplo, para la versión `76400` con `QGSII` y `gheisha`:
```
corsika76400Linux_QGSII_gheisha
```

> Si compilaste con alguna opción que añade un sufijo extra al nombre del binario en `run/` (o si solo cambia el nombre), crea un enlace simbólico en `corsika-<VER>/run/` con el nombre estándar:
> ```bash
> cd /girg/amartinez/corsika-76400/run
> ln -sf <nombre_binario_generado> corsika76400Linux_QGSII_gheisha
> ```

---

## 3. Variables de Entorno Soportadas

| Variable | Descripción |
| :--- | :--- |
| `ARTI_OFFLINE=1` | Fuerza el uso de la base de datos local `/opt/arti/eas/sitesLago.1.1.jsonld` sin realizar peticiones HTTP a GitHub (recomendado en nodos de cómputo sin salida a Internet). |
| `ARTI_NPROCS=<N>` | Define el número de procesos paralelos a utilizar en `go-apptainer-<proyecto>.sh` y `do_showers.sh` (tiene prioridad sobre `$SLURM_CPUS_PER_TASK` y `nproc`). |
| `ARTI_NOSCREEN=1` | En `rain.pl`, genera los `.input` y `run-*.sh` sin lanzar sesiones `screen` en segundo plano. |
| `ARTI_ALLOW_MOUNTED=1` | Permite utilizar directorios de trabajo bajo `/mnt/` en `do_showers.sh` y `do_test_S0.sh` (activado automáticamente dentro de Apptainer/Singularity). |

---

## 4. Flujo de Trabajo Completo (`S0` y `S1`)

Supongamos que en el clúster tienes:
- El directorio `run/` de CORSIKA 7 en `/girg/amartinez/corsika-76400/run` (conteniendo `corsika76400Linux_QGSII_gheisha` y sus tablas de datos).
- Un directorio de trabajo local `./test_work`.

### Paso 1: Generar el proyecto y las tarjetas de flujo (`do_sims.sh`)

> **Importante sobre modelos atmosféricos (`-c`):** Si el ejecutable de CORSIKA fue compilado **sin** la extensión `ATMEXT` (`bernlohr`), no reconoce la tarjeta `ATMOSPHERE <N> Y` y requiere la tarjeta estándar `ATMOD <N>`. En ese caso, pasa siempre `-c <N>` (por ejemplo `-c 1` para atmósfera tropical o `-c 19` para Sudamérica) a `do_sims.sh`.

```bash
mkdir -p ./test_work

ARTI_OFFLINE=1 apptainer exec \
    --bind /girg/amartinez/corsika-76400/run:/opt/corsika/run \
    --bind ./test_work:/work \
    arti.sif \
    do_sims.sh -w /work -p testBGA -s bga -v 76400 -c 1 -t 10 -j 8 -u "$USER" -y -x
```

Esto crea `/work/testBGA_000010/`, enlaza automáticamente los archivos de CORSIKA y genera el ejecutor paralelo `/work/go-apptainer-testBGA_000010.sh`.

### Paso 2: Ejecutar las simulaciones de CORSIKA en paralelo (`S0`)

```bash
ARTI_OFFLINE=1 ARTI_NPROCS=8 apptainer exec \
    --bind /girg/amartinez/corsika-76400/run:/opt/corsika/run \
    --bind ./test_work:/work \
    arti.sif \
    bash /work/go-apptainer-testBGA_000010.sh
```

### Paso 3: Verificar la integridad de la corrida (`do_test_S0.sh`)

```bash
apptainer exec \
    --bind ./test_work:/work \
    arti.sif \
    bash -c "cd /work && do_test_S0.sh -o /work/testBGA_000010 -w /work -m"
```

### Paso 4: Analizar partículas secundarias (`do_showers.sh` -> `S1`)

```bash
ARTI_NPROCS=8 apptainer exec \
    --bind ./test_work:/work \
    arti.sif \
    do_showers.sh -o /work/testBGA_000010 -w /work -p S1_testBGA_000010 -k 956 -t 10 -l
```

Los archivos resultantes (`.pri.bz2`, `.sec.bz2`, `.dse`, `.dst`, `.hst`, `.shw.bz2`) quedan guardados en `./test_work/S1_testBGA_000010/`.

---

## 5. Ejecución mediante SLURM

Puedes usar directamente la plantilla incluida en `eas/slurm_apptainer_template.sh`:

```bash
sbatch eas/slurm_apptainer_template.sh
```

---

## 6. Agradecimientos y Créditos

La auditoría, adaptación del código fuente, diseño de las recetas de contenedorización y pruebas de migración de ARTI a **Apptainer (Singularity)** para entornos HPC fueron realizadas con la asistencia de Inteligencia Artificial utilizando **Gemini 4 (modelo Argon)** en colaboración con el equipo de desarrollo de ARTI / LAGO.


