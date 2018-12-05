#!/usr/bin/env zsh

name=$(basename ${0} .sh)
oracle_home='/usr/local/etc/oracle'
repos=('ansible-oracle-modules')

oracle-instantclient_test()
{
    cd ${workspace}/ansible-openlink
    echo -n  "testing ansible with sqlplus..."
    ansible local -m oracle_sql -a "hostname=olddly01.cnpl.enbridge.com service_name=olddly01 user=endur password=endurIT port=62001 sql='select sysdate from dual'" &> /dev/null
    chk_ret_val
}

oracle-instantclient_main()
{
    echo -n "Configuring ${name} plugin..."
    for repo in ${repos}; do
        if [ ! -d  ${workspace}/${repo} ]
        then
            svn co --username $USER https://mrmsvn.enbridge.com/svn/mrm_systems/Infrastructure/Automation/${repo} ${workspace}/${repo} &> /dev/null
        else
            cd  ${workspace}/${repo}
            svn update --username $USER &> /dev/null
        fi
    done

    if [ ! -L ${library}/ansible-oracle-modules ]
    then
        ln -s ${workspace}/ansible-oracle-modules ${library}/ansible-oracle-modules
    fi

    echo "${green}OK${normal}"
    
    zshrc=$(grep -q '# Oracle' ~/.zshrc)
    if [ ! ${zshrc} ]
    then
        cat >> ~/.zshrc <<EOF
# Oracle
export TNS_ADMIN=C:\\\\path\\\\to\\\\orace\\\\network\\\\admin
export PATH=\${PATH}:${oracle_home}/${instantclient}
EOF
    elif [ $(grep -q ${instantclient} ~/.zshrc) ]
    then
        sed -i -E "/export/s/(^(.)*)\/instantclient_.+$/\1\/${instantclient}/" ~/.zshrc
    fi

    echo "${green}OK${normal}"
}
