# SPDX-License-Identifier: LGPL-3.0-or-later WITH FUnit-CI-Exception
#
# Special exception to LGPL-3.0: Project-specific tweaks and adaptations
# to CI configuration files (changes made to make the file work for a
# different project) may be used, copied, modified, and distributed
# without triggering LGPL copyleft on the downstream project. This does
# not apply to general improvements that would benefit the original project.

FROM factoriotools/factorio

ARG FACTORIO_VERSION
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

COPY "$MOD_NAME"/test/* /

RUN mkdir -p "$CONFIG"
RUN mkdir -p "$MODS"
RUN envsubst < /server-settings.json > "$CONFIG"/server-settings.json
RUN envsubst < /player-data.json > /opt/factorio/player-data.json

COPY artifacts/*/*.zip /
COPY artifacts/"$MOD_NAME"/save_names.txt /save_names.txt
COPY artifacts/"$MOD_NAME"/scenario_names.txt /scenario_names.txt
COPY artifacts/"$MOD_NAME"/scenarios /factorio/scenarios
COPY entrypoint.sh /

RUN chmod +x /entrypoint.sh
RUN chown -R "$USER":"$GROUP" /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
