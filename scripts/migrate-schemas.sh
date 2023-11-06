#!/bin/bash

API_TOKEN="YOUR_API_TOKEN"

SOURCE_REGISTRY="https://schemas.holaplex.tools"
DEST_REGISTRY="https://schemas.holaplex.com"


# Define the list of schemas to be migrated
SCHEMAS=("google%2Fprotobuf%2Ftimestamp.proto" "credential" "credits" "credits_mpsc" "customer" "nfts" "organization" "solana_nfts" "timestamp" "treasury" "webhook" "analytics" "polygon_nfts")

fetch_schema() {
    local schema=$1
    local version=$2

    echo "Fetching version $version of schema $schema from source registry" >&2

    local schema_data
    schema_data=$(curl -s "$SOURCE_REGISTRY/subjects/$schema/versions/$version")

    if ! echo "$schema_data" | jq -e . > /dev/null 2>&1; then
        echo "Error: Fetched data is not valid JSON." >&2
        echo "Fetched Data: $schema_data" >&2
        exit 1
    fi

    echo "$schema_data"
}

schema_version_exists() {
    local schema=$1
    local version=$2

    # Try to fetch the schema version from the given registry
    response=$(curl -s "$DEST_REGISTRY/subjects/$schema/versions/$version")

    # If the schema version exists, we'd get a JSON response with a non-null "id" field
    if echo "$response" | jq -e '.id' > /dev/null 2>&1; then
        return 0
    else
        return 1  # doesn't exist
    fi
}

publish_schema() {
    local schema=$1
    local version=$2
    local data=$3

    local schemaType
    local schemaContent
    local references

    schemaType=$(echo "$data" | jq -r '.schemaType')
    schemaContent=$(echo "$data" | jq '.schema')
    references=$(echo "$data" | jq '.references')

    # Construct the payload based on the presence of references
    if [[ "$references" != "null" ]]; then
        schema_payload="{\"schemaType\": \"$schemaType\", \"schema\": $schemaContent, \"references\": $references}"
    else
        schema_payload="{\"schemaType\": \"$schemaType\", \"schema\": $schemaContent}"
    fi

    if [[ -z "$schema_payload" ]]; then
        echo "Error reconstructing the payload."
        exit 1
    fi

    echo "Payload: $schema_payload"

    response=$(curl -s -X POST "$DEST_REGISTRY/subjects/$schema/versions" \
                     -H "Authorization: $API_TOKEN" \
                     -H "Content-Type: application/vnd.schemaregistry.v1+json" \
                     -d "$schema_payload")

    # Check if the POST request was successful
    if [[ $(echo "$response" | jq -r '.id') == "null" ]]; then
        echo "Error publishing version $version of schema $schema to destination."
        echo "Response: $response"
        exit 1
    fi

    echo "Successfully migrated version $version of schema $schema"
}

for schema in "${SCHEMAS[@]}"; do
    versions=$(curl -s "$SOURCE_REGISTRY/subjects/$schema/versions" | jq '.[]')
    for version in $versions; do
        if schema_version_exists "$schema" "$version"; then
            echo "Schema $schema version $version already exists in destination registry. Skipping."
            continue
        fi

        schema_data=$(fetch_schema "$schema" "$version")
        echo "Printing schema data"
        echo "$schema_data" | jq
        publish_schema "$schema" "$version" "$schema_data"
    done
done

echo "Migration completed successfully!"
