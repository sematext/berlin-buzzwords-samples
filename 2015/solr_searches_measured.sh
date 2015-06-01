SPM_TOKEN=$1
ADDRESS="localhost:8983/solr/test"

CLIENT_FILTER=`curl -s "$ADDRESS/select?q=*.*&fq=clientip:dhcp-569.global-gateway.net.nz&sort=_timestamp+desc&indent=true" | grep QTime | cut -d '>' -f2 | cut -d '<' -f1`
if [ -z $CLIENT_FILTER ]; then
  CLIENT_FILTER=0
fi

AGENT_FILTER=`curl -s "$ADDRESS/select?q=*.*&fq=agent:gecko&sort=_timestamp+desc&indent=true" | grep QTime | cut -d '>' -f2 | cut -d '<' -f1`
if [ -z $AGENT_FILTER ]; then
  AGENT_FILTER=0
fi

WILDCARD_FILTER=`curl -s "$ADDRESS/select?q=*.*&fq=clientip:*.nz&sort=_timestamp+desc&indent=true" | grep QTime | cut -d '>' -f2 | cut -d '<' -f1`
if [ -z $WILDCARD_FILTER ]; then
  WILDCARD_FILTER=0
fi

2015-04-16T17:35:27.874Z

DATE_AGG=`curl -s "$ADDRESS/select?q=*.*&rows=0&facet=true&facet.range=_timestamp&facet.range.start=2015-04-16T17:35:24Z&facet.range.end=2015-04-16T17:35:28Z&facet.range.gap=%2B1SECOND&indent=true" | grep QTime | cut -d '>' -f2 | cut -d '<' -f1`
if [ -z $DATE_AGG ]; then
  DATE_AGG=0
fi

TOP_REPONSES=`curl -s "$ADDRESS/select?q=*.*&rows=0&facet=true&facet.field=response&indent=true" | grep QTime | cut -d '>' -f2 | cut -d '<' -f1`
if [ -z $TOP_REPONSES ]; then
  TOP_REPONSES=0
fi

UNIQUE_IPS=`curl -s "$ADDRESS/query?q=*.*&rows=0&json.facet=%7Buniqueips:\"hll(clientip)\"%7D&indent=true" | grep QTime | cut -d ':' -f2 | sed s/,//`
if [ -z $UNIQUE_IPS ]; then
  UNIQUE_IPS=0
fi

NESTED_AGG=`curl -s "$ADDRESS/query?q=*.*&rows=0&json.facet=%7Bdatehisto:%7Btype:range,field:_timestamp,start:'2015-04-16T17:35:24Z',end:'2015-04-16T17:35:28Z',gap:'%2B1SECOND',facet:%7Btopresponses:%7Btype:terms,field:response,facet:%7Buniqueips:\"hll(clientip)\"%7D%7D%7D%7D%7D&indent=true" | grep QTime | cut -d ':' -f2 | sed s/,//`
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