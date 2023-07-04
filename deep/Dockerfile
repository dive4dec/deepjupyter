ARG BASE_CONTAINER=minimal-notebook-nv

FROM ${BASE_CONTAINER}

USER ${NB_USER}

### Tensorflow ###
# minor issues: 
# https://stackoverflow.com/questions/44232898/memoryerror-in-tensorflow-and-successful-numa-node-read-from-sysfs-had-negativ
# tested with:
# https://docs.vmware.com/en/VMware-vSphere-Bitfusion/4.0/Example-Guide/GUID-8F6BF9A8-DC1A-4ACD-A2FF-C9CD0B50A9DC.html
RUN pip install --quiet --no-cache-dir \
    'tensorflowjs==4.4.*' \
    'tensorflow-datasets==4.7.*' \
    'tensorflow-addons==0.20.*' \
    && \
    fix-permissions "${CONDA_DIR}"


