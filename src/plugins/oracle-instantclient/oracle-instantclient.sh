#!/usr/bin/env zsh

name=$(basename ${0} .sh)
oracle_home='/usr/local/etc/oracle'
instantclient='instantclient_12_2'

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
    if [ ! -d  ${oracle_home} ]
    then
        mkdir -p ${oracle_home}

        # Required login and cookie auth from Oracle
        #wget -qO${oracle_home}/basic.zip ${http_basic_link}
        #wget -qO${oracle_home}/sqlplus.zip ${http_sqlplus_link}
        #wget -qO${oracle_home}/tools.zip ${http_tools_link}

        7za x -o${oracle_home}/ ${workspace}/${script_name}/src/plugins/${name}/${instantclient}.7z &> /dev/null

        if grep -q '# SQLTools for Ansible' ~/.zshrc
        then
            sed -i -E "/export/s/(^(.)*)\/instantclient_.+$/\1\/${instantclient}/" ~/.zshrc
        else
            echo -n "configuring zshell for oracle tools.."
            cat >> ~/.zshrc <<EOF

#
# SQLTools for Ansible
#
export PATH=\${PATH}:${oracle_home}/${instantclient}
EOF
        fi
    fi
    echo "${green}OK${normal}"
}
