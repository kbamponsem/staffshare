# Define the provider (e.g., AWS, GCP, or local)
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.2"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

resource "random_string" "random" {
  length           = 32
  special          = true
  override_special = "/@£$"
}

# Use the random string resource to generate a JWT secret
resource "null_resource" "jwt_secret" {
  triggers = {
    random_string = random_string.random.result
  }

  provisioner "local-exec" {
    command = <<EOF
      echo "JWT_SECRET=${random_string.random.result}" > .env
    EOF
  }
}

# Create a network for the containers to communicate over
resource "docker_network" "staffshare" {
  name = "staffshare"
}


# Run the MongoDB container
resource "docker_container" "mongodb" {
  name = "mongo"
  networks_advanced {
    name    = docker_network.staffshare.name
    aliases = ["mongo"]
  }

  provisioner "local-exec" {
    command = <<EOF
      mkdir -p ${abspath(path.module)}/data/db
    EOF
  }

  volumes {
    container_path = "/data/db"
    host_path      = "${abspath(path.module)}/data/db"
    read_only      = false
  }

  image = var.mongodb_image
  ports {
    internal = 27017
    external = 27017
  }

  restart  = "always"
  must_run = true

  depends_on = [docker_network.staffshare]
}

resource "docker_image" "backend" {
  name = var.staffshare_backend_image
  build {
    context = var.staffshare_backend_dir
    tag     = [var.staffshare_backend_image]
  }
  force_remove = true

  triggers = {
    dir_hash = sha1(join(",", [for f in fileset(abspath(var.staffshare_backend_dir), "**/*.*") : filesha1("${abspath(var.staffshare_backend_dir)}/${f}")]))
  }

}

resource "docker_image" "frontend" {
  name = var.staffshare_frontend_image
  build {
    context = var.staffshare_frontend_dir
    tag     = [var.staffshare_frontend_image]
  }
  force_remove = true

  triggers = {
    dir_hash = sha1(join(",", [for f in fileset(abspath(var.staffshare_frontend_dir), "**/*.*") : filesha1("${abspath(var.staffshare_frontend_dir)}/${f}")]))
  }

}

resource "docker_image" "loadbalancer" {
  name         = "nginx:latest"
  keep_locally = false
  force_remove = true

  build {
    context = var.staffshare_loadbalancer_dir
    tag     = ["nginx:latest"]
  }

}

# Run the backend container
resource "docker_container" "staffshare-backend" {
  name  = var.staffshare_backend
  image = var.staffshare_backend_image

  networks_advanced {
    name    = docker_network.staffshare.name
    aliases = ["staffshare"]
  }

  ports {
    internal = var.staffshare_backend_port
    external = var.staffshare_backend_port
  }

  volumes {
    container_path = "/staffshare_server/src"
    host_path      = abspath(var.staffshare_backend_dir)
    read_only      = false
  }

  restart  = "always"
  must_run = true
  env = [
    "STAFFSHARE_SERVER_ADDR=0.0.0.0",
    "STAFFSHARE_SERVER_PORT=${var.staffshare_backend_port}",
    "JWT_SECRET=${random_string.random.result}",
    "STAFFSHARE_EMAIL_ADDRESS=${var.staffshare_email_address}",
    "STAFFSHARE_EMAIL_PASSWORD=${var.staffshare_email_password}",
    "MONGODB_URI=mongodb://mongo:27017",
    "DB_NAME=staffshare"
  ]

  depends_on = [docker_network.staffshare, docker_image.backend, docker_container.mongodb]
}

# Run the frontend container
resource "docker_container" "staffshare-frontend" {
  name  = var.staffshare_frontend
  image = var.staffshare_frontend_image

  networks_advanced {
    name    = docker_network.staffshare.name
    aliases = ["staffshare"]
  }

  volumes {
    container_path = "/app"
    host_path      = abspath(var.staffshare_frontend_dir)
    read_only      = false
  }

  ports {
    internal = var.staffshare_frontend_port
    external = var.staffshare_frontend_port
  }
  env = [
    "NEXT_PUBLIC_API_URL=https://test.staffshare.co",
    "NEXTAUTH_URL=https://test.staffshare.co",
    "JWT_SECRET=${random_string.random.result}",
    "GOOGLE_CLIENT_ID=${var.staffshare_google_client_id}",
    "GOOGLE_CLIENT_SECRET=${var.staffshare_google_client_secret}",
  ]
  restart  = "always"
  must_run = true

  depends_on = [docker_network.staffshare, docker_image.frontend]

}
output "network_ips" {
  value = docker_container.staffshare-backend.network_data[0].ip_address
}
locals {
  backend_ip  = docker_container.staffshare-backend.network_data[0].ip_address
  frontend_ip = docker_container.staffshare-frontend.network_data[0].ip_address
}
# Run the loadbalancer container 
resource "docker_container" "staffshare-loadbalancer" {
  name  = "staffshare-loadbalancer"
  image = "nginx:latest"

  networks_advanced {
    name    = docker_network.staffshare.name
    aliases = ["staffshare"]
  }

  ports {
    internal = var.staffshare_loadbalancer_port
    external = var.staffshare_loadbalancer_port
  }

  env = [
    "BACKEND_SERVER_IP=${local.backend_ip}",
    "BACKEND_SERVER_PORT=${var.staffshare_backend_port}",
    "FRONTEND_SERVER_IP=${local.frontend_ip}",
    "FRONTEND_SERVER_PORT=${var.staffshare_frontend_port}",
    "LOAD_BALANCER_PORT=${var.staffshare_loadbalancer_port}"
  ]

  restart  = "always"
  must_run = true

  depends_on = [docker_network.staffshare, docker_container.staffshare-backend, docker_container.staffshare-frontend]
}


resource "docker_container" "mongo-express" {
  name = "mongo-express"
  networks_advanced {
    name    = docker_network.staffshare.name
    aliases = ["mongo-express"]
  }

  image = "mongo-express:latest"
  ports {
    internal = 8081
    external = 8081
  }

  restart  = "always"
  must_run = true

  depends_on = [docker_container.mongodb]

}
