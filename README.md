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
gcm build
gcm test
```
Because nobody has time for that, this project also has gcmshort.sh.  To use gcmshort.sh, source it after sourcing gcm.sh.  It is recommended that before installing gcmshort.sh, you already have at least one project with one branch set up.  The reason is that gcmshort.sh assumes that you want to instantly start working on a specific project.  Upon being sourced, gcmshort.sh will look for a GCMSHORT_DEFAULT_PROJ environment variable to determine what that specific project is.
```
echo "GCMSHORT_DEFAULT_PROJ=llvm" >> ~/.bashrc
echo ". ~/gcm_repo/gcmshort.sh" >> ~/.bashrc
```
This will have a more invasive impact upon your environment, primarily due to creating a number of commands.  For example:
```
new-proj projectname
new-branch branchname # Assumes the current project
cont-branch branchname # Assumes the current project
branch-build
branch-test
```
## Configuring a Project
### Initializing repo
TODO
### The skel Directory
TODO
## Configuring a Branch
TODO
