# syntax=docker/dockerfile:1

#Linux, you can use the windows command a well
#docker exec minecraftVanillaU /bin/sh -c 'echo "/say hello" >> stdin.pipe'

#Windows
#docker exec minecraftVanillaU /bin/sh -c "echo '/say hello' >> stdin.pipe"

#------------------------------------------------------------------------------
### global variables
#------------------------------------------------------------------------------

ARG globalOpenJdkOptDirectoryName="jdk-22.0.1"


#------------------------------------------------------------------------------
### openjdk_stage
#------------------------------------------------------------------------------

# Copy and use the data with these commands:
#   `ARG globalOpenJdkOptDirectoryName`
#   `COPY --from=openjdk_stage /opt/${globalOpenJdkOptDirectoryName} /opt/${globalOpenJdkOptDirectoryName}`
#   `ENV PATH=/opt/${globalOpenJdkOptDirectoryName}/bin:$PATH`
FROM alpine AS openjdk_stage

ARG globalOpenJdkOptDirectoryName

ENV openJdkArchive="openjdk-22.0.1.tar.gz"

WORKDIR /build/

# Downloads java and checks file
# Update: https://openjdk.org/
ADD --checksum=sha256:133c8b65113304904cdef7c9103274d141cfb64b191ff48ceb6528aca25c67b1 \
  https://download.java.net/java/GA/jdk22.0.1/c7ec1332f7bb44aeba2eb341ae18aca4/8/GPL/openjdk-22.0.1_linux-x64_bin.tar.gz \
  ${openJdkArchive}

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
ENV VERSION="1.20.5"

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
# Example: `--env EULA=true`
ENV EULA="false"

# variables -------------------------------------------------------------------

# Directory with all jar files
ENV minecraftAppsVersionDirectory="/minecraft/apps/${VERSION}/"

# Server application
ENV minecraftVanillaJar="minecraft_server.${VERSION}.jar"
ENV minecraftSpigotJar="spigot-${VERSION}.jar"

# Used mods
ENV modGroupManagerJar="GroupManager.3.2.jar"
ENV modMultiverseCoreJar="MultiverseCore.4.3.12.jar"

# Stores additional configurations
ENV dockerStartupFileName="startup.json"

# Colored output
ENV colorBYellow='\033[1;33m'
ENV colorBGreen='\033[1;32m'
ENV colorBPurple='\033[1;35m'
ENV colorNormal='\033[0m'

# Colored output note
ENV noteInfo="[ ${colorBYellow}MvD${colorNormal} ]"

# functions -------------------------------------------------------------------

# @brief    If the mount bind folder is empty the local data is copied
#           Example: `eval $evalInitialCopy`
# @return   string, log message
ENV evalInitialCopy='/bin/sh -c "\
  if [ -z \"$(ls -A /minecraft)\" ] ; \
  then \
    echo \"The internal data was copied to the outside\" ; \
    cp -r /app/* /minecraft ; \
  else\
    echo \"Data is available on the outside, nothing has been copied\" ; \
  fi " '

# @brief    Copies files to the mount bind folder, but does not overwrite existing files
#           Example: `eval $evalCopyVersions`
# @return   string, log message
ENV evalCopyVersions='/bin/sh -c "\
  mkdir -p ${minecraftAppsVersionDirectory} ; \
  cp -n /app/plugins/${modGroupManagerJar} ${minecraftAppsVersionDirectory}/${modGroupManagerJar} ; \
  cp -n /app/plugins/${modMultiverseCoreJar} ${minecraftAppsVersionDirectory}/${modMultiverseCoreJar} ; \
  cp -n /app/\"${minecraftVanillaJar}\" ${minecraftAppsVersionDirectory}/\"${minecraftVanillaJar}\" ; \
  cp -n /app/\"${minecraftSpigotJar}\" ${minecraftAppsVersionDirectory}/\"${minecraftSpigotJar}\" ; \
  echo \"The data has been copied here ${minecraftAppsVersionDirectory}\" ; \
  " '

# @brief    Copies the startup file to the mount bind folder, but does not overwrite the existing file
#           Example: `eval $evalCopyStartup`
# @return   string, log message
ENV evalCopyStartup='/bin/sh -c "\
  cp -n /app/${dockerStartupFileName} ./${dockerStartupFileName} ; \
  echo \"The startup file has been copied\" ; \
  " '

# @brief    The value of the `eula` key in the `eula.txt` file in the current folder is set to `true`
#           Example: `eval $evalSetEulaTrue`
# @return   Nothing
ENV evalSetEulaTrue="sed -i -e 's/eula=false/eula=true/g' eula.txt"

# @brief    The value of the `eula` key in the `eula.txt` file in the current folder is set to `true`
#           Example: `eval $evalSetEula`
# @param    EULA is checked and if true the command @see evalSetEulaTrue is executed
# @return   string, log message
ENV evalSetEula='/bin/sh -c "\
  if [ \"${EULA}\" = \"true\" ] ; \
  then \
    eval ${evalSetEulaTrue} ; \
    echo \"The eula file was automatically set to true\" ; \
  else \
    echo \"The eula file has not been touched\" ; \
  fi " '

# @brief    Reads the value of an entry in the file `startup.json`
#           Example: `echo $($fncIfFalseThenVanillaElseSpigot)`
# @return   bool, value of the variable
ENV fncIfFalseThenVanillaElseSpigot="jq .start.ifFalseThenVanillaElseSpigot ./${dockerStartupFileName}"

# @brief    Reads the java parameters
#           Example: `echo $($fncJavaParam)`
# @return   string, value of the variable
ENV fncJavaParam="jq --raw-output .java.param ./${dockerStartupFileName}"

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
# @return   string, returns the value stored in `minecraftVanillaJar` or `minecraftSpigotJar`
ENV evalGetMinecraftApp='/bin/sh -c "\
  if [ \"$(eval ${evalIsVanilla})\" = \"true\" ] ; \
  then \
    echo ${minecraftVanillaJar} ; \
  else \
    if [ \"$(eval ${evalIsSpigot})\" = \"true\" ] ; \
    then \
      echo ${minecraftSpigotJar} ; \
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
# `COPY --from=spigotmc_stage /BuildTools/"${minecraftSpigotJar}" /app/`
# `COPY --from=spigotmc_stage /Downloads/"${modGroupManagerJar}" /app/plugins/`
# `COPY --from=spigotmc_stage /Downloads/"${modMultiverseCoreJar}" /app/plugins/`
FROM base_stage AS spigotmc_stage

RUN \
  apt install -y git && \
  apt install -y wget

# build spigot ----------------------------------------------------------------

# Change working directory.
WORKDIR /BuildTools

# Download BuildTools
# Update: https://www.spigotmc.org/wiki/buildtools/
ADD \
  --checksum=sha256:42678cf1a115e6a75711f4e925b3c2af3a814171af37c7fde9e9b611ded90637 \
  https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar \
  BuildTools.jar

# Build spigotmc
RUN java -jar BuildTools.jar --rev latest


# mods download ---------------------------------------------------------------

WORKDIR /Downloads

# GroupManager
# source https://github.com/ElgarL/GroupManager/releases
ADD \
  --checksum=sha256:7c9fa7e2ea5b3ff2b114be876b2521976408e78ec1587ee56f4aae65521f30ef \
  https://github.com/ElgarL/GroupManager/releases/download/v3.2/GroupManager.jar \
  ${modGroupManagerJar}

# multiverse-core
# source https://dev.bukkit.org/projects/multiverse-core/files
RUN \
  wget https://dev.bukkit.org/projects/multiverse-core/files/4744018/download \
  -O ${modMultiverseCoreJar} && \
  echo "98237AAF35C6EE7BFD95FB7F399EF703B3E72BFF8EAB488A904AAD9D4530CD10 ${modMultiverseCoreJar}" | \
  sha256sum --check || exit 4


#------------------------------------------------------------------------------
### minecraft_stage
#------------------------------------------------------------------------------

# base_stage needs the have an `ENV` defined with the name `VERSION` and the number like `1.20.4`
# base_stage needs the have an `ENV` defined with the name `minecraftVanillaJar` and the filename as content
# Copy the content with this command:
# `COPY --from=minecraft_stage /Downloads/${minecraftVanillaJar} /app/`

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

# Download meta file
RUN wget $(eval ${evalMinecraftMetaUrl}) -O "${minecraftMetaFile}"
RUN echo "$(eval ${evalMinecraftMetaSha1}) ${minecraftMetaFile}" | sha1sum --check || exit 5

# Download Minecraft
RUN \
  wget $(eval ${fncMinecraftVersionUrl}) \
  -O "${minecraftVanillaJar}" && \
  echo "$(eval ${fncMinecraftVersionSha1}) ${minecraftVanillaJar}" | \
  sha1sum --check || exit 6


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

COPY --from=minecraft_stage /Downloads/${minecraftVanillaJar} /app/

# Checks if Minecraft is available
RUN FILE="${minecraftVanillaJar}" ; if [ -f "${FILE}" ] ; then :; else exit 1 ; fi

# Starts Minecraft for the first time without agreeing to the EULA
RUN java ${JAVA_PARAMETER} -jar "${minecraftVanillaJar}" nogui || exit 3 ;

# Copy Spigot and mods
COPY --from=spigotmc_stage /BuildTools/"${minecraftSpigotJar}" /app/
COPY --from=spigotmc_stage /Downloads/"${modGroupManagerJar}" /app/plugins/
COPY --from=spigotmc_stage /Downloads/"${modMultiverseCoreJar}" /app/plugins/

# Starts Spiegot for the first time without agreeing to the EULA
RUN java ${JAVA_PARAMETER} -jar "${minecraftSpigotJar}" nogui || exit 3 ;

ENV trapCommand='echo "${noteInfo} Stops the app" ; echo "stop" >> stdin.pipe ; wait ${PID}'

# Setup the entrypoint
WORKDIR /minecraft
ENTRYPOINT ["/bin/sh", "-c" , "\
  echo \"${noteInfo} $(eval ${evalInitialCopy})\" && \
  echo \"${noteInfo} $(eval ${evalCopyVersions})\" && \
  echo \"${noteInfo} $(eval ${evalCopyStartup})\" && \
  echo \"${noteInfo} $(eval ${evalSetEula})\" && \
  echo \"${noteInfo} java param: $(${fncJavaParam})\" && \
  echo \"${noteInfo} java app  : $(eval ${evalGetMinecraftApp})\" && \
  trap \"${trapCommand}\" TERM && \
    rm -f stdin.pipe ; \
    mkfifo stdin.pipe ; \
    sleep infinity > stdin.pipe & java $(${fncJavaParam}) -jar $(eval ${evalGetMinecraftApp}) nogui < stdin.pipe & PID=$! ; \
    wait ${PID} ; \
  echo \"${noteInfo} Minecraft closed\" ; \
  rm -f stdin.pipe ; \
  echo \"${noteInfo} All actions were completed successfully\" "]


#------------------------------------------------------------------------------
### EOF
#------------------------------------------------------------------------------
