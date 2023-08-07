#!/bin/sh

set -ex
cd "`dirname "$0"`"

podman run -d --pull=always --name=redpanda-1 --rm \
  -p 8081:8081 \
  -p 8082:8082 \
  -p 9092:9092 \
  -p 9644:9644 \
  docker.redpanda.com/vectorized/redpanda:latest \
  redpanda start \
  --overprovisioned \
  --seeds "redpanda-1:33145" \
  --set redpanda.empty_seed_starts_cluster=false \
  --smp 1  \
  --memory 1G \
  --reserve-memory 0M \
  --check=false \
  --advertise-rpc-addr redpanda-1:33145

while :; do
  ! curl 'http://localhost:8081/v1' || break
  sleep 3
done

curl -X POST 'http://localhost:8081/subjects/organization/versions' \
  -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  -d "`ruby -e 'require "json";puts JSON::dump({schemaType:"PROTOBUF",schema:File::read("organization.proto")})'`" \
  -vvv

curl -X POST 'http://localhost:8081/subjects/customer/versions' \
  -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  -d "`ruby -e 'require "json";puts JSON::dump({schemaType:"PROTOBUF",schema:File::read("customer.proto")})'`" \
  -vvv


curl -X POST 'http://localhost:8081/subjects/nfts/versions' \
  -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  -d "`ruby -e 'require "json";puts JSON::dump({schemaType:"PROTOBUF",schema:File::read("nfts.proto")})'`" \
  -vvv


curl -X POST 'http://localhost:8081/subjects/treasury/versions' \
  -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  -d "`ruby -e 'require "json";puts JSON::dump({schemaType:"PROTOBUF",schema:File::read("treasury.proto")})'`" \
  -vvv

curl -X POST 'http://localhost:8081/subjects/credential/versions' \
  -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  -d "`ruby -e 'require "json";puts JSON::dump({schemaType:"PROTOBUF",schema:File::read("credential.proto")})'`" \
  -vvv

curl -X POST 'http://localhost:8081/subjects/credits/versions' \
  -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  -d "`ruby -e 'require "json";puts JSON::dump({schemaType:"PROTOBUF",schema:File::read("credits.proto")})'`" \
  -vvv
  
curl -X POST 'http://localhost:8081/subjects/credits_mpsc/versions' \
  -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  -d "`ruby -e 'require "json";puts JSON::dump({schemaType:"PROTOBUF",schema:File::read("credits_mpsc.proto"), "references":[
      {
         "name":"credits.proto",
         "subject":"credits",
         "version":1
      }
   ]})'`" \
  -vvv

curl -X POST 'http://localhost:8081/subjects/solana_nfts/versions' \
  -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  -d "`ruby -e 'require "json";puts JSON::dump({schemaType:"PROTOBUF",schema:File::read("solana_nfts.proto")})'`" \
  -vvv

curl -X POST 'http://localhost:8081/subjects/timestamp/versions' \
  -H "Content-Type: application/vnd.schemaregistry.v1+json" \
  -d "`ruby -e 'require "json";puts JSON::dump({schemaType:"PROTOBUF",schema:File::read("timestamp.proto")})'`" \
  -vvv

  curl -X POST 'http://localhost:8081/subjects/polygon_nfts/versions' \
  -H "Content-Type: application/vnd.schemaregistry.v1+json" \
 -d "`ruby -e 'require "json";puts JSON::dump({schemaType:"PROTOBUF",schema:File::read("polygon_nfts.proto"), "references":[
      {
         "name":"timestamp.proto",
         "subject":"timestamp",
         "version":1
      }
   ]})'`" \
  -vvv