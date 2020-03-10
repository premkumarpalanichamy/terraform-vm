#!/usr/bin/env bash

set -e

PUPPETMASTER_IP="$1"
PUPPETMASTER_FQDN="$2"
ENV="$3"
ROLE="$4"

if [ -z "$ENV" ]; then
  echo "Environment is not properly set";
  exit 1
fi

if [ -z "$ROLE" ]; then
  echo "Role is not properly set";
  exit 1
fi

echo "Puppetmaster IP=${PUPPETMASTER_IP} FQDN=${PUPPETMASTER_FQDN} ENV=${ENV} Role=${ROLE}" > /tmp/results.txt

# Update local hosts file
echo "Update hosts file..." >> /tmp/results.txt
echo "${PUPPETMASTER_IP}        ${PUPPETMASTER_FQDN} puppet" >> /etc/hosts

echo "kick off puppet..." >> /tmp/results.txt

# Awkcommand to execute, to read Centos/Ubuntu version from /etc/os-release
# Warning: This regex will not work on Ubuntu 14.04,
# because the VERSION_CODENAME is missing.
awkcommand='
/^ID=/ || /^VERSION_CODENAME=/{ # Read ID, VERSION_ID, VERSION_CODENAME lines
    gsub(/"/, "", $2)                             # Remove all quotes
    info[$1]=$2                                   # Save in assoc array
}
/^VERSION_ID=/{ # Read VERSION_ID VERSION_CODENAME lines
    gsub(/"/, "", $2)                             # Remove all quotes
    split($2, array, ".")                         # Split major minor version
    info[$1]=array[1]                             # Save in assoc array
}
END {
    for (x in info){ print x"="info[x]; }         # Creating bash variables.
}'

# Execute awk command
declare $( /usr/bin/gawk -F"=" -- "$awkcommand" /etc/os-release  )

echo "ID = $ID" >> /tmp/results.txt
echo "VERSION = $VERSION_ID"  >> /tmp/results.txt
echo "CODE = $VERSION_CODENAME" >> /tmp/results.txt

case "$ID" in
          "centos")
              yum -y install "https://yum.puppet.com/puppet6/puppet6-release-el-$VERSION_ID.noarch.rpm"
              # Install puppet
              echo "Install puppet 6 release..." >> /tmp/results.txt
              yum -y install puppet
              ;;
          "rhel")
              yum -y install "https://yum.puppet.com/puppet6/puppet6-release-el-$VERSION_ID.noarch.rpm"
              # Install puppet
              echo "Install puppet 6 release..." >> /tmp/results.txt
              yum -y install puppet
              ;;
          *)
              echo $"$ID is not supported."
              exit 1
esac

# Update csr_attributes
echo "Update csr_attributes..." >> /tmp/results.txt
cat << EOF > /etc/puppetlabs/puppet/csr_attributes.yaml
---
extension_requests:
  pp_environment: ${ENV}
  pp_role: ${ROLE}
EOF

# Register puppet node
echo "Start puppet service..." >> /tmp/results.txt
/opt/puppetlabs/bin/puppet agent -t --environment ${ENV}

# Start puppet service
echo "Start puppet service..." >> /tmp/results.txt
service puppet start

echo "bootscript ended..." >> /tmp/results.txt

exit 0