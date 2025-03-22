resource "google_container_cluster" "gke_cluster" {
  name     = var.cluster_name
  location = var.region
  network  = google_compute_network.vpc_network.self_link
  remove_default_node_pool = true
  initial_node_count       = 1

  lifecycle {
    ignore_changes = [node_pool]
  }
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "node-pool"
  location   = var.region
  cluster    = google_container_cluster.gke_cluster.name
  node_count = var.node_count

  autoscaling {
    min_node_count = var.min_nodes
    max_node_count = var.max_nodes
  }

  node_config {
    preemptible  = false
    machine_type = var.node_machine_type
    disk_size_gb = 50
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}
