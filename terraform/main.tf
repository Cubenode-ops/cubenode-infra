terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

# =====================================================
# DOCKER NETWORK (WICHTIG!)
# =====================================================

resource "docker_network" "app_network" {
  name = "cubenode-network"
}

# =====================================================
# NGINX REVERSE PROXY
# =====================================================

resource "docker_image" "nginx" {
  name = "nginx:latest"
}

resource "docker_container" "nginx" {
  name  = "cubenode-nginx"
  image = docker_image.nginx.name

  ports {
    internal = 80
    external = 8080
  }

  networks_advanced {
    name = docker_network.app_network.name
  }

  volumes {
    host_path      = "${abspath(path.module)}/nginx.conf"
    container_path = "/etc/nginx/conf.d/default.conf"
  }

  depends_on = [docker_container.backend]
}

# =====================================================
# POSTGRES DATABASE
# =====================================================

resource "docker_image" "postgres" {
  name = "postgres:15"
}

resource "docker_container" "postgres" {
  name  = "cubenode-postgres"
  image = docker_image.postgres.name

  ports {
    internal = 5432
    external = 5432
  }

  networks_advanced {
    name = docker_network.app_network.name
  }

  env = [
    "POSTGRES_USER=admin",
    "POSTGRES_PASSWORD=admin123",
    "POSTGRES_DB=cubenode"
  ]
}

# =====================================================
# NODE BACKEND
# =====================================================

resource "docker_image" "backend" {
  name = "cubenode-backend:latest"
}

resource "docker_container" "backend" {
  name  = "cubenode-backend"
  image = docker_image.backend.name

  ports {
    internal = 3000
    external = 3000
  }

  networks_advanced {
    name = docker_network.app_network.name
  }

  env = [
    "DB_HOST=cubenode-postgres",
    "DB_PORT=5432",
    "DB_USER=admin",
    "DB_PASSWORD=admin123",
    "DB_NAME=cubenode"
  ]

  depends_on = [docker_container.postgres]
}
