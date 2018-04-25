#!/usr/bin/env bash
php_major='PHP 7.2.4'
php_version='/php-7.2.4-nts-Win32-VC15-x64'

php_url='http://windows.php.net/downloads/releases'
name=$(basename ${0} .sh)
php_path='/usr/local/etc/php'

php_test()
{
    echo -n "testing php version.."
    cd ${workspace}
    php -v | grep ${php_major} > /dev/null
    chk_ret_val
}

php_main()
{
    echo -n "Configuring ${name} plugin..."

    if [ ! -d  ${php_path}/${php_version} ]
    then
        mkdir -p ${php_path}
        wget -qO${php_path}/php.zip ${php_url}/${php_version}.zip
        unzip -qq ${php_path}/php.zip -d ${php_path}/${php_version}
        chmod -R +x ${php_path}/${php_version}
        cp ${php_path}/${php_version}/php.ini-development ${php_path}/${php_version}/php.ini

        #sed -i 's/; extension_dir = "ext"/extension_dir = "ext"/' ${php_path}/${php_version}/php.ini
        #sed -i 's;/;extension=php_openssl.dll/extension=php_openssl.dll/' ${php_path}/${php_version}/php.ini
        #sed -i 's;/;date.timezone =/date.timezone = America\/Edmonton/' ${php_path}/${php_version}/php.ini
        #sed -i 's;/;extension=php_mbstring.dll/extension=php_mbstring.dll/' ${php_path}/${php_version}/php.ini
        sed -i 's/; extension_dir = "ext"/extension_dir = "ext"/;s/;extension=php_openssl.dll/extension=php_openssl.dll/;s/;date.timezone =/date.timezone = America\/Edmonton/;s/;extension=php_mbstring.dll/extension=php_mbstring.dll/' ${php_path}/${php_version}/php.ini

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

    echo "${green}OK${normal}"
}
