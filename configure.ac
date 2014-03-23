# Process this file with autoconf to produce a configure script.

# Copyright (c) 2008-2014 LG Electronics, Inc.
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

AC_INIT(webos, 0.0)
AC_PREREQ([2.61])
AC_COPYRIGHT([Copyright (c) 2008-2013 LG Electronics, Inc.])
AC_CONFIG_SRCDIR([build-templates/mcf-status.in])

# customization
AC_MSG_CHECKING([customization])
case "$webos_customization" in
"") webos_customization_result="none" ;;
*)
	webos_customization_result=$webos_customization
	webos_customization_feature=":$webos_customization_result"
	;;
esac
AC_SUBST([customization], [$webos_customization])
AC_SUBST([customization_feature], [$webos_customization_feature])
AC_MSG_RESULT([$webos_customization_result])

# parallel_make
AC_MSG_CHECKING([parallel_make])
m4_define([webos_default_parallel_make], [1])
AC_ARG_ENABLE([parallel-make], [AS_HELP_STRING([--enable-parallel-make=N],
		     maximum number of tasks for each submake of bitbake to spawn (default: "webos_default_parallel_make"))],
		     [],
		     [enable_parallel_make="webos_default_parallel_make"])
case "$enable_parallel_make" in
     no|yes) enable_parallel_make=1 ;;
esac
AC_SUBST([parallel_make], [$enable_parallel_make])
AC_MSG_RESULT([$enable_parallel_make])

# bb_number_threads
AC_MSG_CHECKING([bb_number_threads])
m4_define([webos_default_bb_number_threads], [1])
AC_ARG_ENABLE([bb-number-threads], [AS_HELP_STRING([--enable-bb-number-threads=N],
		     maximum number of tasks for each submake of bitbake to spawn (default: "webos_default_bb_number_threads"))],
		     [],
		     [enable_bb_number_threads="webos_default_bb_number_threads"])
case "$enable_bb_number_threads" in
     no|yes) enable_bb_number_threads=1 ;;
esac
AC_SUBST([bb_number_threads], [$enable_bb_number_threads])
AC_MSG_RESULT([$enable_bb_number_threads])

# icecc
AC_MSG_CHECKING([disable-icecc])
AC_ARG_ENABLE([icecc], [AS_HELP_STRING([--disable-icecc],
		     disable build from using icecc (default: "False"))],
		     [case "$enableval" in
yes) disable_icecc="" ;;
no) disable_icecc="1" ;;
esac],
		     [disable_icecc=""])
AC_SUBST([icecc_disable_enable], [$disable_icecc])
AC_MSG_RESULT([$disable_icecc])

AC_MSG_CHECKING([icecc-parallel-make])
m4_define([webos_icecc_parallel_make], [16])
AC_ARG_ENABLE([icecc-parallel-make], [AS_HELP_STRING([--enable-icecc-parallel-make=N],
		     maximum number of threads for distribute make with icecc (default: "webos_icecc_parallel_make"))],
		     [],
		     [enable_icecc_parallel_make="webos_icecc_parallel_make"])
case "$enable_icecc_parallel_make" in
     no|yes) enable_icecc_parallel_make=16 ;;
esac
AC_SUBST([icecc_parallel_make], [$enable_icecc_parallel_make])
AC_MSG_RESULT([$enable_icecc_parallel_make])

AC_MSG_CHECKING([icecc-location])
AC_ARG_ENABLE([icecc-location], [AS_HELP_STRING([--enable-icecc-location=LOCATION],
		     where is the icecc tool location (default: None))],
                     [if test -z "$enableval"; then
                         enable_icecc_location=""
                      else
                         enable_icecc_location="ICECC_PATH ?= \"$enableval\""
                      fi
                     ],
                     [ enable_icecc_location=""])
AC_SUBST([alternative_icecc_installation], [$enable_icecc_location])
AC_MSG_RESULT([$enable_icecc_location])

AC_MSG_CHECKING([icecc-env-exec])
AC_ARG_ENABLE([icecc-env-exec], [AS_HELP_STRING([--enable-icecc-env-exec=LOCATION],
		     where is the icecc environment script location (default: None))],
                     [if test -z "$enableval"; then
                         enable_icecc_env_exec=""
                      else
                         enable_icecc_env_exec="ICECC_ENV_EXEC ?= \"$enableval\""
                      fi
                     ],
                     [ enable_icecc_env_exec=""])
AC_SUBST([icecc_environment_script], [$enable_icecc_env_exec])
AC_MSG_RESULT([$enable_icecc_env_exec])

AC_MSG_CHECKING([icecc-user-package-blacklist])
AC_ARG_ENABLE([icecc-user-package-blacklist], [AS_HELP_STRING([--enable-icecc-user-package-blacklist=LIST],
		     Space separated list of components/recipes to be excluded from building with icecc (default: None))],
                     [if test -z "$enableval"; then
                         enable_icecc_user_package_blacklist=""
                      else
                         enable_icecc_user_package_blacklist="ICECC_USER_PACKAGE_BL ?= \" \\"
                         for pkgname in $enableval; do
                             enable_icecc_user_package_blacklist="$enable_icecc_user_package_blacklist
 $pkgname \\"
                         done
                         enable_icecc_user_package_blacklist="$enable_icecc_user_package_blacklist
\""
                      fi
                     ],
                     [ enable_icecc_user_package_blacklist="" ])
AC_SUBST([icecc_user_package_blacklist], [$enable_icecc_user_package_blacklist])
AC_MSG_RESULT([$enable_icecc_user_package_blacklist])

AC_MSG_CHECKING([icecc-user-class-blacklist])
AC_ARG_ENABLE([icecc-user-class-blacklist], [AS_HELP_STRING([--enable-icecc-user-class-blacklist=LIST],
		     Space separated list of components/recipes class to be excluded from building with icecc (default: None))],
                     [if test -z "$enableval"; then
                         enable_icecc_user_class_blacklist=""
                      else
                         enable_icecc_user_class_blacklist="ICECC_USER_CLASS_BL ?= \" \\"
                         for pkgname in $enableval; do
                             enable_icecc_user_class_blacklist="$enable_icecc_user_class_blacklist
 $pkgname \\"
                         done
                         enable_icecc_user_class_blacklist="$enable_icecc_user_class_blacklist
\""
                      fi
                     ],
                     [ enable_icecc_user_class_blacklist="" ])
AC_SUBST([icecc_user_class_blacklist], [$enable_icecc_user_class_blacklist])
AC_MSG_RESULT([$enable_icecc_user_class_blacklist])

AC_MSG_CHECKING([icecc-user-package-whitelist])
AC_ARG_ENABLE([icecc-user-package-whitelist], [AS_HELP_STRING([--enable-icecc-user-package-whitelist=LIST],
		     Space separated list of components/recipes to force build with icecc (default: None))],
                     [if test -z "$enableval"; then
                         enable_icecc_user_package_whitelist=""
                      else
                         enable_icecc_user_package_whitelist="ICECC_USER_PACKAGE_WL ?= \" \\"
                         for pkgname in $enableval; do
                             enable_icecc_user_package_whitelist="$enable_icecc_user_package_whitelist
 $pkgname \\"
                         done
                         enable_icecc_user_package_whitelist="$enable_icecc_user_package_whitelist
\""
                      fi
                     ],
                     [ enable_icecc_user_package_whitelist="" ])
AC_SUBST([icecc_user_package_whitelist], [$enable_icecc_user_package_whitelist])
AC_MSG_RESULT([$enable_icecc_user_package_whitelist])

# premirror
AC_MSG_CHECKING([premirror])
AC_ARG_ENABLE([premirror], [AS_HELP_STRING([--enable-premirror=PREMIRROR],
		     set PREMIRROR (default: none, own-mirrors class will not be used))],
                     [if test -z "$enableval"; then
                         enable_premirror_assignment=""
                         enable_premirror_inherit=""
                      else
                         enable_premirror_assignment="SOURCE_MIRROR_URL ?= \"$enableval\""
                         enable_premirror_inherit="INHERIT += \"own-mirrors\""
                      fi
                     ],
                     [ enable_premirror_assignment=""
                       enable_premirror_inherit=""
                     ])
AC_SUBST([premirror_assignment], [$enable_premirror_assignment])
AC_SUBST([premirror_inherit], [$enable_premirror_inherit])
AC_MSG_RESULT([$enableval])

# sstate mirror
AC_MSG_CHECKING([sstatemirror])
AC_ARG_ENABLE([sstatemirror], [AS_HELP_STRING([--enable-sstatemirror=SSTATE_MIRROR_URL],
                     set SSTATE_MIRROR_URL (default: none))],
                     [if test -z "$enableval"; then
                         enable_sstatemirror_assignment=""
                      else
                         enable_sstatemirror_assignment="SSTATE_MIRRORS ?= \" \\"
                         for URL in $enableval; do
                           echo "$URL" | grep "/PATH$" && AC_MSG_ERROR([$URL already ends with '/PATH', remove that])
                           echo "$URL" | grep "/$" && AC_MSG_ERROR([$URL ends with '/', remove that])
                           enable_sstatemirror_assignment="$enable_sstatemirror_assignment
  file://.* $URL/PATH \n \\"
                         done
                         enable_sstatemirror_assignment="$enable_sstatemirror_assignment
\""
                      fi
                     ],
                     [ enable_sstatemirror_assignment=""
                     ])
AC_SUBST([sstatemirror_assignment], [$enable_sstatemirror_assignment])
AC_MSG_RESULT([$enableval])

# network
AC_MSG_CHECKING([network])
AC_ARG_ENABLE([network], [AS_HELP_STRING([--enable-network],
		     enable network fetching (default: "True"))],
		     [case "$enableval" in
yes) enable_no_network="0" ;;
no) enable_no_network="1" ;;
esac],
		     [enable_no_network="0"])
AC_SUBST([no_network], [$enable_no_network])
AC_MSG_RESULT([$enable_network])

# fetch-premirror-only
AC_MSG_CHECKING([fetch_premirror_only])
AC_ARG_ENABLE([fetch_premirror_only], [AS_HELP_STRING([--enable-fetch-premirror-only],
		     fetch only from premirror (default: "False"))],
		     [case "$enableval" in
yes) enable_fetchpremirroronly="1" ;;
no) enable_fetchpremirroronly="0" ;;
esac],
		     [enable_fetchpremirroronly="0"])
AC_SUBST([fetchpremirroronly], [$enable_fetchpremirroronly])
AC_MSG_RESULT([$enable_fetchpremirroronly])

# generate-mirror-tarballs
AC_MSG_CHECKING([generate_mirror_tarballs])
AC_ARG_ENABLE([generate_mirror_tarballs], [AS_HELP_STRING([--enable-generate-mirror-tarballs],
		     generate tarballs suitable for mirroring (default: "False"))],
		     [case "$enableval" in
yes) enable_generatemirrortarballs="1" ;;
no) enable_generatemirrortarballs="0" ;;
esac],
		     [enable_generatemirrortarballs="0"])
AC_SUBST([generatemirrortarballs], [$enable_generatemirrortarballs])
AC_MSG_RESULT([$enable_generatemirrortarballs])

# private-internal-component-mirror
AC_MSG_CHECKING([private_internal_component_mirror])
AC_ARG_ENABLE([private_internal_component_mirror], [AS_HELP_STRING([--enable-private-internal-component-mirror],
		     enable private internal component mirror (default: "False"))],
		     [case "$enableval" in
yes) enable_privateinternalcomponentmirror="git://github-mirror.palm.com/openwebos" ;;
no) enable_privateinternalcomponentmirror="git://github.com/openwebos" ;;
esac],
		     [enable_privateinternalcomponentmirror="git://github.com/openwebos"])
AC_SUBST([privateinternalcomponentmirror], [$enable_privateinternalcomponentmirror])
AC_MSG_RESULT([$enableval])

# distro
AC_MSG_CHECKING([distro])
m4_define([webos_default_distro], [webos])
AC_ARG_ENABLE([distro], [AS_HELP_STRING([--enable-distro=DISTRO],
		     specify distro name (default: "webos_default_distro"))],
		     [],
		     [enable_distro="webos_default_distro"])
AC_SUBST([distro], [$enable_distro])
AC_MSG_RESULT([$enable_distro])

# buildhistory
AC_MSG_CHECKING([buildhistory])
AC_ARG_ENABLE([buildhistory], [AS_HELP_STRING([--enable-buildhistory],
		     enable buildhistory to check that versions are not going backward and content of images (default: "True"))],
		     [case "$enableval" in
yes) enable_buildhistory="1"; class_buildhistory="buildhistory" ;;
no) enable_buildhistory="0"; class_buildhistory="" ;;
esac],
		     [enable_buidhistory="1", class_buildhistory="buildhistory"])
AC_SUBST([buildhistory_enabled], [$enable_buildhistory])
AC_SUBST([buildhistory_class], [$class_buildhistory])
AC_MSG_RESULT([$enable_buildhistory])

AC_MSG_CHECKING([buildhistoryauthor])
AC_ARG_ENABLE([buildhistoryauthor], [AS_HELP_STRING([--enable-buildhistoryauthor="webos builder webos@builder.org"],
                     specify author to use in buildhistory git commits (default: none, will use author from git global config))],
                     [if test -z "$enableval"; then
                         enable_buildhistoryauthor_assignment=""
                      else
                         enable_buildhistoryauthor_assignment="BUILDHISTORY_COMMIT_AUTHOR ?= \"$enableval\""
                      fi
                     ],
                     [enable_buildhistoryauthor_assignment=""])
AC_SUBST([buildhistory_author], [$enable_buildhistoryauthor])
AC_SUBST([buildhistory_author_assignment], [$enable_buildhistoryauthor_assignment])
AC_MSG_RESULT([$enable_buildhistoryauthor])

AC_CONFIG_FILES([Makefile:build-templates/Makefile.in])
AC_CONFIG_FILES([bitbake.rc:build-templates/bitbake-rc.in])
AC_CONFIG_FILES([conf/bblayers.conf:build-templates/bblayers-conf.in])
AC_CONFIG_FILES([conf/local.conf:build-templates/local-conf.in])
AC_OUTPUT
