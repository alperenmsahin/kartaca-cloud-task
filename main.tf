# Creating vpc.
resource "google_compute_network" "vpc" {
  name = "kartaca-staj"
}
# Creating subnet. 
resource "google_compute_subnetwork" "subnetwork" {
  name          = "kartaca-staj-subnet"
  ip_cidr_range = "10.0.0.0/24"
  network       = google_compute_network.vpc.self_link
  region        = "europe-west1"

}
# Creating Cluster.
resource "google_container_cluster" "gke_cluster" {
  name               = "kartacastaj"
  location           = "europe-west1"
  initial_node_count = 1
  network            = google_compute_network.vpc.self_link
  subnetwork         = google_compute_subnetwork.subnetwork.self_link
  node_config {
    machine_type = "n1-standard-1"
    disk_size_gb = 50
  }
}
# Deployment 
resource "kubernetes_deployment" "web" {

  depends_on = [
    google_container_cluster.gke_cluster
  ]

  metadata {
    name = "kartacastaj-deployment"
  }

  spec {
    selector {
      match_labels = {
        app = "kartacastaj"
      }
    }

    template {
      metadata {
        labels = {
          app = "kartacastaj"
        }
      }

      spec {
        container {
          name  = "kartacastaj-container"
          image = "alperenmsahin/kartaca:v1.0"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}
# Creating Kubernetes Service (Load Balancer)
resource "kubernetes_service" "kartacasvc" {
  metadata {
    name = "kartaca-staj-svc"
  }

  spec {
    selector = {
      app = "kartacastaj"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }

  depends_on = [
    kubernetes_deployment.web
  ]
}
#Outputs
output "application_address" {
  value = "http://${kubernetes_service.kartacasvc.status[0].load_balancer[0].ingress[0].ip}"
}
