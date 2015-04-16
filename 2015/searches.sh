curl 'localhost:9200/_search?pretty' -d '{
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
}'
curl 'localhost:9200/_search?pretty' -d '{
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
}'
curl 'localhost:9200/_search?pretty' -d '{
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
}'
curl 'localhost:9200/_search?pretty' -d '{
  "aggs": {
    "frequency_chart": {
      "date_histogram": {
        "field": "@timestamp",
        "interval": "second"
      }
    }
  },
  "size": 0
}'
curl 'localhost:9200/_search?pretty' -d '{
  "aggs": {
    "response_distribution": {
      "terms": {
        "field": "response"
      }
    }
  },
  "size": 0
}'
curl 'localhost:9200/_search?pretty' -d '{
  "aggs": {
    "unique_ips": {
      "cardinality": {
        "field": "clientip"
      }
    }
  },
  "size": 0
}'
curl 'localhost:9200/_search?pretty' -d '{
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
}'