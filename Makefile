GCP_PROJECT_ID := ubie-yu-sandbox
TAG := v0.6.0
DOCKER_IMAGE := gcr.io/$(GCP_PROJECT_ID)/dataflow-template:$(TAG)

TEMPLATE_GCS_BUCKET := ubie-yu-sandbox-dataflow-template
CONFIG_JSON := spanner-to-bigquery.json

TEMPLATE_FILE_GCS_LOCATION := gs://$(TEMPLATE_GCS_BUCKET)/$(TAG)/templates.json
CONFIG_FILE_GCS_LOCATION := gs://$(TEMPLATE_GCS_BUCKET)/config/$(CONFIG_JSON)

SUBNETWORK := https://www.googleapis.com/compute/v1/projects/$(GCP_PROJECT_ID)/regions/asia-northeast1/subnetworks/dataflow-subnet


build: build-image upload-template

build-image:
	mvn clean package -X -DskipTests -Dimage="$(DOCKER_IMAGE)"

upload-template:
	gcloud dataflow flex-template build "$(TEMPLATE_FILE_GCS_LOCATION)" \
		  --image "$(DOCKER_IMAGE)" \
			--sdk-language "JAVA" \
			--enable-streaming-engine

run-dataflow:
	gsutil cp "$(CONFIG_JSON)" "gs://$(TEMPLATE_GCS_BUCKET)/config/$(CONFIG_JSON)"
	gcloud dataflow flex-template run test-spanner-to-bigquery \
			--project="$(GCP_PROJECT_ID)" \
			--subnetwork="$(SUBNETWORK)" \
			--region="asia-northeast1" \
			--template-file-gcs-location="$(TEMPLATE_FILE_GCS_LOCATION)" \
			--parameters=config="$(CONFIG_FILE_GCS_LOCATION)" \
