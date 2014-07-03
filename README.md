build-webos
===========

Summary
-------
Build Open webOS images

Description
-----------
This repository contains the top level code that aggregates the various [OpenEmbedded](http://openembedded.org) layers into a whole from which Open webOS images can be built.

Cloning
=======
To access Git repositories, you may need to register your SSH key with GitHub. For help on doing this, visit [Generating SSH Keys] (https://help.github.com/articles/generating-ssh-keys).

Set up build-webos by cloning its Git repository:

     git clone https://github.com/openwebos/build-webos.git

Note: If you populate it by downloading an archive (zip or tar.gz file), then you will get the following error when you run mcf:

     fatal: Not a git repository (or any parent up to mount parent).
     Stopping at filesystem boundary (GIT_DISCOVERY_ACROSS_FILESYTEM not set).


Prerequisites
=============
Before you can build, you will need some tools.  If you try to build without them, bitbake will fail a sanity check and tell you what's missing, but not really how to get the missing pieces. On Ubuntu, you can force all of the missing pieces to be installed by entering:

    $ sudo scripts/prerequisites.sh

Also, the bitbake sanity check will issue a warning if you're not running under Ubuntu 11.04 or 12.04.1 LTS, either 32-bit or 64-bit.


Building
========
To configure the build for the qemux86 emulator and to fetch the sources:

    $ ./mcf -p 0 -b 0 qemux86

The `-p 0` and `-b 0` options set the make and bitbake parallelism values to the number of CPU cores found on your computer.

To kick off a full build of Open webOS, make sure you have at least 40GB of disk space available and enter the following:

    $ make webos-image

This may take in the neighborhood of two hours on a multi-core workstation with a fast disk subsystem and lots of memory, or many more hours on a laptop with less memory and slower disks or in a VM.


Running
=======
To run the resulting build in the qemux86 emulator, enter:

    $ cd BUILD-qemux86
    $ source bitbake.rc
    $ runqemu webos-image qemux86 qemuparams="-m 512" kvm serial

You will be prompted by sudo for a password:

    Assuming webos-image really means .../BUILD-qemux86/deploy/images/webos-image-qemux86.ext3
    Continuing with the following parameters:
    KERNEL: [.../BUILD-qemux86/deploy/images/bzImage-qemux86.bin]
    ROOTFS: [.../BUILD-qemux86/deploy/images/webos-image-qemux86.ext3]
    FSTYPE: [ext3]
    Setting up tap interface under sudo
    [sudo] password for <user>:

A window entitled QEMU will appear with a login prompt. Don't do anything. A bit later, the Open webOS lock screen will appear. Use your mouse to drag up the yellow lock icon. Welcome to (emulated) Open webOS!

To go into Card View after launching an app, press your keyboard’s `HOME` key.

To start up a console on the emulator, don't attempt to login at the prompt that appears in the console from which you launched runqemu. Instead, ssh into it as root (no password):

    $ ssh root@192.168.7.2
    root@192.168.7.2's password:
    root@qemux86:~#

Each new image appears to ssh as a new machine with the same IP address as the previous one. ssh will therefore warn you of a potential "man-in-the-middle" attack and not allow you to connect. To resolve this, remove the stale ssh key by entering:

    $ ssh-keygen -f ~/.ssh/known_hosts -R 192.168.7.2

then re-enter the ssh command.

To shut down the emulator, startup a console and enter:

    root@qemux86:~# halt

The connection will be dropped:

    Broadcast message from root@qemux86
	(/dev/pts/0) at 18:39 ...

    The system is going down for halt NOW!
    Connection to 192.168.7.2 closed by remote host.
    Connection to 192.168.7.2 closed.

and the QEMU window will close. (If this doesn't happen, just close the QEMU window manually.) Depending on how long your emulator session lasted, you may be prompted again by sudo for a password:

    [sudo] password for <user>:
    Set 'tap0' nonpersistent
    Releasing lockfile of preconfigured tap device 'tap0'


Images
======
The following images can be built:

- `webos-image`: The production Open webOS image.
- `webos-image-devel`: Adds various development tools to `webos-image`, including gdb and strace. See `packagegroup-core-tools-debug` and `packagegroup-core-tools-profile` in `oe-core` and `packagegroup-webos-test` in `meta-webos` for the complete list.


Cleaning
========
To blow away the build artifacts and prepare to do clean build, you can remove the build directory and recreate it by typing:

    $ rm -rf BUILD-qemux86
    $ ./mcf.status

What this retains are the caches of downloaded source (under `./downloads`) and shared state (under `./sstate-cache`). These caches will save you a tremendous amount of time during development as they facilitate incremental builds, but can cause seemingly inexplicable behavior when corrupted. If you experience strangeness, use the command presented below to remove the shared state of suspicious components. In extreme cases, you may need to remove the entire shared state cache. See [here](http://www.yoctoproject.org/docs/latest/poky-ref-manual/poky-ref-manual.html#shared-state-cache) for more information on it.


Building Individual Components
==============================
To build an individual component, enter:

    $ make <component-name>

To clean a component's build artifacts under BUILD-qemux86, enter:

    $ make clean-<component-name>

To remove the shared state for a component as well as its build artifacts to ensure it gets rebuilt afresh from its source, enter:

    $ make cleanall-<component-name>

Adding new layers
=================
The script automates the process of adding new OE layers to the build environment.  The information required for integrate new layer are; layer name, OE priority, repository, identification in the form branch, commit or tag ids. It is also possible to reference a layer from local storage area.  The details are documented in weboslayers.py.

Copyright and License Information
=================================
Unless otherwise specified, all content, including all source code files and
documentation files in this repository are:

Copyright (c) 2008-2013 LG Electronics, Inc.

Unless otherwise specified or set forth in the NOTICE file, all content,
including all source code files and documentation files in this repository are:
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this content except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
