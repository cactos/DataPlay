#!/bin/bash

# This is setup script for Load Balancer.

set -ex

#if [ "$(id -u)" != "0" ]; then
#	echo >&2 "Error: This script must be run as user 'root'";
#	exit 1
#fi

source $(dirname $0)/../helper.sh

if [ "$(id -u)" != "0" ]; then
LOGDIR=${PWD}/var/log/dataplay
#PROJECTDIR=/opt/dataplay
else
LOGDIR=/var/log/dataplay
#PROJECTDIR=/opt/dataplay
fi
LOGFILENAME=haproxy.log
LOGFILE=$LOGDIR/$LOGFILENAME

logsetup

check_variables () {
	verify_variable_set "CONTAINER_IP"
	verify_variable_set "PUBLIC_PUBLICLOADBALANCERPORT"
	verify_variable_set "CLOUD_LOADBALANCERSTATSPORT"

	verify_variable_notempty "CONTAINER_IP"
	verify_variable_notempty "PUBLIC_PUBLICLOADBALANCERPORT"
	verify_variable_notempty "CLOUD_LOADBALANCERSTATSPORT"
	
	CONTAINER_HOST_IP=$CONTAINER_IP
}

GO_VERSION="go1.4.3"

HOST=$(ifconfig eth0 | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}')
PORT="1938"

# REDIS_HOST="109.231.121.13"
REDIS_HOST="abcd" #$(ss-get --timeout 360 redis.hostname)
REDIS_PORT="6379"

#JCATASCOPIA_REPO="109.231.126.62"
#JCATASCOPIA_DASHBOARD="109.231.122.112"

print_config_file_header() {
echo "global" >> ${PWD}/haproxy.cfg
echo "   log /dev/log    local0" >> ${PWD}/haproxy.cfg
echo "   log /dev/log    local1 notice" >> ${PWD}/haproxy.cfg
echo "   chroot /var/lib/haproxy >> ${PWD}/haproxy.cfg" >> ${PWD}/haproxy.cfg
echo "   stats socket /run/haproxy/admin.sock mode 660 level admin" >> ${PWD}/haproxy.cfg
echo "   stats timeout 30s" >> ${PWD}/haproxy.cfg
echo "   user haproxy" >> ${PWD}/haproxy.cfg
echo "   group haproxy" >> ${PWD}/haproxy.cfg
echo "" >> ${PWD}/haproxy.cfg
echo "   # Default SSL material locations" >> ${PWD}/haproxy.cfg
echo "   ca-base /etc/ssl/certs" >> ${PWD}/haproxy.cfg
echo "   crt-base /etc/ssl/private" >> ${PWD}/haproxy.cfg
echo "" >> ${PWD}/haproxy.cfg
echo "   # Default ciphers to use on SSL-enabled listening sockets." >> ${PWD}/haproxy.cfg
echo "   # For more information, see ciphers(1SSL)." >> ${PWD}/haproxy.cfg
echo "   ssl-default-bind-ciphers kEECDH+aRSA+AES:kRSA+AES:+AES256:RC4-SHA:!kEDH:!LOW:!EXP:!MD5:!aNULL:!eNULL" >> ${PWD}/haproxy.cfg
echo ""  >> ${PWD}/haproxy.cfg
echo "defaults" >> ${PWD}/haproxy.cfg
echo "    log     global" >> ${PWD}/haproxy.cfg
echo "    mode    http" >> ${PWD}/haproxy.cfg
echo "    balance roundrobin" >> ${PWD}/haproxy.cfg
echo ""   >> ${PWD}/haproxy.cfg
echo "    option  abortonclose # abort request if client closes output channel while waiting" >> ${PWD}/haproxy.cfg
echo "    option  httpclose # add "Connection:close" header if it is missing" >> ${PWD}/haproxy.cfg
echo "    option  forwardfor # insert x-forwarded-for header so that app servers can see both proxy and client IPs" >> ${PWD}/haproxy.cfg
echo "    option  redispatch # any server can handle any session" >> ${PWD}/haproxy.cfg
echo "    option  http-server-close # allows keep-alive and pipelining" >> ${PWD}/haproxy.cfg
echo "    option  httplog" >> ${PWD}/haproxy.cfg
echo "    option  dontlognull" >> ${PWD}/haproxy.cfg
echo "    timeout connect 5s" >> ${PWD}/haproxy.cfg
echo "    timeout client  600s" >> ${PWD}/haproxy.cfg
echo "    timeout server  600s" >> ${PWD}/haproxy.cfg
echo "    timeout check   5s" >> ${PWD}/haproxy.cfg
echo "    timeout http-keep-alive 300s" >> ${PWD}/haproxy.cfg
echo "" >> ${PWD}/haproxy.cfg
echo "    retries 3 # number of connection retries for the session" >> ${PWD}/haproxy.cfg
echo "    maxconn 10000" >> ${PWD}/haproxy.cfg
echo "" >> ${PWD}/haproxy.cfg
echo "    http-check expect status 200" >> ${PWD}/haproxy.cfg
echo "" >> ${PWD}/haproxy.cfg
echo "    errorfile 400 /etc/haproxy/errors/400.http" >> ${PWD}/haproxy.cfg
echo "    errorfile 403 /etc/haproxy/errors/403.http" >> ${PWD}/haproxy.cfg
echo "    errorfile 408 /etc/haproxy/errors/408.http" >> ${PWD}/haproxy.cfg
echo "    errorfile 500 /etc/haproxy/errors/500.http" >> ${PWD}/haproxy.cfg
echo "    errorfile 502 /etc/haproxy/errors/502.http" >> ${PWD}/haproxy.cfg
echo "    errorfile 503 /etc/haproxy/errors/503.http" >> ${PWD}/haproxy.cfg
echo "    errorfile 504 /etc/haproxy/errors/504.http" >> ${PWD}/haproxy.cfg
echo "" >> ${PWD}/haproxy.cfg
echo "frontend web" >> ${PWD}/haproxy.cfg
echo "    bind *:${PUBLIC_PUBLICLOADBALANCERPORT}" >> ${PWD}/haproxy.cfg
echo "" >> ${PWD}/haproxy.cfg
echo "    # API traffic goes to Master cluster" >> ${PWD}/haproxy.cfg
echo "    acl api path_beg /api" >> ${PWD}/haproxy.cfg
echo "    use_backend masters if api" >> ${PWD}/haproxy.cfg
echo "" >> ${PWD}/haproxy.cfg
echo "    # Other traffic goes to Gamification server" >> ${PWD}/haproxy.cfg
echo "    default_backend gamification" >> ${PWD}/haproxy.cfg
}

print_config_file_misc() {
echo "" >> ${PWD}/haproxy.cfg
echo "    {% for node in master %}" >> ${PWD}/haproxy.cfg
echo "    server {{ node.id|lower }} {{ node.endpoint }} cookie {{ node.id|upper }} check # added on {{ node.timestamp|date('r') }}" >> ${PWD}/haproxy.cfg
echo "    {% endfor %}" >> ${PWD}/haproxy.cfg
}

print_config_file_footer() {
echo "" >> ${PWD}/haproxy.cfg
echo "listen stats *:${CLOUD_LOADBALANCERSTATSPORT}" >> ${PWD}/haproxy.cfg
echo "    stats enable" >> ${PWD}/haproxy.cfg
echo "    stats uri /" >> ${PWD}/haproxy.cfg
echo "    stats hide-version" >> ${PWD}/haproxy.cfg
echo "    stats auth playgen:D@taP1aY" >> ${PWD}/haproxy.cfg
}

add_gamification_prefix() {
echo "" >> ${PWD}/haproxy.cfg
echo "backend gamification" >> ${PWD}/haproxy.cfg
echo "    http-request set-header X-Forwarded-Port ${PUBLIC_PUBLICLOADBALANCERPORT}" >> ${PWD}/haproxy.cfg
echo "    http-request add-header X-Forwarded-Proto https if { ssl_fc }" >> ${PWD}/haproxy.cfg
echo "    option httpchk HEAD / HTTP/1.1\r\nHost:localhost" >> ${PWD}/haproxy.cfg
echo "    cookie DPSession prefix" >> ${PWD}/haproxy.cfg
}

add_master_prefix() {
echo "" >> ${PWD}/haproxy.cfg
echo "backend masters" >> ${PWD}/haproxy.cfg
echo "    http-request set-header X-Forwarded-Port ${PUBLIC_PUBLICLOADBALANCERPORT}" >> ${PWD}/haproxy.cfg
echo "    http-request add-header X-Forwarded-Proto https if { ssl_fc }" >> ${PWD}/haproxy.cfg
echo "    option httpchk HEAD /api/ping HTTP/1.1\r\nHost:localhost" >> ${PWD}/haproxy.cfg
echo "    cookie DPSession prefix" >> ${PWD}/haproxy.cfg
}

add_master_node() {
# echo "    {% for node in gamification %}" >> ${PWD}/haproxy.cfg
#echo "    server master${2} lower $1 cookie master${2} upper check # added on {{ node.timestamp|date('r') }}" >> ${PWD}/haproxy.cfg
echo "    server master${2} $1 cookie master${2} check # added on {{ node.timestamp|date('r') }}" >> ${PWD}/haproxy.cfg
# echo "    {% endfor %}" >> ${PWD}/haproxy.cfg
}

add_gamification_node() {
# echo "    {% for node in gamification %}" >> ${PWD}/haproxy.cfg
#echo "    server master${2} lower $1 cookie master${2} upper check # added on {{ node.timestamp|date('r') }}" >> ${PWD}/haproxy.cfg
echo "    server gamification${2} $1 cookie master${2} check # added on {{ node.timestamp|date('r') }}" >> ${PWD}/haproxy.cfg
# echo "    {% endfor %}" >> ${PWD}/haproxy.cfg
}

update_config_file() {

echo "" > ${PWD}/haproxy.cfg

verify_variable_set "CLOUD_MasterDownstreamPort"
verify_variable_set "CLOUD_GamificationDownstreamNode"

print_config_file_header

counter=0
add_master_prefix
if [ -z ${CLOUD_MasterDownstreamPort} ] ; then 
	log "no master downstream nodes set"
else 
    arr=$(echo $CLOUD_MasterDownstreamPort | tr "," "\n")
    for x in $arr
    ## take the last one (for no particular reason)
        do
		add_master_node $x $counter
                log "CLOUD_MasterDownstreamPort > [$x]"
		counter=$((counter+1))
        done
fi

add_gamification_prefix
counter=0
if [ -z ${CLOUD_GamificationDownstreamNode} ] ; then 
	log "no gamification downstream nodes set"
else 
    arr=$(echo $CLOUD_GamificationDownstreamNode | tr "," "\n")
    for x in $arr
    ## take the last one (for no particular reason)
        do
		add_gamification_node $x $counter
                log "CLOUD_GamificationDownstreamNode > [$x]"
		counter=$((counter+1))
        done
fi

print_config_file_footer
sudo cp ${PWD}/haproxy.cfg /etc/haproxy/haproxy.cfg
}

timestamp () {
	date +"%F %T,%3N"
}

setuphost () {
	HOSTNAME=$(hostname)
	HOSTLOCAL="127.0.1.1"
	echo "$HOSTLOCAL $HOSTNAME" >> /etc/hosts
}

install_haproxy () {
#	apt-add-repository -y ppa:vbernat/haproxy-1.5
#	apt-get update
	apt-get install -y haproxy sysstat htop

	# Using single quotes to avoid bash $ variable expansion
	echo '# HAProxy' >> /etc/rsyslog.conf
	echo '$ModLoad imudp' >> /etc/rsyslog.conf
	echo '$UDPServerAddress 127.0.0.1' >> /etc/rsyslog.conf
	echo '$UDPServerRun 514' >> /etc/rsyslog.conf

	service rsyslog restart
	service haproxy stop
	#update-rc.d haproxy disable
}

setup_haproxy_api () {
	URL="https://raw.githubusercontent.com"
	USER="playgenhub"
	REPO="DataPlay"
	BRANCH="master"
	SOURCE="$URL/$USER/$REPO/$BRANCH"

	command -v haproxy >/dev/null 2>&1 || { echo >&2 "Error: Command 'haproxy' not found!"; exit 1; }

	command -v npm >/dev/null 2>&1 || { echo >&2 'Error: Command "npm" not found!'; exit 1; }

	command -v forever >/dev/null 2>&1 || { echo >&2 "Error: 'forever' is not installed!"; exit 1; }

	command -v coffee >/dev/null 2>&1 || { echo >&2 "Error: 'coffee-script' is not installed!"; exit 1; }

	mkdir -p /home/ubuntu && cd /home/ubuntu
	mkdir -p haproxy-api && cd haproxy-api

	wget --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 -t 0 -N $SOURCE/tools/deployment/loadbalancer/api/app.coffee && \
	wget --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 -t 0 -N $SOURCE/tools/deployment/loadbalancer/api/package.json && \
	wget --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 -t 0 -N $SOURCE/tools/deployment/loadbalancer/api/proxy.json && \
	wget --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 -t 0 -N $SOURCE/tools/deployment/loadbalancer/api/haproxy.cfg.template

	npm install

	coffee -cb app.coffee > app.js

	forever start -l forever.log -o output.log -e errors.log app.js >/dev/null 2>&1

	# Gamification:
	# curl -i -H "Accept: application/json" -H "Content-Type: application/json" -X POST -d '{"ip":"109.231.121.55:80"}' http://109.231.121.84:1937/gamification
	# curl -i -H "Accept: application/json" -X DELETE http://109.231.121.84:1937/gamification/109.231.121.55:80
	#
	# Master:
	# curl -i -H "Accept: application/json" -H "Content-Type: application/json" -X POST -d '{"ip":"109.231.121.94:3000"}' http://109.231.121.84:1937/master
	# curl -i -H "Accept: application/json" -X DELETE http://109.231.121.84:1937/master/109.231.121.94:3000
}

install_go () {
	apt-get install -y mercurial bzr

	mkdir -p /home/ubuntu && cd /home/ubuntu
	mkdir -p gocode && mkdir -p www

	wget --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 -t 0 -N https://storage.googleapis.com/golang/$GO_VERSION.linux-amd64.tar.gz
	tar xf $GO_VERSION.linux-amd64.tar.gz

	echo "export GOROOT=/home/ubuntu/go" >> /etc/profile.d/dataplay.sh
	echo "PATH=\$PATH:\$GOROOT/bin" >> /etc/profile.d/dataplay.sh

	echo "export GOPATH=/home/ubuntu/gocode" >> /etc/profile.d/dataplay.sh
	echo "PATH=\$PATH:\$GOPATH/bin" >> /etc/profile.d/dataplay.sh

	. /etc/profile
}

run_monitoring () {
	URL="https://github.com"
	USER="playgenhub"
	REPO="DataPlay-Monitoring"
	BRANCH="master"
	SOURCE="$URL/$USER/$REPO"
	DEST="/home/ubuntu/www"
	APP="dataplay-monitoring"

	START="start.sh"
	LOG="output.log"

	# Kill any running process
	if ps ax | grep -v grep | grep $APP > /dev/null; then
		echo "SHUTDOWN RUNING APP..."
		killall -9 $APP
	fi

	cd $DEST
	echo "Fetching latest ZIP"
	wget --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 -t 0 -N $SOURCE/archive/$BRANCH.zip -O $BRANCH.zip
	echo "Extracting from $BRANCH.zip"
	unzip -oq $BRANCH.zip
	if [ -d $APP ]; then
		rm -r $APP
	fi
	mkdir -p $APP
	echo "Moving files from $REPO-$BRANCH/ to $APP"
	mv -f $REPO-$BRANCH/* $APP
	cd $APP
	chmod u+x $START
	echo "Starting $START"
	nohup sh $START > $LOG 2>&1&
	echo "Done! $ sudo tail -f $DEST/$APP/$LOG for more details"
}

export_variables () {
	echo "export DP_REDIS_HOST=$REDIS_HOST" >> /etc/profile.d/dataplay.sh
	echo "export DP_REDIS_PORT=$REDIS_PORT" >> /etc/profile.d/dataplay.sh
	echo "export DP_MONITORING_PORT=$PORT" >> /etc/profile.d/dataplay.sh

	. /etc/profile

	su - ubuntu -c ". /etc/profile"
}

update_iptables () {
	iptables -A INPUT -p tcp --dport 1936 -j ACCEPT # HAProxy statistics
	iptables -A INPUT -p tcp --dport 1937 -j ACCEPT # HAProxy API
	iptables -A INPUT -p tcp --dport $PORT -j ACCEPT # API Health monitor

	iptables-save
}

setup_JCatascopiaAgent(){
	wget -q https://raw.githubusercontent.com/CELAR/celar-deployment/master/vm/jcatascopia-agent.sh

	wget -q http://$JCATASCOPIA_REPO/JCatascopiaProbes/HAProxyProbe.jar
	mv ./HAProxyProbe.jar /usr/local/bin/

	bash ./jcatascopia-agent.sh > /tmp/JCata.txt 2>&1

	echo "probes_external=HAProxyProbe,/usr/local/bin/HAProxyProbe.jar" | sudo -S tee -a /usr/local/bin/JCatascopiaAgentDir/resources/agent.properties
	eval "sed -i 's/server_ip=.*/server_ip=$JCATASCOPIA_DASHBOARD/g' /usr/local/bin/JCatascopiaAgentDir/resources/agent.properties"

	/etc/init.d/JCatascopia-Agent restart > /tmp/JCata.txt 2>&1

	rm ./jcatascopia-agent.sh
}

#command -v node >/dev/null 2>&1 || { echo >&2 "Error: Command 'node' not found!"; exit 1; }

#command -v npm >/dev/null 2>&1 || { echo >&2 "Error: Command 'npm' not found!"; exit 1; }

# in case other servers are running
sudo service nginx stop

case "$1" in 
	        install)
			echo "[$(timestamp)] ---- 1. Setup Host ----"
			setuphost
			echo "[$(timestamp)] ---- 2. Install HAProxy ----"
			install_haproxy
			#echo "[$(timestamp)] ---- 3. Setup HAProxy API ----"
			#setup_haproxy_api
			;;
		configure)
			check_variables
			update_config_file
			/usr/bin/sudo sed -i -e 's/daemon//g' /etc/haproxy/haproxy.cfg
			#echo "[$(timestamp)] ---- 4. Install GO ----"
			#install_go
			#echo "[$(timestamp)] ---- 5. Export Variables ----"
			#export_variables
			#echo "[$(timestamp)] ---- 6. Run API Monitoring Probe ----"
			#run_monitoring
			#echo "[$(timestamp)] ---- 7. Update IPTables rules ----"
			#update_iptables
			;;
		start)
			check_variables
			service haproxy stop
			service haproxy start
			#exec sleep infinity
			;;
		stop)
			service haproxy stop
			## FIxME
			### kill -9 1
			;;
		startdetect)
			;;
		stopdetect)
			;;
		updateports)
			check_variables
			update_config_file
			service haproxy reload
			;;
esac

echo "[$(timestamp)] ---- Completed ----"

exit 0

