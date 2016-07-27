k8s-zk
==============

This image is the zookeeper dynamic conf for k8s. It comes from [rawmind/k8s-tools][k8s-tools].

## Build

```
docker build -t rawmind/k8s-zk:<version> .
```

## Versions

- `3.4.8-8` [(Dockerfile)](https://github.com/rawmind0/k8s-zk/blob/3.4.8-8/README.md)

## Usage

This image has to be run as a complement of [rawmind/alpine-zk][alpine-zk], and it configures /opt/tools volume. It scans from k8s etcd, for a zookeeper endpoints and generates /opt/zk/conf/zoo.cfg and /opt/zk/conf/myid dynamicly.

/opt/tools/scripts/zk-service.sh scripts, generates and set a ZKID for every node. It also checks a minimal zk quorum before to reboot the zk node on scale the rc.


[alpine-zk]: https://github.com/rawmind0/alpine-zk
[k8s-tools]: https://github.com/rawmind0/rancher-tools
