# Virtual Environment

This is the virtualization blueprint to deploy:
* PostgreSQL
* Prometheus

## Requirements
* Vagrant (tested on 1.8.6)
* Virtual Box (tested on 5.1.6)

## Deploy

```bash
$ git clone git@github.com:jasonodonnell/Vagrant.git
$ cd ./Prometheus/Vagrant
$ vagrant up
```

## Access Prometheus 

First, create an SSH tunnel to prometheus:

```bash
$ ssh -i .vagrant/machines/prometheus/virtualbox/private_key \
      -N -f -L 9090:localhost:9090 vagrant@172.17.8.101
```

Next, navigate to the following:

```bash
http://localhost:9090/
```
