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
_gcm_completion()
{
    if [ ${#COMP_WORDS[@]} -eq 2 ]; then
        COMPREPLY=($(compgen -W "new-proj enter-proj new-branch enter-branch close-branch build test help status" ${COMP_WORDS[1]}));
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
            "close-branch")
                COMPREPLY=($(compgen -W "$(_gcm_lsproj)" ${COMP_WORDS[2]}));
                return 0;;
            *)
                return 0;;
        esac
    fi
    if [ ${#COMP_WORDS[@]} -eq 4 ]; then
        case ${COMP_WORDS[1]} in
            "enter-branch")
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

_gcm_lsproj()
{
    _gcm_pushd "$GCM_DIR/proj";
    ls -1 --color=none | sort;
    _gcm_popd;
    return 0;
}

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
    local branch=$2;

    if [ -d "$GCM_DIR/proj/$proj/branch/open/$branch" ]; then
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

_gcm_enterbranch()
{
    local proj=$1;
    local branch=$2;

    if _gcm_isproj "$proj"; then
        if _gcm_isbranch "$proj" "$branch"; then
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

            if [ $GCM_SET_PS -ne 0 ]; then
                PS1="\`if [ \$? -eq 0 ]; then echo \e[0\;32m\:\)\e[0m; else echo \e[0\;31m\:\(\e[0m; fi\` ";
                PS1+="\e[0;36m[$GCM_PROJ:$GCM_BRANCH]\e[0m ";
                PS1+="\`echo \${PWD#\$GCM_DIR/proj/$GCM_PROJ/branch/open/}\` ";
                PS1+="\`if [ ! -z \$(git rev-parse --is-inside-work-tree 2>/dev/null) ]; then echo \e[0\;35m[git:\$(git rev-parse --abbrev-ref HEAD)]\e[0m; fi\` "
                PS1+="\n> ";
            fi

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

_gcm_status()
{
    for proj in $(_gcm_lsproj); do
        _gcm_pushd "$GCM_DIR/proj/$proj/repo";
        local dirty="\e[32m[clean]\e[0m";
        if [ $(git status --porcelain=v1 --untracked-files=no | wc -l) -gt 0 ]; then
            local dirty="\e[31;1m[dirty]\e[0m";
        fi
        echo -e "\e[36;1m$proj\e[0m $dirty";
        local active_branch=$(git rev-parse --abbrev-ref HEAD)
        cd ../branch/open;
        for branch in $(_gcm_lsbranch $proj); do
            cd "$branch";
            if [ $branch = $active_branch ]; then
                local A="*";
            else
                local A=" ";
            fi
            cd repo;
            local desc=$(git config branch.$branch.description | head -n 1)
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
            echo -e " $A$B $branch $D";
            cd ..;
        done
        _gcm_popd
    done
}

_gcm_help()
{
    echo "Behold, a help prompt";
    return 0;
}

