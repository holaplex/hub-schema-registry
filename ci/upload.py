import os
import json
import requests
from pathlib import Path

SCHEMA_REGISTRY_TOKEN = os.getenv("SCHEMA_REGISTRY_TOKEN")
SCHEMA_REGISTRY_URL = os.getenv("SCHEMA_REGISTRY_URL")

def upload_schema(file_path):
    subject = file_path.stem

    with open(file_path, "r") as f:
        content = f.read()

    payload = {
        "schemaType": "PROTOBUF",
        "schema": content
    }

    imports = [line for line in content.splitlines() if line.startswith('import "') and line.endswith('.proto";')]

    references = []

    for line in imports:
        import_file = line.split('"')[1]
        import_subject = Path(import_file).stem
        import_path = file_path.parent / import_file

        #Upload imports first and get the version and use that for the reference
        upload_schema(import_path)

        headers = {"Authorization": SCHEMA_REGISTRY_TOKEN} if SCHEMA_REGISTRY_TOKEN else {}
        import_version = requests.get(
            f"{SCHEMA_REGISTRY_URL}/subjects/{import_subject}/versions",
            headers=headers
            ).json()[-1]


        references.append({
            "name": import_file,
            "subject": import_subject,
            "version": import_version
        })

    if references:
        payload["references"] = references
    #debug
    print(json.dumps(payload, indent=2))

    headers = {
        "Content-Type": "application/vnd.schemaregistry.v1+json"
    }

    if SCHEMA_REGISTRY_TOKEN:
        headers["Authorization"] = SCHEMA_REGISTRY_TOKEN

    response = requests.post(
        f"{SCHEMA_REGISTRY_URL}/subjects/{subject}/versions",
        headers=headers,
        data=json.dumps(payload)
    )

    response.raise_for_status()

for file in Path("protos").glob("*.proto"):
    upload_schema(file)
