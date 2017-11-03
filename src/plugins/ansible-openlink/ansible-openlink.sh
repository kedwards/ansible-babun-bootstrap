#!/usr/bin/env zsh

# sys
pushd `dirname ${0}` > /dev/null && plugin_path=`pwd` && popd > /dev/null
title='Ansible Automation'
name=$(basename ${0} .sh)

source "${plugin_path}/${name}.local"
github_user='kedwards'
library="${workspace}/${name}/library"
filter_plugins="${workspace}/${name}/filter_plugins"
repos=('ansible-openlink' 'ansible-vault-filter' 'ansible-module-devel')
title="MRM ${title}"
github_url="https://${github_key}@github.com"

ansible-openlink_test()
{
    cd ${workspace}/ansible-openlink
    echo -n "testing openlink connections..."
    chmod -x ${workspace}/${name}/conf/{vault_password,vault_key}
    ansible VPWV0281AP01,EWWV0480AP01 -i inventory -m win_ping &> /dev/null
    chk_ret_val
}

ansible-openlink_main()
{
    echo -n "Configuring ${name} plugin..."
    for repo in ${repos}; do
        if [ ! -d  ${workspace}/${repo} ]
        then
            git clone ${github_url}/${github_user}/${repo}.git ${workspace}/${repo} #&> /dev/null
        else
            cd  ${workspace}/${repo}
            git checkout master &> /dev/null
            git pull --rebase &> /dev/null
        fi

        if [[ ${repo} == "${name}" ]]
        then
            chmod -x ${workspace}/${repo}/conf/{vault_password,vault_key}
        fi

        if [[ ${repo} == "ansible-module-devel" ]] && [ ! -L ${library}/modules ]
        then
            ln -s ${workspace}/${repo}/src ${library}/modules
        fi

        if [[ ${repo} == "ansible-filter_vault" ]] && [ ! -L ${filter_plugins}/vault.py ]
        then
            ln -s ${workspace}/${repo}/src/vault.py ${filter_plugins}/vault.py
        fi
    done
    echo "${green}OK${normal}"
}
