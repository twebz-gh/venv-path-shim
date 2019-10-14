#!/bin/sh

# Find <arg 1> in a `venv/bin/` between pwd and `/` and run command line.
# If none found, use system PATH to run command line.

function dbg {
    if [ -n "$verbose" ]; then
        printf "$@"
    fi
}

function get_venv_exe_path {
    dpath_tmp=$(pwd)  # the directory path of the original command
    while [ -n "$dpath_tmp" ]
    do
        if [ x"$dpath_tmp" = x"/" ]; then
            path_tmp="/venv/bin/$executable_name"
        else
            path_tmp="${dpath_tmp}/venv/bin/$executable_name"
        fi
        dbg "%s..." "$path_tmp"
        if [ ! -e "$path_tmp" ]; then
            dbg "not found\n"
        elif [ ! -f "$path_tmp" ]; then
            dbg "not a regular file\n"
        elif [ ! -x "$path_tmp" ]; then
            dbg "not executable\n"
        else
            dbg "found\n"
            executable_in_venv="$path_tmp"
            return
        fi

        if [ x"$dpath_tmp" = x"/" ]; then
            return
        fi

        dpath_tmp=$(dirname $dpath_tmp)
    done
}

function create_path_no_shim {
    while read -d ':' path_segment
    do
        case "$path_segment" in
            *"venv-path-shim"* )
                # skip it
            ;;

            * )
                if [ -z "$path_no_shim" ]; then
                    path_no_shim=$path_segment
                else
                    path_no_shim=${path_no_shim}:$path_segment
                fi
            ;;
        esac
    done <<< "${PATH}:"
}


executable_name=$1
shift

# Check cmd line args intended for this script.
while true; do
    if [ x"$1" = x"--vps-show-cmd" ] || [ x"$1" = x"--vps-show-command" ]; then
        show_command=1
        shift
    elif [ x"$1" = x"--vps-verbose" ]; then
        verbose=1
        shift
    else
        break
    fi
done

get_venv_exe_path

if [ -n "$executable_in_venv" ]; then
    if [ "$show_command" ]; then
        echo "$executable_in_venv $@"
    fi
    if [ -n "$verbose" ]; then
        printf "    executable:  <%s>\n" "$executable_name"
        printf "    %d args: " "$#"
        printf " <%s>" "$@"
        echo
    fi
    $executable_in_venv "$@"
else  # venv/bin/executable not found, use system PATH
    create_path_no_shim
    if [ "$show_command" ]; then
        echo PATH=$path_no_shim $executable_name $@
    fi
    if [ -n "$verbose" ]; then
        printf "    executable:  <%s>\n" "$executable_name"
        printf "    %d args: " "$#"
        printf " <%s>" "$@"
        echo
    fi
    PATH=$path_no_shim $executable_name "$@"
fi

