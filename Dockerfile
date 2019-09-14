FROM openjdk:8-jdk-slim

ENV APP_NAME Vanilla Minecraft
ARG APP_VERSION
ENV APP_VERSION ${APP_VERSION}
ENV JAR_FILE minecraft_server.${APP_VERSION}.jar
ENV INSTALL_DIR /opt/mc
ENV APP_DIR ${INSTALL_DIR}/jar
ENV SERVER_DIR ${INSTALL_DIR}/server
ENV JAVA_MAXHEAP 1024M
ENV JAVA_MINHEAP 1024M
ENV JAVA_PARAM_SUFFIX nogui
ENV JAVA_PARAM_PREFIX -XX:+UseConcMarkSweepGC
ARG RCONPWD
ENV RCONPWD ${RCONPWD}
ENV GRACEFUL_STOP_TIMEOUT 30
ENV PATH ${INSTALL_DIR}/bin:$PATH
# Copy latest.log to standard out only necessary for vanilla mc jar.
ARG ECHO_LOG2STDOUT=NO
ENV ECHO_LOG2STDOUT ${ECHO_LOG2STDOUT}

RUN apt-get update
RUN apt-get -y install musl > /dev/null
RUN apt-get -y install procps > /dev/null

ADD rootfs /

RUN echo -e ' ************************************************** \n' \
  "Docker Image to run app ${APP_NAME} ${APP_VERSION}. \n" \
  '\n' \
  'Usage: \n' \
  "   Start service: docker run -v <host-world-dir>:${SERVER_DIR}/world \\ \n" \
  "                             -d <image_name> ${INSTALL_DIR}/bin/run_java_app.sh \n" \
  "   Stop service:  docker exec ${INSTALL_DIR}/bin/stop_java_app.sh \n" \
  "   Send command:  docker exec ${INSTALL_DIR}/bin/app_cmd.sh  \\ \n" \
  "                              '<cmd1> <param1-1> <param1-2> ..' \\ \n" \
  "                              '<cmd2> <param2-1> <param2-2> ..'   \n" \
  "                  Every app command and its parameters must be single or double quoted. \n" \
  "   Default rcon password is ${RCONPWD}.  \n" \
'**************************************************' > /image_info.txt

VOLUME ["${SERVER_DIR}", "${SERVER_DIR}/logs"]

EXPOSE 25565 25575

CMD ["/bin/cat", "/image_info.txt"]
