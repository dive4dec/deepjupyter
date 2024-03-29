ARG ROOT_CONTAINER=ubuntu:22.04

FROM $ROOT_CONTAINER as foundation

ARG NB_USER="jovyan"
ARG NB_UID="1000"
ARG NB_GID="100"

# Configure environment
ENV CONDA_DIR=/opt/conda \
    SHELL=/bin/bash \
    NB_USER="${NB_USER}" \
    NB_UID=${NB_UID} \
    NB_GID=${NB_GID} \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8
ENV PATH="${CONDA_DIR}/bin:${PATH}" \
    HOME="/home/${NB_USER}"

# Fix: https://github.com/hadolint/hadolint/wiki/DL4006
# Fix: https://github.com/koalaman/shellcheck/wiki/SC3014
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

# Install all OS dependencies for notebook server that starts but lacks all
# features (e.g., download as all possible file formats)
ENV DEBIAN_FRONTEND noninteractive

FROM foundation as base

RUN apt-get update --yes && \
    # - apt-get upgrade is run to patch known vulnerabilities in apt-get packages as
    #   the ubuntu base image is rebuilt too seldom sometimes (less than once a month)
    apt-get upgrade --yes && \
    apt-get install --yes --no-install-recommends \
    # - bzip2 is necessary to extract the micromamba executable.
    bzip2 \
    ca-certificates \
    locales \
    sudo \
    # - tini is installed as a helpful container entrypoint that reaps zombie
    #   processes and such of the actual executable we want to start, see
    #   https://github.com/krallin/tini#why-tini for details.
    tini \
    wget \
    less \
    curl \
    && \
    # apt-get clean && rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

# Configure environment
ENV CONDA_DIR=/opt/conda \
    SHELL=/bin/bash \
    NB_USER="${NB_USER}" \
    NB_UID=${NB_UID} \
    NB_GID=${NB_GID} \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8
ENV PATH="${CONDA_DIR}/bin:${PATH}" \
    HOME="/home/${NB_USER}"

# Copy a script that we will use to correct permissions after running certain commands
COPY fix-permissions /usr/local/bin/fix-permissions
RUN chmod a+rx /usr/local/bin/fix-permissions

# Enable prompt color in the skeleton .bashrc before creating the default NB_USER
# hadolint ignore=SC2016
RUN sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' /etc/skel/.bashrc && \
   # Add call to conda init script see https://stackoverflow.com/a/58081608/4413446
   echo 'eval "$(command conda shell.bash hook 2> /dev/null)"' >> /etc/skel/.bashrc

# Create NB_USER with name jovyan user with UID=1000 and in the 'users' group
# and make sure these dirs are writable by the `users` group.
RUN echo "auth requisite pam_deny.so" >> /etc/pam.d/su && \
    sed -i.bak -e 's/^%admin/#%admin/' /etc/sudoers && \
    sed -i.bak -e 's/^%sudo/#%sudo/' /etc/sudoers && \
    useradd -l -m -s /bin/bash -N -u "${NB_UID}" "${NB_USER}" && \
    mkdir -p "${CONDA_DIR}" && \
    chown "${NB_USER}:${NB_GID}" "${CONDA_DIR}" && \
    chmod g+w /etc/passwd && \
    fix-permissions "${HOME}" && \
    fix-permissions "${CONDA_DIR}"

USER ${NB_UID}

# Pin python version here, or set it to "default"
ARG PYTHON_VERSION=3.11

# Setup work directory for backward-compatibility
RUN mkdir "/home/${NB_USER}/work" && \
    fix-permissions "/home/${NB_USER}"

# Download and install Micromamba, and initialize Conda prefix.
#   <https://github.com/mamba-org/mamba#micromamba>
#   Similar projects using Micromamba:
#     - Micromamba-Docker: <https://github.com/mamba-org/micromamba-docker>
#     - repo2docker: <https://github.com/jupyterhub/repo2docker>
# Install Python, Mamba and jupyter_core
# Cleanup temporary files and remove Micromamba
# Correct permissions
# Do all this in a single RUN command to avoid duplicating all of the
# files across image layers when the permissions change
COPY --chown="${NB_UID}:${NB_GID}" initial-condarc "${CONDA_DIR}/.condarc"
WORKDIR /tmp
RUN set -x && \
    arch=$(uname -m) && \
    if [ "${arch}" = "x86_64" ]; then \
        # Should be simpler, see <https://github.com/mamba-org/mamba/issues/1437>
        arch="64"; \
    fi && \
    wget --progress=dot:giga -O /tmp/micromamba.tar.bz2 \
        "https://micromamba.snakepit.net/api/micromamba/linux-${arch}/latest" && \
    tar -xvjf /tmp/micromamba.tar.bz2 --strip-components=1 bin/micromamba && \
    rm /tmp/micromamba.tar.bz2 && \
    PYTHON_SPECIFIER="python=${PYTHON_VERSION}" && \
    if [[ "${PYTHON_VERSION}" == "default" ]]; then PYTHON_SPECIFIER="python"; fi && \
    # Install the packages
    ./micromamba install \
        --root-prefix="${CONDA_DIR}" \
        --prefix="${CONDA_DIR}" \
        --yes \
        "${PYTHON_SPECIFIER}" \
        'mamba' \
        'jupyter_core' && \
    rm micromamba && \
    # Pin major.minor version of python
    mamba list python | grep '^python ' | tr -s ' ' | cut -d ' ' -f 1,2 >> "${CONDA_DIR}/conda-meta/pinned" && \
    # mamba clean --all -f -y && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

# ------------------------------------
# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

USER root

# Install all OS dependencies for notebook server that starts but lacks all
# features (e.g., download as all possible file formats)
RUN \
    apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    fonts-liberation \
    # - pandoc is used to convert notebooks to html files
    #   it's not present in aarch64 ubuntu image, so we install it here
    pandoc \
    # - run-one - a wrapper script that runs no more
    #   than one unique  instance  of  some  command with a unique set of arguments,
    #   we use `run-one-constantly` to support `RESTARTABLE` option
    run-one 
    # && \
    # apt-get clean && rm -rf /var/lib/apt/lists/*

# Install all OS dependencies for fully functional notebook server
RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    # Common useful utilities
    git \
    nano-tiny \
    tzdata \
    unzip \
    vim-tiny \
    # git-over-ssh
    openssh-client \
    # nbconvert dependencies
    # https://nbconvert.readthedocs.io/en/latest/install.html#installing-tex
    texlive-xetex \
    texlive-fonts-recommended \
    texlive-plain-generic \
    # Enable clipboard on Linux host systems
    xclip
    # apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Jupyter Notebook, Lab, and Hub
# Generate a notebook server config
# Cleanup temporary files
# Correct permissions
# Do all this in a single RUN command to avoid duplicating all of the
# files across image layers when the permissions change
WORKDIR /tmp
RUN mamba install --yes \
    'notebook<7.0.0' \
    'jupyterhub==4.0.*' \
    'jupyterlab==4.0.*' \
    'nbclassic==1.0.0' \
    && \
    jupyter notebook --generate-config && \
    # mamba clean --all -f -y && \
    # npm cache clean --force && \
    # jupyter lab clean && \
    rm -rf "/home/${NB_USER}/.cache/yarn" && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

ENV JUPYTER_PORT=8888
EXPOSE $JUPYTER_PORT

ENV TZ=Hongkong
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# fix https://github.com/jupyter/docker-stacks/issues/815
RUN cat /etc/skel/.bashrc >> /etc/bash.bashrc

USER ${NB_UID}

RUN mamba install --quiet --yes \
    'code-server=4.15.*' \
    'websockify=0.11.*' \
    'jupyter-vscode-proxy=0.2' \
    'jupyterlab-git=0.41.*' \
    'jupytext=1.14.*' \
    'nbgitpuller=1.1.*' \
    'black=23.3.*' \
    'jupyterlab_code_formatter=2.2.*' \
    'python-lsp-server=1.7.*' \
    && \
    pip install --quiet --no-cache-dir \
    'jupyterlab_filesystem_access==0.5.*' \
    'jupyter-www-proxy' \
    && \
    mamba clean --all -f -y && \
    fix-permissions "${CONDA_DIR}"

# Code extensions
RUN for ext in \
        ms-python.python \
        ms-toolsai.jupyter \
        ms-toolsai.vscode-jupyter-powertoys \
        streetsidesoftware.code-spell-checker \
        sugatoray.vscode-git-extension-pack \
        Kelvin.vscode-sshfs \
        ; do \
        code-server --install-extension "$ext"; \
    done

USER root

# Programming languages backends
RUN \
    apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    # C, C++
    build-essential \
    unzip \
    # python
    # thonny \
    # python3-dev \
    gdb \
    fpc-source \
    # SQL
    sqlite3 \
    # itikz
    pdf2svg
    # && \
    # apt-get clean && rm -rf /var/lib/apt/lists/*

USER ${NB_USER}

# Programming languages frontends
RUN npm \
    # Javascript and Typescript
    install -g tslab && \
    tslab install --sys-prefix \
    && \
    mamba install --quiet --yes \
    'pandas=2.0.*' \
    'matplotlib-base=3.7.*' \
    'graphviz=8.1.*' \
    # 'xeus-python' \
    # C, C++
    'xeus-cling=0.15.*' \
    # LaTeX
    'tectonic=0.14.*' \
    'texlab=5.7.*' \
    'chktex=1.7.*' \
    # Java
    'openjdk=20.0.*' \
    && \
    npm install -g \
    bash-language-server \
    vscode-css-languageserver-bin \
    dockerfile-language-server-nodejs \
    vscode-html-languageserver-bin \
    javascript-typescript-langserver \
    vscode-json-languageserver-bin \
    yaml-language-server \
    && \
    pip install --quiet \
    # --no-cache-dir \
    'itikz==0.1.*' \
    && \
    # mamba clean --all -f -y && \
    fix-permissions "${CONDA_DIR}" && \
    # Java kernel
    wget 'https://github.com/SpencerPark/IJava/releases/download/v1.3.0/ijava-1.3.0.zip' \
    -O /tmp/ijava.zip && \
    unzip /tmp/ijava.zip -d /tmp/ijava && \
    python /tmp/ijava/install.py --sys-prefix && \
    rm -rf /tmp/ijava

RUN mamba install --quiet --yes \
    'manim=0.17.*' \
    'pandas=2.0.*' \
    'matplotlib-base=3.7.*' \
    'sympy=1.*' \
    && \
    pip install --quiet --no-cache-dir \
    'divewidgets' \
    'jupyterlab-myst==2.0.*' \
    && \
    # mamba clean --all -f -y && \
    fix-permissions "${CONDA_DIR}"

# Nbgrader
RUN pip install --quiet --no-cache-dir \
    # 'nbgrader>=v0.9.0a1' && \
    git+https://github.com/dive4dec/nbgrader.git && \
    fix-permissions "${CONDA_DIR}"

RUN pip install --quiet --no-cache-dir \
    'jupyterlab_theme_solarized_dark' \
    'jupyterlab-night' \
    'jupyterlab_theme_solarized_dark' \
    'theme-darcula' && \
    fix-permissions "${CONDA_DIR}"

RUN mkdir -p ${CONDA_DIR}/srv/exchange && chmod ugo+rw $_

RUN jupyter server extension disable --sys-prefix nbgrader.server_extensions.formgrader

COPY --chown=${NB_USER}:${NB_GID} nbgrader_config.py ${CONDA_DIR}/etc/jupyter/nbgrader_config.py

# ----------------------------------------------------------

### Tensorflow ###
# minor issues: 
# https://stackoverflow.com/questions/44232898/memoryerror-in-tensorflow-and-successful-numa-node-read-from-sysfs-had-negativ
# tested with:
# https://docs.vmware.com/en/VMware-vSphere-Bitfusion/4.0/Example-Guide/GUID-8F6BF9A8-DC1A-4ACD-A2FF-C9CD0B50A9DC.html
RUN pip install --quiet \
    # --no-cache-dir \
    'tensorflow==2.13.*' \
    'tensorflowjs==4.9.*' \
    'tensorflow-datasets==4.9.*' \
    'tensorflow-addons==0.21.*' \
    && \
    fix-permissions "${CONDA_DIR}"

# ----------------------------------------------------------
# Cleanup

USER root

RUN apt-get clean && rm -rf /var/lib/apt/lists/*

USER ${NB_UID}

RUN npm cache clean --force && \
    jupyter lab clean && \
    mamba clean --all -f -y && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

# ----------------------------------------------------------

FROM foundation as prod

COPY --from=base /etc/ /etc/
COPY --from=base /usr/ /usr/
COPY --from=base /var/ /var/
COPY --from=base /home/ /home/
COPY --from=base /opt/ /opt/

# Configure container startup
ENTRYPOINT ["tini", "-g", "--"]
# Configure container startup
CMD ["start-notebook.sh"]

# Copy local files as late as possible to avoid cache busting
COPY start.sh /usr/local/bin/
# Copy local files as late as possible to avoid cache busting
COPY start-notebook.sh start-singleuser.sh grader_setup /usr/local/bin/
# Currently need to have both jupyter_notebook_config and jupyter_server_config to support classic and lab
COPY jupyter_server_config.py docker_healthcheck.py /etc/jupyter/

ENV TF_CPP_MIN_LOG_LEVEL=2

# Switch back to jovyan to avoid accidental container runs as root
USER ${NB_UID}

WORKDIR "${HOME}"

FROM prod as gpu

# Install NVCC
# # See https://www.tensorflow.org/install/pip
# RUN mamba install --quiet --yes -c nvidia cuda-nvcc=12.2.91 && \
#     # Configure the XLA cuda directory
#     mkdir -p ${CONDA_DIR}/etc/conda/activate.d && \
#     # Link libdevice file to the required path
#     mkdir -p "${CONDA_DIR}/lib/" && \
#     ln -s ${CONDA_DIR}/nvvm/ ${CONDA_DIR}/lib/nvvm


# Install Tensorflow with pip
# hadolint ignore=DL3013
RUN pip install --no-cache-dir \
    'nvidia-cudnn-cu11==8.6.0.163' && \
    mamba install -c nvidia --yes \
    'cuda-nvcc=11.3.58' && \
    mamba install -c conda-forge --yes \
    'cudatoolkit=11.8.0' && \
    mamba clean --all -f -y && \
    # Link libdevice file to the required path
    mkdir -p "${CONDA_DIR}/lib/" && \
    ln -s ${CONDA_DIR}/nvvm/ ${CONDA_DIR}/lib/nvvm && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

ENV XLA_FLAGS=--xla_gpu_cuda_data_dir=${CONDA_DIR}/lib
ENV LD_LIBRARY_PATH="/opt/conda/lib/:${CONDA_DIR}/lib/python3.11/site-packages/nvidia/cudnn/lib/"

