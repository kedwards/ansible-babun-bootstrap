#!/usr/bin/env zsh

name=$(basename ${0} .sh)
oracle_home='/usr/local/etc/oracle'
instantclient='instantclient_12_2'
repos=('ansible-oracle-modules')
github_user='kedwards'
http_basic_link='http://download.oracle.com/otn/nt/instantclient/122010/instantclient-basic-nt-12.2.0.1.0.zip'
http_sqlplus_link='http://download.oracle.com/otn/nt/instantclient/122010/instantclient-sqlplus-nt-12.2.0.1.0.zip'
http_tools_link='http://download.oracle.com/otn/nt/instantclient/122010/instantclient-tools-nt-12.2.0.1.0.zip'

oracle-instantclient_test()
{
    cd ${workspace}/ansible-openlink
    echo -n  "testing ansible with sqlplus..."
    ansible local, -m oracle_sql -a "hostname=olddly01.cnpl.enbridge.com service_name=olddly01 user=endur password=endurIT port=62001 sql='select sysdate from dual'" &> /dev/null
    chk_ret_val
}

oracle-instantclient_main()
{
    echo -n "Configuring ${name} plugin..."
    if [ ! -d  ${oracle_home}/tmp ]
    then
        mkdir -p ${oracle_home}/tmp

        # Required login and cookie auth from Oracle
        #wget -qO${oracle_home}/basic.zip ${http_basic_link}
        7za x -o${oracle_home}/ ${workspace}/${script_name}/src/plugins/${name}/instantclient-basiclite-nt-12.2.0.1.0.zip &> /dev/null
        #wget -qO${oracle_home}/sqlplus.zip ${http_sqlplus_link}
        7za x -o${oracle_home}/ ${workspace}/${script_name}/src/plugins/${name}/instantclient-sqlplus-nt-12.2.0.1.0.zip &> /dev/null
        #wget -qO${oracle_home}/tools.zip ${http_tools_link}
        7za x -o${oracle_home}/ ${workspace}/${script_name}/src/plugins/${name}/instantclient-tools-nt-12.2.0.1.0.zip &> /dev/null

        if grep -q '# SQLTools for Ansible' ~/.zshrc
        then
            sed -i -E "/export/s/(^(.)*)\/instantclient_.+$/\1\/${instantclient}/" ~/.zshrc
        else
            cat >> ~/.zshrc <<EOF

#
# SQLTools for Ansible
#
export PATH=\${PATH}:${oracle_home}/${instantclient}
EOF
        fi
    fi

    for repo in ${repos}; do
        if [ ! -d  ${workspace}/${repo} ]
        then
            git clone ${github_url}/${github_user}/${repo}.git ${workspace}/${repo} &> /dev/null
        else
            cd  ${workspace}/${repo}
            git checkout master &> /dev/null
            git pull --rebase &> /dev/null
        fi

        if [ ! -L ${library}/${repo} ]
        then
            ln -s ${workspace}/${repo} ${library}/${repo}
        fi
    done
    echo "${green}OK${normal}"
}
