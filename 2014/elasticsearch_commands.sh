echo
echo =================
echo "download"
echo =================
wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.1.0.tar.gz

echo
echo =================
echo "extract and get in"
echo =================
tar zxf elasticsearch-1.1.0.tar.gz
cd elasticsearch-1.1.0

echo
echo =================
echo "starting..."
echo =================
bin/elasticsearch -d
#wait for it to start
ERROR=1; while [ ! $ERROR -eq 0 ]; do sleep 1; curl localhost:9200; ERROR=$?; done
tail -20 logs/elasticsearch.log

echo
echo =================
echo "index the sample documents"
echo =================
cd ../sample-documents
for file in *.json; do
  echo -n $file
  curl -XPOST localhost:9200/bbuzz/videos/ -d "`cat $file`"
  echo
done

echo
echo =================
echo "get mapping"
echo =================
curl localhost:9200/bbuzz/videos/_mapping?pretty

echo
echo =================
echo "update mapping and reindex"
echo =================
curl -XDELETE localhost:9200/bbuzz
curl -XPUT localhost:9200/bbuzz/
curl -XPUT localhost:9200/bbuzz/videos/_mapping -d '{
    "videos": {
        "_id": {
            "path": "id"
        },
        "properties": {
            "id": {
                "type": "string"
            },
            "likes": {
                "type": "long"
            },
            "tags": {
                "type": "string",
                "index": "not_analyzed"
            },
            "title": {
                "type": "string"
            },
            "upload_date": {
                "type": "date",
                "format": "dateOptionalTime"
            },
            "uploaded_by": {
                "type": "string"
            },
            "url": {
                "type": "string"
            },
            "views": {
                "type": "long"
            }
        }
    }
}'
for file in *.json; do
  echo -n $file
  curl -XPOST localhost:9200/bbuzz/videos/ -d "`cat $file`"
  echo
done
curl -XPOST localhost:9200/bbuzz/_refresh

echo
echo =================
echo "URI search"
echo =================
curl 'localhost:9200/bbuzz/videos/_search?q=elasticsearch&pretty'

curl 'localhost:9200/bbuzz/videos/_search?pretty' -d '{
    "query": {
        "bool": {
            "should": [
                {
                    "match": {
                        "title": "elasticsearch"
                    }
                },
                {
                    "term": {
                        "tags": "logs"
                    }
                }
            ]
        }
    }
}'

curl 'localhost:9200/bbuzz/videos/_search?pretty' -d '{
    "query": {
        "function_score": {
            "query": {
                "match": {
                    "title": "elasticsearch"
                }
            },
            "functions": [
                {
                    "exp": {
                        "upload_date": {
                            "origin": "now",
                            "scale": "500d",
                            "offset": "60d",
                            "decay": 0.1
                        }
                    }
                }
            ]
        }
    }
}'

echo
echo =================
echo "Percolate"
echo =================
curl -XPUT 'localhost:9200/bbuzz/.percolator/1' -d '{
    "query" : {
        "term" : {
            "tags" : "elasticsearch"
        }
    }
}'
curl -XGET 'localhost:9200/bbuzz/videos/_percolate?pretty' -d '{
    "doc": {
        "id": "12",
        "url": "http://vimeo.com/44718089",
        "title": "Rafał Kuć - Scaling Massive ElasticSearch Clusters",
        "uploaded_by": "newthinking",
        "upload_date": "2012-06-26",
        "tags": [ "elasticsearch", "scaling", "routing", "sharding", "caching", "monitoring" ]
    }
}'


echo
echo =================
echo "Aggregations"
echo =================
curl 'localhost:9200/bbuzz/videos/_search?pretty' -d '{
    "size": 0,
    "aggregations" : {
        "tags" : {
            "terms" : { "field" : "tags" }
        }
    }
}'

curl 'localhost:9200/bbuzz/videos/_search?pretty' -d '{
    "size": 0,
    "aggregations": {
        "uploader_count": {
            "cardinality": {
                "field": "uploaded_by",
                "precision_threshold": 100
            }
        }
    }
}'

curl 'localhost:9200/bbuzz/videos/_search?pretty' -d '{
    "size": 0,
    "aggregations" : {
        "tags" : {
            "terms" : { "field" : "tags" },
            "aggregations": {
                "dates": {
                    "date_histogram": {
                        "field": "upload_date",
                        "interval": "month",
                        "format" : "yyyy-MM"
                    }
                }
            }
        }
    }
}'

echo
echo =================
echo "Scale out"
echo =================
cd ../elasticsearch-1.1.0
# start fresh
curl -XDELETE localhost:9200/_all
# put a new index with 2 shards
curl -XPOST localhost:9200/scale-this/ -d '{"settings": {"number_of_shards": 2}}'
# start another node - shards should be replicated
bin/elasticsearch -d
#wait for it to start
ERROR=1; while [ ! $ERROR -eq 0 ]; do sleep 1; curl localhost:9201; ERROR=$?; done
# start another two nodes - shards should be balanced
bin/elasticsearch -d
bin/elasticsearch -d
#wait for them to start
ERROR=1; while [ ! $ERROR -eq 0 ]; do sleep 1; curl localhost:9203; ERROR=$?; done

echo
echo =================
echo "Monitoring"
echo =================
#indices stats
curl localhost:9200/_stats?pretty
#cluster stats
curl localhost:9200/_cluster/stats?pretty
