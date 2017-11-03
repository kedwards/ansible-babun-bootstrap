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
script_name=$(basename $(readlink -nf $0))
workspace=~/workspace
installed="/etc/${script_name}.installed"

# github
github_url='https://github.com'

# sysdeps
pact_dependencies='figlet gcc-g++ wget python python-crypto python-paramiko libyaml-devel libffi-devel'
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
    echo -n "configuring ansible virtual environment.."
    cd ${ansible_dir}
    git checkout ${ansible_version} &> /dev/null
    source ./hacking/env-setup &> /dev/null
    echo "${green}OK${normal}"
    sleep 1
    clear
    figlet "${title}"
    echo "\nConfigure Windows remotes with one of the below PS cmds\n. { iwr -useb https://bit.ly/2v9xsrG } | iex;\n. { iwr -useb http://mrmwebp.enbridge.com/OLFShare/ConfigureRemoteForAnsible.ps1 } | iex;\n. { iwr -useb https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1 } | iex;\n\n"
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

        while IFS="" read -d $'\0' -r plugins_test
        do
            for file in ${plugins_test}/*.sh
            do
                name=$(basename ${file} ".sh")
                source $file
                ${name}_test
            done
        done < <(find ${plugin_dir} -mindepth 1 -maxdepth 1 -not -path ${disabled_plugin_dir} -type d -print0)
    fi
}

seed_test_project()
{
    echo -n "seeding test project.."
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
    echo "${green}OK${normal}"
}

configure_shell() {
    echo -n "configuring zshell for ansible.."
    cat >> ~/.zshrc <<EOF

#
# Ansible in Babun
#

# If you want to update Ansible every time set bootstrap_ansible_update=1
export bootstrap_ansible_update=0

# Configure Babun for Ansible
if [ -f ${workspace}/${script_name%.*}/src/${script_name} ]
then
    source ${workspace}/${script_name%.*}/src/${script_name}
fi
EOF
    echo "${green}OK${normal}"
}

update()
{
    if [ ${bootstrap_ansible_update} -eq 1 ]
    then
        echo -n "updating ansible source.."
        cd ${ansible_directory}
        git checkout devel &> /dev/null
        git pull --rebase &> /dev/null
        git submodule update --init --recursive &> /dev/null
        echo "${green}OK${normal}"
    fi
}

chk_ret_val()
{
    if [ $? -eq 0 ]
    then
        echo "${green}OK${normal}"
    else
        echo "${red}OK${normal}"
    fi
}

installer()
{
    if [ ! -f ${installed} ] || [ ${force_install} -eq 1 ]
    then
        cd ~
        clear
        echo "${cyan}${title} Installer${normal}\n\n"

        echo -n "installing pact dependencies.."
        pact install ${pact_dependencies} &> /dev/null
        echo "${green}OK${normal}"

        echo -n "installing pip.."
        wget -q ${pip_url}
        python get-pip.py &> /dev/null
        rm -r get-pip.py
        echo "${green}OK${normal}"

        echo -n "Installing pip dependencies.."
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
        echo "${green}OK${normal}"

        if [ -d ${ansible_dir} ]
        then
            echo -n "updating Ansible.."
            cd ${ansible_directory}
            git checkout devel &> /dev/null
            git pull --rebase &> /dev/null
            git submodule update --init --recursive &> /dev/null
            echo "${green}OK${normal}"
        else
            echo -n "installing Ansible.."
            git clone ${ansible_repo_url} --recursive ${ansible_dir} --quiet
            cp ${ansible_dir}/examples/ansible.cfg ~/.ansible.cfg
            sed -i 's|#\?transport.*$|transport = paramiko|;s|#host_key_checking = False|host_key_checking = False|' ~/.ansible.cfg
            touch ${installed}
            echo "${green}OK${normal}"
        fi
        seed_test_project
        configure_shell
        sleep 2
        clear
        echo "${green}installed completed, exiting..${normal}"
        sleep 3
        exit
    fi
}

plugin()
{
    while IFS="" read -d $'\0' -r plugins_main
    do
        for file in ${plugins_main}/*.sh
        do
            name=$(basename ${file} ".sh")
            source $file
            ${name}_main
        done
    done < <(find ${plugin_dir} -mindepth 1 -maxdepth 1 -not -path ${disabled_plugin_dir} -type d -print0)
}

clear
echo "${green}starting up..${normal}"
installer
update
plugin
run
tests
