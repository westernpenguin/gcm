#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: test.sh [gcm file]";
    exit 1;
fi

GCM_FILE=$1

#------------------------------------------------------------------------------
# Helper routines for testing
#------------------------------------------------------------------------------
check_dir()
{
    local dir=$1;

    echo -n "? Ensuring that $dir exists...";

    if [ ! -d "$dir" ]; then
        echo "FAIL";
        exit 1;
    else
        echo "PASS";
        return 0;
    fi
}

check_not_dir()
{
    local dir=$1;

    echo -n "? Ensuring that $dir DOESN'T exist...";

    if [ -d "$dir" ]; then
        echo "FAIL";
        exit 1;
    else
        echo "PASS";
        return 0;
    fi
}

check_file()
{
    local file=$1;

    echo -n "? Ensuring that $file exists...";

    if [ ! -f "$file" ]; then
        echo "FAIL";
        exit 1;
    else
        echo "PASS";
        return 0;
    fi
}

check_not_file()
{
    local file=$1;

    echo -n "? Ensuring that $file DOESN'T exist...";

    if [ -f "$file" ]; then
        echo "FAIL";
        exit 1;
    else
        echo "PASS";
        return 0;
    fi
}

do_and_check()
{
    echo "> $@";
    eval "$@";
    if [ $? -ne 0 ]; then
        echo "Command failed.";
        exit 1;
    fi
    return 0;
}

print_test_section()
{
    local section=$1;
    echo "=== $section ===";
    return 0;
}

#------------------------------------------------------------------------------
# Source the GCM file with GCM_DIR in current directory.  Check that the
# directory exists.
#------------------------------------------------------------------------------
GCM_DIR=$(pwd)/gcm_test

print_test_section "loading gcm";
check_not_dir "$GCM_DIR";
do_and_check source "$GCM_FILE";
check_dir "$GCM_DIR";
check_dir "$GCM_DIR/proj";

#------------------------------------------------------------------------------
# Test project creation.
#------------------------------------------------------------------------------
print_test_section "new project creation";
do_and_check gcm new-proj test-proj;
check_dir "$GCM_DIR/proj/test-proj";
check_dir "$GCM_DIR/proj/test-proj/branch";
check_dir "$GCM_DIR/proj/test-proj/branch/open";
check_dir "$GCM_DIR/proj/test-proj/branch/closed";
check_dir "$GCM_DIR/proj/test-proj/skel";
check_file "$GCM_DIR/proj/test-proj/skel/build.sh";
do_and_check echo 'echo modified build' >> "$GCM_DIR/proj/test-proj/skel/build.sh"
check_file "$GCM_DIR/proj/test-proj/skel/test.sh";
do_and_check echo 'echo modified test' >> "$GCM_DIR/proj/test-proj/skel/test.sh"
check_file "$GCM_DIR/proj/test-proj/skel/gcmrc";
do_and_check echo "TEST_PROJ_VAR=1" >> "$GCM_DIR/proj/test-proj/skel/gcmrc"
check_dir "$GCM_DIR/proj/test-proj/repo";
check_dir "$GCM_DIR/proj/test-proj/repo/.git";
do_and_check pushd "$GCM_DIR/proj/test-proj/repo"
do_and_check git remote add origin https://github.com/westernpenguin/gcm.git
do_and_check git fetch
do_and_check git checkout master
do_and_check popd

#------------------------------------------------------------------------------
# Test project entry.
#------------------------------------------------------------------------------
print_test_section "project entry";
do_and_check gcm enter-proj test-proj
do_and_check [ $(pwd) = $(realpath "$GCM_DIR/proj/test-proj") ]

#------------------------------------------------------------------------------
# Test project branch creation.
#------------------------------------------------------------------------------
print_test_section "branch creation";
do_and_check gcm new-branch test-proj test-branch
check_dir "$GCM_DIR/proj/test-proj/branch/open/test-branch";

#------------------------------------------------------------------------------
# Test project branch entry
#------------------------------------------------------------------------------
print_test_section "branch continuation"
do_and_check gcm cont-branch test-proj test-branch
do_and_check  [ ! -z $TEST_PROJ_VAR ]
do_and_check [ $(pwd) = $(realpath "$GCM_DIR/proj/test-proj/branch/open/test-branch") ]
check_dir "repo/.git"
do_and_check pushd repo;
do_and_check [ $(git rev-parse --abbrev-ref HEAD) = "test-branch" ]
do_and_check popd;
do_and_check "RES=\"$(gcm build)\"";
do_and_check [ $(echo "$RES" | grep -e "modified build" | wc -l) -eq 1 ]
do_and_check "RES=\"$(gcm test)\"";
do_and_check [ $(echo "$RES" | grep -e "modified test" | wc -l) -eq 1 ]

#------------------------------------------------------------------------------
# Test project branch close
#------------------------------------------------------------------------------
print_test_section "branch closing";
do_and_check gcm close-branch test-proj test-branch
check_not_dir "$GCM_DIR/proj/test-proj/branch/open/test-branch";
check_file "$GCM_DIR/proj/test-proj/branch/closed/test-branch.tar.gz";
do_and_check pushd "$GCM_DIR/proj/test-proj/branch/closed";
do_and_check tar -xzf test-branch.tar.gz;
do_and_check rm -fR test-branch;

#------------------------------------------------------------------------------
# Cleanup.
#------------------------------------------------------------------------------
echo "All tests executed successfully.";
rm -fR "$GCM_DIR";
exit 0;
