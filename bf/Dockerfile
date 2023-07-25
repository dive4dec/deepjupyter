ARG BASE_CONTAINER=scipy-nv

FROM ${BASE_CONTAINER}

USER root

## Bitfusion ###
RUN wget 'https://packages.vmware.com/bitfusion/ubuntu/20.04/bitfusion-client-ubuntu2004_3.5.0-5_amd64.deb' \
    -O /tmp/bitfusion-client.deb && \
    apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
    apt-utils \
    /tmp/bitfusion-client.deb \
    && \
    rm /tmp/bitfusion-client.deb && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    usermod -aG bitfusion "${NB_USER}" && \
    chmod -R o+rX /etc/bitfusion

USER ${NB_USER}

COPY --chown=${NB_UID}:${NB_GID} bin/ /usr/local/bin/

RUN bitfusion list_gpus && chmod a+x /usr/local/bin/bf*start*.sh

# COPY --chown=${NB_USER}:${NB_GID} nbgrader_config /etc/jupyter/nbgrader_config.py
# RUN cp -rf /tmp/nb/nbgrader_config /etc/jupyter/nbgrader_config.py
    #  && \
    # cp -rf /tmp/nb/assignment_list.js "$(pip show nbgrader | grep Location | awk '{print $2}')/nbgrader/nbextensions/assignment_list/assignment_list.js" && \
    # cp -rf /tmp/nb/fetch_feedback.py "$(pip show ngshare_exchange | grep Location | awk '{print $2}')/ngshare_exchange/fetch_feedback.py" && \
    # cp -rf /tmp/nb/validator.py "$(pip show nbgrader | grep Location | awk '{print $2}')/nbgrader/validator.py" && \
    # cp -rf /tmp/nb/list.py "$(pip show nbgrader | grep Location | awk '{print $2}')/nbgrader/list.py" && \
    # rm -rf /tmp/nb