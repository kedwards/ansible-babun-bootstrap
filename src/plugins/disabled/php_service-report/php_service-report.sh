#!/usr/bin/env bash

name=$(basename ${0} .sh)
repos=('service-report')

service-report_test()
{
    echo -n "testing service-report.."
    cd ${workspace}/ansible-openlink
    ansible-playbook plays/service-report.yml &> /dev/null
    chk_ret_val
}

service-report_main()
{
    echo -n "Configuring ${name} plugin..."
    for repo in ${repos}; do
        if [ ! -d  ${workspace}/${repo} ]
        then
            cd ${workspace}
            svn co --username $USER https://mrmsvn.enbridge.com/svn/mrm_systems/Infrastructure/Automation/${repo} ${workspace}/${repo} &> /dev/null
        else
            cd  ${workspace}/${repo}
            svn update --username $USER
        fi
    done

    echo "${green}OK${normal}"
}
