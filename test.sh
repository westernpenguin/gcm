#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: test.sh [gcm file]";
    exit 1;
fi

GCM_FILE=$1

#------------------------------------------------------------------------------
# Source the GCM file with GCM_DIR in current directory.  Check that the
# directory exists.
#------------------------------------------------------------------------------
GCM_DIR=$(pwd)/gcm_test

if [ -d "$GCM_DIR" ]; then
    echo "GCM_DIR already exists!";
    exit 1;
fi

. "$GCM_FILE"

echo "Ensuring $GCM_DIR exists.";
if [ ! -d "$GCM_DIR" ]; then
    echo "Failed to create $GCM_DIR";
    exit 1;
fi

echo "Ensuring $GCM_DIR/proj exists.";
if [ ! -d "$GCM_DIR/proj" ]; then
    echo "Failed to create $GCM_DIR/proj";
    exit 1;
fi

#------------------------------------------------------------------------------
# Test project creation.
#------------------------------------------------------------------------------
echo "Testing new project creation."
gcm new-proj test-proj
if [ $? -ne 0 ]; then
    echo "gcm new-proj failed.";
    exit 1;
fi
if [ ! -d "$GCM_DIR/proj/test-proj" ]; then
    echo "Failed to create project directory.";
    exit 1;
fi
if [ ! -d "$GCM_DIR/proj/test-proj/branch" ]; then
    echo "Failed to create project branch directory.";
    exit 1;
fi
if [ ! -d "$GCM_DIR/proj/test-proj/branch/open" ]; then
    echo "Failed to create project branch open directory.";
    exit 1;
fi
if [ ! -d "$GCM_DIR/proj/test-proj/branch/closed" ]; then
    echo "Failed to create project branch closed directory.";
    exit 1;
fi
if [ ! -d "$GCM_DIR/proj/test-proj/skel" ]; then
    echo "Failed to create project branch skeleton directory.";
    exit 1;
fi
if [ ! -f "$GCM_DIR/proj/test-proj/skel/build.sh" ]; then
    echo "Failed to create project branch skeleton build script.";
    exit 1;
fi
if [ ! -x "$GCM_DIR/proj/test-proj/skel/build.sh" ]; then
    echo "Project branch skeleton build script is not executable.";
    exit 1;
fi
echo 'echo modified build' >> "$GCM_DIR/proj/test-proj/skel/build.sh"
if [ ! -f "$GCM_DIR/proj/test-proj/skel/test.sh" ]; then
    echo "Failed to create project branch skeleton test script.";
    exit 1;
fi
if [ ! -x "$GCM_DIR/proj/test-proj/skel/test.sh" ]; then
    echo "Project branch skeleton test script is not executable.";
    exit 1;
fi
echo 'echo modified test' >> "$GCM_DIR/proj/test-proj/skel/test.sh"
if [ ! -f "$GCM_DIR/proj/test-proj/skel/gcmrc" ]; then
    echo "Failed to create project branch skeleton configuration file.";
    exit 1;
fi
echo "TEST_PROJ_VAR=1" >> "$GCM_DIR/proj/test-proj/skel/gcmrc"
if [ ! -d "$GCM_DIR/proj/test-proj/repo" ]; then
    echo "Failed to create project branch git repository directory.";
    exit 1;
fi
if [ ! -d "$GCM_DIR/proj/test-proj/repo/.git" ]; then
    echo "Failed to initialize project branch git repository.";
    exit 1;
fi
pushd "$GCM_DIR/proj/test-proj/repo" &>/dev/null
git remote add origin https://github.com/westernpenguin/gcm.git
git fetch
git checkout master
popd &>/dev/null

#------------------------------------------------------------------------------
# Test project entry.
#------------------------------------------------------------------------------
echo "Testing project entry."
gcm enter-proj test-proj
if [ $? -ne 0 ]; then
    echo "gcm enter-proj failed.";
    exit 1;
fi
if [ $(pwd) != $(realpath "$GCM_DIR/proj/test-proj") ]; then
    echo "Went into the wrong directory.";
    exit 1;
fi

#------------------------------------------------------------------------------
# Test project branch creation.
#------------------------------------------------------------------------------
echo "Testing new project branch creation."
gcm new-branch test-proj test-branch
if [ $? -ne 0 ]; then
    echo "gcm new-branch failed.";
    exit 1;
fi
if [ ! -d "$GCM_DIR/proj/test-proj/branch/open/test-branch" ]; then
    echo "Failed to create project branch directory.";
    exit 1;
fi

#------------------------------------------------------------------------------
# Test project branch entry
#------------------------------------------------------------------------------
echo "Testing project branch entry."
gcm enter-branch test-proj test-branch
if [ $? -ne 0 ]; then
    echo "gcm enter-branch failed.";
    exit 1;
fi
if [ -z $TEST_PROJ_VAR ]; then
    echo "gcmrc was not sourced.";
    exit 1;
fi
if [ $(pwd) != $(realpath "$GCM_DIR/proj/test-proj/branch/open/test-branch") ]; then
    echo "Went into the wrong directory.";
    exit 1;
fi
if [ ! -d repo/.git ]; then
    echo "Repo is broken.";
    exit 1;
fi
cd repo;
if [ $(git rev-parse --abbrev-ref HEAD) != "test-branch" ]; then
    echo "Not on expected branch.";
    exit 1;
fi
cd ..;
RES=$(gcm build)
if [ $? -ne 0 ]; then
    echo "$RES";
    echo "gcm build failed.";
    exit 1
fi
if [ $(echo "$RES" | grep -e "modified build" | wc -l) != "1" ]; then
    echo "Build command did not generate expected output.";
    exit 1;
fi
RES=$(gcm test)
if [ $? -ne 0 ]; then
    echo "$RES";
    echo "gcm test failed.";
    exit 1
fi
if [ $(echo "$RES" | grep -e "modified test" | wc -l) != "1" ]; then
    echo "Test command did not generate expected output.";
    exit 1;
fi

#------------------------------------------------------------------------------
# Test project branch close
#------------------------------------------------------------------------------
echo "Testing branch closing";
gcm close-branch test-proj test-branch
if [ $? -ne 0 ]; then
    echo "gcm close-branch failed."
    exit 1;
fi
cd "$GCM_DIR/proj/test-proj/branch/open";
if [ -d test-branch ]; then
    echo "Failed to remove branch directory."
    exit 1;
fi
cd ../closed;
if [ ! -f test-branch.tar.gz ]; then
    echo "Failed to create branch archive.";
    exit 1;
fi
tar -xzf test-branch.tar.gz;
if [ ! -d test-branch ]; then
    echo "Tar extraction failed.";
    exit 1;
fi
rm -fR test-branch;

#------------------------------------------------------------------------------
# Cleanup.
#------------------------------------------------------------------------------
echo "All tests executed successfully.";
rm -fR "$GCM_DIR";
exit 0;
