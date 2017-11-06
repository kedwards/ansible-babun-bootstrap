#!/usr/bin/env zsh

# cli override
bootstrap_ansible_update=0
ansible_tests=1
force_install=0

# sys
title='Ansible Automation'
pushd `dirname ${0}` > /dev/null && script_dir=`pwd` && popd > /dev/null
plugin_dir="${script_dir}/plugins"
disabled_plugin_dir="${plugin_dir}/disabled"
script_name=$(basename $(readlink -nf $0) ".sh")
workspace=~/workspace
installed="/etc/${script_name}.installed"

# github
github_url='https://github.com'

# sysdeps
pact_dependencies='figlet gcc-g++ wget python python-crypto python-paramiko p7zip libyaml-devel libffi-devel'
pip_url='https://bootstrap.pypa.io/get-pip.py'
pip_dependencies=('urllib3[secure]' 'pywinrm' 'cryptography' 'pyyaml' 'jinja2' 'httplib2' 'boto' 'awscli' 'cx_Oracle')
markupsafe_url='https://github.com/pallets/markupsafe/archive/master.zip'

# ansible
ansible_dir=/usr/local/etc/ansible
ansible_repo_url="${github_url}/ansible/ansible.git"
ansible_version='stable-2.4'

# console colours
green=\\e[92m
normal=\\e[0m
red=\\e[91m
cyan=\\e[96m

run()
{
    cd ${ansible_dir}
    git checkout ${ansible_version} &> /dev/null
    source ./hacking/env-setup &> /dev/null
    sleep 1
    clear
    figlet "${title}"
    echo "\nConfigure Windows remotes with one of the below PS cmds\n. { iwr -useb https://bit.ly/2v9xsrG } | iex;\n. { iwr -useb http://mrmwebp.enbridge.com/OLFShare/ConfigureRemoteForAnsible.ps1 } | iex;\n. { iwr -useb https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1 } | iex;\n"
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
        cd ${ansible_directory}
        git checkout devel &> /dev/null
        git pull --rebase &> /dev/null
        git submodule update --init --recursive &> /dev/null
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
    if [! -d  ${workspace}/test ]
    then
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
    fi
}

sys_install()
{
    pact install ${pact_dependencies} &> /dev/null

    wget -q ${pip_url}
    python get-pip.py &> /dev/null
    rm -r get-pip.py

    for dep in ${pip_dependencies}
    do
        pip install ${dep} --quiet &> /dev/null
    done

    pip uninstall markupsafe -y --quiet

    cd ${workspace}
    git clone https://github.com/pallets/markupsafe.git --quiet
    cd markupsafe
    python setup.py --without-speedups install &> /dev/null
    cd ${workspace}
    rm -rf markupsafe*
}

installer()
{
    if [ ! -f ${installed} ] || [ ${force_install} -eq 1 ]
    then
        cd ~
        clear
        echo "${cyan}${title} Installer${normal}"
        echo -n "installing please wait.."

        sys_install

        if [ -d ${ansible_dir} ]
        then
            cd ${ansible_directory}
            git checkout devel &> /dev/null
            git pull --rebase &> /dev/null
            git submodule update --init --recursive &> /dev/null
        else
            git clone ${ansible_repo_url} --recursive ${ansible_dir} --quiet
            cp ${ansible_dir}/examples/ansible.cfg ~/.ansible.cfg
            sed -i 's|#\?transport.*$|transport = paramiko|;s|#host_key_checking = False|host_key_checking = False|' ~/.ansible.cfg
            touch ${installed}
        fi

        mk_test_project

        if [ `grep -q '# Ansible in Babun' ~/.zshrc` -eq 1 ]
        then
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
        exit
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
# plugin
plugin ${plugin_dir} "main"
run
tests
