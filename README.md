## Description
Global protobuf schema registry for Hub [Redpanda](https://github.com/redpanda-data/redpanda) eventbus.

## Uploading schemas to Schema registry
The upload script [upload.py](./ci/upload.py) automates the process of uploading protobuf schema files to the schema registry.
The script reads the protobuf files in the current directory and uploads them along with their dependencies (imported protobuf files) to the schema registry.

### Usage
-  Set up the environment variables:
```bash
export SCHEMA_REGISTRY_URL="http://localhost:8081"
#Optional (usually not set for local envs)
export SCHEMA_REGISTRY_TOKEN="<your-schema-registry-token>"
```

> If the `SCHEMA_REGISTRY_TOKEN` environment variable is not set, the script will not include the "Authorization" header in the requests.

- Install the required dependencies:

```bash
pip3 install requests
```

- Run the script:

```bash
python3 ./ci/upload.py
```

The script will find all the .proto files in the current directory and upload the schema files along with their references (if any) to the schema registry.

If you want to use the script in a CI/CD pipeline, make sure to set the environment variables correctly. Check the [release workflow](.github/workflows/release) in this repo for reference.
