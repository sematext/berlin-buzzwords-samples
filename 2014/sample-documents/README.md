To index the sample documents in Elasticsearch, you would run

    cd sample-documents
    for file in *.json; do echo -n $file; curl -XPOST -H 'Content-Type: application/json' localhost:9200/videosearch/_doc/ -d "`cat $file`"; echo; done

To index the sample documents in Solr, you would run

    cd sample-documents
    for file in *.json; do echo $file; curl 'http://localhost:8983/solr/update?commit=true' -H 'Content-type:application/json' -d "[`cat $file`]"; echo; done
