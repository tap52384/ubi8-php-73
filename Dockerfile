# https://access.redhat.com/containers/?tab=images&get-method=unauthenticated#/registry.access.redhat.com/ubi8/php-73
# https://github.com/sclorg/s2i-php-container/tree/master/7.3
# https://access.redhat.com/containers/?architecture&tab=docker-file#/registry.access.redhat.com/ubi8/php-73/images/1-18
# docker build --pull -t tap52384:ubi8-php-73 ~/code/ubi8-php-73
FROM registry.access.redhat.com/ubi8/php-73

# Add necessary labels
LABEL io.k8s.description="PHP 7.3 with Database Connectors" \
      io.k8s.display-name="Apache 2.4 with PHP 7.3 and Database Connectors" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="builder,php,php73,sqlsrv,mcrypt,oracle,oci8,oci" \
      help="For more information visit https://access.redhat.com/containers/?tab=images&get-method=unauthenticated#/registry.access.redhat.com/ubi8/php-73" \
      io.openshift.s2i.scripts-url="image:///opt/app-root/s2i/bin"

# Change the Source-to-Image Scripts URL Environment Variable
ENV STI_SCRIPTS_PATH=/opt/app-root/s2i/bin

EXPOSE 8443

# Switch to the root user
USER 0

COPY ./s2i/bin/ /opt/app-root/s2i/bin

COPY ./etc /opt/app-root/etc/
COPY ./src/*.rpm /opt/app-root/etc/

# Set so that you can use the "clear" command
ENV TERM=xterm

# Install necessary packages
RUN cp /opt/app-root/etc/ubi7.repo /etc/yum.repos.d/ubi7.repo && \
    yum -y --disableplugin=subscription-manager remove unixODBC-utf16 && \
    yum config-manager --disableplugin=subscription-manager \
    --enable ubi-7-server-optional-rpms \
    --enable ubi-7-server-extras-rpms \
    --enable ubi-7 && \
    curl https://packages.microsoft.com/config/rhel/8/prod.repo > /etc/yum.repos.d/mssql-release.repo && \
    # https://fedoraproject.org/wiki/EPEL
    echo 'Installing epel-release (Extra Packages for Enterprise Linux)...' && \
    yum install -y --setopt=tsflags=nodocs --disableplugin=subscription-manager https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm && \
    ARCH=$( /bin/arch ) && \
    yum --disableplugin=subscription-manager repolist > /dev/null && \
    echo 'Installing downloaded dependencies before yum install...' && \
    rpm -i /opt/app-root/etc/net-snmp-libs-5.8-10.el8.x86_64.rpm \
    /opt/app-root/etc/net-snmp-utils-5.8-10.el8.x86_64.rpm \
    /opt/app-root/etc/libyaml-devel-0.1.7-5.el8.x86_64.rpm && \
    echo 'Installing packages via yum...' && \
    # fuse, fuse-libs, fuse-common is needed for e2fsprogs
    # diffutils installs cmp command
    # Download RedHat packages from here (requires free account)
    # https://access.redhat.com/downloads/content/package-browser
    INSTALL_PKGS="diffutils fuse fuse-common fuse-libs gettext libzip libzip-devel nss_wrapper libaio libmcrypt libmcrypt-devel libss libyaml pcre-utf16 php-devel php-pear php-pecl-zip php-snmp unixODBC-devel" && \
    ACCEPT_EULA=Y yum install -y --setopt=tsflags=nodocs --disableplugin=subscription-manager $INSTALL_PKGS && \
    echo 'rpm -V $INSTALL_PKGS...' && \
    rpm -V $INSTALL_PKGS && \
    echo 'Installing manually downloaded packages...' && \
    # e2fsprogs is needed for msodbcsql17, but not available via yum
    rpm -i /opt/app-root/etc/e2fsprogs-libs-1.44.6-3.el8.x86_64.rpm \
    /opt/app-root/etc/libnsl-2.28-72.el8.x86_64.rpm \
    /opt/app-root/etc/e2fsprogs-1.44.6-3.el8.x86_64.rpm \
    # Needed for LDAP headers
    /opt/app-root/etc/libtalloc-devel-2.1.16-3.el8.x86_64.rpm \
    /opt/app-root/etc/libtevent-devel-0.9.39-2.el8.x86_64.rpm \
    /opt/app-root/etc/libtevent-0.9.39-2.el8.x86_64.rpm \
    /opt/app-root/etc/libtdb-1.3.18-2.el8.x86_64.rpm \
    /opt/app-root/etc/libtdb-devel-1.3.18-2.el8.x86_64.rpm \
    /opt/app-root/etc/libldb-1.5.4-2.el8.x86_64.rpm \
    /opt/app-root/etc/libldb-devel-1.5.4-2.el8.x86_64.rpm && \
    echo 'Installing MS SQL 17...' && \
    INSTALL_PKGS="mssql-tools msodbcsql17" && \
    ACCEPT_EULA=Y yum install -y --setopt=tsflags=nodocs --disableplugin=subscription-manager $INSTALL_PKGS && \
    echo 'rpm -V $INSTALL_PKGS...' && \
    # Install Oracle InstantClient (including SQL*Plus)
    echo "Installing Oracle InstantClient..." && \
    rpm -i https://download.oracle.com/otn_software/linux/instantclient/195000/oracle-instantclient19.5-basic-19.5.0.0.0-1.x86_64.rpm && \
    rpm -i https://download.oracle.com/otn_software/linux/instantclient/195000/oracle-instantclient19.5-devel-19.5.0.0.0-1.x86_64.rpm && \
    rpm -i https://download.oracle.com/otn_software/linux/instantclient/195000/oracle-instantclient19.5-sqlplus-19.5.0.0.0-1.x86_64.rpm && \
    echo "/usr/lib/oracle/19.5/client64/lib" > /etc/ld.so.conf.d/oracle-instantclient.conf && \
    ldconfig && \
    # ln -s /usr/lib64/libnsl.so.2.0.0 /usr/lib64/libnsl.so.1 && \
    echo 'Oracle InstantClient installation complete.' && \
    # echo 'Finished installing manually downloaded packages (that are not broken)...' && \
    # yum update -y --disableplugin=subscription-manager --skip-broken --nobest
    # Configure, install, and enable PHP extensions
    # Uninstall any PECL extensions and install fresh copies
    echo 'Update PECL' && \
    pecl channel-update pecl.php.net && \
    echo "Uninstalling old versions of PECL extensions..." && \
    pecl uninstall -r oci8 \
    pdo_sqlsrv \
    sqlsrv \
    xdebug \
    yaml && \
    # Download, compile, and install PHP extensions via PECL
    pecl install mcrypt && \
    echo "$ORACLE_HOME" | pecl install oci8 && \
    pecl install pdo_sqlsrv && \
    # pecl install smbclient && \
    pecl install sqlsrv && \
    pecl install xdebug && \
    # Needed manual install of libyaml-devel rpm
    printf "\n" | pecl install yaml && \
    echo $PATH && \
    # Shows what extensions have INI files already specified
    ls -al /etc/php.d/

    # Download the source for the current version of PHP as a tar.xz
RUN PHP_SOURCE_VERSION=$(php -v | grep cli | cut -d ' ' -f 2) && \
    echo "PHP_SOURCE_VERSION : ${PHP_SOURCE_VERSION}" && \
    mkdir -p /usr/src/ && \
    curl -Lo /usr/src/php.tar.xz http://php.net/get/php-${PHP_SOURCE_VERSION}.tar.xz/from/this/mirror && \
    # Download commands from the official PHP docker image to make
    # installing and configuring extensions easier
    curl -L https://raw.githubusercontent.com/docker-library/php/master/docker-php-ext-configure -o /usr/local/bin/docker-php-ext-configure && \
    curl -L https://raw.githubusercontent.com/docker-library/php/master/docker-php-source -o /usr/local/bin/docker-php-source && \
    curl -L https://raw.githubusercontent.com/docker-library/php/master/docker-php-ext-install -o /usr/local/bin/docker-php-ext-install && \
    curl -L https://raw.githubusercontent.com/docker-library/php/master/docker-php-ext-enable -o /usr/local/bin/docker-php-ext-enable && \
    chmod u+x /usr/local/bin/docker-php-ext-configure \
    /usr/local/bin/docker-php-ext-enable \
    /usr/local/bin/docker-php-ext-install \
    /usr/local/bin/docker-php-source && \
    # Needed for ClamAV class for scanning attachments
    docker-php-ext-install sockets && \
    docker-php-ext-install zip && \
    echo "extension=mcrypt.so" > /etc/php.d/30-mcrypt.ini && \
    # Clean yum cache - https://stackoverflow.com/a/46089220/1620794
    echo 'Clearing cache...' && \
    yum clean all -y --disableplugin=subscription-manager && \
    rm -rf /var/cache/yum && \
    rm -rf /var/cache/dnf && \
    rm -rfv /opt/app-root/etc/*.rpm && \
    touch /tmp/passwd && \
    chmod 664 /tmp/passwd && \
    chmod 664 /etc/odbcinst.ini && \
    which httpd && \
    chmod -R a+rwx /usr/sbin/httpd && \
    # chmod -R a+rwx /opt/rh/httpd24/root/var/run/httpd && \
    cp /etc/openldap/ldap.conf /etc/openldap/ldap.conf.rpm && \
    mv /opt/app-root/etc/ldap.conf /etc/openldap/ldap.conf

# Set associated nss_wrapper environment variables.
ENV LD_PRELOAD=/usr/lib64/libnss_wrapper.so
ENV NSS_WRAPPER_PASSWD=/tmp/passwd
ENV NSS_WRAPPER_GROUP=/etc/group

# Switch back to non-root user
USER 1001

# Configure additional path for MSSQL tools
ENV PATH=$PATH:/opt/mssql-tools/bin

# Set the default CMD to print the usage of the language image
CMD $STI_SCRIPTS_PATH/usage
