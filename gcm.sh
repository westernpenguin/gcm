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
        return 1;
    fi
fi

#------------------------------------------------------------------------------
# Set the GCM_SET_PS environment variable if not already done.
#------------------------------------------------------------------------------
if [ -z "$GCM_SET_PS" ]; then
    GCM_SET_PS=0;
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
            _gcm_newbranch "$proj" "$branch";
            return $?;;
        "enter-branch")
            if [ $# -ne 3 ]; then
                echo "enter-branch expects 2 arguments.";
                return 1;
            fi
            local proj=$2;
            local branch=$3;
            _gcm_enterbranch "$proj" "$branch";
            return $?;;
        "cont-branch")
            if [ $# -ne 3 ]; then
                echo "cont-branch expects 2 arguments.";
                return 1;
            fi
            local proj=$2;
            local branch=$3;
            _gcm_contbranch "$proj" "$branch";
            return $?;;
        "close-branch")
            if [ $# -ne 3 ]; then
                echo "close-branch expects 2 arguments.";
                return 1;
            fi
            local proj=$2;
            local branch=$3;
            _gcm_closebranch "$proj" "$branch";
            return $?;;
        "build")
            if [ $# -ne 1 ]; then
                echo "build expects 0 arguments.";
                return 1;
            fi
            _gcm_build;
            return $?;;
        "test")
            if [ $# -ne 1 ]; then
                echo "test expects 0 arguments.";
                return 1;
            fi
            _gcm_test;
            return $?;;
        "status")
            if [ $# -ne 1 ]; then
                echo "status expects 0 arguments.";
                return 1;
            fi
            _gcm_status;
            return $?;;
        "help") 
            _gcm_help;
            return $?;;
        *)  
            echo "Invalid command \"$1\"";
            return 1;;
    esac
}

#==============================================================================
# _gcm_completion
#   Implementation of autocomplete for the gcm function.
#==============================================================================
_gcm_completion()
{
    if [ ${#COMP_WORDS[@]} -eq 2 ]; then
        COMPREPLY=($(compgen -W "new-proj enter-proj new-branch enter-branch cont-branch close-branch build test help status" ${COMP_WORDS[1]}));
        return 0;
    fi
    if [ ${#COMP_WORDS[@]} -eq 3 ]; then
        case ${COMP_WORDS[1]} in
            "new-proj")
                return 0;;
            "enter-proj")
                COMPREPLY=($(compgen -W "$(_gcm_lsproj)" ${COMP_WORDS[2]}));
                return 0;;
            "new-branch")
                COMPREPLY=($(compgen -W "$(_gcm_lsproj)" ${COMP_WORDS[2]}));
                return 0;;
            "enter-branch")
                COMPREPLY=($(compgen -W "$(_gcm_lsproj)" ${COMP_WORDS[2]}));
                return 0;;
            "cont-branch")
                COMPREPLY=($(compgen -W "$(_gcm_lsproj)" ${COMP_WORDS[2]}));
                return 0;;
            "close-branch")
                COMPREPLY=($(compgen -W "$(_gcm_lsproj)" ${COMP_WORDS[2]}));
                return 0;;
            *)
                return 0;;
        esac
    fi
    if [ ${#COMP_WORDS[@]} -eq 4 ]; then
        case ${COMP_WORDS[1]} in
            "cont-branch")
                COMPREPLY=($(compgen -W "$(_gcm_lsbranch ${COMP_WORDS[2]})" ${COMP_WORDS[3]}));
                return 0;;
            "close-branch")
                COMPREPLY=($(compgen -W "$(_gcm_lsbranch ${COMP_WORDS[2]})" ${COMP_WORDS[3]}));
                return 0;;
            *)
                return 0;;
        esac
    fi
}
complete -F _gcm_completion gcm;

#==============================================================================
# _gcm_lsproj
#   Lists the current projects in gcm
#==============================================================================
_gcm_lsproj()
{
    _gcm_pushd "$GCM_DIR/proj";
    ls -1 --color=none | sort;
    _gcm_popd;
    return 0;
}

#==============================================================================
# _gcm_lsbranch projname
#   Lists the current branches in the given project in gcm
#==============================================================================
_gcm_lsbranch()
{
    local proj=$1;
    if [ ! -d "$GCM_DIR/proj/$proj/branch" ]; then
        return 1;
    fi
    _gcm_pushd "$GCM_DIR/proj/$proj/branch/open";
    ls -1 --color=none | sort;
    _gcm_popd;
    return 0;
}

#==============================================================================
# _gcm_pushd dir
#   pushd, but without feedback
#==============================================================================
_gcm_pushd()
{
    pushd "$1" &>/dev/null;
}

#==============================================================================
# _gcm_popd
#   popd, but without feedback
#==============================================================================
_gcm_popd()
{
    popd &>/dev/null;
}

#==============================================================================
# _gcm_isproj projname
#   Returns 0 if the given project name is a project in gcm.  Return 1
#   otherwise.
#==============================================================================
_gcm_isproj()
{
    local proj=$1;

    if [ -d "$GCM_DIR/proj/$proj" ]; then
        return 0;
    else
        return 1;
    fi
}

#==============================================================================
# _gcm_isbranch projname branchname
#   Returns 0 if the given branch name is a gcm branch in the given project.
#   Returns 1 otherwise.
#==============================================================================
_gcm_isbranch()
{
    local proj=$1;
    local branch=$2;

    if [ -d "$GCM_DIR/proj/$proj/branch/open/$branch" ]; then
        return 0;
    else
        return 1;
    fi
}

#==============================================================================
# _gcm_newproj projname
#   Creates a new project with the given name.
#==============================================================================
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
        echo "master" > "$proj/branch_start";
        mkdir -p "$proj/skel";
        mkdir -p "$proj/branch/open";
        mkdir -p "$proj/branch/closed";
        mkdir -p "$proj/repo";
        _gcm_pushd "$proj/repo";
        git init . 1>/dev/null
        _gcm_popd
        _gcm_pushd "$proj/skel";
        touch "gcmrc";
        echo "#!/bin/bash" > build.sh;
        echo "set -x" >> build.sh;
        echo "set -e" >> build.sh;
        chmod +x build.sh;
        echo "#!/bin/bash" > test.sh;
        echo "set -x" >> test.sh;
        echo "set -e" >> test.sh;
        chmod +x test.sh;
        ln -s "$GCM_DIR/proj/$proj/repo" repo
        _gcm_popd
    fi

    _gcm_popd;
    return $rc;
}

#==============================================================================
# _gcm_enterproj projname
#   Go to the project directory.  Used for editing projects.
#==============================================================================
_gcm_enterproj()
{
    local proj=$1;

    if _gcm_isproj "$proj"; then
        cd "$GCM_DIR/proj/$proj";
        GCM_PROJ=$proj
        unset GCM_BRANCH;

        if [ $GCM_SET_PS -ne 0 ]; then
            PS1="\`if [ \$? -eq 0 ]; then echo \e[0\;32m\:\)\e[0m; else echo \e[0\;31m\:\(\e[0m; fi\` ";
            PS1+="\e[0;31m[$GCM_PROJ]\e[0m ";
            PS1+="\`echo \${PWD#\$GCM_DIR/proj/}\` ";
            PS1+="\n> ";
        fi

        return 0;
    else
        echo "\"$proj\" is not a project.";
        return 1;
    fi
}

#==============================================================================
# _gcm_newbranch projname branchname
#   Create a new gcm branch with the given name in the given project.
#==============================================================================
_gcm_newbranch()
{
    local proj=$1;
    local branch=$2;

    if _gcm_isproj "$proj"; then
        _gcm_pushd "$GCM_DIR/proj/$proj";
        local branch_start=$(cat branch_start);
        cd repo;
        git branch $branch $branch_start
        cd ../branch/open;
        cp -R ../../skel $branch;
        _gcm_popd;
        return 0;
    else
        echo "\"$proj\" is not a project.";
        return 1;
    fi
}

#==============================================================================
# _gcm_currbranch projname
#   Prints the current branch in git in the given project.
#==============================================================================
_gcm_currbranch()
{
    local proj=$1;

    if _gcm_isproj $proj; then
        _gcm_pushd $GCM_DIR/proj/$proj/repo;
        git rev-parse --abbrev-ref HEAD;
        _gcm_popd;
        return 0;
    else
        return 1;
    fi
}

#==============================================================================
# _gcm_projisclean projname
#   Returns 0 if the givne project's git repository is clean; 1 otherwise.
#==============================================================================
_gcm_projisclean()
{
    local proj=$1;

    if _gcm_isproj $proj; then
        local res=0;
        _gcm_pushd $GCM_DIR/proj/$proj/repo;
        if [ $(git status --porcelain=v1 --untracked-files=no | wc -l) -gt 0 ]; then
            res=1;
        fi
        _gcm_popd;
        return $res;
    else
        return 1;
    fi
}

#==============================================================================
# _gcm_setbranchps
#   Setup the PS variables for a branch.
#==============================================================================
_gcm_setbranchps()
{
    if [ $GCM_SET_PS -ne 0 ]; then
        PS1="\`if [ \$? -eq 0 ]; then echo \e[0\;32m\:\)\e[0m; else echo \e[0\;31m\:\(\e[0m; fi\` ";
        PS1+="\e[0;36m[$GCM_PROJ:$GCM_BRANCH]\e[0m ";
        PS1+="\`echo \${PWD#\$GCM_DIR/proj/$GCM_PROJ/branch/open/}\` ";
        PS1+="\`if [ ! -z \$(git rev-parse --is-inside-work-tree 2>/dev/null) ]; then echo \e[0\;35m[git:\$(git rev-parse --abbrev-ref HEAD)]\e[0m; fi\` "
        PS1+="\n> ";
    fi
}

#==============================================================================
# _gcm_enterbranch projname branchname
#   Go to the given gcm branch directory in the given project, but do not
#   change the git branch.
#==============================================================================
_gcm_enterbranch()
{
    local proj=$1;
    local branch=$2;

    if _gcm_isproj "$proj"; then
        if _gcm_isbranch "$proj" "$branch"; then
            cd "$GCM_DIR/proj/$proj/branch/open/$branch";
            GCM_PROJ=$proj;
            GCM_BRANCH=$branch;

            . gcmrc
            
            _gcm_setbranchps;

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

#==============================================================================
# _gcm_contbranch projname branchname
#   Continue working on the given gcm branch.  Changes the directory and
#   changes the git branch.
#==============================================================================
_gcm_contbranch()
{
    local proj=$1;
    local branch=$2;

    if _gcm_isproj "$proj"; then
        if _gcm_isbranch "$proj" "$branch"; then
            if ! _gcm_projisclean "$proj"; then
                if [ $(_gcm_currbranch "$proj") != "$branch" ]; then
                    echo "Unsaved changes exist in branch $(_gcm_currbranch $proj).";
                    echo "Please commit or stash these changes before changing branches.";
                    return 1;
                fi
            fi
            cd "$GCM_DIR/proj/$proj/branch/open/$branch";
            GCM_PROJ=$proj;
            GCM_BRANCH=$branch;

            cd repo;
            git checkout -q $branch;
            if [ $? -ne 0 ]; then
                echo "Failed to checkout branch $branch."
            fi
            cd ..;

            . gcmrc

            _gcm_setbranchps;

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

#==============================================================================
# _gcm_closebranch projname branchname
#   Archive the given gcm branch in the given project. 
#==============================================================================
_gcm_closebranch()
{
    local proj=$1;
    local branch=$2;

    if _gcm_isproj "$proj"; then
        if _gcm_isbranch "$proj" "$branch"; then
            _gcm_pushd "$GCM_DIR/proj/$proj/branch/open"
            tar -czvf "../closed/$branch.tar.gz" "$branch";
            rm -fR "$branch";
            _gcm_popd
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

#==============================================================================
# _gcm_build
#   Short form command to build when already in a branch.
#==============================================================================
_gcm_build()
{
    if [ -z "$GCM_PROJ" ]; then
        echo "Not in a project.";
        return 1;
    fi
    if [ -z "$GCM_BRANCH" ]; then
        echo "Not on a branch.";
        return 1;
    fi

    if [ $(_gcm_currbranch "$GCM_PROJ") != "$GCM_BRANCH" ]; then
        echo "Git branch is $(_gcm_currbranch $GCM_PROJ).";
        echo "Please move to branch $GCM_BRANCH before building.";
        return 1;
    fi

    local rc=0;
    _gcm_pushd "$GCM_DIR/proj/$GCM_PROJ/branch/open/$GCM_BRANCH";
    rm -f .passed .failed .built
    ./build.sh
    local rc=$?;
    if [ $rc -eq 0 ]; then
        touch .built;
    fi
    _gcm_popd
    return $rc;
}

#==============================================================================
# _gcm_test
#   Short form command to test when already in a branch.
#==============================================================================
_gcm_test()
{
    if [ -z "$GCM_PROJ" ]; then
        echo "Not in a project.";
        return 1;
    fi
    if [ -z "$GCM_BRANCH" ]; then
        echo "Not on a branch.";
        return 1;
    fi

    if [ $(_gcm_currbranch "$GCM_PROJ") != "$GCM_BRANCH" ]; then
        echo "Git branch is $(_gcm_currbranch $GCM_PROJ).";
        echo "Please move to branch $GCM_BRANCH before testing.";
        return 1;
    fi

    local rc=0;
    _gcm_pushd "$GCM_DIR/proj/$GCM_PROJ/branch/open/$GCM_BRANCH";
    rm -f .passed .failed
    ./test.sh
    local rc=$?
    if [ $rc -eq 0 ]; then
        touch .passed;
    else
        touch .failed;
    fi
    _gcm_popd
    return $rc;
}

#==============================================================================
# _gcm_branchstart projname
#   Prints the name of the preferred branch start point for the given
#   project.
#==============================================================================
_gcm_branchstart()
{
    local proj=$1;

    if _gcm_isproj $proj; then
        _gcm_pushd $GCM_DIR/proj/$proj
        cat branch_start
        _gcm_popd
        return 0;
    else
        return 1;
    fi
}

#==============================================================================
# _gcm_status
#   Print the status of all gcm projects and branches.
#==============================================================================
_gcm_status()
{
    for proj in $(_gcm_lsproj); do
        if _gcm_projisclean $proj; then
            local dirty="\e[32m[clean]\e[0m";
        else
            local dirty="\e[31;1m[dirty]\e[0m";
        fi
        echo -e "\e[36;1m$proj\e[0m $dirty";
        local active_branch=$(_gcm_currbranch $proj);
        local branch_start=$(_gcm_branchstart $proj);
        _gcm_pushd "$GCM_DIR/proj/$proj/branch/open";
        for branch in $(_gcm_lsbranch $proj); do
            cd "$branch";
            if [ $branch = $active_branch ]; then
                local A="*";
            else
                local A=" ";
            fi
            cd repo;
            local desc=$(git config branch.$branch.description | head -n 1)
            local behind_ahead=$(git rev-list --left-right --count $branch_start...$branch)
            cd ..;
            if [ ! -z "$desc" ]; then
                local D="\e[37m[$desc]\e[0m";
            else
                local D="\e[90m[no description]\e[0m";
            fi
            local B="\e[33m[?]\e[0m";
            if [ -f ".built" ]; then
                local B="\e[34;1m[B]\e[0m";
                if [ -f ".passed" ]; then
                    local B="\e[32;1m[P]\e[0m";
                fi
                if [ -f ".failed" ]; then
                    local B="\e[31;1m[F]\e[0m";
                fi
            fi
            local BA=$(echo "$behind_ahead" | sed -e "s/\([0-9]\+\)\s\+\([0-9]\+\)/[B:\1;A:\2]/g");
            # A -- Active
            # B -- Build status
            # D -- Description
            # BA -- Behind/ahead
            echo -e " $A$B $branch $D $BA";
            cd ..;
        done
        _gcm_popd
    done
}

#==============================================================================
# _gcm_help
#   Print the gcm help information.
#==============================================================================
_gcm_help()
{
    echo "Behold, a help prompt";
    return 0;
}

GCM_SRCED=1;
