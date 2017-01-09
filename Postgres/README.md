# Postgres Source Builder

Add patches to apply to the PostgreSQL source and build the project.

```bash
$ cp <some_patch_file> ./patch
$ vagrant up
```

Once provisioned, run the following:

```bash
$ vagrant ssh
$ ./init_pg.sh
```
