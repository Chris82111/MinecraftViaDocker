# MinecraftViaDocker

The Dockerfile creates a container and downloads a Vanilla server and a Spiegot server. This is therefore an automation of the download. The internally created files are copied to a subfolder of the mounted folder (`apps/<version>`) after starting the container. Other data is only copied if the folder is empty. With each start, the system checks whether the folder is empty and copies the data if necessary. The Dockerfile can therefore be used to operate a server or to obtain only the necessary `*.jar` files.

## Change Settings

Docker creates a configuration file `startup.json`. In this file, you can select Vanilla or Spigot (`.start.ifFalseThenVanillaElseSpigot`) and additional Java start parameters (`.java.param`).

## Using Docker

After cloning the repository or downloading the Dockerfile, the image and the container must be created.

Command to create the image (the creation takes about 215 seconds):

```sh
docker build --build-arg="JAVA_PARAMETER=-Xmx1024M -Xms1024M" --build-arg="START_SPIGOT=false" -t minecraft_via_docker:1.20.4 .
```

Command to create the container without executing it:

```sh
docker container create -it --name mcContainer -p 25565:25565 --mount type=bind,source="$(pwd)"/minecraft,target=/minecraft --env EULA=true minecraft_via_docker:1.20.4 sh
```

Start:

```sh
docker start mcContainer
```

Stop, stopping the container sends the correct command to the app so that the app saves all data and shuts down:

```sh
docker stop mcContainer
```

Commands can be sent directly from the host system to the application in the container.
Under Linux you can use the following command or the Windows command:

```sh
docker exec mcContainer /bin/sh -c 'echo "/say hello" >> stdin.pipe'
```

Under Windows you can use the following command:

```ps1
docker exec mcContainer /bin/sh -c "echo '/say hello' >> stdin.pipe"
```

Connect to a running container to execute commands:

```sh
docker exec -it mcContainer sh
```

Remove

```sh
docker stop mcContainer ; docker remove mcContainer
```

## Overview

<img src="readmeMisc/overview.jpg" width="300" alt="">

<!--
digraph G {
  Dockerfile -> Image[label="docker build ..."];
  http[shape=cylinder,label="https:\n\nopenjdk\nminecraft\nspigot\nGroupManager\nMultiverseCore"];
  http -> Image;
  { rank=same; http; Image }
  Image -> Container[label="docker container create ..."];
  minecraft[shape=cylinder,label="/minecraft"];
  minecraft -> Container[label="mount"];
  { rank=same; minecraft; Container }
}
-->

## Terms

All data contained in this Dockerfile, including without limitation e.g. source code, programs, applications have their own terms and must be respected. The "Unlicense license" refers to the GitHub repository and the Dockerfile but not to the data downloaded in the container.
