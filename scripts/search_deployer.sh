#######################################################
##################### Disable firewalld ###############
#######################################################
systemctl stop firewalld
systemctl disable firewalld

site_string=$(echo $json | jq -r $CONFIG_LOCATION.site_string)
count=$(echo $json | jq -r $CONFIG_LOCATION.count)
master_public_ip=$(echo $json | jq -r $CONFIG_LOCATION.master_public_ip)
role_title=$(echo $json | jq -r $CONFIG_LOCATION.role_title)

file="splunk-7.3.1-bd63e13aa157-linux-2.6-x86_64.rpm"
version="7.3.1"
url="https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=$version&product=splunk&filename=$file&wget=true"
wget $url -O $file
chmod 744 $file
mkdir -p /opt/splunk
rpm -i $file

# template other conf files
cat << EOF > /opt/splunk/etc/system/local/inputs.conf
[default]
host = $role_title
EOF

cat << EOF > /opt/splunk/etc/system/local/outputs.conf
[indexer_discovery:indexer_discovery]
pass4SymmKey = democluster
master_uri = https://$master_public_ip:8089

[tcpout:indexers]
indexerDiscovery = indexer_discovery

[tcpout]
defaultGroup = indexers
EOF

cat << EOF > /opt/splunk/etc/system/local/ui-tour.conf
[search-tour]
viewed = 1
EOF

cat << EOF > /opt/splunk/etc/system/local/server.conf
[general]
site = site0

[clustering]
multisite = true
mode = searchhead
master_uri = https://$master_public_ip:8089
pass4SymmKey = democluster

#[shclustering]
#disabled = 0
#pass4SymmKey = demoshcluster
#shcluster_label = search_head_cluster

[diskUsage]
minFreeSpace = 1000

EOF

cat << EOF > /opt/splunk/etc/system/local/user-seed.conf
USERNAME = admin
PASSWORD = $password
EOF

/opt/splunk/bin/splunk start --accept-license --answer-yes --no-prompt