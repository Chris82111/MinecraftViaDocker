# MinecraftViaDocker

<img src="readmeMisc/overview.jpg" width="300" alt="">

Recommended command to create the image:

```sh
docker build --build-arg="JAVA_PARAMETER=-Xmx2048M -Xms2048M" --build-arg="START_SPIGOT=false" -t minecraftImage .
```

Recommended command for exiting the container:

```sh
docker container create -it --name minecraftContainer -p 25565:25565 --mount type=bind,source="$(pwd)"/minecraft,target=/minecraft --env ACCEPT_EULA=true minecraftImage sh
```

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

## Working List of Commands

Url to download the actual list of minecraft versions with download link: [version_manifest_v2.json](https://launchermeta.mojang.com/mc/game/version_manifest_v2.json)

Create image from current folders `Dockerfile` (optional --no-cache):

```sh
docker build -t my_minecraft_image .
```

```sh
docker build --no-cache -t my_minecraft_image .
```

```sh
docker build --build-arg="JAVA_PARAMETER=-Xmx2048M -Xms2048M" -t my_minecraft_image .
```

List all Images:

```sh
docker images
```

Deleate Image

```sh
docker image rm my_minecraft_image
```

Check group

```sh
if grep -q "docker" /etc/group ; then echo Yes; else echo no; fi
```

Add group (needs restart)

```sh
usermod -aG docker $USER
```

List all containers

```sh
docker ps -a
```

Create without running

```sh
docker container create -it --name minecraftVanillaU -p 25565:25565 ubuntu:latest sh
```

```sh
docker container create -it --name minecraftVanillaU -p 25565:25565 --mount type=bind,source="$(pwd)"/minecraft,target=/minecraft --env ACCEPT_EULA=true my_minecraft_image sh
```

Stop

```sh
docker stop minecraftVanillaU
```

Remove

```sh
docker stop minecraftVanillaU ; docker remove minecraftVanillaU
```

Start

```sh
docker start minecraftVanillaU
```

(1) Execute

```sh
docker exec -it minecraftVanillaU sh
```

(2) Execute multiple

```sh
docker exec -it minecraftVanillaU sh -c 'export VAR1=value1; echo Hi; echo Yes${VAR1}'
```
