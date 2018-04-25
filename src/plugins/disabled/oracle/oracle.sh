#!/usr/bin/env zsh

instantclient='instantclient_12_2'

name=$(basename ${0} .sh)
oracle_home='/usr/local/etc/oracle'
http_basic_link='http://download.oracle.com/otn/nt/instantclient/122010/instantclient-basic-nt-12.2.0.1.0.zip'
http_sqlplus_link='http://download.oracle.com/otn/nt/instantclient/122010/instantclient-sqlplus-nt-12.2.0.1.0.zip'
http_tools_link='http://download.oracle.com/otn/nt/instantclient/122010/instantclient-tools-nt-12.2.0.1.0.zip'

oracle_test()
{
    cd ${workspace}/ansible-openlink
    echo -n  "No current tests for Oracle SQL with sqlplus..."
    chk_ret_val
}

oracle_main()
{
    echo -n "Configuring ${name} plugin..."
    if [ ! -d  ${oracle_home} ]
    then
        mkdir -p ${oracle_home}

        # Required login and cookie auth from Oracle
        #wget -qO${oracle_home}/basic.zip ${http_basic_link}
        7za x -o${oracle_home}/ ${workspace}/${script_name}/src/plugins/${name}/instantclient-basiclite-nt-12.2.0.1.0.zip &> /dev/null
        #wget -qO${oracle_home}/sqlplus.zip ${http_sqlplus_link}
        7za x -o${oracle_home}/ ${workspace}/${script_name}/src/plugins/${name}/instantclient-sqlplus-nt-12.2.0.1.0.zip &> /dev/null
        #wget -qO${oracle_home}/tools.zip ${http_tools_link}
        7za x -o${oracle_home}/ ${workspace}/${script_name}/src/plugins/${name}/instantclient-tools-nt-12.2.0.1.0.zip &> /dev/null
    fi

    zshrc=$(grep -q '# SQLDeveloper Configuration' ~/.zshrc)
    if [ ! ${zshrc} ]
    then
        cat >> ~/.zshrc <<EOF

#
# SQLDeveloper Configuration
#
export TNS_ADMIN=L:\\\\Endur\\\\Main\\\\Database\\\\oracle\\\\NETWORK\\\\ADMIN
export PATH=\${PATH}:${oracle_home}/${instantclient}
EOF
    elif [ $(grep -q ${instantclient} ~/.zshrc) ]
    then
        sed -i -E "/export/s/(^(.)*)\/instantclient_.+$/\1\/${instantclient}/" ~/.zshrc
    fi

    echo "${green}OK${normal}"
}
