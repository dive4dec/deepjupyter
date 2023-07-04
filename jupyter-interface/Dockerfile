ARG BASE_CONTAINER=jupyter/scipy-notebook

FROM ${BASE_CONTAINER}

USER root

### code-server ###
RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    curl \
    && \
    wget -q https://code-server.dev/install.sh -O /tmp/install.sh && \
    sh /tmp/install.sh --version 4.14.1 && \
    code-server --extensions-dir /usr/lib/code-server/lib/vscode/extensions --install-extension ms-python.python && \
    fix-permissions "${HOME}" && \
    rm -rf ~/.cache/code-server/ && \
    rm -rf /tmp/install.sh && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

ENV TZ=Hongkong
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# fix https://github.com/jupyter/docker-stacks/issues/815
RUN cat /etc/skel/.bashrc >> /etc/bash.bashrc

USER ${NB_UID}

RUN mamba install --quiet --yes \
    'websockify=0.11.*' \
    'jupyter-vscode-proxy=0.2' \
    'jupyterlab-git=0.41.*' \
    'jupytext=1.14.*' \
    'nbgitpuller=1.1.*' \
    'black=23.3.*' \
    'jupyterlab_code_formatter=2.2.*' \
    # 'python-lsp-server=1.7.*' \
    # 'jedi-language-server=0.34.*' \
    && \
    pip install --quiet --no-cache-dir \
    # 'jupyter_collaboration==1.0.*' \
    'jupyterlab_filesystem_access==0.5.*' \
    'jupyter-www-proxy' \
    && \
    mamba clean --all -f -y && \
    fix-permissions "${CONDA_DIR}"

# RUN mamba install --quiet --yes \
#     'websockify=0.11.*' \
#     'jupyter-vscode-proxy=0.2' \
#     'jupyterlab-git=0.41.*' \
#     'jupytext=1.14.*' \
#     'nbgitpuller=1.1.*' \
#     # 'python-lsp-server=1.7.*' \
#     'jedi-language-server=0.34.*' \
#     'jupyterlab_code_formatter=2.2.*' \
#     && \
#     pip install --quiet --no-cache-dir \
#     'jupyter_collaboration==1.0.*' \
#     'jupyter-desktop-server==0.1.*' \
#     'jupyterlab_filesystem_access==0.5.*' \
#     'jupyter-www-proxy' \
#     && \
#     mamba clean --all -f -y && \
#     fix-permissions "${CONDA_DIR}"

# RUN mamba install --quiet --yes \
#     'websockify=0.10.*' \
#     'jupyter-vscode-proxy=0.1.*' \
#     'ipydrawio=1.2.*' \
#     'ipydrawio-export=1.2.*' \
#     'ipydrawio-mathjax=1.2.*' \
#     'jupyter-offlinenotebook=0.2.*' \
#     'jupyterlab-system-monitor=0.8.*' \
#     'jupyterlab-spellchecker=0.7.*' \
#     'jupytext=1.13.*' \
#     'jupyterlab-git=0.37.*' \
#     'nbgitpuller=1.1.*' \
#     'retrolab=0.3.*' \
#     && \
#     pip install --quiet --no-cache-dir \
#     'jupyter-desktop-server==0.1.*' \
#     'jupyterlab_sublime==0.4.*' \
#     'jupyterlab_filesystem_access==0.5.*' \
#     # 'jupyterlab-citation-manager==0.3.*' \
#     'jupyter-www-proxy' \
#     && \
#     mamba clean --all -f -y && \
#     fix-permissions "${CONDA_DIR}"


# # # Jupyter-book
# # RUN mamba install --quiet --yes \
# #     'jupyter-book=0.12.*' \
# #     'myst-nb==0.13.*' \
# #     && \
# #     pip install --quiet --no-cache-dir \
# #     'sphinx-proof==0.1.*' \
# #     && \
# #     mamba clean --all -f -y && \
# #     fix-permissions "${CONDA_DIR}"

COPY --chown=${NB_USER}:${NB_GID} jupyter-interface/condarc "${CONDA_DIR}/.condarc"

WORKDIR "${HOME}"

CMD ["start-notebook.sh"]