#!/bin/bash

# Copyright (c) 2013-2014 LG Electronics, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Uncomment line below for debugging
#set -x

# Some constants
SCRIPT_VERSION="5.1.0"
SCRIPT_NAME=`basename $0`
AUTHORITATIVE_OFFICIAL_BUILD_SITE="svl"

BUILD_REPO="build-webos"
BUILD_LAYERS=("meta-webos"
              "meta-webos-backports")

# Create BOM files, by default disabled
CREATE_BOM=

# Dump signatures, by default disabled
SIGNATURES=

# Build site passed to script from outside (Replaces detecting it from JENKINS_URL)
BUILD_SITE=
# Build job passed to script from outside (Replaces detecting it from JOB_NAME)
BUILD_JOB=
# Branch where to push buildhistory, for repositories on gerrit it should start with refs/heads (Replaces detecting it from JOB_NAME and JENKINS_URL)
BUILD_BUILDHISTORY_BRANCH=

# We assume that script is inside scripts subfolder of build project
# and form paths based on that
CALLDIR=${PWD}

BUILD_TIMESTAMP_START=`date -u +%s`
BUILD_TIMESTAMP_OLD=$BUILD_TIMESTAMP_START

TIME_STR="TIME: %e %S %U %P %c %w %R %F %M %x %C"

# We need absolute path for ARTIFACTS
pushd `dirname $0` > /dev/null
SCRIPTDIR=`pwd -P`
popd > /dev/null

# Now let's ensure that:
pushd ${SCRIPTDIR} > /dev/null
if [ ! -d "../scripts" ] ; then
  echo "Make sure that ${SCRIPT_NAME} is in scripts folder of project"
  exit 2
fi
popd > /dev/null

cd "${SCRIPTDIR}/.."

BUILD_TOPDIR=`echo "$SCRIPTDIR" | sed 's#/scripts/*##g'`
ARTIFACTS="${BUILD_TOPDIR}/BUILD-ARTIFACTS"
mkdir -p "${ARTIFACTS}"
BUILD_TIME_LOG=${BUILD_TOPDIR}/time.txt

function print_timestamp {
  BUILD_TIMESTAMP=`date -u +%s`
  BUILD_TIMESTAMPH=`date -u +%Y%m%dT%TZ`

  local BUILD_TIMEDIFF=`expr ${BUILD_TIMESTAMP} - ${BUILD_TIMESTAMP_OLD}`
  local BUILD_TIMEDIFF_START=`expr ${BUILD_TIMESTAMP} - ${BUILD_TIMESTAMP_START}`
  BUILD_TIMESTAMP_OLD=${BUILD_TIMESTAMP}
  printf "TIME: ${SCRIPT_NAME}-${SCRIPT_VERSION} $1: ${BUILD_TIMESTAMP}, +${BUILD_TIMEDIFF}, +${BUILD_TIMEDIFF_START}, ${BUILD_TIMESTAMPH}\n" | tee -a ${BUILD_TIME_LOG}
}

print_timestamp "start"

declare -i RESULT=0

function showusage {
  echo "Usage: ${SCRIPT_NAME} [OPTION...]"
  cat <<!
OPTIONS:
  -I, --images             Images to build
  -T, --targets            Targets to build (unlike images they aren't copied from buildhistory)
  -M, --machines           Machines to build
  -b, --bom                Generate BOM files
  -s, --signatures         Dump sstate signatures, useful to compare why something is rebuilding
  -u, --scp-url            scp will use this path to download and update
                           \${URL}/latest_project_baselines.txt and also
                           \${URL}/history will be populated
  -S, --site               Build site, replaces detecting it from JENKINS_URL
  -j, --jenkins            Jenkins server which triggered this job, replaces detecting it form JENKINS_UL
  -J, --job                Type of job we want to run, replaces detecting it from JOB_NAME
  -B, --buildhistory-ref   Branch where to push buildhistory
                           for repositories on gerrit it should start with refs/heads
                           replaces detecting it from JOB_NAME and JENKINS_URL
  -V, --version            Show script version
  -h, --help               Print this help message
!
  exit 0
}

function check_project {
# Check out appropriate refspec for layer verification based on GERRIT_PROJECT
# or master if we assume other layers stable
  layer=`basename $1`
  if [ -d "${layer}" ] ; then
    pushd "${layer}" >/dev/null
    if [ "$GERRIT_PROJECT" = "$1" ] ; then
      REMOTE=origin
      if [ "${layer}" = "meta-webos" -o "${layer}" = "meta-webos-backports" ]; then
        # We cannot use origin, because by default it points to
        # github.com/openwebos not to g2g and we won't find GERRIT_REFSPEC on github
        REMOTE=ssh://g2g.palm.com/${layer}
      fi
      git fetch $REMOTE $GERRIT_REFSPEC
      echo "NOTE: Checking out $layer in $GERRIT_REFSPEC" >&2
      git checkout FETCH_HEAD
    else
      current_branch=`git branch --list|grep ^*\ |awk '{print $2}'`
      echo "NOTE: Run 'git remote update && git reset --hard origin/$current_branch' in  $layer" >&2
      echo "NOTE: Current branch - $current_branch"
      git remote update && git reset --hard origin/$current_branch
    fi
    popd >/dev/null
  fi
}

function check_project_vars {
  # Check out appropriate refspec passed in <layer-name>_commit
  # when requested by use_<layer-name>_commit
  layer=`basename $1`
  use=$(eval echo \$"use_${layer//-/_}_commit")
  ref=$(eval echo "\$${layer//-/_}_commit")
  if [ "$use" = "true" ]; then
    echo "NOTE: Checking out $layer in $ref" >&2
    ldesc=" $layer:$ref"
    if [ -d "${layer}" ] ; then
      pushd "${layer}" >/dev/null
      if echo $ref | grep -q '^refs/changes/'; then
        REMOTE=origin
        if [ "${layer}" = "meta-webos" -o "${layer}" = "meta-webos-backports" ]; then
          # We cannot use origin, because by default it points to
          # github.com/openwebos not to g2g and we won't find GERRIT_REFSPEC on github
          REMOTE=ssh://g2g.palm.com/${layer}
        fi
        git fetch $REMOTE $ref
        git checkout FETCH_HEAD
      else
        # for incremental builds we should add "git fetch" here
        git checkout $ref
      fi
      popd >/dev/null
    else
      echo "ERROR: Layer $layer does not exist!" >&2
    fi
  fi
  echo "$ldesc"
}

function generate_bom {
  MACHINE=$1
  I=$2
  BBFLAGS=$3
  FILENAME=$4

  mkdir -p "${ARTIFACTS}/${MACHINE}/${I}" || true
  /usr/bin/time -f "$TIME_STR" bitbake ${BBFLAGS} -g ${I} 2>&1 | tee /dev/stderr | grep '^TIME:' >> ${BUILD_TIME_LOG}
  grep '^"\([^"]*\)" \[label="\([^ ]*\) :\([^\\]*\)\\n\([^"]*\)"\]$' package-depends.dot |\
    grep -v '^"\([^"]*\)" \[label="\([^ (]*([^ ]*)\) :\([^\\]*\)\\n\([^"]*\)"\]$' |\
      sed 's/^"\([^"]*\)" \[label="\([^ ]*\) :\([^\\]*\)\\n\([^"]*\)"\]$/\1;\2;\3;\4/g' |\
        sed "s#;${BUILD_TOPDIR}/#;#g" |\
          sort > ${ARTIFACTS}/${MACHINE}/${I}/${FILENAME}
}

function set_build_site_and_server {
  # JENKINS_URL is set by the Jenkins executor. If it's not set or if it's not
  # recognized, then the build is, by definition, unofficial.
  if [ -n "${JENKINS_URL}" ]; then
    case "${JENKINS_URL}" in
      https://gecko.palm.com/jenkins/)
        BUILD_SITE="svl"
        BUILD_JENKINS_SERVER="gecko"
        ;;
      https://anaconda.palm.com/jenkins/)
        BUILD_SITE="svl"
        BUILD_JENKINS_SERVER="anaconda"
        ;;
      # Add detection of other sites here
      *)
        echo "Unrecognized JENKINS_URL: '${JENKINS_URL}'"
        exit 1
        ;;
    esac
  fi
}

function set_build_job {
  # JOB_NAME is set by the Jenkins executor
  if [ -z "${JOB_NAME}" ] ; then
    echo "JENKINS_URL set but JOB_NAME isn't"
    exit 1
  fi

  # It's not expected that this script would ever be used for Open webOS as is,
  # but the tests for it have been added as a guide for creating that edition.
  case ${JOB_NAME} in
    *-official-*)
      BUILD_JOB="official"
      ;;
    *-official.nonMP*)
      BUILD_JOB="official"
      ;;
    clean-engineering-*)
      # it cannot be verf or engr, because clean builds are managing layer checkouts alone
      BUILD_JOB="clean"
      ;;
    *-engineering-*)
      BUILD_JOB="engr"
      ;;
    *-engineering.MP*)
      BUILD_JOB="engr"
      ;;
    *-verify-*)
      BUILD_JOB="verf"
      ;;
    # The *-integrate-* jobs are like the verification builds done right before
    # the official builds. They have different names so that they can use a
    # separate, special pool of Jenkins slaves.
    *-integrate-*)
      BUILD_JOB="integ"
      ;;
    # The *-multilayer-* builds allow developers to trigger a multi-layer build
    # from their desktop, without using the Jenkins parameterized build UI.
    #
    # The 'mlverf' job type is used so that the build-id makes it obvious that
    # a multilayer build was performed (useful when evaluating CCC's).
    *-multilayer-*)
      BUILD_JOB="mlverf"
      ;;
    # Legacy job names
    build-webos-nightly|build-webos|build-webos-qemu*)
      BUILD_JOB="official"
      ;;
    *-layers-verification)
      BUILD_JOB="verf"
      ;;
    build-webos-*)
      BUILD_JOB="${JOB_NAME#build-webos-}"
      ;;
    # Add detection of other job types here
    *)
      echo "Unrecognized JOB_NAME: '${JOB_NAME}'"
      BUILD_JOB="unrecognized!${JOB_NAME}"
      ;;
  esac

  # Convert BUILD_JOBs we recognize into abbreviations
  case ${BUILD_JOB} in
    engineering)
      BUILD_JOB="engr"
      ;;
  esac
}

function set_buildhistory_branch {
  # When we're running with BUILD_JENKINS_SERVER set we assume that buildhistory repo is on gerrit server (needs refs/heads/ prefix)
  [ -n "${BUILD_JENKINS_SERVER}" -a -n "${BUILD_BUILDHISTORY_PUSH_REF_PREFIX}" ] && BUILD_BUILDHISTORY_PUSH_REF_PREFIX="refs/heads/"
  # We need to prefix branch name, because anaconda and gecko have few jobs with the same name
  [ "${BUILD_JENKINS_SERVER}" = "anaconda" -a "${BUILD_BUILDHISTORY_PUSH_REF_PREFIX}" = "refs/heads/" ] && BUILD_BUILDHISTORY_PUSH_REF_PREFIX="${BUILD_BUILDHISTORY_PUSH_REF_PREFIX}anaconda-"
  # default is whole job name
  BUILD_BUILDHISTORY_BRANCH="${JOB_NAME}-${BUILD_NUMBER}"

  # checkouts master, pushes to master - We assume that there won't be two slaves
  # doing official build at the same time, second build will fail to push buildhistory
  # when this assumption is broken.
  [ "${BUILD_JOB}" = "official" ] && BUILD_BUILDHISTORY_BRANCH="master"

  BUILD_BUILDHISTORY_PUSH_REF=${BUILDHISTORY_PUSH_REF_PREFIX}${BUILDHISTORY_BRANCH}
}

TEMP=`getopt -o I:T:M:S:j:J:B:u:bshV --long images:,targets:,machines:,scp-url:,site:,jenkins:,job:,buildhistory-ref:,bom,signatures,help,version \
     -n $(basename $0) -- "$@"`

if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 2 ; fi

# Note the quotes around `$TEMP': they are essential!
eval set -- "$TEMP"

while true ; do
  case $1 in
    -I|--images) IMAGES="$2" ; shift 2 ;;
    -T|--targets) TARGETS="$2" ; shift 2 ;;
    -M|--machines) BMACHINES="$2" ; shift 2 ;;
    -S|--site) BUILD_SITE="$2" ; shift 2 ;;
    -j|--jenkins) BUILD_JENKINS_SERVER="$2" ; shift 2 ;;
    -J|--job) BUILD_JOB="$2" ; shift 2 ;;
    -B|--buildhistory-ref) BUILD_BUILDHISTORY_PUSH_REF="$2" ; shift 2 ;;
    -u|--scp-url) URL="$2" ; shift 2 ;;
    -b|--bom) CREATE_BOM="Y" ; shift ;;
    -s|--signatures) SIGNATURES="Y" ; shift ;;
    -h|--help) showusage ; shift ;;
    -V|--version) echo ${SCRIPT_NAME} ${SCRIPT_VERSION}; exit ;;
    --) shift ; break ;;
    *) echo "${SCRIPT_NAME} Unrecognized option '$1'";
       showusage ;;
  esac
done

# Has mcf been run and generated a makefile?
if [ ! -f "Makefile" ] ; then
  echo "Make sure that mcf has been run and Makefile has been generated"
  exit 2
fi

[ -n "${BUILD_SITE}" -a -n "${BUILD_JENKINS_SERVER}" ] || set_build_site_and_server
[ -n "${BUILD_JOB}" ] || set_build_job
[ -n "${BUILD_BUILDHISTORY_PUSH_REF}" ] || set_buildhistory_branch

if [ -z "${BUILD_SITE}" -o "${BUILD_JENKINS_SERVER}" = "anaconda" ]; then
  # Let the distro determine the policy on setting WEBOS_DISTRO_BUILD_ID when builds
  # are unofficial
  unset WEBOS_DISTRO_BUILD_ID
else
  # If this is an official build, no BUILD_JOB prefix appears in
  # WEBOS_DISTRO_BUILD_ID regardless of the build site.
  if [ "${BUILD_JOB}" = "official" ]; then
    if [ ${BUILD_SITE} = ${AUTHORITATIVE_OFFICIAL_BUILD_SITE} ]; then
      BUILD_SITE=""
    fi
    BUILD_JOB=""
  else
    # BUILD_JOB can not contain any hyphens
    BUILD_JOB="${BUILD_JOB//-/}"
  fi

  # Append the separators to site and build-type.
  #
  # Use intermediate variables so that the remainder of the script need not concern
  # itself with the separators, which are purely related to formatting the build id.
  idsite="${BUILD_SITE}"
  idtype="${BUILD_JOB}"

  if [ -n "$idsite" ]; then
    idsite="${idsite}-"
  fi

  if [ -n "$idtype" ]; then
    idtype="${idtype}."
  fi

  # BUILD_NUMBER should be set by the Jenkins executor
  if [ -z "${BUILD_NUMBER}" ] ; then
    echo "BUILD_SITE is set, but BUILD_NUMBER isn't"
    exit 1
  fi

  # Format WEBOS_DISTRO_BUILD_ID as <build-type>.<site>-<build number>
  export WEBOS_DISTRO_BUILD_ID=${idtype}${idsite}${BUILD_NUMBER}
fi

# Generate BOM files with metadata checked out by mcf (pinned versions)
if [ -n "${CREATE_BOM}" -a -n "${BMACHINES}" ]; then
  print_timestamp "before first bom"
  if [ "${BUILD_JOB}" = "verf" -o "${BUILD_JOB}" = "mlverf" -o "${BUILD_JOB}" = "integ" -o "${BUILD_JOB}" = "engr" -o "${BUILD_JOB}" = "clean" ] ; then
    # don't use -before suffix for official builds, because they don't need -after and .diff because
    # there is no logic for using different revisions than weboslayers.py
    BOM_FILE_SUFFIX="-before"
  fi
  . oe-init-build-env
  for MACHINE in ${BMACHINES}; do
    for I in ${IMAGES} ${TARGETS}; do
      generate_bom "${MACHINE}" "${I}" "${BBFLAGS}" "bom${BOM_FILE_SUFFIX}.txt"
    done
  done
fi

print_timestamp "before verf/engr/clean logic"

if [ "${BUILD_JOB}" = "verf" -o "${BUILD_JOB}" = "mlverf" -o "${BUILD_JOB}" = "integ" -o "${BUILD_JOB}" = "engr" ] ; then
  if [ "$GERRIT_PROJECT" != "${BUILD_REPO}" ] ; then
    set -e # checkout issues are critical for verification and engineering builds
    for project in "${BUILD_LAYERS[@]}" ; do
      check_project ${project}
    done
    set +e
  fi
  # use -k for verf and engr builds, see [ES-85]
  BBFLAGS="${BBFLAGS} -k"
fi

if [ "${BUILD_JOB}" = "clean" ] ; then
  set -e # checkout issues are critical for clean build
  desc="[DESC]"
  for project in "${BUILD_LAYERS[@]}" ; do
    desc="${desc}`check_project_vars ${project}`"
  done
  # This is picked by regexp in jenkins config as description of the build
  echo $desc
  set +e
fi

# Generate BOM files again, this time with metadata possibly different for engineering and verification builds
if [ -n "${CREATE_BOM}" -a -n "${BMACHINES}" ]; then
  if [ "${BUILD_JOB}" = "verf" -o "${BUILD_JOB}" = "mlverf" -o "${BUILD_JOB}" = "integ" -o "${BUILD_JOB}" = "engr" -o "${BUILD_JOB}" = "clean" ] ; then
    print_timestamp "before 2nd bom"
    . oe-init-build-env
    for MACHINE in ${BMACHINES}; do
      for I in ${IMAGES} ${TARGETS}; do
        generate_bom "${MACHINE}" "${I}" "${BBFLAGS}" "bom-after.txt"
        diff ${ARTIFACTS}/${MACHINE}/${I}/bom-before.txt \
             ${ARTIFACTS}/${MACHINE}/${I}/bom-after.txt \
           > ${ARTIFACTS}/${MACHINE}/${I}/bom-diff.txt
      done
    done
  fi
fi

print_timestamp "before signatures"

if [ -n "${SIGNATURES}" -a -n "${BMACHINES}" ]; then
  . oe-init-build-env
  oe-core/scripts/sstate-diff-machines.sh --tmpdir=. --targets="${IMAGES} ${TARGETS}" --machines="${BMACHINES}"
  for MACHINE in ${BMACHINES}; do
    mkdir -p "${ARTIFACTS}/${MACHINE}" || true
    tar cjf ${ARTIFACTS}/${MACHINE}/sstate-diff.tar.bz2 sstate-diff/*/${MACHINE} --remove-files
  done
fi

# If there is git checkout in buildhistory dir and we have BUILD_BUILDHISTORY_PUSH_REF
# add or replace push repo in webos-local
# Write it this way so that BUILDHISTORY_PUSH_REPO is kept in the same place in webos-local.conf
if [ -d "buildhistory/.git" -a -n "${BUILD_BUILDHISTORY_PUSH_REF}" ] ; then
  if [ -f webos-local.conf ] && grep -q ^BUILDHISTORY_PUSH_REPO webos-local.conf ; then
    sed "s#^BUILDHISTORY_PUSH_REPO.*#BUILDHISTORY_PUSH_REPO ?= \"origin master:${BUILD_BUILDHISTORY_PUSH_REF} 2>/dev/null\"#g" -i webos-local.conf
  else
    echo "BUILDHISTORY_PUSH_REPO ?= \"origin master:${BUILD_BUILDHISTORY_PUSH_REF} 2>/dev/null\"" >> webos-local.conf
  fi
  echo "INFO: buildhistory will be pushed to '${BUILD_BUILDHISTORY_PUSH_REF}'"
else
  [ -f webos-local.conf ] && sed "/^BUILDHISTORY_PUSH_REPO.*/d" -i webos-local.conf
  echo "INFO: buildhistory won't be pushed because buildhistory directory isn't git repo or BUILD_BUILDHISTORY_PUSH_REF wasn't set"
fi

print_timestamp "before main '${JOB_NAME}' build"

FIRST_IMAGE=
if [ -z "${BMACHINES}" ]; then
  echo "ERROR: calling build.sh without -M parameter"
else
  . oe-init-build-env
  for MACHINE in ${BMACHINES}; do
    /usr/bin/time -f "$TIME_STR" bitbake ${BBFLAGS} ${IMAGES} ${TARGETS} 2>&1 | tee /dev/stderr | grep '^TIME:' >> ${BUILD_TIME_LOG}

    # Be aware that non-zero exit code from bitbake doesn't always mean that images weren't created.
    # All images were created if it shows "all succeeded" in" Tasks Summary":
    # NOTE: Tasks Summary: Attempted 5450 tasks of which 5205 didn't need to be rerun and all succeeded.

    # Sometimes it's followed by:
    # Summary: There were 2 ERROR messages shown, returning a non-zero exit code.
    # the ERRORs can be from failed setscene tasks or from QA checks, but weren't fatal for build.

    # Collect exit codes to return them from this script (Use PIPESTATUS to read return code from bitbake, not from added tee)
    RESULT+=${PIPESTATUS[0]}

    for I in ${IMAGES}; do
      mkdir -p "${ARTIFACTS}/${MACHINE}/${I}" || true
      # we store only tar.gz, vmdk.zip and .epk images
      # and we don't publish kernel images anymore
      if ls BUILD/deploy/images/${MACHINE}/${I}-${MACHINE}-*.vmdk >/dev/null 2>/dev/null; then
        if type zip >/dev/null 2>/dev/null; then
          # zip vmdk images if they exists
          find BUILD/deploy/images/${MACHINE}/${I}-${MACHINE}-*.vmdk -exec zip -j {}.zip {} \; || true
          mv BUILD/deploy/images/${MACHINE}/${I}-${MACHINE}-*.vmdk.zip ${ARTIFACTS}/${MACHINE}/${I}/ || true
        else
          # report failure and publish vmdk
          RESULT+=1
          mv BUILD/deploy/images/${MACHINE}/${I}-${MACHINE}-*.vmdk ${ARTIFACTS}/${MACHINE}/${I}/ || true
        fi
        # copy webosvbox if we've built vmdk image
        cp meta-webos/scripts/webosvbox ${ARTIFACTS}/${MACHINE} || true
        # copy few more files for creating different vmdk files with the same rootfs
        mv BUILD/deploy/images/${MACHINE}/${I}-${MACHINE}-*.rootfs.ext3 ${ARTIFACTS}/${MACHINE}/${I}/ || true
        cp BUILD/sysroots/${MACHINE}/usr/lib/syslinux/mbr.bin ${ARTIFACTS}/${MACHINE}/${I}/ || true
        # this won't work in jobs which inherit rm_work, but until we change the image build to stage them use WORKDIR paths
        cp BUILD/work/${MACHINE}*/${I}/*/*/hdd/boot/ldlinux.sys ${ARTIFACTS}/${MACHINE}/${I}/ 2>/dev/null || echo "INFO: ldlinux.sys doesn't exist, probably using rm_work"
        cp BUILD/work/${MACHINE}*/${I}/*/*/hdd/boot/syslinux.cfg ${ARTIFACTS}/${MACHINE}/${I}/ 2>/dev/null || echo "INFO: syslinux.cfg doesn't exist, probably using rm_work"
        cp BUILD/work/${MACHINE}*/${I}/*/*/hdd/boot/vmlinuz ${ARTIFACTS}/${MACHINE}/${I}/ 2>/dev/null || echo "INFO: vmlinuz doesn't exist, probably using rm_work"
      elif ls BUILD/deploy/images/${MACHINE}/${I}-${MACHINE}-*.tar.gz >/dev/null 2>/dev/null \
        || ls BUILD/deploy/images/${MACHINE}/${I}-${MACHINE}-*.epk    >/dev/null 2>/dev/null; then
        if ls BUILD/deploy/images/${MACHINE}/${I}-${MACHINE}-*.tar.gz >/dev/null 2>/dev/null; then
          mv  BUILD/deploy/images/${MACHINE}/${I}-${MACHINE}-*.tar.gz ${ARTIFACTS}/${MACHINE}/${I}/
        fi
        if ls BUILD/deploy/images/${MACHINE}/${I}-${MACHINE}-*.epk >/dev/null 2>/dev/null; then
          mv  BUILD/deploy/images/${MACHINE}/${I}-${MACHINE}-*.epk ${ARTIFACTS}/${MACHINE}/${I}/
        fi
      elif ls BUILD/deploy/sdk/${I}-*.sh >/dev/null 2>/dev/null; then
        mv    BUILD/deploy/sdk/${I}-*.sh ${ARTIFACTS}/${MACHINE}/${I}/
      else
        echo "WARN: No recognized IMAGE_FSTYPES to copy to build artifacts"
      fi
      FOUND_IMAGE="false"
      # Add .md5 files for image files, if they are missing or older than image file
      for IMG_FILE in ${ARTIFACTS}/${MACHINE}/${I}/*.vmdk* ${ARTIFACTS}/${MACHINE}/${I}/*.tar.gz ${ARTIFACTS}/${MACHINE}/${I}/*.epk ${ARTIFACTS}/${MACHINE}/${I}/*.sh; do
        if echo $IMG_FILE | grep -q "\.md5$"; then
          continue
        fi
        if [ -e ${IMG_FILE} -a ! -h ${IMG_FILE} ] ; then
          FOUND_IMAGE="true"
          if [ ! -e ${IMG_FILE}.md5 -o ${IMG_FILE}.md5 -ot ${IMG_FILE} ] ; then
            echo MD5: ${IMG_FILE}
            md5sum ${IMG_FILE} | sed 's#  .*/#  #g' > ${IMG_FILE}.md5
          fi
        fi
      done

      # copy few interesting buildhistory reports only if the image was really created
      # (otherwise old report from previous build checked out from buildhistory repo could be used)
      if [ "${FOUND_IMAGE}" = "true" ] ; then
        # XXX Might there be other subdirectories under buildhistory/sdk that weren't created by this build?
        if ls buildhistory/sdk/*/${I} >/dev/null 2>/dev/null; then
          # Unfortunately, the subdirectories under buildhistory/sdk are <target>-<TUNE_PKGARCH>
          for d in buildhistory/sdk/*; do
            target_tunepkgarch=$(basename $d)
            mkdir -p ${ARTIFACTS}/$target_tunepkgarch/
            cp -a $d/${I} ${ARTIFACTS}/$target_tunepkgarch/
          done
        else
          if [ -f buildhistory/images/${MACHINE}/eglibc/${I}/build-id.txt ]; then
            cp buildhistory/images/${MACHINE}/eglibc/${I}/build-id.txt ${ARTIFACTS}/${MACHINE}/${I}/build-id.txt
          else
            cp buildhistory/images/${MACHINE}/eglibc/${I}/build-id ${ARTIFACTS}/${MACHINE}/${I}/build-id.txt
          fi
          if [ -z "$FIRST_IMAGE" ] ; then
            # store build-id.txt from first IMAGE and first MACHINE as representant of whole build for InfoBadge
            # instead of requiring jenkins job to hardcode MACHINE/IMAGE name in:
            # manager.addInfoBadge("${manager.build.getWorkspace().child('buildhistory/images/qemux86/eglibc/webos-image/build-id.txt').readToString()}")
            # we should be able to use:
            # manager.addInfoBadge("${manager.build.getWorkspace().child('BUILD-ARTIFACTS/build-id.txt').readToString()}")
            # in all builds (making BUILD_IMAGES/BUILD_MACHINE changes less error-prone)
            FIRST_IMAGE="${MACHINE}/${I}"
            cp ${ARTIFACTS}/${MACHINE}/${I}/build-id.txt ${ARTIFACTS}/build-id.txt
          fi
          cp buildhistory/images/${MACHINE}/eglibc/${I}/image-info.txt ${ARTIFACTS}/${MACHINE}/${I}/image-info.txt
          cp buildhistory/images/${MACHINE}/eglibc/${I}/files-in-image.txt ${ARTIFACTS}/${MACHINE}/${I}/files-in-image.txt
          cp buildhistory/images/${MACHINE}/eglibc/${I}/installed-packages.txt ${ARTIFACTS}/${MACHINE}/${I}/installed-packages.txt
          cp buildhistory/images/${MACHINE}/eglibc/${I}/installed-package-sizes.txt ${ARTIFACTS}/${MACHINE}/${I}/installed-package-sizes.txt
          if [ -e buildhistory/images/${MACHINE}/eglibc/${I}/installed-package-file-sizes.txt ] ; then
            cp buildhistory/images/${MACHINE}/eglibc/${I}/installed-package-file-sizes.txt ${ARTIFACTS}/${MACHINE}/${I}/installed-package-file-sizes.txt
          fi
        fi
      fi
    done
  done

  grep "Elapsed time" buildstats/*/*/*/* | sed 's/^.*\/\(.*\): Elapsed time: \(.*\)$/\2 \1/g' | sort -n | tail -n 20 | tee -a ${ARTIFACTS}/top20buildstats.txt
  tar cjf ${ARTIFACTS}/buildstats.tar.bz2 BUILD/buildstats
  if [ -e BUILD/qa.log ]; then
    cp BUILD/qa.log ${ARTIFACTS} || true
    # show them in console log so they are easier to spot (without downloading qa.log from artifacts
    echo "WARN: Following QA issues were found:"
    cat BUILD/qa.log
  else
    echo "NOTE: No QA issues were found."
  fi
  cp BUILD/WEBOS_BOM_data.pkl ${ARTIFACTS} || true
  if [ -d BUILD/deploy/sources ] ; then
    # exclude diff.gz files, because with old archiver they contain whole source (nothing creates .orig directory)
    # see http://lists.openembedded.org/pipermail/openembedded-core/2013-December/087729.html
    tar czf ${ARTIFACTS}/sources.tar.gz BUILD/deploy/sources --exclude \*.diff.gz
  fi
fi

print_timestamp "before package-src-uris"

# Generate list of SRC_URI and SRCREV values for all components
echo "NOTE: generating package-srcuris.txt"
BUILDHISTORY_PACKAGE_SRCURIS="package-srcuris.txt"
./meta-webos/scripts/buildhistory-collect-srcuris buildhistory >${BUILDHISTORY_PACKAGE_SRCURIS}
./oe-core/scripts/buildhistory-collect-srcrevs buildhistory >>${BUILDHISTORY_PACKAGE_SRCURIS}
cp ${BUILDHISTORY_PACKAGE_SRCURIS} ${ARTIFACTS} || true

print_timestamp "before baselines"

# Don't do these for unofficial builds
if [ -n "${WEBOS_DISTRO_BUILD_ID}" -a "${RESULT}" -eq 0 ]; then
  if [ ! -f latest_project_baselines.txt ]; then
    # create dummy, especially useful for verification builds (diff against origin/master)
    echo ". origin/master" > latest_project_baselines.txt
    for project in "${BUILD_LAYERS[@]}" ; do
      layer=`basename ${project}`
      if [ -d "${layer}" ] ; then
        echo "${layer} origin/master" >> latest_project_baselines.txt
      fi
    done
  fi

  command \
    meta-webos/scripts/build-changes/update_build_changes.sh \
      "${BUILD_NUMBER}" \
      "${URL}" 2>&1 || printf "\nChangelog generation failed or script not found.\nPlease check lines above for errors\n"
  cp build_changes.log ${ARTIFACTS} || true
fi

print_timestamp "stop"

cd "${CALLDIR}"

# only the result from bitbake/make is important
exit ${RESULT}

# vim: ts=2 sts=2 sw=2 et
