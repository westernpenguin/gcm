# Git Collateral Manager
## Overview
Git Collateral Manager (gcm) provides bash functions to create git repositories and branches with associated directories, environment configuration files, and scripts.
## Who, why, and how
Git ~~Crap~~ Collateral Manager is designed for developers who work primarily at the command line, especially when that work is spread across multiple repositories/projects and branches and leaves tons of ~~crap~~ collateral everywhere.

Every project has its own way of being built.  Perhaps you just call `make`; perhaps you call `cmake`; or perhaps you do five different calls with seven environment variables set and with nineteen options passed.  Testing is in all likelihood worse.  So what do we do?  We stick a ton of project specific stuff in our .bashrc and start creating scripts in random places.  We create random directories to house our test inputs and outputs.  Gcm's purpose it to organize that ~~crap~~ collateral such that you can simply type `branch-build` or `branch-test` while controlling how much junk is in your initial environment.

If you already have a system of organization that you actually stick to or don't use bash, this project will probably not be useful to you.  However, if you are like me and always end up with a mess, continue reading.
## Installation
Installation is as simple as sourcing gcm.sh in your .bashrc.  Do not execute gcm.sh.  Upon being sourced, gcm will look for a GCM_DIR environment variable to determine where to work.  This variable will default to ~/gcm.  Simply point it to a location where you have space to work.
```
echo "GCM_DIR=/mnt/wideopenspaces/gcm" >> ~/.bashrc
echo ". ~/gcm_repo/gcm.sh" >> ~/.bashrc
```
You may also use the GCM_SET_PS variable to allow gcm to override your default PS variables for projects and branches.
```
echo "GCM_SET_PS=1" >> ~/.bashrc
```
This is enough to get you going.  It provides the `gcm` command along with autocompletion.  However, these commands tend to be very long and very specific.  For example:
```
gcm new-proj projectname
gcm new-branch projectname branchname
gcm cont-branch projectname branchname
gcm build # Assumes the current project and branch
gcm test # Assumes the current project and branch
```
Because nobody has time for that, this project also has gcmshort.sh, which provides shortcut commands.  To use gcmshort.sh, source it after sourcing gcm.sh.  It is recommended that before installing gcmshort.sh, you already have at least one project with one branch set up.  The reason is that gcmshort.sh assumes that you want to instantly start working on a specific project.  Upon being sourced, gcmshort.sh will look for a GCMSHORT_DEFAULT_PROJ environment variable to determine what that specific project is.
```
echo "GCMSHORT_DEFAULT_PROJ=llvm" >> ~/.bashrc
echo ". ~/gcm_repo/gcmshort.sh" >> ~/.bashrc
```
This will have a more invasive impact upon your environment, primarily due to creating a number of commands.  For example:
```
new-proj projectname
new-branch branchname # Assumes the current project
cont-branch branchname # Assumes the current project
branch-build # Assumes the current project and branch
branch-test # Assumes the current project and branch
```
## Configuring a Project
Starting a new project name ``foo`` is simple:
```
gcm new-proj foo
```
This will generate the project's folder.  To enter that directory and begin configuration, use the command:
```
gcm enter-proj foo
```
Upon entry, you will see the file ``branch_start`` and three folders: ``branch``, ``repo``, and ``skel``.  ``branch`` will ultimately contain collateral for branches you create and should generally not be interacted with directly.
### Initializing repo
Once in the project folder, the first thing that should generally be done is initializing the git repository.  In most cases, this simply means adding a remote and fetching:
```
gcm enter-proj foo
cd repo
git remote add origin https://github.com/path/to/foo.git
git fetch
```
### The skel Directory
The skeleton directory ``skel`` is similar in concept to the ``/etc/skel`` directory on many UNIX and UNIX-like systems such as Ubuntu.  Where on a GNU/Linux system, this directory is used as a template for any new user and is copied to create a home directory, ``skel`` is used as a template for any new branch and is copied to create a new branch.  Edit the contents of ``skel`` in any way you see fit, but preserve the existance of any files that are already present.  (These are required by GCM itself.)
```
gcm enter-proj foo
cd skel
```
Let's make some changes for our hypothetical project ``foo`` in the below sections for any future branches.
#### gcmrc
Similar in concept to the ``.bashrc`` that we were appending to earlier, a branch's ``gcmrc`` is sourced when a branch is entered to modify the bash environment.  This could include things like modifying the environment's ``PATH`` or adding additional bash functions.  Let's suppose that on any branch of ``foo``, we need the environment variable ``BAR`` set to 1 and export it.  Then we would add the lines:
```
export BAR=1
```
to gcmrc.  Because this file is in the ``skel`` directory, this file will be copied to each branch and each branch can tweak the contents.  As such, it may be most useful to leave helpful comments about what is happening:
```
# Set BAR to 1 to use the warp drive when building and cleaning.
# Set BAR to 0 to build and clean with impulse power only.
export BAR=1
```
#### build.sh
The ``build.sh`` file is executed by the command ``gcm build``.  This is where we will place our build commands.  Let us suppose that for our project ``foo`` that we can do an out-of-branch build of the repository.  First, we can create a ``build`` directory in ``skel`` where the build output will be placed:
```
mkdir build
```
We might edit our ``build.sh`` to look something like:
```
#!/bin/bash
set -x
set -e
make -C repo -j$(nproc) BUILD_DIR=build
```
Salt and pepper to taste.  Because this file is in the ``skel`` directory, this file will be copied to each branch and each branch can tweak the contents.  As such, it may be useful to leave comments and alternate build methods:
```
#!/bin/bash
set -x
set -e
cd build
# Build only the baz target with debug
# make -C repo -j$(nproc) BUILD_DIR=build BUILD_TYPE=debug baz
# Do a full build
make -C repo -j$(nproc) BUILD_DIR=build
```
#### test.sh
The ``test.sh`` file is executed by the command ``gcm test``.  This is where we will place our testing commands.  Let us suppose that for our project ``foo`` that we have a testing target built into the repository.  Furthermore, let us suppose that the testing target needs a directory to work in.  First, we create a ``test`` directory in ``skel`` where the testing output will be placed:
```
mkdir test
```
We might edit our ``test.sh`` to look something like:
```
#!/bin/bash
set -x
set -e
make -C repo -j$(nproc) BUILD_DIR=build TEST_DIR=test test_all
```
Add ketchup and mustard to taste.  Because this file is in the ``skel`` directory, this file will be copied to each branch and each branch can tweak the contents.  As such, it may be useful to leave comments and alternative test methods:
```
#!/bin/bash
set -x
set -e
# Test only the baz target with debug
# make -C repo -j$(nproc) BUILD_DIR=build TEST_DIR=test test_baz
# Do a full test
make -C repo -j$(nproc) BUILD_DIR=build TEST_DIR=test test_all
```
### The branch_start file
The ``branch_start`` file is a one line declaration of where you like branches to start at.  This is usually a moving target such as a branch name.  By default, it contains ``master``.  This can easily be something else such as ``origin/master`` or ``origin/stable``.  This name is fed directly into git.  As such, any name that makes sense in git, even tag names or SHAs may be placed here.
## Configuring a Branch
Once your project is configured, you are ready to create a branch.  Let's suppose that for our project ``foo``, we want to create branch ``feature_1``.  Then we would execute:
```
gcm new-branch foo feature_1
```
To go to the branch directory and configure the environment, including changing the git branch, use:
```
gcm cont-branch foo feature_1
```
To go to the branch directory and configure the environment, but **not** change the git branch, use:
```
gcm enter-branch foo feature_1
```
At this point, you are free to modify ``gcmrc``, ``build.sh``, and ``test.sh`` in ways that our fitting for your branch in particular.  Remember, these are copies of those files and your changes here won't affect other branches.  This folder is a good place to put any collateral associated with your branch such as toy test cases and notes.  To build from any location, use the command ``gcm build``.  To test from any location, use the command ``gcm clean``.
## GCM Command Reference
TODO
## GCMShort Command Reference
TODO
