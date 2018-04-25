#!/usr/bin/env zsh

# sys
pushd `dirname ${0}` > /dev/null && plugin_path=`pwd` && popd > /dev/null
title='Ansible Automation'
name=$(basename ${0} .sh)
if [ -e "${plugin_path}/${name}.local" ]
then
    source "${plugin_path}/${name}.local"
fi
library="${workspace}/${name}/library"
filter_plugins="${workspace}/${name}/filter_plugins"
repos=('ansible-openlink' 'ansible-vault-filter' 'ansible-module-devel')
title="MRM ${title}"

ansible-openlink_test()
{
    cd ${workspace}/ansible-openlink
    chmod -x ${workspace}/${name}/conf/{vault_password,vault_key}
    echo -n "testing openlink connections (ctx)..."
    ansible vp_app,ew_app -i inventory -m win_ping &> /dev/null
    chk_ret_val
    echo -n "testing openlink connections (app)..."
    ansible vp_ctx,ew_ctx -i inventory -m win_ping &> /dev/null
    chk_ret_val
}

ansible-openlink_main()
{
    echo -n "Configuring ${name} plugin.."
    for repo in ${repos}; do
        if [ ! -d  ${workspace}/${repo} ]
        then
            svn co --username $USER https://mrmsvn.enbridge.com/svn/mrm_systems/Infrastructure/Automation/${repo} ${workspace}/${repo} #&> /dev/null
        # else
        #     cd  ${workspace}/${repo}
        #     svn update --username $USER #&> /dev/null
        fi
    done

    chmod -x ${workspace}/ansible-openlink/conf/{vault_password,vault_key}
    mkdir -p ${workspace}/ansible-openlink/library

    if [ ! -L  ${library}/ansible-module-devel ]
    then
        ln -s ${workspace}/ansible-module-devel/src ${library}/ansible-module-devel
    fi

    if [ ! -f ${filter_plugins}/vault.py ]
    then
        cp ${workspace}/ansible-vault-filter/src/vault.py ${filter_plugins}/vault.py
    fi
    echo "${green}OK${normal}"
}
