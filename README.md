# content-postgresql

## Initial production setup:

    sudo yum install http://yum.postgresql.org/9.4/redhat/rhel-6-x86_64/pgdg-ami201503-94-9.4-1.noarch.rpm
    sudo yum install postgresql94

    apply install.sh

    echo "HOST:5432:user:api:PASSWORD" > ~/.pgpass
    chmod 0600 ~/.pgpass

    sem-dist
    scp -i /web/keys/ssh/mbryzek-key-pair-us-east.pem dist/schema-*.tar.gz ec2-user@IP:~/
    ssh -i /web/keys/ssh/mbryzek-key-pair-us-east.pem ec2-user@IP
    tar xfz schema-*.tar.gz
    cd schema-*

    sudo yum install git

    sem-apply --user api --host HOST --name user
