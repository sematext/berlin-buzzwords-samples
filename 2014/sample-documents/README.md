To index the sample documents in Elasticsearch, you would run

    cd sample-documents
    for file in `ls -1`; do echo -n $file; curl -XPOST localhost:9200/es-solr/videos/ -d "`cat $file`"; echo; done
