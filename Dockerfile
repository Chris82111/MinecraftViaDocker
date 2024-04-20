# syntax=docker/dockerfile:1

#------------------------------------------------------------------------------
### global variables
#------------------------------------------------------------------------------

ARG globalOpenJdkOptDirectoryName="jdk-21.0.2"


#------------------------------------------------------------------------------
### openjdk_stage
#------------------------------------------------------------------------------

# Copy and use the data with these commands:
#   `ARG globalOpenJdkOptDirectoryName`
#   `COPY --from=openjdk_stage /opt/${globalOpenJdkOptDirectoryName} /opt/${globalOpenJdkOptDirectoryName}`
#   `ENV PATH=/opt/${globalOpenJdkOptDirectoryName}/bin:$PATH`
FROM alpine AS openjdk_stage

ARG globalOpenJdkOptDirectoryName

ENV openJdkArchive="openjdk-21.0.2.tar.gz"

WORKDIR /build/

# TODO-Production
# Downloads java and checks file
#ADD --checksum=sha256:a2def047a73941e01a73739f92755f86b895811afb1f91243db214cff5bdac3f \
#  https://download.java.net/java/GA/jdk21.0.2/f2283984656d49d69e91c558476027ac/13/GPL/openjdk-21.0.2_linux-x64_bin.tar.gz \
#  ${openJdkArchive}

# TODO-Debug: 
COPY ${openJdkArchive} .

# Extracts the archive
RUN tar -xvf ${openJdkArchive} -C /opt/

# Checks if java is available
RUN FILE="/opt/${globalOpenJdkOptDirectoryName}/bin/java"; if [ -f "$FILE" ] ; then :; else exit 1 ; fi


#------------------------------------------------------------------------------
### base_stage
#------------------------------------------------------------------------------

# Create a new build stage from a base image.
FROM ubuntu:22.04 AS base_stage

# Updates the system
RUN apt update

ARG globalOpenJdkOptDirectoryName

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

# Copies extracted openjdk
COPY --from=openjdk_stage /opt/${globalOpenJdkOptDirectoryName} /opt/${globalOpenJdkOptDirectoryName}

# Makes `java` known as a program
ENV PATH=/opt/${globalOpenJdkOptDirectoryName}/bin:$PATH


#------------------------------------------------------------------------------
### spigotmc_stage
#------------------------------------------------------------------------------

# Copy the data with these commands:
# `COPY --from=spigotmc_stage /BuildTools/"${MINECRAFT_SPIGOT}" /app/`
# `COPY --from=spigotmc_stage /Downloads/"${MOD_GROUP_MANAGER}" /app/plugins/`
# `COPY --from=spigotmc_stage /Downloads/"${MOD_MULTIVERSE_CORE}" /app/plugins/`
FROM base_stage AS spigotmc_stage

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

# Build spigotmc
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
### minecraft_stage
#------------------------------------------------------------------------------

# base_stage needs the have an `ENV` defined with the name `VERSION` and the number like `1.20.4`
# base_stage needs the have an `ENV` defined with the name `MINECRAFT_VANILLA` and the filename as content
# Copy the content with this command:
# `COPY --from=minecraft_stage /Downloads/${MINECRAFT_VANILLA} /app/`

FROM base_stage AS minecraft_stage

RUN \
  apt install -y jq && \
  apt install -y wget
  
WORKDIR /Downloads

ENV minecraftManifest="version_manifest_v2.json"
ENV minecraftMetaFile="version_meta.json"

ADD https://launchermeta.mojang.com/mc/game/version_manifest_v2.json "${minecraftManifest}"

ENV fncMinecraftLatestVersion="jq --raw-output .latest.release ${minecraftManifest}"

RUN if [ "$(${fncMinecraftLatestVersion})"="${VERSION}" ] ; then echo "yes" ; else exit 10; fi

ENV evalMinecraftMetaUrl="jq -r \" .versions[] | select(.id==\\\"${VERSION}\\\") | .url \" ${minecraftManifest}"

ENV evalMinecraftMetaSha1="jq -r \" .versions[] | select(.id==\\\"${VERSION}\\\") | .sha1 \" ${minecraftManifest}"

ENV fncMinecraftVersionSha1="jq --raw-output .downloads.server.sha1 ${minecraftMetaFile}"

ENV fncMinecraftVersionUrl="jq --raw-output .downloads.server.url ${minecraftMetaFile}"

RUN if [  "$(eval ${evalMinecraftMetaSha1})" = "" ]; then exit 11 ; else echo "Version exists" ; fi

RUN wget $(eval ${evalMinecraftMetaUrl}) -O "${minecraftMetaFile}"
RUN echo "$(eval ${evalMinecraftMetaSha1}) ${minecraftMetaFile}" | sha1sum --check || exit 5

# TODO-Production
#RUN wget $(eval ${fncMinecraftVersionUrl}) -O "${MINECRAFT_VANILLA}"
#RUN echo "$(eval ${fncMinecraftVersionSha1}) ${MINECRAFT_VANILLA}" | sha1sum --check || exit 6

# TODO-Debug: 
ADD "${MINECRAFT_VANILLA}" .


#------------------------------------------------------------------------------
### imageStage
#------------------------------------------------------------------------------

FROM base_stage AS image_stage

RUN \
  apt install -y jq
  
WORKDIR /app

# create startup --------------------------------------------------------------

# Creates a start configuration file whose data can be changed.
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

COPY --from=minecraft_stage /Downloads/${MINECRAFT_VANILLA} /app/

# Checks if Minecraft is available
RUN FILE="${MINECRAFT_VANILLA}" ; if [ -f "${FILE}" ] ; then :; else exit 1 ; fi

# Starts Minecraft for the first time without agreeing to the EULA
RUN java ${JAVA_PARAMETER} -jar "${MINECRAFT_VANILLA}" nogui || exit 3 ;

# Copy Spigot and mods
COPY --from=spigotmc_stage /BuildTools/"${MINECRAFT_SPIGOT}" /app/
COPY --from=spigotmc_stage /Downloads/"${MOD_GROUP_MANAGER}" /app/plugins/
COPY --from=spigotmc_stage /Downloads/"${MOD_MULTIVERSE_CORE}" /app/plugins/

# Starts Spiegot for the first time without agreeing to the EULA
RUN java ${JAVA_PARAMETER} -jar "${MINECRAFT_SPIGOT}" nogui || exit 3 ;


# Setup the entrypoint
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
