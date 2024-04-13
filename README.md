# Minecraft via Docker

<img src="readmeMisc/overview.jpg" width="300" alt="">

Recommended command to create the image:

```sh
docker build --build-arg="JAVA_PARAMETER=-Xmx2048M -Xms2048M" --build-arg="SPIGOT=false" -t minecraftImage .
```

Recommended command for exiting the container:

```sh
docker container create -it --name minecraftContainer -p 25565:25565 --mount type=bind,source="$(pwd)"/minecraft,target=/minecraft --env ACCEPT_EULA=true minecraftImage sh
```

<!--
digraph G {
  Dockerfile -> Image[label="docker build ..."];
  http[shape=cylinder,label="https:\n\nminecraft\nspigot\nGroupManager\nMultiverseCore"];
  http -> Image;
  { rank=same; http; Image }
  Image -> Container[label="docker container create ..."];
  minecraft[shape=cylinder,label="/minecraft"];
  minecraft -> Container[label="mount"];
  { rank=same; minecraft; Container }
}
-->
