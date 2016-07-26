k8s-zk
==============

This image is the zookeeper dynamic conf for k8s. It comes from [rawmind/k8s-tools][k8s-tools].

## Build

```
docker build -t rawmind/k8s-zk:<version> .
```

## Versions

- `3.4.8-5` [(Dockerfile)](https://github.com/rawmind0/k8s-zk/blob/3.4.8-5/README.md)

## Usage

This image has to be run as a complement of [rawmind/alpine-zk][alpine-zk], and it configures /opt/tools volume. It scans from k8s etcd, for a zookeeper rc and generates /opt/zk/conf/zoo.cfg and /opt/zk/conf/myid dynamicly.


[alpine-zk]: https://github.com/rawmind0/alpine-zk
[k8s-tools]: https://github.com/rawmind0/rancher-tools
