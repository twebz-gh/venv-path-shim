# VPS

Use virtualenvs the easy way.

1. [Introduction](#introduction-to-vps)
1. [Install](#install)
1. [Usage](#usage)
1. [Rationale](#rationale )
1. [How to Install Many Versions of Python](#how-to-install-many-versions-of-python)
1. [How to Create virtualenv with a Specific Python](#how-to-create-a-virtualenv-with-a-specific-python)


## Introduction to VPS

### What it Is

VPS is an initialism for **V**irtualenv **P**ath **S**him.  It eases the use of Python virtualenvs.  With it, your system automatically selects the appropriate virtualenv for each project.

It is for people who develop code using Python.

### What it Does

Consider this file tree:
```text
~/projects/
    ProjectA/
        src/
            program.py
        test/
        venv/
            bin/
                pip
                python
                <other executables>
        requirements.txt
        setup.py
    ProjectB/  # contains no venv
```

While your shell is in or under `~/projects/ProjectA/`,  
invocations of `pip` and `python`,  
use the ones found in `~/projects/ProjectA/venv/bin/`

Examples:

```sh
$ cd ~/projects/ProjectA/src
$ head -n 1 program.py
#!/usr/bin/env python
$ ./program.py arg1 arg2 ...  # Uses ~/projects/ProjectA/venv/bin/python

$ pip install <pypi-package>  # Uses ~/projects/ProjectA/venv/bin/pip

$ cd ~/projects/ProjectA
$ python  # Uses ~/projects/ProjectA/venv/bin/python
```

### How it Works

When you enter `python` at the command line, VPS looks for `./venv/bin/python`.  If it finds it, it calls it.  If not, it moves up one directory and tries again, until it has tried in the root directory.

If VPS finds no virtualenv, it runs the command with VPS removed from the PATH.  Notionally, that looks like this:
```sh
$ PATH=<PATH-with-VPS-removed> python <args>
```

By default, VPS does this for `python` and `pip`.  The user can add other commands.

#### How it is Implemented

VPS installs these files, and adds the noted directories to your PATH:
```
~/.local/
    bin/  # added to the end of your PATH
        find-venv-executable.sh
    venv-path-shim/  # added to the beginning of your PATH
        pip
        python
```
A call to `python` executes `~/.local/venv-path-shim/python`.

That calls `~/.local/bin/find-venv-path-shim.sh`.

That finds and calls the appropriate `python` with the command line args.

VPS shell scripts work under `bash`, `dash`, `ksh`, `sh`, and `zsh`.

#### Implications

After installing VPS, there is no need to activate, deactivate, or otherwise select which virtualenv you want to use.

VPS does not affect system users, or other real users, since the `PATH` changes are restricted to your user environment.  `cron` jobs, and similar, will not use VPS by default.  However, you can tell an individual `cron` job to use it by editing its `PATH`.


## Install

### Step 1 Clone the Git Repository

For the purpose of demonstration, we'll put the git repo in `$HOME/app/`:
```sh
$ mkdir ~/app  &&  cd ~/app
$ git clone <url-of-repo>
```

### Step 2 Install to the Filesystem
```sh
$ cd ~/app/venv-path-shim
$ ./install.sh
```

### Step 3 Set `PATH`

Warning:  If you are not comfortable with how `PATH` affects your system, and how to modify it, this is a place to get some help.

The details of how to set `PATH` differ based on which OS and shell you use.  The requirements are the same for all of them:

* put `${HOME}/.local/venv-path-shim` at the beginning of your PATH
* put `${HOME}/.local/bin` at the end of your PATH
* make this take effect for login shells

For POSIX systems, edit `~/.profile` so that the last 2 lines containing `PATH` are these:
```sh
PATH=${HOME}/.local/venv-path-shim:${PATH}:${HOME}/.local/bin
export PATH
```

Make sure `~/.profile` is sourced for login shells.  Related [answer](https://serverfault.com/a/500071) on serverfault.com.


### Step 4 Make `PATH` Take Effect

An easy way to make the new PATH settings take effect is to logout and login.  After you login, you can check your `PATH` by typing:
```sh
$ echo $PATH | tr ':' '\n'
```
You should get something like this:
```sh
/home/<username>/.local/venv-path-shim
/usr/local/bin
/usr/local/sbin
/usr/bin
/usr/sbin
/bin
/sbin
/home/<username>/.local/bin
```

The first and last lines should match those above.  The lines in between should make sense for your system.

### Optional Step:  Add Executables

Use the file named `python`, that is installed by VPS, as a template:
```sh
$ cd ~/.local/venv-path-shim
$ cat python
#!/bin/sh

exec find-venv-executable.sh python "$@"
```

Copy it to the name of the executable you want to add.  Change the 'python' in the new file to the executable name.  Then VPS will look for it in your virtualenvs.

### Optional Step:  Uninstall

```sh
$ cd ~/app/venv-path-shim
$ ./uninstall.sh
```

## Usage

### Basic Usage

To use a particular virtualenv, navigate into the directory tree containing its `venv`  and issue your command:
```sh
$ cd ~/projects/ProjectA
$ python -c "print ('hello from Python')"
hello from Python
```

Suppose you want to use a particular virtualenv's executable from a shell script in a different directory.  You can get there with `cd`, or `pushd` and `popd`, or by specifying the absolute path to the executable.

### Usage With Debugging Output

VPS accepts, and consumes, two command line flags:

* `--vps-show-cmd` : show the final command line
* `--vps-verbose` : show verbose output

These flags must come before other command line arguments.  They are not passed to the final command.

For example, using the sample directory tree from the top of this page:
```sh
$ python --vps-show-cmd -c "print ('hello from Python')"
/home/<user>/projects/ProjectA/venv/bin/python -c print ('hello from Python')
hello from Python

$ python --vps-verbose -c "print ('hello from Python')"
/home/<user>/projects/ProjectA/venv/bin/python...found
    executable:  <python>
    2 args:  <-c> <print ('hello from Python')>
hello from Python
```

Using both flags, in either order, from a directory with no `venv`:
```sh
$ cd ~/projects/ProjectB
$ python --vps-verbose --vps-show-cmd -c "print ('hello from Python')"
/home/<user>/projects/ProjectB/venv/bin/python...not found
/home/<user>/projects/venv/bin/python...not found
/home/<user>/venv/bin/python...not found
/home/venv/bin/python...not found
/venv/bin/python...not found
PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/home/<user>/.local/bin python -c print ('hello from Python')
    executable:  <python>
    2 args:  <-c> <print ('hello from Python')>
hello from Python
```

## Rationale

This section explains the reasoning and motivation behind the development of VPS.


### Use virtualenvs and pip for Python Development

These are from python.org's [Installation tool recommendations](https://packaging.python.org/guides/tool-recommendations/#installation-tool-recommendations).


### Do not use `bin/activate.sh`

Michael Lamb explains the problems with `bin/activate.sh` in this [article](https://datagrok.org/python/activate/).


### Keep Each virtualenv in its Project

Storing the virtualenv in its project tree is better than storing it in some centralized location.  To see why, consider how we treat other build artifacts.  They go in a project sub-directory, like `build`, for caching purposes.  While the project is in use, it automatically uses that `build` directory.  When the project is deleted, so is the build directory, leaving no remnants on the system.  They do not belong in version control.

Treat virtualenvs in the same way.  Put your `requirements.txt` and `setup.py` in version control.  From those, other developers can build the corresponding virtualenv.


### Do Not Use `pip` to Install to the OS\'s Python

The [warning in the installation instructions](https://pip.pypa.io/en/stable/installing/) for `pip` mentions that it can be harmful to use `pip` to install to the OS\'s Python.  Here is a little more detail.  Some system programs depend on the OS\'s Python.  That is reason to be careful with how you treat the packages installed there.  In some cases, it may be fine to add or update packages in the system's Python; although, I do not recommend it, and virtualenvs provide a better alternative.  If you do, only do so using your system's package manager, which maintains the dependencies related to these installs.  Using `pip` to modify these installs might cause problems for the system package manager's understanding of what is installed and their dependencies.

It is [recommended](https://github.com/pypa/pip/issues/1668) to use the OS\'s package manager to handle Python packages for the OS\'s Python install.  For other Python installations, it is [recommended](https://packaging.python.org/guides/tool-recommendations/#installation-tool-recommendations) to use `pip` to handle python packages.

This [quote](https://github.com/pypa/pip/issues/1668) demonstrates how an unwary `pip` user is unintentionally influenced to do the wrong thing:
>  When pip is installed on a system that has an OS Python install there is currently a problem where ``pip install foo`` will throw an error because it doesn't have file permissions. This causes people to instead run ``sudo pip install foo`` which globally installs to the system Python. This creates an issue where people are using pip to manage system level packages when they should likely be using the system package manager.

There is a similar problem with the official pip install [instructions](https://pip.pypa.io/en/stable/installing/).  They warn against using the OS\'s python, but do not suggest how to modify their command (`python git-pip.py`) to do that.


### Path Shim Vs Other Techniques

Compare VPS to these techniques that do not use a PATH shim.


#### Existing Path

We could use an existing `$PATH` element instead of the PATH shim in `~/.local/venv-path-shim`.  It is common to have `/usr/local/bin` before `/usr/bin` in `$PATH` (or similar spelling for your OS).  Instead of installing our `python` to `$HOME/.local/venv-path-shim`, we could put it in `/usr/local/bin`.

The potential downsides:

- other methods of install use `/usr/local/bin`, possibly clobbering our `python`, or vice versa
- it affects other users
- it requires root privilege


#### Shell Alias

In some cases, we could use a shell alias instead of a PATH shim.  Consider
```sh
alias python="$HOME/.local/venv-path-shim/python"
```

This works if you call it directly from the command line, but not inside scripts.  Consider
```sh
$!/bin/sh

# do some things
python
# do other things
```

In the script above, the alias to `python` cannot be seen, so the call looks for `python` on the `$PATH`.


#### `/etc/alternatives`


We could use `alternatives` to get a similar effect to a PATH shim; however, that has the same potential downsides as using an [Existing Path](#existing-path).


### Other Notes

Stackoverflow [comparison](https://stackoverflow.com/questions/41573587/what-is-the-difference-between-venv-pyvenv-pyenv-virtualenv-virtualenvwrapper) of related tools.


## Appendices

### How to Install Many Versions of Python

Each virtualenv is created at the version of Python that was used to create it.  If you need different versions of Python, you also need a way to organize them.  This section shows a way to do that by installing to `$HOME/.local/opt/`.  Here is an example that creates a local install of Python at any version.

```sh
$ mkdir -p ~/.local/opt ~/.local/tmp
$ cd .local/tmp
# See python.org to select the version you want.
$ wget https://www.python.org/ftp/python/<version>/Python-<version>.tgz
$ tar zxf Python-<version>.tgz
$ cd Python-<version>
# Before `./configure`, install the ssl development libraries.
$ ./configure --prefix=$HOME/.local/opt/python-<version> --with-ensurepip=install
$ make
$ make install
```

With this technique, you can install all the versions of Python you want in `$HOME/.local/opt/`.


### How to Create a virtualenv With a Specific Python

#### Create Virtualenv with Python2

```sh
$ cd <project-dir>
$ mkdir venv
# Use the OS package manager to install python-virtualenv.
$ virtualenv -p $HOME/.local/opt/python-<version>/bin/python venv
$ pip install --upgrade pip setuptools
```

#### Create Virtualenv with Python3

```sh
$ cd <project-dir>
$ mkdir venv
$ $HOME/.local/opt/python-<version>/bin/python -m venv venv
$ pip install --upgrade pip setuptools
```

