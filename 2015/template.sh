curl -XDELETE localhost:9200/test-index/
curl -XPUT localhost:9200/test-index -d '{
  "mappings": {
    "_default_": {
      "dynamic_templates": [ {
            "string_fields": {
              "match": "*",
              "match_mapping_type": "string",
              "mapping": {
                "type": "string",
                "norms": {
                  "enabled": false
                },
                "index_options": "docs"
              }
            }
          },
          {
            "other_fields": {
              "match": "*",
              "match_mapping_type": "*",
              "mapping": {
                "doc_values": true
              }
            }
          } ],
       "properties": {
          "@timestamp": {
            "type": "date",
            "doc_values": true
          },
          "clientip": {
            "type": "string",
            "index": "not_analyzed",
            "doc_values": true
          },
          "verb": {
            "type": "string",
            "index": "not_analyzed",
            "doc_values": true
          },
          "request": {
            "type": "string",
            "index": "not_analyzed",
            "doc_values": true
          },
          "response": {
            "type": "short",
            "doc_values": true
          },
          "bytes": {
            "type": "long",
            "doc_values": true
          }
       }
    }
  },
  "settings": {
    "index": {
      "routing.allocation.include.tag": "hot",
      "number_of_shards": "2",
      "refresh_interval": "5s",
      "translog.flush_threshold_size": "200mb"
    }
  }
}'

#TODO: cold indices -> optimize