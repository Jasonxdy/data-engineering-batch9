FROM apache/airflow:2.2.0-python3.7

ENV AIRFLOW__KUBERNETES__FS_GROUP=50000
ENV AIRFLOW__KUBERNETES__RUN_AS_USER=50000

ARG DEST_INSTALL=/home/airflow

USER root
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    && apt-get autoremove -yqq --purge \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

USER airflow

WORKDIR ${DEST_INSTALL}

ENV PATH=${PATH}:/home/airflow/.local/bin

ARG UPDATE_PIP_VERSION_TO="21.0.1"
RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
    python get-pip.py --user pip==${UPDATE_PIP_VERSION_TO} && \
    pip install pipenv

ENV PYTHONPATH="${AIRFLOW_HOME}:${PYTHONPATH}"

# Install custom plugins and custom libraries
COPY Pipfile* ${DEST_INSTALL}/
RUN pipenv install --system --ignore-pipfile --deploy

USER root

### update entrypoint: add "airflow initdb" command
### before running the webserver
COPY ./entrypoint_* /
RUN sed -i "s/exec airflow.*/###/g" /entrypoint && \
    cat /entrypoint_update_exec >> /entrypoint

ENV AIRFLOW__KUBERNETES__KUBE_CLIENT_REQUEST_ARGS=""

COPY ./dags/ ${AIRFLOW_HOME}/dags/

# Make sure Airflow is owned by airflow user
RUN chown -R "airflow" "${AIRFLOW_HOME}"

USER airflow
WORKDIR ${AIRFLOW_HOME}
