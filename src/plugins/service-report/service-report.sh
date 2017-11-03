#!/usr/bin/env bash

name=$(basename ${0} .sh)
github_user='kedwards'
repos=('service-report')
php_url='http://windows.php.net/downloads/releases'
php_path='/usr/local/etc/php'
php_version='php-7.1.11-Win32-VC14-x64'

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
            git clone ${github_url}/${github_user}/${repo}.git ${workspace}/${repo} &> /dev/null
        else
            cd  ${workspace}/${repo}
            git checkout master &> /dev/null
            git pull --rebase &> /dev/null
        fi
    done

    get_dependencies
    echo "${green}OK${normal}"
}

get_dependencies()
{
    if [ ! -d  ${php_path}/${php_version} ]
    then
        mkdir -p ${php_path}
        wget -qO${php_path}/php.zip ${php_url}/${php_version}.zip
        unzip -qq ${php_path}/php.zip -d ${php_path}/${php_version}
        chmod -R +x ${php_path}/${php_version}
        cp ${php_path}/${php_version}/php.ini-development ${php_path}/${php_version}/php.ini
        rm ${php_path}/php.zip

        cat > /usr/local/bin/php << EOF
#!/bin/bash

php="${php_path}/${php_version}/php.exe"

for ((n=1; n <= \$#; n++)); do
    if [ -e "\${!n}" ]; then
        # Converts Unix style paths to Windows equivalents
        path="\$(cygpath --mixed \${!n} | xargs)"

        case 1 in
            \$(( n == 1 )) )
                set -- "\$path" "\${@:\$((\$n+1))}";;
            \$(( n < \$# )) )
                set -- "\${@:1:\$((n-1))}" "\$path" \${@:\$((n+1)):\$#};;
            *)
                set -- "\${@:1:\$((\$#-1))}" "\$path";;
        esac
    fi
done

"\$php" "\$@"
EOF
        chmod +x /usr/local/bin/php
    fi
}
