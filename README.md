# MinecraftViaDocker

⚠ The current version is currently still copying the data in parallel to the Dockerfile.

The Dockerfile creates a container with a Minecraft server. Alternatively, a Spiegot server can also be created. The internally created files are copied to a subfolder of the mounted folder (`apps/<version>`) after starting the container. Other data is only copied if the folder is empty. With each start, the system checks whether the folder is empty and copies the data if necessary. The Dockerfile can therefore be used to operate a server or to obtain only the necessary `*.jar` files.

## Using Docker

After cloning the repository or downloading the Dockerfile, the image and the container must be created.

Command to create the image:

```sh
docker build --build-arg="JAVA_PARAMETER=-Xmx1024M -Xms1024M" --build-arg="START_SPIGOT=false" -t minecraft_via_docker:1.20.4 .
```

Command to create the container without executing it:

```sh
docker container create -it --name minecraftContainer -p 25565:25565 --mount type=bind,source="$(pwd)"/minecraft,target=/minecraft --env ACCEPT_EULA=true minecraft_via_docker:1.20.4 sh
```

Start

```sh
docker start minecraftContainer
```

Stop

```sh
docker stop minecraftContainer
```

Commands can be sent directly from the host system to the application in the container.
Under Linux you can use the following command or the Windows command:

```sh
docker exec minecraftContainer /bin/sh -c 'echo "/say hello" >> stdin.pipe'
```

Under Windows you can use the following command:

```ps1
docker exec minecraftContainer /bin/sh -c "echo '/say hello' >> stdin.pipe"
```

Connect to a running container to execute commands:

```sh
docker exec -it minecraftContainer sh
```

Remove

```sh
docker stop minecraftContainer ; docker remove minecraftContainer
```

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
