#!/bin/bash
set -e

: ${BI_JAVA_OPTS:='-XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap -Djava.security.egd=file:/dev/./urandom -Xms4096m -Xmx4096m -XX:+UseG1GC -XX:+UseStringDeduplication -XX:+PreserveFramePointer -Djava.awt.headless=true -XX:+HeapDumpOnOutOfMemoryError -XX:ErrorFile=../logs/jvm_error.log -XX:HeapDumpPath=../logs/ -verbose:gc -Xloggc:../logs/gc.log -XX:+PrintGCDetails -XX:+PrintGCDateStamps -XX:+PrintHeapAtGC -XX:+PrintStringDeduplicationStatistics -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=2 -XX:GCLogFileSize=64M -XX:OnOutOfMemoryError=/usr/bin/oom_killer -Dsun.rmi.dgc.client.gcInterval=3600000 -Dsun.rmi.dgc.server.gcInterval=3600000 -Dfile.encoding=utf8 -DDI_HOME=\"$DI_HOME\"'}

JAVA_XMS=${JAVA_XMS:-2048}m
JAVA_XMX=${JAVA_XMX:-2048}m
#JAVA_MAXPERM=${JAVA_MAXPERM:-512}m
fix_permission() {
	
	# all sub-directories
	find $PENTAHO_HOME -type d -print0 | xargs -0 chown $PENTAHO_USER
	# and then work directories and files underneath
	for d in "$PENTAHO_HOME/.pentaho" "$PENTAHO_HOME/data/hsqldb" "$PENTAHO_HOME/biserver-ce/tomcat/logs" \
		"$PENTAHO_HOME/pentaho-solutions/system/jackrabbit/repository" "$PENTAHO_HOME/tmp"; do
		[ -d $d ] && chown -Rf $PENTAHO_USER $d/* || true
	done
	find $PENTAHO_HOME -type d -print0 -name "*.sh" | xargs -0 chown $PENTAHO_USER
}

init_biserver() {
	if [ ! -f $PENTAHO_HOME/.initialized ]; then
		echo "Initializing BI server..."
		rm -rf .pentaho/* tmp/* pentaho-solutions/system/jackrabbit/repository/* /tmp/kettle tomcat/temp tomcat/work \
			&& mkdir -p tmp/kettle tmp/osgi/cache tmp/osgi/data/log tmp/osgi/data/tmp tmp/tomcat/temp tmp/tomcat/work \
				tomcat/logs/audit pentaho-solutions/system/logs \
			&& sed -i -e "/CATALINA_OPTS=/a # http://wiki.apache.org/tomcat/HowTo/FasterStartUp#Entropy_Source" /pentaho-server/start-pentaho.sh \
			&& sed -i -e "s|CATALINA_OPTS=.*|CATALINA_OPTS='${BI_JAVA_OPTS}'|" /pentaho-server/start-pentaho.sh \
			&& sed -i -e "s|-Xms4096m -Xmx4096m|-Xms${JAVA_XMS} -Xmx${JAVA_XMX}|" /pentaho-server/start-pentaho.sh \
			&& find $PENTAHO_HOME -type d -print0 | xargs -0 chown $PENTAHO_USER \
			&& touch $PENTAHO_HOME/.initialized
			yes | $PENTAHO_HOME/pentaho-server/start-pentaho.sh		
	else 
		# now start the bi server
		$PENTAHO_HOME/pentaho-server/start-pentaho.sh
	fi
}

# start BI server
init_biserver
fix_permission

/bin/bash -c "trap : TERM INT; sleep infinity & wait"

