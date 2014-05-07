echo
echo =================
echo "download"
echo =================
wget http://www.eu.apache.org/dist/lucene/solr/4.8.0/solr-4.8.0.tgz

echo
echo =================
echo "extract and get in"
echo =================
tar zxf solr-4.8.0.tgz
rm -r solr-4.8.0/example/solr/collection1
mkdir node2
mkdir node3
cp -R solr-4.8.0/example/* node2/
cp -R solr-4.8.0/example/* node3/
cd solr-4.8.0/example/

echo
echo =================
echo "starting..."
echo =================
java -jar -DzkRun -Dcollection.configName=bbuzz_less -Dhost=127.0.0.1 -Dbootstrap_confdir=./example-schemaless/solr/collection1/conf start.jar --daemon &
# wait for Solr to start - ZooKeeper will be started at 9983 port 
ERROR=1; while [ ! $ERROR -eq 0 ]; do sleep 1; curl 'localhost:8983/solr/admin/ping' > /dev/null; ERROR=$?; done
tail -20 logs/solr.log

echo
echo =================
echo "create sample collection"
echo =================
curl 'http://localhost:8983/solr/admin/collections?action=CREATE&name=bbuzz_less&numShards=1&replicationFactor=1'

echo
echo =================
echo "index the sample documents"
echo =================
cd ../../sample-documents
for file in *.json; do 
  echo $file
  curl 'http://localhost:8983/solr/bbuzz_less/update?commit=true' -H 'Content-type:application/json' -d "[`cat $file`]" 
  echo 
done

echo
echo =================
echo "get schema fields"
echo =================
curl 'http://localhost:8983/solr/bbuzz_less/schema/fields'

echo
echo =================
echo "delete collection"
echo =================
curl 'http://localhost:8983/solr/admin/collections?action=DELETE&name=bbuzz_less'

echo
echo =================
echo "upload new config"
echo =================
cd ../solr-4.8.0/example/
chmod +x scripts/cloud-scripts/zkcli.sh
./scripts/cloud-scripts/zkcli.sh -cmd upconfig -zkhost localhost:9983 -confdir ../../config/solr/ -confname bbuzz

echo
echo =================
echo "create bbuzz collection"
echo =================
curl 'http://localhost:8983/solr/admin/collections?action=CREATE&name=bbuzz&numShards=1&replicationFactor=1'

echo
echo =================
echo "index the sample documents once again"
echo =================
cd ../../sample-documents
for file in *.json; do 
  echo $file
  curl 'http://localhost:8983/solr/bbuzz/update?commit=true' -H 'Content-type:application/json' -d "[`cat $file`]" 
  echo 
done

echo
echo =================
echo "URI search"
echo =================
curl 'http://localhost:8983/solr/bbuzz/select?q=elasticsearch&indent=true'
curl 'http://localhost:8983/solr/bbuzz/select?q=title:elasticsearch%20tags:logs&q.op=OR&indent=true'
curl 'http://localhost:8983/solr/bbuzz/select?q=title:elasticsearch&defType=edismax&bf=recip(ms(NOW,upload_date),3.16e-11,1,1)&indent=true'

echo
echo =================
echo "Field collapsing"
echo =================
curl 'http://localhost:8983/solr/bbuzz/select?q=*:*&group=true&group.field=uploaded_by&group.query=tags:elasticsearch&group.query=tags:solr&group.query=tags:logstash&indent=true'

echo
echo =================
echo "Scale out"
echo =================
curl 'http://localhost:8983/solr/admin/collections?action=DELETE&name=bbuzz'

echo
echo =================
echo "Scale out - creating collection..."
echo =================
curl 'http://localhost:8983/solr/admin/collections?action=CREATE&name=scale-this&numShards=1&replicationFactor=1&collection.configName=bbuzz'

# start node2 - on port 7983
cd ../node2
java -jar -DzkHost=localhost:9983 -Dhost=127.0.0.1 -Djetty.port=7983 start.jar --daemon &
ERROR=1; while [ ! $ERROR -eq 0 ]; do sleep 1; curl 'localhost:7983/solr/admin/ping' > /dev/null; ERROR=$?; done

echo
echo =================
echo "Scale out - adding replica..."
echo =================
curl 'http://localhost:8983/solr/admin/collections?action=ADDREPLICA&shard=shard1&collection=scale-this&node=127.0.0.1:7983_solr'

echo
echo =================
echo "Scale out - starting third node..."
echo =================
cd ../node3
java -jar -DzkHost=localhost:9983 -Dhost=127.0.0.1 -Djetty.port=6983 start.jar --daemon &
ERROR=1; while [ ! $ERROR -eq 0 ]; do sleep 1; curl 'localhost:6983/solr/admin/ping' > /dev/null; ERROR=$?; done

echo
echo =================
echo "Scale out - adding another replica..."
echo =================
curl 'http://localhost:8983/solr/admin/collections?action=ADDREPLICA&shard=shard1&collection=scale-this&node=127.0.0.1:6983_solr'

echo
echo =================
echo "Scale out - split shard..."
echo =================
curl 'http://localhost:8983/solr/admin/collections?action=SPLITSHARD&collection=scale-this&shard=shard1'

echo
echo =================
echo "Monitoring"
echo =================
# get dump from ZooKeeper
curl 'http://localhost:8983/solr/zookeeper?wt=json&dump=true'
# get only cluster state
curl 'http://localhost:8983/solr/zookeeper?wt=json&detail=true&path=%2Fclusterstate.json'
# get cluster status
curl 'http://localhost:8983/solr/admin/collections?action=CLUSTERSTATUS'

# REST stats can be found in JMX Mbeans
# Check jconsole provided with JVM
