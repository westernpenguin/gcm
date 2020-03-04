# Source this file under bash.  DO NOT EXECUTE.

#------------------------------------------------------------------------------
# Ensure that the core GCM extension is loaded.
#------------------------------------------------------------------------------
if [ -z $GCM_SRCED ]; then
    echo "Source gcm.sh before sourcing gcmshort.sh.";
    return 1;
fi

#------------------------------------------------------------------------------
# Check that GCMSHORT_DEFAULT_PROJ has been set.
#------------------------------------------------------------------------------
if [ -z $GCMSHORT_DEFAULT_PROJ ]; then
    echo "Set GCMSHORT_DEFAULT_PROJ to your preferred default project before sourcing gcmshort.sh";
    echo "Attempting to default to first project.";
    GCMSHORT_DEFAULT_PROJ=$(_gcm_lsproj | head -n 1)
    if [ -z $GCMSHORT_DEFAULT_PROJ ]; then
        echo "Failed to use a default project.  Stopping load of gcmshort.";
        echo "Perhaps you don't have any projects yet?";
        return 1;
    else
        echo "Using project $GCMSHORT_DEFAULT_PROJ.";
    fi
elif ! _gcm_isproj $GCMSHORT_DEFAULT_PROJ; then
    echo "$GCMSHORT_DEFAULT_PROJ is not a project.  Stopping load of gcmshort.";
    return 1;
fi

#------------------------------------------------------------------------------
# Load configuration for the branch, but don't change directories.
#------------------------------------------------------------------------------
if [ ! -z $(_gcm_currbranch $GCMSHORT_DEFAULT_PROJ) ]; then
    _gcm_pushd .;
    _gcm_enterbranch $GCMSHORT_DEFAULT_PROJ $(_gcm_currbranch $GCMSHORT_DEFAULT_PROJ);
    _gcm_popd;
else
    echo "Failed to enter the current branch in $GCMSHORT_DEFAULT_PROJ.";
    echo "Stopping load of gcmshort.";
    echo "Check your gcm and git status."
    echo "Perhaps you don't have any branches yet?";
    return 1;
fi

#------------------------------------------------------------------------------
# Completion routines
#------------------------------------------------------------------------------
_gcmshort_projcompletion()
{
    if [ ${#COMP_WORDS[@]} -ne 2 ]; then
        return 1;
    fi
    COMPREPLY=($(compgen -W "$(_gcm_lsproj)" ${COMP_WORDS[1]}));
}

_gcmshort_branchcompletion()
{
    if [ ${#COMP_WORDS[@]} -ne 2 ]; then
        return 1;
    fi
    COMPREPLY=($(compgen -W "$(_gcm_lsbranch $GCM_PROJ)" ${COMP_WORDS[1]}));
}

#------------------------------------------------------------------------------
# Define the shortcuts
#------------------------------------------------------------------------------
new-proj()
{
    if [ $# -ne 1 ]; then
        echo "new-proj expects 1 argument";
        return 1;
    fi
    _gcm_newproj "$1";
    return $?;
}

enter-proj()
{
    if [ $# -ne 1 ]; then
        echo "enter-proj expects 1 argument";
        return 1;
    fi
    _gcm_enterproj "$1";
    return $?;
}
complete -F _gcmshort_projcompletion enter-proj;

new-branch()
{
    if [ $# -ne 1 ]; then
        echo "new-branch expects 1 argument";
        return 1;
    fi
    _gcm_newbranch "$GCM_PROJ" "$1";
    return $?;
}

enter-branch()
{
    if [ $# -ne 1 ]; then
        echo "enter-branch expects 1 argument";
        return 1;
    fi
    _gcm_enterbranch "$GCM_PROJ" "$1";
    return $?;
}
complete -F _gcmshort_branchcompletion enter-branch;

cont-branch()
{
    if [ $# -ne 1 ]; then
        echo "cont-branch expects 1 argument";
        return 1;
    fi
    _gcm_contbranch "$GCM_PROJ" "$1";
    return $?;
}
complete -F _gcmshort_branchcompletion cont-branch;

close-branch()
{
    if [ $# -ne 1 ]; then
        echo "close-branch expects 1 argument";
        return 1;
    fi
    _gcm_closebranch "$GCM_PROJ" "$1";
    return $?;
}
complete -F _gcmshort_branchcompletion close-branch;

branch-build()
{
    if [ $# -ne 0 ]; then
        echo "branch-build expects 0 arguments";
        return 1;
    fi
    _gcm_build;
    return $?;
}

branch-test()
{
    if [ $# -ne 0 ]; then
        echo "branch-test expects 0 arguments";
        return 1;
    fi
    _gcm_test;
    return $?;
}

branch-base()
{
    if [ $# -ne 0 ]; then
        echo "branch-test expects 0 arguments";
        return 1;
    fi
    _gcm_base;
    return $?;
}
