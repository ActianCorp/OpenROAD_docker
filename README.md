# How to Run the Actian OpenROAD Server in Docker

This article shows how to setup a Docker image with the Actian OpenROAD Server on Linux (rockylinux)

## Steps

Before running the script 

- Git clone will extract the files and place them in a directory (e.g. `openroad_server_docker`) which will be the base directory for the setup. `git clone https://alm.actian.com/bitbucket/scm/or/openroad_server_docker.git`
- Check `saveset` directory for known working versions
- Download the latest version of RPM based ActianX 12.0 for Linux 64-bit and place it in the `saveset` directory (e.g. `openroad_server_docker`). See `INGRES_ARCHIVE` in Dockerfile.
- Download the latest version of OpenROAD 12.0 for Linux 64-bit and place it in the `saveset` directory (e.g. `openroad_server_docker`). See `OPENROAD_ARCHIVE` in Dockerfile.
- Download the tar.gz Apache Tomcat package from the Apache Tomcat page and place it in the `saveset` directory (e.g. `openroad_server_docker`). See `TOMCAT_ARCHIVE` in Dockerfile.
- Get OpenROAD `licence.xml` from https://actian.atlassian.net/wiki/spaces/GlobalSupport/pages/12486370/Emergency+Licenses and place it inside licdata directory in the base directory (eg. `openroad_server_docker/licdata`)
- If you want to deploy new OpenROAD Server application then copy orjarinstall_cfg.json, orjarinstall.py and orserver-add-<appname>.zip in the `saveset` directory.
- Keep mandatory orjarinstall_cfg.json file in `saveset` directory. This file will be copied to $II_SYTEM/ingres/files
- The JSON file orjarinstall_cfg.json should contain a JSON object {...} with the following members (all optional):
         "libu3gldir" - the directory shared libraries/DLLs are deployed into.
             This directory should be contained in LD_LIBRARY_PATH (Linux) or PATH (Windows); default: $II_SYTEM/ingres/lib (Linux) or %II_SYSTEM%\ingres\bin (Windows)
         "orjsonconfigdir" - the directory JSON config files for OpenROAD server applications are deployed into (default: $II_SYTEM/ingres/files/orjsonconfig)
         "resourcedir" - the directory "resource*" directories (and their contents) are deployed into (default: $II_SYTEM/ingres)
         "w4glappsdir" - the directory 4GL image files are deployed into; directory should be contained in II_W4GLAPPS_DIR (default: $II_SYTEM/ingres/w4glapps)
- orserver-add-<appname>.zip is an archive containing the server application and other resources required
  This archive can have the following subdirectories that will be processed:
      - libu3gl - shared libraries/DLLs
      - netutil - netutil command scripts
      - orjsonconfig - JSON config files for OpenROAD server applications
      - orserveradm_removeapp - JSON file to be used by the "orserveradm.py" script with RemoveApp command
      - orserveradm_addapp - JSON file to be used by the "orserveradm.py" script with AddApp command
      - resource* - Additional resource directories to be deployed
      - w4glapps - OpenROAD Server application images

Once all the above steps are completed, run following commands 

	docker build -t actian_orserver .
	docker run -d -p 8080:8080 --name actian_orserver_demo -it actian_orserver

Then check if OpenROAD gRPC Servlet is accessible:

    curl http://localhost:8080/openroadg/jsonrpc?app=comtest

Debug shell inside docker container:

    docker exec -it actian_orserver_demo /bin/bash 
    
Test OpenROAD gRPC server under debug shell:

    comtest_g

The following directories are going to be used as volumes (`docker-compose.yml`):
- `deploy/` - for configuration files, including tomcat, orserver.json and application json files.
- `logs/` - catalina.out, w4gl.log and application logs


## Docker Cheat sheet items

Generic

    docker ps
    docker ps -a
    docker images

Specific

    docker stop actian_orserver_demo
    docker rm actian_orserver_demo

    docker image rm actian_orserver

## Notes

1. This is copy of https://alm.actian.com/bitbucket/scm/or/openroad_server_docker.git
