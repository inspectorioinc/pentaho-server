ARG IMAGE_BASE="inspectorio/docker-java"
ARG IMAGE_TAG="8"


FROM "${IMAGE_BASE}:${IMAGE_TAG}"
MAINTAINER devops@inspectorio.com

ENV PENTAHO_HOME="/pentaho" \
    DEBIAN_FRONTEND=noninteractive \
    PENTAHO_CE_VERSION=8.1.0.0-365 \
    PENTAHO_USER=pentaho \
    BISERVER_VERSION=8.1

LABEL server="Pentaho BA Server $PENTAHO_CE_VERSION CE"

COPY . "${PENTAHO_HOME}"

RUN echo "Download and unpack Pentaho server..." \
    && wget --progress=dot:giga "https://sourceforge.net/projects/pentaho/files/Pentaho%20${BISERVER_VERSION}/server/pentaho-server-ce-${PENTAHO_CE_VERSION}.zip/download" -O "${PENTAHO_HOME}"/pentaho-server-ce-"${PENTAHO_CE_VERSION}".zip \
    && cd "${PENTAHO_HOME}" \
    && unzip -q "pentaho-server-ce-${PENTAHO_CE_VERSION}".zip \
    && rm -f pentaho-server-ce-"${PENTAHO_CE_VERSION}".zip \
    && ln -s "${PENTAHO_HOME}"/pentaho-server /pentaho-server \
    && apt-get update && apt-get -y install vim \
    && echo "Add Pentaho user..." \
    && useradd -md "${PENTAHO_HOME}" -s /bin/bash "${PENTAHO_USER}" \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && sed -i 's| start | run |' "${PENTAHO_HOME}/pentaho-server/tomcat/bin/startup.sh" \
    && rm -f "${PENTAHO_HOME}/pentaho-server/promptuser.sh" \
    && chmod a+x "${PENTAHO_HOME}/entrypoint.sh"

WORKDIR "${PENTAHO_HOME}"
     

EXPOSE 8080
ENTRYPOINT ["./entrypoint.sh"]