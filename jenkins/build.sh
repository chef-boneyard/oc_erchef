#!/bin/bash -xe
PROJ_NAME=oc_erchef
export PATH=/opt/ruby1.9/bin:/opt/erlang/bin:$PATH:/usr/local/bin
git clean -fdX
MAKEFLAGS="-j 4" USE_SYSTEM_GECODE=1 make distclean rel || exit 1

# If the string is null, then the git command returned false
if git describe --tags --match='[0-9]*.[0-9]*.[0-9]*' --exact-match
then
    VERSION=$(git describe --tags --exact-match --match='[0-9]*.[0-9]*.[0-9]*')
else
    REL_VERSION=`cat rel/reltool.config|grep '{rel,.*"oc_erchef"'|cut -d ',' -f 3|sed 's/"//g'`
    GIT_SHA=`git rev-parse --short HEAD`
    VERSION=${REL_VERSION}-${GIT_SHA}
    cd rel
fi
PACKAGE=${PROJ_NAME}-${VERSION}.tar.gz
cd rel
# Yep, hard-coding platform and version. We're building ubuntu only, 10.04 only,
# but need to distribute to both.
tar zcf $PACKAGE $PROJ_NAME/
s3cmd put $PACKAGE s3://opscode-ci/artifacts/ubuntu-10.04/x86_64/$PROJ_NAME/$PACKAGE
s3cmd put $PACKAGE s3://opscode-ci/artifacts/ubuntu-12.04/x86_64/$PROJ_NAME/$PACKAGE
