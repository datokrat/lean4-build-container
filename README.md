# Isolated `lean4` builds

This is an *experimental* project helping to build untrusted modifications to `lean4` on Mac OS Tahoe in a safe, isolated VM.

It relies on Apple's new [OCI container framework](https://github.com/apple/container/) tool. Other than Docker containers, this tool promises to provide real isolation,
[spawning a separate (Micro-)VM for every container](https://github.com/apple/container/). This makes it a good basis for sandboxing untrusted code. 

The container running the Lean build is designed to have very limited permissions. It can only talk to the Internet via a proxy that only allows very few domains such as GitHub.
