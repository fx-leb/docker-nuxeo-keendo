if [ -n "$NUXEO_CLUSTERING_ENABLED" ]; then
	echo "repository.clustering.enabled=true" >> $NUXEO_CONF
	echo "nuxeo.server.jvmRoute=$NUXEO_SERVER_JVM_ROUTE" >> $NUXEO_CONF
	echo "repository.clustering.id=$NUXEO_CLUSTER_NODE_ID" >> $NUXEO_CONF
	echo "nuxeo.db.validationQuery=$NUXEO_DB_VALIDATION_QUERY" >> $NUXEO_CONF
fi


# Only the first time the container starts
if [ ! -f $NUXEO_HOME/cluster-configured ]; then
	for f in /deploy/*; do
		case "$f" in
		  *.zip)  
				echo "$0: installing $f";
				gosu $NUXEO_USER nuxeoctl mp-install $f --relax=false --accept=true ;;
		  *)    echo "$0: ignoring $f" ;;
		esac
	done

	if [ -n "$NUXEO_STUDIO_VERSION" ]; then
		gosu $NUXEO_USER nuxeoctl mp-add $NUXEO_STUDIO_VERSION --relax=false --accept=true
		gosu $NUXEO_USER nuxeoctl mp-install $NUXEO_STUDIO_VERSION --relax=false --accept=true
	fi
	touch $NUXEO_HOME/cluster-configured
fi


# Wait for db 
until nc -q 1 $NUXEO_DB_HOST 5432 < /dev/null; do
    sleep 1
done

# Wait for Elasticsearch
IFS=',' read -r -a ES_HOSTS <<< "$NUXEO_ES_HOSTS"
for ES_HOST in "${ES_HOSTS[@]}"
do
	IFS=':' read ES_NAME ES_PORT <<< $ES_HOST
	until nc -q 1 $ES_NAME $ES_PORT < /dev/null; do
	    sleep 1
	done
done

# Wait for nuxeo cluster master instance
if [ -n "$NUXEO_CLUSTER_MASTER_HOST" ]; then
	until [ "$(curl -m 5 -s http://$NUXEO_CLUSTER_MASTER_HOST:8080/nuxeo/runningstatus?info=started)" == "true" ]; do
	    sleep 1
	done	
fi

