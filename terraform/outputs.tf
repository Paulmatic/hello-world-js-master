output "cluster_name" {
  value = google_container_cluster.gke_cluster.name
}

output "kubeconfig" {
  value = <<EOT
gcloud container clusters get-credentials ${google_container_cluster.gke_cluster.name} --region ${var.region} --project ${var.project_id}
EOT
}
