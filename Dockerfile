# syntax=docker/dockerfile:1

#------------------------------------------------------------------------------
### Base
#------------------------------------------------------------------------------

# Create a new build stage from a base image.
FROM ubuntu:22.04 AS base

# Execute build command: Updates the system
RUN apt update

# Version
ENV VERSION="1.20.4"

# Custom metadata
LABEL com.chris82111.minecraft.game.version=${VERSION}

# Create volume mounts.
# Example: `--mount type=bind,source="$(pwd)"/minecraft,target=/minecraft`
VOLUME ["/minecraft"]

# Working directory used later
WORKDIR /minecraft

# Ports application is listening on.
EXPOSE 25565

# Specify the system call signal for exiting a container.
STOPSIGNAL SIGTERM

# docker build ----------------------------------------------------------------

# Example: `--build-arg="JAVA_PARAMETER= -Xmx1024M -Xms1024M "`
ARG JAVA_PARAMETER="-Xmx1024M -Xms1024M"

# Example: `--build-arg="START_SPIGOT=false"`
ARG START_SPIGOT=false

# docker container create -----------------------------------------------------

# If not set to `true` you need to edit the `eula.txt` file
# Example: `--env ACCEPT_EULA=true`
ENV ACCEPT_EULA="false"

# variables -------------------------------------------------------------------

ENV MINECRAFT_APPS_VERSION="/minecraft/apps/${VERSION}/"

ENV MINECRAFT_VANILLA="minecraft_server.${VERSION}.jar"
ENV MINECRAFT_SPIGOT="spigot-${VERSION}.jar"

ENV MOD_GROUP_MANAGER="GroupManager.3.2.jar"
ENV MOD_MULTIVERSE_CORE="MultiverseCore.4.3.12.jar"

# Stores additional configurations
ENV STARTUP_NAME="startup.json"

ENV colorBYellow='\033[1;33m'
ENV colorBGreen='\033[1;32m'
ENV colorBPurple='\033[1;35m'
ENV colorNormal='\033[0m'

ENV noteInfo="[ ${colorBYellow}inf${colorNormal} ]"
ENV noteNothing="[ ${colorBPurple}nul${colorNormal} ]"
ENV noteEntry="[ ${colorBGreen}ent${colorNormal} ]"

# functions -------------------------------------------------------------------

# @brief    If the mount bind folder is empty the local data is copied
#           Example: `eval $evalInitialCopy`
# @return   string, log message
ENV evalInitialCopy='/bin/sh -c "\
  if [ -z \"$(ls -A /minecraft)\" ] ; \
  then \
    echo \"${noteInfo} The internal data was copied to the outside\" ; \
    cp -r /app/* /minecraft ; \
  else\
    echo \"${noteNothing} Data is available on the outside, nothing has been copied\" ; \
  fi " '
  
# @brief    Copies files to the mount bind folder, but does not overwrite existing files
#           Example: `eval $evalCopyVersions`
# @return   string, log message
ENV evalCopyVersions='/bin/sh -c "\
  mkdir -p ${MINECRAFT_APPS_VERSION} ; \
  cp -n /app/plugins/${MOD_GROUP_MANAGER} ${MINECRAFT_APPS_VERSION}/${MOD_GROUP_MANAGER} ; \
  cp -n /app/plugins/${MOD_MULTIVERSE_CORE} ${MINECRAFT_APPS_VERSION}/${MOD_MULTIVERSE_CORE} ; \
  cp -n /app/\"${MINECRAFT_VANILLA}\" ${MINECRAFT_APPS_VERSION}/\"${MINECRAFT_VANILLA}\" ; \
  cp -n /app/\"${MINECRAFT_SPIGOT}\" ${MINECRAFT_APPS_VERSION}/\"${MINECRAFT_SPIGOT}\" ; \
  echo \"The data has been copied here ${MINECRAFT_APPS_VERSION}\" ; \
  " '

# @brief    The value of the `eula` key in the `eula.txt` file in the current folder is set to `true`
#           Example: `eval $evalSetEulaTrue`
# @return   Nothing
ENV evalSetEulaTrue="sed -i -e 's/eula=false/eula=true/g' eula.txt"

# @brief    The value of the `eula` key in the `eula.txt` file in the current folder is set to `true`
#           Example: `eval $evalSetEula`
# @param    ACCEPT_EULA is checked and if true the command @see evalSetEulaTrue is executed
# @return   string, log message
ENV evalSetEula='/bin/sh -c "\
  if [ \"${ACCEPT_EULA}\" = \"true\" ] ; \
  then \
    eval ${evalSetEulaTrue} ; \
    echo \"${noteInfo} The eula file was automatically set to true\" ; \
  else \
    echo \"${noteNothing} The eula file has not been touched\" ; \
  fi " '

# @brief    Reads the value of an entry in the file `startup.json`
#           Example: `echo $($fncIfFalseThenVanillaElseSpigot)`
# @return   bool, value of the variable
ENV fncIfFalseThenVanillaElseSpigot="jq .start.ifFalseThenVanillaElseSpigot ./${STARTUP_NAME}"

# @brief    Reads the java parameters
#           Example: `echo $($fncJavaParam)`
# @return   string, value of the variable
ENV fncJavaParam="jq --raw-output .java.param ./${STARTUP_NAME}"

# @brief    Checks if Vanilla should be used
#           Example: `eval $evalIsVanilla`
# @return   bool, true if Vanilla should be used
ENV evalIsVanilla='/bin/sh -c "\
  if [ \"$($fncIfFalseThenVanillaElseSpigot)\" = \"false\" ] ; \
  then \
    echo \"true\" ; \
  else \
    echo \"false\" ; \
  fi " '

# @brief    Checks if Spigot should be used
#           Example: `eval $evalIsSpigot`
# @return   bool, true if Spigot should be used
ENV evalIsSpigot='/bin/sh -c "\
  if [ \"$($fncIfFalseThenVanillaElseSpigot)\" = \"true\" ] ; \
  then \
    echo \"true\" ; \
  else \
    echo \"false\" ; \
  fi " '

# @brief    Returns the application that is to be started
#           Example: `eval $evalGetMinecraftApp`
# @return   string, returns the value stored in `MINECRAFT_VANILLA` or `MINECRAFT_SPIGOT`
ENV evalGetMinecraftApp='/bin/sh -c "\
  if [ \"$(eval ${evalIsVanilla})\" = \"true\" ] ; \
  then \
    echo ${MINECRAFT_VANILLA} ; \
  else \
    if [ \"$(eval ${evalIsSpigot})\" = \"true\" ] ; \
    then \
      echo ${MINECRAFT_SPIGOT} ; \
    else \
      echo "" ; \
      exit 3 ; \
    fi ; \
  fi " '

# opt. Software ---------------------------------------------------------------

WORKDIR /build/

# Add local or remote files and directories: Downloads java and checks file
# TODO-Production
#ADD \
#  --checksum=sha256:a2def047a73941e01a73739f92755f86b895811afb1f91243db214cff5bdac3f \
#  https://download.java.net/java/GA/jdk21.0.2/f2283984656d49d69e91c558476027ac/13/GPL/openjdk-21.0.2_linux-x64_bin.tar.gz \
#  openjdk-21.0.2.tar.gz

# TODO-Production
# Extracts the archive
#RUN tar -xvf openjdk-21.0.2.tar.gz -C /opt/

WORKDIR /opt/

RUN rm -dr /build/

# TODO-Debug: 
ADD openjdk-21.0.2.tar.gz .

# Execute build command: Checks if java is available
RUN FILE="/opt/jdk-21.0.2/bin/java"; if [ -f "$FILE" ] ; then :; else exit 1 ; fi

# Set environment variable: Makes `java` known as a program
ENV PATH=/opt/jdk-21.0.2/bin:$PATH


#------------------------------------------------------------------------------
### Spigotmc
#------------------------------------------------------------------------------

# Create a new build stage from a base image.
FROM base AS SPIGOT

RUN \
  apt install -y git && \
  apt install -y wget

# build spigot ----------------------------------------------------------------

# Change working directory.
WORKDIR /BuildTools

# Download BuildTools
# TODO-Production
#ADD \
#  --checksum=sha256:42678cf1a115e6a75711f4e925b3c2af3a814171af37c7fde9e9b611ded90637 \
#  https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar \
#  BuildTools.jar

# TODO-Debug: 
ADD BuildTools.jar /BuildTools/

# Execute build command: Build spigotmc
#RUN java -jar BuildTools.jar --rev latest

# TODO-Debug: 
ADD "${MINECRAFT_SPIGOT}" /BuildTools/

# mods download ---------------------------------------------------------------

WORKDIR /Downloads

# GroupManager
# source https://github.com/ElgarL/GroupManager/releases
# TODO-Production
#ADD \
#  --checksum=sha256:7c9fa7e2ea5b3ff2b114be876b2521976408e78ec1587ee56f4aae65521f30ef \
#  https://github.com/ElgarL/GroupManager/releases/download/v3.2/GroupManager.jar \
#  ${MOD_GROUP_MANAGER}

# TODO-Debug: 
ADD ${MOD_GROUP_MANAGER} .

# multiverse-core
# source https://dev.bukkit.org/projects/multiverse-core/files
# TODO-Production
#RUN \
#  wget https://dev.bukkit.org/projects/multiverse-core/files/4744018/download \
#  -O ${MOD_MULTIVERSE_CORE} && \
#  echo "98237AAF35C6EE7BFD95FB7F399EF703B3E72BFF8EAB488A904AAD9D4530CD10 ${MOD_MULTIVERSE_CORE}" | \
#  sha256sum --check || exit 4

# TODO-Debug: 
ADD ${MOD_MULTIVERSE_CORE} .

#------------------------------------------------------------------------------
### Minecraft
#------------------------------------------------------------------------------

FROM base AS NORMAL

RUN \
  apt install -y jq
  
WORKDIR /app

# create startup --------------------------------------------------------------

COPY <<EOF startup.json
{
  "start": {
    "ifFalseThenVanillaElseSpigot": ${START_SPIGOT}
  },
  "java": {
    "param": "${JAVA_PARAMETER}"
  }
}
EOF

# create startup --------------------------------------------------------------

# Add local or remote files and directories: Downloads Minecraft
# TODO-Production
#ADD \
#  --checksum=sha256:c03fa6f39daa69ddf413c965a3a83084db746a7a138ce535a693293b5472d363 \
#  https://piston-data.mojang.com/v1/objects/8dd1a28015f51b1803213892b50b7b4fc76e594d/server.jar \
#  "${MINECRAFT_VANILLA}"

# TODO-Debug: 
ADD "${MINECRAFT_VANILLA}" .

# Execute build command: Checks if Minecraft is available
RUN FILE=/app/"${MINECRAFT_VANILLA}" ; if [ -f "${FILE}" ] ; then :; else exit 1 ; fi

RUN java ${JAVA_PARAMETER} -jar "${MINECRAFT_VANILLA}" nogui || exit 3 ;

COPY --from=SPIGOT /BuildTools/"${MINECRAFT_SPIGOT}" /app/

COPY --from=SPIGOT /Downloads/GroupManager.3.2.jar /app/plugins/

COPY --from=SPIGOT /Downloads/MultiverseCore.4.3.12.jar /app/plugins/

WORKDIR /app
RUN java ${JAVA_PARAMETER} -jar "${MINECRAFT_SPIGOT}" nogui || exit 3 ;

WORKDIR /minecraft
ENTRYPOINT ["/bin/sh", "-c" , "\
  echo \"${noteEntry} $(eval ${evalInitialCopy})\" && \
  echo \"${noteEntry} $(eval ${evalCopyVersions})\" && \
  echo \"${noteEntry} $(eval ${evalSetEula})\" && \
  echo \"${noteEntry} java param: $(${fncJavaParam})\" && \
  echo \"${noteEntry} java app  : $(eval ${evalGetMinecraftApp})\" && \
  java $(${fncJavaParam}) -jar $(eval ${evalGetMinecraftApp}) nogui && \
  echo \"The program has been executed\" "]

#------------------------------------------------------------------------------
### EOF
#------------------------------------------------------------------------------
