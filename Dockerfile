FROM factoriotools/factorio

ARG FACTORIO_VERSION
ARG ARCHIVE_NAME
ARG USERNAME
ARG TOKEN
ARG MOD_NAME

ENV TIMEOUT=${TIMEOUT}
ENV UPDATE_MODS_ON_START=true
ENV MOD_NAME=${MOD_NAME}
ENV CONFIG=/factorio/config
ENV MODS=/factorio/mods
ENV USERNAME=${USERNAME}
ENV TOKEN=${TOKEN}
ENV ARCHIVE_NAME=${ARCHIVE_NAME}

COPY "$MOD_NAME"/config/* /

RUN ls /

RUN mkdir -p "$CONFIG"
RUN mkdir -p "$MODS"
RUN envsubst < /server-settings.json > "$CONFIG"/server-settings.json

COPY "artifacts/${MOD_NAME}/${ARCHIVE_NAME}" /
COPY artifacts/"$MOD_NAME"/scenario_names.txt /scenario_names.txt
COPY artifacts/"$MOD_NAME"/scenarios /factorio/scenarios
COPY entrypoint.sh /

RUN chmod +x /entrypoint.sh
RUN chown -R "$USER":"$GROUP" /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
