terraform {
  backend "local" {
    path = "./terraform.tfstate"
  }
}

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
}
provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_namespace" "dev_stack_io" {
  metadata {
    name = "dev-stack-io"

    labels = {
      name = "devlopment"
    }
  }
}

resource "kubernetes_deployment" "websrv_deployment" {
  metadata {
    name      = "websrv-deployment"
    namespace = kubernetes_namespace.dev_stack_io.metadata.0.name
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "websrv"
      }
    }

    template {
      metadata {
        name      = "websrv"
        namespace = kubernetes_namespace.dev_stack_io.metadata.0.name
        labels = {
          app = "websrv"
        }
      }

      spec {
        init_container {
          name    = "init-myservice"
          image   = "stalin909/web_srv:1.0"
          command = ["sh", "-c", "sleep 30"]
        }

        container {
          name  = "webserver"
          image = "stalin909/web_srv:1.0"

          port {
            name           = "http"
            container_port = 8080
            protocol       = "TCP"
          }

          liveness_probe {
            http_get {
              path = "/web_server"
              port = "8080"
            }

            initial_delay_seconds = 5
            timeout_seconds       = 1
            period_seconds        = 10
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/web_server"
              port = "8080"
            }

            initial_delay_seconds = 30
            timeout_seconds       = 1
            period_seconds        = 10
            failure_threshold     = 3
          }

          lifecycle {
            pre_stop {
              http_get {
                path = "shutdown"
                port = "8080"
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "websrv_service" {
  metadata {
    name = "websrv-service"
    namespace = kubernetes_namespace.dev_stack_io.metadata.0.name
  }

  spec {
    port {
      protocol    = "TCP"
      port        = 80
      target_port = "8080"
    }

    selector = {
      app = "websrv"
    }
  }
}

