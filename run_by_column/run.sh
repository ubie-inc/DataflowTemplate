#!/bin/bash

columns=(
#  StringClm
  BoolClm
  BytesClm
  Int64Clm
  DateClm
  Float64Clm
  JsonClm
  NumericClm
  TimestampClm
  ArrayInt64Clm
  ArrayStringClm
  ArrayDateClm
  ArrayNumericClm
  ArrayTimestampClm
)

for column in "${columns[@]}"
do
  lower_column=$(echo "$column" | tr '[:upper:]' '[:lower:]')

  # Generate the config file
  SPANNER_COLUMN="$column"
  LOWER_SPANNER_COLUMN="$lower_column"
  export SPANNER_COLUMN LOWER_SPANNER_COLUMN
  config_json="spanner-to-bigquery.${lower_column}.json"
  envsubst <spanner-to-bigquery.tmpl.json >"$config_json"

  # Run the dataflow job
  config_json_on_gcs="gs://ubie-yu-sandbox-dataflow-template/config/${config_json}"
  gsutil cp "$config_json" "$config_json_on_gcs"
  gcloud dataflow flex-template run "test-spanner2bq-${lower_column}" \
      --project="ubie-yu-sandbox" \
      --subnetwork="https://www.googleapis.com/compute/v1/projects/ubie-yu-sandbox/regions/asia-northeast1/subnetworks/dataflow-subnet" \
      --region="asia-northeast1" \
      --template-file-gcs-location="gs://ubie-yu-sandbox-dataflow-template/v0.6.0/templates.json" \
      --parameters=config="$config_json_on_gcs" \
      --additional-user-labels=column="$lower_column"
done
