#!/bin/sh
set -e

CB_ADMIN_USERNAME=${CB_ADMIN_USERNAME:-administrator}
CB_ADMIN_PASSWORD=${CB_ADMIN_PASSWORD:-password}
CB_HOSTNAME=${CB_HOSTNAME:-localhost}
CB_BUCKET_NAME=${CB_BUCKET_NAME:-my-bucket}
CB_SCOPE_NAME=${CB_SCOPE_NAME:-my-scope}
CB_COLLECTION_NAME=${CB_COLLECTION_NAME:-my-collection}
CB_CLUSTER_HOSTNAME=127.0.0.1

check_couchbase_reachable() {
  curl -s --head --request GET http://$CB_HOSTNAME:8091/_ui/authMethods | head -n 1 | grep "HTTP/1.1 200 OK" > /dev/null
  code=$?
  return $code
}

initialize_cluster() {
  curl -X POST http://$CB_HOSTNAME:8091/clusterInit \
    -d hostname=$CB_CLUSTER_HOSTNAME \
    -d username=$CB_ADMIN_USERNAME \
    -d password=$CB_ADMIN_PASSWORD \
    -d sendStats=false \
    -d clusterName=test-cluster \
    -d services=kv,n1ql,index,fts,eventing,cbas,backup \
    -d memoryQuota=256 \
    -d queryMemoryQuota=256 \
    -d indexMemoryQuota=256 \
    -d eventingMemoryQuota=256 \
    -d ftsMemoryQuota=256 \
    -d cbasMemoryQuota=1024 \
    -d afamily=ipv4 \
    -d afamilyOnly=true \
    -d nodeEncryption=off \
    -d indexerStorageMode=plasma \
    -d port=SAME \
    -d allowedHosts='*' \
    -s > /dev/null
  echo "Cluster initialized."
}

create_bucket() {
  curl -X POST http://$CB_HOSTNAME:8091/pools/default/buckets \
    -u $CB_ADMIN_USERNAME:$CB_ADMIN_PASSWORD \
    -d name=$CB_BUCKET_NAME \
    -d bucketType=couchbase \
    -d ramQuotaMB=256 \
    -s
  echo "Bucket '$CB_BUCKET_NAME' created."
}

create_scope() {
  curl -X POST -u $CB_ADMIN_USERNAME:$CB_ADMIN_PASSWORD \
    http://$CB_HOSTNAME:8091/pools/default/buckets/$CB_BUCKET_NAME/scopes \
    -d name=$CB_SCOPE_NAME \
    -s > /dev/null
  echo "Scope '$CB_SCOPE_NAME' created."
}

create_collection() {
  curl -X POST -u $CB_ADMIN_USERNAME:$CB_ADMIN_PASSWORD \
    http://$CB_HOSTNAME:8091/pools/default/buckets/$CB_BUCKET_NAME/scopes/$CB_SCOPE_NAME/collections \
    -d name=$CB_COLLECTION_NAME \
    -s > /dev/null
  echo "Collection '$CB_COLLECTION_NAME' created."
}

echo "Checking if Couchbase server is reachable..."
until check_couchbase_reachable; do
  echo "Couchbase server is not reachable. Retrying in 3 seconds..."
  sleep 3
done

echo "Couchbase server is up."
echo "Initializing Couchbase cluster..."
initialize_cluster
echo "Creating bucket, scope, and collection..."
create_bucket
create_scope
create_collection
echo "Couchbase setup completed."
