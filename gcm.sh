# Source this file under bash.  DO NOT EXECUTE.

#------------------------------------------------------------------------------
# Figure out where the GCM root directory will be.
#------------------------------------------------------------------------------
if [ -z $GCM_DIR ]; then
    echo "GCM_DIR is unset.  Defaulting to ~/gcm.";
    GCM_DIR=~/gcm;
fi

#------------------------------------------------------------------------------
# Create the root directory and warn if something went wacky.
#------------------------------------------------------------------------------
if [ ! -d "$GCM_DIR" ]; then
    echo "Creating directory $GCM_DIR.";
    mkdir -p "$GCM_DIR";
    if [ $? -ne 0 ]; then
        echo "Failed to make $GCM_DIR.  Engaging improbability drive.";
    fi
fi

#------------------------------------------------------------------------------
# At this point assume the world is sane.  Create subdirectories if they don't
# exist.
#------------------------------------------------------------------------------
mkdir -p "$GCM_DIR/proj"

#==============================================================================
# Git Collateral Manager
#   Command entry point.
#==============================================================================
gcm()
{
    if [ $# -eq 0 ]; then
        echo "Usage: gcm [command]";
        echo "Try 'gcm help' for more information.";
        return 1;
    fi

    local command=$1;

    case $command in
        "new-proj")
            if [ $# -ne 2 ]; then
                echo "new-proj expects 1 argument.";
                return 1;
            fi
            local proj=$2;
            _gcm_newproj "$proj";
            return $?;;
        "enter-proj")
            if [ $# -ne 2 ]; then
                echo "enter-proj expects 1 argument.";
                return 1;
            fi
            local proj=$2;
            _gcm_enterproj "$proj";
            return $?;;
        "new-branch")
            if [ $# -ne 3 ]; then
                echo "new-branch expects 2 arguments.";
                return 1;
            fi
            local proj=$2;
            local branch=$3;
            _gcm_newbranch "$2" "$3";
            return $?;;
        "enter-branch")
            if [ $# -ne 3 ]; then
                echo "enter-branch expects 2 arguments.";
                return 1;
            fi
            local proj=$2;
            local branch=$3;
            _gcm_enterbranch "$2" "$3";
            _return $?;;
        "help") 
            _gcm_help;
            return $?;;
        *)  
            echo "Invalid command \"$1\"";
            return 1;;
    esac
}

_gcm_pushd()
{
    pushd "$1" &>/dev/null;
}

_gcm_popd()
{
    popd &>/dev/null;
}

_gcm_isproj()
{
    local proj=$1;

    if [ -d "$GCM_DIR/proj/$proj" ]; then
        return 0;
    else
        return 1;
    fi
}

_gcm_isbranch()
{
    local proj=$1;
    local branch=$1;

    if [ -d "$GCM_DIR/proj/$proj/branch/open/$1" ]; then
        return 0;
    else
        return 1;
    fi
}

_gcm_newproj()
{
    local proj=$1;

    echo "Creating new project \"$proj\"";

    if _gcm_isproj "$proj"; then
        echo "\"$proj\" is already a project.";
        return 1;
    fi

    local rc=0;
    _gcm_pushd "$GCM_DIR/proj";
    
    mkdir -p "$proj"
    if [ $? -ne 0 ]; then
        echo "Failed to create project directory.";
        local rc=1;
    else
        mkdir -p "$proj/branch/open";
        mkdir -p "$proj/branch/closed";
    fi

    _gcm_popd;
    return $rc;
}

_gcm_enterproj()
{
    local proj=$1;

    if _gcm_isproj "$proj"; then
        cd "$GCM_DIR/proj/$proj";
        return 0;
    else
        echo "\"$proj\" is not a project.";
        return 1;
    fi
}

_gcm_newbranch()
{
    local proj=$1;
    local branch=$2;

    if _gcm_isproj "$proj"; then
        _gcm_pushd "$GCM_DIR/proj/$proj/branch/open";
        mkdir $branch;
        _gcm_popd;
        return 0;
    else
        echo "\"$proj\" is not a project.";
        return 1;
    fi

    return 0;
}

_gcm_enterbranch()
{
    local proj=$1;
    local branch=$2;

    if _gcm_isproj "$proj"; then
        if _gcm_isbranch "$branch"; then
            cd "$GCM_DIR/proj/$proj/branch/open/$branch";
            return 0;
        else
            echo "\"$branch\" is not a branch in \"$proj\"";
            return 1;
        fi
    else
        echo "\"$proj\" is not a project.";
        return 1;
    fi
}

_gcm_help()
{
    echo "Behold, a help prompt";
    return 0;
}
