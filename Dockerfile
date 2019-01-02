FROM openjdk:11-jre-alpine

ENV APP_NAME Vanilla Minecraft
ENV APP_VERSION 1.12.2
ENV JAR_FILE minecraft_server.${APP_VERSION}.jar
ENV INSTALL_DIR /opt/mc
ENV APP_DIR ${INSTALL_DIR}/server
ENV JAVA_MAXHEAP 2048M
ENV JAVA_MINHEAP 512M
ENV JAVA_PARAM_SUFFIX nogui
ENV JAVA_PARAM_PREFIX -XX:+UseConcMarkSweepGC
ENV RCONPWD set_this
ENV GRACEFUL_STOP_TIMEOUT 30
ENV PATH ${INSTALL_DIR}/bin:$PATH

ADD rootfs /

RUN echo -e ' ************************************************** \n' \
  "Docker Image to run app ${APP_NAME} ${APP_VERSION}. \n" \
  '\n' \
  'Usage: \n' \
  "   Start service: docker run -v <host-world-dir>:${APP_DIR}/world \\ \n" \
  "                             -v <host-log-dir>:${APP_DIR}/logs \\ \n" \
  "                             -d <image_name> ${INSTALL_DIR}/bin/run_java_app.sh \n" \
  "   Stop service:  docker exec ${INSTALL_DIR}/bin/stop_java_app.sh \n" \
  "   Send command:  docker exec ${INSTALL_DIR}/bin/app_cmd.sh  \\ \n" \
  "                              '<cmd1> <param1-1> <param1-2> ..' \\ \n" \
  "                              '<cmd2> <param2-1> <param2-2> ..'   \n" \
  "                  Every app command and its parameters must be single or double quoted. \n" \
  "   Default rcon password is ${RCONPWD}.  \n" \
'**************************************************' > /image_info.txt

VOLUME ["${APP_DIR}/world", "${APP_DIR}/logs"]

EXPOSE 25565 25575

CMD ["/bin/cat", "/image_info.txt"]
