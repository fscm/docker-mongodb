# MongoDB for Docker

A small MongoDB image that can be used to start a MongoDB server.

## Supported tags

- `4.0.5`
- `4.0.6`
- `4.0.10`
- `4.0.11`
- `4.2.1`
- `4.2.6`, `latest`

## What is MongoDB?

> MongoDB is a document database with the scalability and flexibility that you want with the querying and indexing that you need.

*from* [mongodb.com](https://www.mongodb.com/what-is-mongodb)

## Getting Started

There are a couple of things needed for the script to work.

### Prerequisites

Docker, either the Community Edition (CE) or Enterprise Edition (EE), needs to
be installed on your local computer.

#### Docker

Docker installation instructions can be found
[here](https://docs.docker.com/install/).

### Usage

In order to end up with a functional MongoDB service - after having build
the container - some configurations have to be performed.

To help perform those configurations a small set of commands is included on the
Docker container.

- `help` - Usage help.
- `init` - Configure the MongoDB service (__Not required in this image__).
- `start` - Start the MongoDB service.

To store the data of the MongoDB server a volume should be created and added
to the container when running the same.

#### Creating Volumes

To be able to make all of the MongoDB data persistent, the same will have to
be stored on a different volume.

Creating volumes can be done using the `docker` tool. To create a volume use
the following command:

```
docker volume create --name VOLUME_NAME
```

Two create the required volume the following command can be used:

```
docker volume create --name my_data
```

**Note:** A local folder can also be used instead of a volume. Use the path of
the folder in place of the volume name.

#### Configuring the MongoDB Server

This step is not required for this MongoDB Docker image.

#### Start the MongoDB Server

After configuring the MongoDB server the same can now be started.

Starting the MongoDB server can be done with the `start` command.

```
docker container run --volume MONGODB_VOL:/data:rw --detach --publish 27017:27017 fscm/mongodb:latest start
```

An example on how the MongoDB service can be started:

```
docker container run --volume my_data:/data:rw --detach --publish 27017:27017 --name my_mongodb fscm/mongodb:latest start
```

To see the output of the container that was started use the following command:

```
docker container attach CONTAINER_ID
```

Use the `ctrl+p` `ctrl+q` command sequence to detach from the container.

#### Stop the MongoDB Server

If needed the MongoDB server can be stoped and later started again (as long as
the command used to perform the initial start was as indicated before).

To stop the server use the following command:

```
docker container stop CONTAINER_ID
```

To start the server again use the following command:

```
docker container start CONTAINER_ID
```

### MongoDB Status

The MongoDB server status can be check by looking at the MongoDB server output
data using the docker command:

```
docker container logs CONTAINER_ID
```

## Build

Build instructions can be found
[here](https://github.com/fscm/docker-mongodb/blob/master/README.build.md).

## Versioning

This project uses [SemVer](http://semver.org/) for versioning. For the versions
available, see the [tags on this repository](https://github.com/fscm/docker-mongodb/tags).

## Authors

* **Frederico Martins** - [fscm](https://github.com/fscm)

See also the list of [contributors](https://github.com/fscm/docker-mongodb/contributors)
who participated in this project.
