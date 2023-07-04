FROM jupyterhub/k8s-hub:2.0.0

USER root

# For LDAP & RADIUS
RUN apt-get update && \
    apt-get upgrade --yes && \
    apt-get install --yes --no-install-recommends \
    libnss-ldap \
    libpam-ldap \
    libpam-radius-auth \
    ldap-utils \
    sudo \
    && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
RUN echo "${NB_USER}  ALL=(ALL) NOPASSWD: $(which mkhomedir_helper)" >> /etc/sudoers.d/nbuser_mkhomedir

# RUN python3 -m pip install --upgrade cdsdashboards>=0.6.2

COPY etc/libnss-ldap.conf /etc/libnss-ldap.conf
COPY etc/nsswitch.conf /etc/nsswitch.conf
COPY etc/pam_radius_auth.conf /etc/pam_radius_auth.conf
COPY etc/pam.d /etc/pam.d

COPY login.html /usr/local/share/jupyterhub/templates/login.html

# RUN /usr/bin/python3 -m pip install --quiet --upgrade pip && \
#     pip install --quiet --no-cache-dir \
#     "cdsdashboards==0.6.*" \
#     "notebook==6.4.*" \
#     'traitlets==5.1.*' \
#     "nbgrader==0.7.*" && \
#     jupyter nbextension install --system --py --overwrite nbgrader && \
#     jupyter nbextension enable --system --py nbgrader && \
#     jupyter serverextension enable --system --py nbgrader && \
#     jupyter nbextension disable --system assignment_list/main --section=tree && \
#     jupyter serverextension disable --system nbgrader.server_extensions.assignment_list && \
#     jupyter nbextension disable --system course_list/main --section=tree && \
#     jupyter serverextension disable --system nbgrader.server_extensions.course_list

# RUN pip install --quiet --no-deps --no-cache-dir \
#     "ngshare_exchange" \
#     "fuzzywuzzy==0.18.*" 

# COPY --chown=root:staff collect.py /usr/local/lib/python3.8/site-packages/ngshare_exchange/collect.py
# COPY --chown=root:staff exchange.py /usr/local/lib/python3.8/site-packages/ngshare_exchange/exchange.py

USER jovyan

# COPY --chown=jovyan:jovyan etc/nbgrader_config.py /home/jovyan/.jupyter/nbgrader_config.py
