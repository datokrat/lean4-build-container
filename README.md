# Isolated `lean4` builds

This is an *experimental* project helping to build untrusted modifications to `lean4` on Mac OS Tahoe in a safe, isolated VM.

It relies on Apple's new [OCI container framework](https://github.com/apple/container/) tool. Other than Docker containers, this tool promises to provide real isolation,
[spawning a separate (Micro-)VM for every container](https://github.com/apple/container/). This makes it a good basis for sandboxing untrusted code. 

The container running the Lean build is designed to have very limited permissions. It can only talk to the Internet via a proxy that only allows very few domains such as GitHub.

## Preparations

* You need Mac OS Tahoe. On other systems, you can adjust the scripts to use the `docker` command instead of `container` (and replacing some commands, such as `container list` with `docker ps`), but [you might not get really isolated containers](https://opensource.com/business/14/7/docker-security-selinux).
* Read the scripts yourself; this is the first time I used the new container tool and I might have made mistakes. (I would be happy to hear about them!)
* ihttps://opensource.com/business/14/7/docker-security-selinux
* Install Rosetta: `softwareupdate --install-rosetta`
* Install Apple Containers: `brew install containers`
* Do NOT try to [set up the local DNS domain](https://github.com/apple/container/blob/main/docs/tutorial.md). For me, it didn't work and broke DNS requests inside all containers and when building images.
* Use `build-image.sh` to build the container image.

## Creating and starting containers

* To create a new container, use `create.sh`. It will open a shell inside the container.
* To restart a container that has been stopped, use `start.sh $BUILD_ID` (inserting the correct number fo BUILD_ID).

## Working inside a container

* Use `/scripts/sync.sh` to rsync the files from the current working directory into the container.
* Use `/scripts/build.sh` to trigger the Lean build.

## Getting files outside a container. This is, admittedly, fiddly right now.

1. Use `cp` to copy the files into the container's `/output` directory.
2. After stopping the container, you will find a `vm-output` symlink in the working directory that points to the place where the `/output` volume can be found in the host system.
