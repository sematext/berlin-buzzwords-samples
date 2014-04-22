echo
echo =================
echo "download"
echo =================
wget http://www.eu.apache.org/dist/lucene/solr/4.7.2/solr-4.7.2.tgz

echo
echo =================
echo "extract and get in"
echo =================
tar zxf solr-4.7.2.tgz
cd solr-4.7.2/example/

echo
echo =================
echo "starting..."
echo =================
rm -r ./solr/collection1
java -jar -DzkRun -Dcollection.configName=bbuzz_less -Dbootstrap_confdir=./example-schemaless/solr/collection1/conf start.jar --daemon &
# wait for Solr to start - ZooKeeper will be started at 9983 port 
ERROR=1; while [ ! $ERROR -eq 0 ]; do sleep 1; curl 'localhost:8983/solr/admin/ping'; ERROR=$?; done
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
cd ../solr-4.7.2/example/
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
echo "TODO"

echo
echo =================
echo "Monitoring"
echo =================
# get dump from ZooKeeper
curl 'http://localhost:8983/solr/zookeeper?wt=json&dump=true'
# get only cluster state
curl 'http://localhost:8983/solr/zookeeper?wt=json&detail=true&path=%2Fclusterstate.json'

# REST stats can be found in JMX Mbeans
# Check jconsole provided with JVM