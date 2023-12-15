!/usr/bin/env bash
#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#

set -e -x
SCRIPTPATH="$(dirname "$(readlink -f "$0")")"
SRC_ROOT_DIR=${SCRIPTPATH}/../..
cd $SRC_ROOT_DIR

POM_VERSION=`cat $SRC_ROOT_DIR/version.txt | xargs`
# Sanitize VERSION by removing `SNAPSHOT` if any since it's not legal in DEB
VERSION=`echo $POM_VERSION | awk -F-  '{print $1}'`

ROOT_DIR=apache-pulsar-client-cpp-$POM_VERSION
BUILD_DIR=$SCRIPTPATH/BUILD
CPP_DIR=$SCRIPTPATH/BUILD/$ROOT_DIR

rm -rf $BUILD_DIR
mkdir $BUILD_DIR
cd $BUILD_DIR
tar xfz $SRC_ROOT_DIR/apache-pulsar-client-cpp-$POM_VERSION.tar.gz

export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

chmod +x $(find . -name "*.sh")
cmake . -DBUILD_TESTS=OFF -DBUILD_PERF_TOOLS=OFF  -DCMAKE_CXX_FLAGS="-fPIC"
make -j 3

DEST_DIR=$CPP_DIR/apache-pulsar-client
mkdir -p $DEST_DIR/DEBIAN
cat <<EOF > $DEST_DIR/DEBIAN/control
Package: apache-pulsar-client
Version: ${VERSION}
Maintainer: Apache Pulsar <dev@pulsar.apache.org>
Architecture: amd64
Description: The Apache Pulsar client contains a C++ and C APIs to interact with Apache Pulsar brokers.
EOF

DEVEL_DEST_DIR=$CPP_DIR/apache-pulsar-client-dev
mkdir -p $DEVEL_DEST_DIR/DEBIAN
cat <<EOF > $DEVEL_DEST_DIR/DEBIAN/control
Package: apache-pulsar-client-dev
Version: ${VERSION}
Maintainer: Apache Pulsar <dev@pulsar.apache.org>
Architecture: amd64
Depends: apache-pulsar-client
Description: The Apache Pulsar client contains a C++ and C APIs to interact with Apache Pulsar brokers.
EOF

mkdir -p $DEST_DIR/usr/lib
mkdir -p $DEVEL_DEST_DIR/usr/lib/pulsar
mkdir -p $DEVEL_DEST_DIR/usr/include/pulsar
mkdir -p $DEST_DIR/usr/share/doc/pulsar-client-$VERSION
mkdir -p $DEVEL_DEST_DIR/usr/share/doc/pulsar-client-dev-$VERSION

cp -ar $BUILD_DIR/include/pulsar $DEVEL_DEST_DIR/usr/include/
find $BUILD_DIR/lib -name "*.h" -exec cp {} $DEVEL_DEST_DIR/usr/include/pulsar/ \;
cp $BUILD_DIR/lib/libpulsar.a $DEVEL_DEST_DIR/usr/lib
cp $BUILD_DIR/lib/libpulsar.so $DEST_DIR/usr/lib

cp $BUILD_DIR/pkg/licenses/* $DEST_DIR/usr/share/doc/pulsar-client-$VERSION
cp $BUILD_DIR/pkg/licenses/LICENSE.txt $DEST_DIR/usr/share/doc/pulsar-client-$VERSION/copyright
cp $BUILD_DIR/pkg/licenses/LICENSE.txt $DEST_DIR/DEBIAN/copyright
cp $BUILD_DIR/pkg/licenses/LICENSE.txt $DEVEL_DEST_DIR/DEBIAN/copyright

dpkg-deb --build $DEST_DIR
dpkg-deb --build $DEVEL_DEST_DIR


