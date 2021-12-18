---
title: "Jumping fences with socat"
date: 2021-12-19T07:50:17+11:00
draft: false
summary: "Accessing stuff using socat as a proxy, and re-learning docker (again)"
tags:
- docker
- unix
- kubernetes
- postgres
---

There's a kubernetes cluster I use often that runs software I'm responsible for.
The databases for that software are also in the kubernetes cluster, and are only
accessible to other resources in that cluster. This _can_ prevent silly mistakes
like accidentally dropping a table, but also makes prototyping difficult.

<figure>
  <img src="/blog/20211219_jumping_fences_with_socat/initia_state.png"
  alt="Image of me not being able to access my app's database"
  width="645"
  loading="lazy" />
  <figcaption>Me, locked out from the juicy data</figcaption>
</figure>

It should be possible to use [socat](https://linux.die.net/man/1/socat) as a
proxy to be able to connect to the database. `socat` is a unix program that
pipes data between a wide range of sinks & sources, eg. network sockets & files.

<figure>
  <img src="/blog/20211219_jumping_fences_with_socat/idea_state.png"
  alt="Image of me accessing my app's database via socat"
  width="669"
  loading="lazy" />
  <figcaption>My dream</figcaption>
</figure>


## Practicing with docker
I'll use docker since it will roughly simulate what I think I need to do with
kubernetes, and I don't have to install postgres and/or `psql` on my machine. I
have to re-learn docker every time I use it, so I'll document my steps this
time.

### Goal #1: connect psql to postgres

`psql` is a postgres CLI client. I'm using it as a quick way to verify that I
can connect a postgres client to a postgres instance.

<figure>
  <img src="/blog/20211219_jumping_fences_with_socat/psql_to_pg.png"
  alt="psql in one container, connecting to postgres in another container"
  width="422"
  loading="lazy" />
  <figcaption></figcaption>
</figure>


```sh
# Run postgres
docker run --rm --name pg -e POSTGRES_PASSWORD=pw -d postgres

# There it is:
docker ps
> CONTAINER ID   IMAGE      COMMAND                  CREATED         STATUS         PORTS      NAMES
> 6d2a5ad74c8e   postgres   "docker-entrypoint.s…"   4 seconds ago   Up 3 seconds   5432/tcp   pg

# OK. Can I connect to it with psql?
docker run -it --rm postgres psql
> psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: No such file or directory
>       Is the server running locally and accepting connections on that socket?

# No. Is there anything listening on port 5432?
netstat -aon | grep 5432
>

# No. Why? Because I didn't expose the port that postgres serves over when
# running the postgres container. Let's do that. First, stop the currently
# running postgres container:
docker stop pg
# Now run it again, exposing port 5432 to the host machine:
docker run --rm --name pg -e POSTGRES_PASSWORD=pw -d -p 5432:5432 postgres

# Now there's stuff listening on port 5432:
netstat -aon | grep 5432
>  TCP    0.0.0.0:5432           0.0.0.0:0              LISTENING       16448
>  TCP    [::]:5432              [::]:0                 LISTENING       16448
>  TCP    [::1]:5432             [::]:0                 LISTENING       18520

# Try psql again:
docker run -it --rm postgres psql
> psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: No such file or directory
>       Is the server running locally and accepting connections on that socket?

# Still no. This is because I'm running the psql container in an isolated
# (network) environment, where there's nothing listening on port 5432. I can
# use the special host address 'host.docker.internal' which resolves to the IP
# of the host machine (see https://docs.docker.com/desktop/windows/networking/):
docker run -it --rm postgres psql -h host.docker.internal -U postgres
> Password for user postgres: # enter the password 'pw' defined above
> psql (14.1 (Debian 14.1-1.pgdg110+1))
> Type "help" for help.
>
> postgres=#

# Woo! I'm in!
```


### Goal #2: connect psql to postgres, via socat

<figure>
  <img src="/blog/20211219_jumping_fences_with_socat/psql_to_socat_to_pg.png"
  alt="psql in one container, connecting to socat in another container, which
  connects to postgres in a third container"
  width="646"
  loading="lazy" />
  <figcaption></figcaption>
</figure>

- run postgres on a non-default port (6543)
- use socat to pipe traffic between the non-default and default postgres port
  (5432)
- run psql as in goal #1, which will show that it is connecting to postgres via
  socat


```sh
# stop the currently running postgres db
docker stop pg
# Start it again, this time hosting on port 6543.
docker run --rm --name pg -e POSTGRES_PASSWORD=pw -e PGPORT=6543 -d -p 6543:6543 postgres

# Check it is running, by connecting psql directly:
docker run -it --rm postgres psql -h host.docker.internal -U postgres -p 6543

# All good. Now, time for socat. The dockerhub page for socat has nearly the
# use case I want: "Publish a port on an existing container". In my case, the
# port is already published (6543), but I want to "republish" it on a different
# port (5432).
docker run -d --rm --name sc -p 5432:6543 alpine/socat \
    tcp-listen:6543,fork,reuseaddr tcp-connect:target:6543

# I don't really understand what all those options are doing, so I'll just hope
# for the best :) Let's try connecting psql. Note that psql uses the default
# port (5432) when you don't tell it to do otherwise.
docker run -it --rm postgres psql -h host.docker.internal -U postgres
> psql: error: connection to server at "host.docker.internal" (192.168.65.2), port 5432 failed: server closed the connection unexpectedly
>         This probably means the server terminated abnormally
>         before or while processing the request.

# d'oh. Why?
docker container logs sc
> 2021/12/18 01:28:47 socat[8] E getaddrinfo("target", "NULL", {1,0,1,6}, {}): Name does not resolve

# "Does not resolve". I think means it can't find the host. Did I need to
# point socat to host.docker.internal?
docker stop sc
docker run -d --rm --name sc -p 5432:6543 alpine/socat \
    tcp-listen:6543,fork,reuseaddr tcp-connect:host.docker.internal:6543

docker run -it --rm postgres psql -h host.docker.internal -U postgres
# Yep, I'm in!!
```


## Endgame

Time to try connecting to the database in kubernetes. Here's the goal state
again:

<figure>
  <img src="/blog/20211219_jumping_fences_with_socat/idea_state_ports.png"
  alt="Me accessing my app's database via socat, with port numbers shown"
  width="683"
  loading="lazy" />
  <figcaption>My dream, with ports</figcaption>
</figure>

It's basically the same as in goal #2, except:

- socat will be running in a pod in kubernetes
- socat will essentially just be 'forwarding' postgres's default port
- I'll need to use `kubectl` to forward a local port to the socat pod

```sh
# This is the host address of where the database is running. This is stored
# in a secret location...
DB_HOST=asdf
NAMESPACE=my_apps_namespace
SOCAT_POD_NAME=woz-db-proxy

# Run socat in a pod in kubernetes
kubectl run -n ${NAMESPACE} --restart=Never --image=alpine/socat \
    ${SOCAT_POD_NAME} -- \
    tcp-listen:5432,fork,reuseaddr \
    tcp-connect:${DB_HOST}:5432

# Wait for the pod to be ready
kubectl wait -n ${NAMESPACE} --for=condition=Ready pod/${SOCAT_POD_NAME}

# Forward port 5432 to the pod
kubectl port-forward -n ${NAMESPACE} pod/${SOCAT_POD_NAME} 5432:5432

# The moment of truth ... will it connect?
docker run -it --rm postgres psql -h host.docker.internal -U my_user -d my_db
> Password for user postgres:
> psql (14.1 (Debian 14.1-1.pgdg110+1))
> Type "help" for help.
>
> postgres=#

# Woo #2! I'm in!

# Delete the pod when I'm done
kubectl delete -n ${NAMESPACE} pod/${SOCAT_POD_NAME} --grace-period 1 --wait=false
```


Wahoo! Now I can now do all kinds of silly stuff, like accidentally inserting
test data into production, dropping tables, and overwriting customer data. All
the fun things in life.

I wonder if I could have just used `kubectl port-forward` directly to the
database? Too late, I've already learned a bunch of stuff, and now I'm tired.
