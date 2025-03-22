provider "google" {
  credentials = file("/var/lib/jenkins/workspace/gcp-key.json")
  project     = var.project_id
  region      = var.region
}
