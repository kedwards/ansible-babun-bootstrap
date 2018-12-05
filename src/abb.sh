#!/usr/bin/sh
opts=':fthu:v:'

# cli overrides
bootstrap_ansible_update=0
ansible_tests=0
force_install=0
verbose=0

# sys
title='Ansible Automation'
pushd `dirname ${0}` > /dev/null && script_dir=`pwd` && popd > /dev/null
plugin_dir="${script_dir}/plugins"
disabled_plugin_dir="${plugin_dir}/disabled"
script_name=$(basename $(readlink -nf $0) ".sh")
workspace=~/workspace
installed="/etc/${script_name}.installed"

# sysdeps
pact_dependencies='figlet gcc-g++ wget python python-crypto python-setuptools python-paramiko p7zip libyaml-devel libffi-devel'
pip_url='https://bootstrap.pypa.io/get-pip.py'
pip_dependencies=('urllib3[secure]' 'pywinrm' 'cryptography' 'pyyaml' 'jinja2' 'httplib2' 'boto' 'awscli' 'cx_Oracle')
markupsafe_url='https://github.com/pallets/markupsafe/archive/master.zip'

# ansible
ansible_dir=/usr/local/etc/ansible
ansible_repo_url="https://github.com/ansible/ansible.git"
ansible_version='stable-2.7'

# console colours
green=\\e[92m
normal=\\e[0m
red=\\e[91m
cyan=\\e[96m

show_help()
{
    cat << EOF
Usage: ${script_name}.sh [-f|-t|-u|-v]

Run the installer, with following options:

    -f  force install
    -h  prints this help message
    -t  runs tests when initializing
    -u  run updates when initializing
    -v  prints verbose log messages

EOF
}

OPTIND=1
while getopts ${opts} opt
do
    case "$opt" in
      f)  force_install=1;;
      h)  show_help
          exit 1;;
      t)  ansible_tests=1;;
      u)  bootstrap_ansible_update=1;;
      v)  verbose=1;;
      \?)		# unknown flag
      	  show_help
	  	    exit 1;;
    esac
done

shift $(($OPTIND - 1))

if [ ${verbose} -eq 1 ]; then
    # -- verbose enables
    exec 4>&2 3>&1
else
    # -- verbose disabled, quiet all output
    exec 4>/dev/null 3>/dev/null
fi

run()
{
    cd ${ansible_dir}
    git checkout ${ansible_version} &> /dev/null
    source ./hacking/env-setup &> /dev/null
    sleep 1
    cd ${workspace}
    clear
    figlet "${title}"
    echo "\nConfigure Windows remotes with the below PS cmd\n. { iwr -useb https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1 } | iex;\n"
}

tests()
{
    if [ $ansible_tests -eq 1 ]
    then
        cd ${workspace}/test
        echo -n "testing ansible local connection.."
        ansible local -m ping &> /dev/null
        chk_ret_val
        sleep 1

        plugin ${plugin_dir} "test"
    fi
}

update()
{
    if [ ${bootstrap_ansible_update} -eq 1 ]
    then
        echo -n "Updating Ansible checkout.."
        cd ${ansible_dir}
        git checkout devel &> /dev/null
        git pull --rebase &> /dev/null
        git submodule update --init --recursive &> /dev/null
        echo "OK"
    fi
}

chk_ret_val()
{
    if [ $? -eq 0 ]
    then
        echo "${green}OK${normal}"
    else
        echo "${red}NOT OK${normal}"
    fi
}

mk_test_project ()
{
    if [ ! -d  ${workspace}/test ]
    then
        echo -n "Creating Test project..."
        mkdir -p ${workspace}/test/{conf,inventory}
        touch ${workspace}/test/conf/{vault_password,vault_key}
        chmod -x ${workspace}/test/conf/{vault_password,vault_key}
        cat > ${workspace}/test/inventory/hosts << EOF
# Local control machine
[local]
localhost ansible_connection=local
EOF
        cat > ${workspace}/test/ansible.cfg << EOF
[defaults]
ansible_managed = Ansible managed: {file} modified on %Y-%m-%d %H:%M:%S by {uid} on {host}
inventory = inventory/
module_name = win_ping
retry_files_enabled = False

[ssh_connection]
pipelining = True
ssh_args = -o ControlMaster=auto -o ControlPersist=30m -o StrictHostKeyChecking=no
control_path = /tmp/ansible-ssh-%%h-%%p-%%r

[privilege_escalation]
become_user = true
EOF
        echo "OK"
    fi
}

sys_install()
{
    echo -n "Installing Pact Dependencies.."
    pact install ${pact_dependencies} &> /dev/null
    echo "OK"

    pip=$(which pip)
    if [ $? -eq 1 ]
    then
        echo -n "Retrieving Python PIP.."
        wget -q ${pip_url}
        python get-pip.py &> /dev/null
        rm -r get-pip.py
        echo ".ok"
    fi

    echo -n "Installing PIP dependencies.."
    for dep in ${pip_dependencies}
    do
        pip install ${dep} --quiet &> /dev/null
    done
    echo "OK"

    if [ ! -e /etc/marksupsafe.updated ]
    then
        echo -n "Replacing default markupsafe with source (github).."
        pip uninstall markupsafe -y --quiet
        cd ${workspace}
        git clone https://github.com/pallets/markupsafe.git --quiet
        cd markupsafe
        python setup.py --without-speedups install &> /dev/null
        cd ${workspace}
        rm -rf markupsafe*
        touch /etc/marksupsafe.updated
        echo "OK"
    fi
}

installer()
{
    if [ ! -f ${installed} ];
    then
        cd ~
        echo "${cyan}${title} Installer${normal}"

        sys_install

        if [ ! -d ${ansible_dir} ]
        then
          echo -n "Retrieving Ansible source (github).."
          git clone ${ansible_repo_url} --recursive ${ansible_dir} --quiet
          cp ${ansible_dir}/examples/ansible.cfg ~/.ansible.cfg
          sed -i 's|#\?transport.*$|transport = paramiko|;s|#host_key_checking = False|host_key_checking = False|' ~/.ansible.cfg
          echo "OK"
        else
            echo -n "Updating Ansible source (github).."
            cd ${ansible_dir}
            git checkout devel &> /dev/null
            git pull --rebase &> /dev/null
            git submodule update --init --recursive &> /dev/null
            echo "OK"
        fi

        mk_test_project

        abb=$(grep -q '# Ansible in Babun' ~/.zshrc)
        if [ ! ${abb} ]
        then
            echo -n "Updating ~/.zshrc (Babun).."
            cat >> ~/.zshrc << EOF

#
# Ansible in Babun
#
# If you want to update Ansible every time set bootstrap_ansible_update=1
#
export bootstrap_ansible_update=0
if [ -f ${workspace}/${script_name%.*}/src/${script_name}.sh ]
then
    source ${workspace}/${script_name%.*}/src/${script_name}.sh
fi
EOF
        fi
        touch ${installed}
        echo ".OK"
    fi
}

plugin()
{
    #$1 = plug directory, ${plugin_dir}
    #$2 = function, [main | test]
    while IFS="" read -d $'\0' -r plug_main
    do
        for file in ${plug_main}/*.sh
        do
            name=$(basename ${file} ".sh")
            source $file
            ${name}_$2
        done
    done < <(find $1 -mindepth 1 -maxdepth 1 -not -path ${disabled_plugin_dir} -type d -print0)
}

clear
echo "${green}starting up..${normal}"
installer
update
plugin ${plugin_dir} "main"
run
tests
