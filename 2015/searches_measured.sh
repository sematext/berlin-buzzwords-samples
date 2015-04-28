SPM_TOKEN=$1
ADDRESS="localhost:9200"

CLIENT_FILTER=`curl -s $ADDRESS/_search?pretty -d '{
  "query": {
    "filtered": {
      "filter": {
        "term": {
          "clientip": "dhcp-569.global-gateway.net.nz"
        }
      }
    }
  },
  "sort": [{
    "@timestamp": {
      "order": "desc"
    }
  }]
}' | grep took | cut -d ' ' -f 5 | sed s/,//`
if [ -z $CLIENT_FILTER ]; then
  CLIENT_FILTER=0
fi

AGENT_FILTER=`curl -s $ADDRESS/_search?pretty -d '{
  "query": {
    "match": {
      "agent": "gecko"
    }
  },
  "sort": [{
    "@timestamp": {
      "order": "desc"
    }
  }]
}' | grep took | cut -d ' ' -f 5 | sed s/,//`
if [ -z $AGENT_FILTER ]; then
  AGENT_FILTER=0
fi

WILDCARD_FILTER=`curl -s $ADDRESS/_search?pretty -d '{
  "query": {
    "query_string": {
      "query": "clientip:*.nz"
    }
  },
  "sort": [{
    "@timestamp": {
      "order": "desc"
    }
  }]
}'| grep took | cut -d ' ' -f 5 | sed s/,//`
if [ -z $WILDCARD_FILTER ]; then
  WILDCARD_FILTER=0
fi

DATE_AGG=`curl -s $ADDRESS/_search?pretty -d '{
  "aggs": {
    "frequency_chart": {
      "date_histogram": {
        "field": "@timestamp",
        "interval": "second"
      }
    }
  },
  "size": 0
}'| grep took | cut -d ' ' -f 5 | sed s/,//`
if [ -z $DATE_AGG ]; then
  DATE_AGG=0
fi

TOP_REPONSES=`curl -s $ADDRESS/_search?pretty -d '{
  "aggs": {
    "response_distribution": {
      "terms": {
        "field": "response"
      }
    }
  },
  "size": 0
}'| grep took | cut -d ' ' -f 5 | sed s/,//`
if [ -z $TOP_REPONSES ]; then
  TOP_REPONSES=0
fi

UNIQUE_IPS=`curl -s $ADDRESS/_search?pretty -d '{
  "aggs": {
    "unique_ips": {
      "cardinality": {
        "field": "clientip"
      }
    }
  },
  "size": 0
}'| grep took | cut -d ' ' -f 5 | sed s/,//`
if [ -z $UNIQUE_IPS ]; then
  UNIQUE_IPS=0
fi

NESTED_AGG=`curl -s $ADDRESS/_search?pretty -d '{
  "aggs": {
    "frequency_chart": {
      "date_histogram": {
        "field": "@timestamp",
        "interval": "second"
      },
      "aggs": {
        "response_distribution": {
          "terms": {
            "field": "response"
          },
          "aggs": {
            "unique_ips": {
              "cardinality": {
                "field": "clientip"
              }
            }
          }
        }
      }
    }
  },
  "size": 0
}'| grep took | cut -d ' ' -f 5 | sed s/,//`
if [ -z $NESTED_AGG ]; then
  NESTED_AGG=0
fi

curl -H 'Content-type: application/json' -d "{
  \"datapoints\" : [
    {
      \"name\": \"client filter\",
      \"value\" : $CLIENT_FILTER,
      \"aggregation\" : \"avg\"
    },
    {
      \"name\": \"agent filter\",
      \"value\" : $AGENT_FILTER,
      \"aggregation\" : \"avg\"
    },
    {
      \"name\": \"wildcard filter\",
      \"value\" : $WILDCARD_FILTER,
      \"aggregation\" : \"avg\"
    },
    {
      \"name\": \"date agg\",
      \"value\" : $DATE_AGG,
      \"aggregation\" : \"avg\"
    },
    {
      \"name\": \"top responses\",
      \"value\" : $TOP_REPONSES,
      \"aggregation\" : \"avg\"
    },
    {
      \"name\": \"unique ips\",
      \"value\" : $UNIQUE_IPS,
      \"aggregation\" : \"avg\"
    },
    {
      \"name\": \"nested agg\",
      \"value\" : $NESTED_AGG,
      \"aggregation\" : \"avg\"
    }
  ]
}" http://spm-receiver.sematext.com/receiver/custom/receive.json?token=$SPM_TOKEN