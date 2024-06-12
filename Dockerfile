#-------------------------------------------------------------------------------

# Copyright 2023 Actian Corporation

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

# http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#-------------------------------------------------------------------------------
# Pre-requisites required before using this Dockerfile:
#   1. An installed and working Docker
#   2. Download Ingres / Actian X
#   3. Download OpenROAD
#   4. Download Apache Tomcat
#   4. Copy Ingres *.tgz , OpenROAD .tar.gz and Tomcat tar.gz files you downloaded to the same location as this Dockerfile

FROM rockylinux:9
# Docker file for Actian OpenROAD Server
LABEL com.actian.vendor="Actian Corporation" \
      version=12.0\
      description="Actian OpenROAD 12.0(Server)" \
      maintainer=prasad.sawant@actian.com
#TAG actian openroad server v12 v12.0

# Pull dependencies
RUN dnf update -y && \
    dnf install -y sudo wget which libaio libX11 libXext initscripts java-1.8.0-openjdk-devel libxcrypt-compat dos2unix python3

# Create python symlink  
RUN alternatives --install /usr/bin/python python /usr/bin/python3 100

# Pull WinLib dependencies
RUN dnf -y groupinstall 'Development Tools'
RUN dnf -y install gcc libX11-devel freetype-devel zlib-devel libxcb-devel libxslt-devel libgcrypt-devel libxml2-devel gnutls-devel libpng-devel libjpeg-turbo-devel libtiff-devel dbus-devel fontconfig-devel

# Install gRPCurl
RUN wget https://github.com/fullstorydev/grpcurl/releases/download/v1.9.0/grpcurl_1.9.0_linux_x86_64.tar.gz
RUN tar -xvzf grpcurl_1.9.0_linux_x86_64.tar.gz
RUN chmod +x grpcurl
RUN mv grpcurl /usr/local/bin/grpcurl

# This Dockerfile will work with any community linux version that follows this naming convention
ENV VERSION=12.0                      \
INGRES_ARCHIVE=actianx-*-x86_64*      \
TOMCAT_ARCHIVE=apache-tomcat*.tar.gz  \
OPENROAD_ARCHIVE=or12_0_com           \
OPENROAD_APP=orserver-add-*.zip       \
II_SYSTEM=/IngresOR                   \
TIMEZONE=America/Los_Angeles          \
LicDir=/License                       \
II_RESPONSE_FILE=/response_file.rsp   \
CATALINA_HOME=/usr/local/tomcat       

# Pull in Ingres saveset
ADD savesets/${INGRES_ARCHIVE}.tgz .
COPY savesets/${OPENROAD_ARCHIVE}.tar.gz .

# Setup for OpenROAD App Deployment
RUN mkdir /deploy
COPY savesets/orjarinstall* /deploy
COPY savesets/${OPENROAD_APP} /deploy

ADD licdata/license.xml $LicDir/
ADD ${II_RESPONSE_FILE} /
RUN dos2unix ${II_RESPONSE_FILE}
RUN useradd actian

# Setup Tomcat
ADD savesets/${TOMCAT_ARCHIVE} /usr/local
RUN cd /usr/local && mv apache-tomcat* tomcat && chown -R actian:actian ${CATALINA_HOME}

# Install Ingres
RUN rpm -qp rpm/ingres-${VERSION}.*.rpm --requires
RUN cd $INGRES_ARCHIVE && \
    rpm -ivh --prefix=${II_SYSTEM} rpm/ingres-${VERSION}.*.rpm rpm/ingres-net-${VERSION}*.rpm && \
    ${II_SYSTEM}/ingres/utility/iisystemd -a configure -d "${II_SYSTEM}" -i OR -s rdbms             && \
    . ${II_SYSTEM}/ingres/.ingORsh   && \
    cd -

RUN ln -snf /usr/share/zoneinfo/$TIMEZONE /etc/localtime && echo $TIMEZONE > /etc/timezone

# set environment globally
RUN cp $II_SYSTEM/ingres/.ingORsh /etc/profile.d/ingresOR.sh

# Installing OpenROAD
RUN source /etc/profile.d/ingresOR.sh && \
    tar xzf ${OPENROAD_ARCHIVE}.tar.gz orinstall.sh cilicchk lichostinfo && \
    mv cilicchk lichostinfo $II_SYSTEM/ingres/utility && \
    chmod u+x ./orinstall.sh && \
    su actian -c "sh orinstall.sh -t orrun -licdir ${LicDir} -f ${OPENROAD_ARCHIVE}.tar.gz -l accept -r O" && \
    sed -i -e "s,`hostname`,localhost," $II_SYSTEM/ingres/files/orserver.json

RUN cp /home/actian/.orORsh /etc/profile.d/ingresOR.sh && \
# COMPUTERNAME is required for orjarinstall.py/orserveradm.py AddApp
    echo "export COMPUTERNAME=localhost" >> /etc/profile.d/ingresOR.sh && \
    echo "export CATALINA_PID=${CATALINA_HOME}/temp/tomcat.pid" >> /etc/profile.d/ingresOR.sh && \
    echo "export CATALINA_HOME=${CATALINA_HOME}" >> /etc/profile.d/ingresOR.sh                && \
    echo "export CATALINA_BASE=${CATALINA_HOME}" >> /etc/profile.d/ingresOR.sh                && \
    echo 'export JAVA_OPTS="-Djava.library.path=$II_SYSTEM/ingres/lib"' >> /etc/profile.d/ingresOR.sh 

# Install Ingres control script
ADD or_dockerctl.sh $II_SYSTEM/ingres/utility/or_dockerctl
RUN dos2unix $II_SYSTEM/ingres/utility/or_dockerctl
RUN chmod 755 $II_SYSTEM/ingres/utility/or_dockerctl
RUN ln -s $II_SYSTEM/ingres/utility/or_dockerctl /usr/local/bin/or_dockerctl

# Deploy OpenROAD gRPC servlet
RUN cp -p $II_SYSTEM/ingres/orgrpcjava/openroadg.jar $CATALINA_HOME/webapps
RUN cd $CATALINA_HOME/webapps && jar -xvf $CATALINA_HOME/webapps/openroadg.jar

# Allow external connections
EXPOSE 50052 8080

# Allow external locations
VOLUME /deploy
VOLUME /logs

ENTRYPOINT ["or_dockerctl"]
