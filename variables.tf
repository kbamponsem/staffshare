
# Define variables
variable "staffshare_backend_dir" {
  description = "The directory containing the staffshare source code"
  default     = "./backend"
}

variable "staffshare_frontend_dir" {
  description = "The directory containing the staffshare source code"
  default     = "./frontend"
}

variable "staffshare_frontend" {
  description = "Container name for the frontend"
  default     = "staffshare-frontend"
}

variable "staffshare_backend" {
  description = "Container name for the backend"
  default     = "staffshare-backend"
}

variable "staffshare_backend_image" {
  description = "The Docker image for the backend"
  default     = "staffshare-backend:latest"
}

variable "staffshare_frontend_image" {
  description = "The Docker image for the frontend"
  default     = "staffshare-frontend:latest"
}

variable "staffshare_backend_port" {
  description = "The port the backend will listen on"
  default     = 8080
}

variable "staffshare_frontend_port" {
  description = "The port the frontend will listen on"
  default     = 3000
}

variable "mongodb_image" {
  description = "The Docker image for MongoDB"
  default     = "mongo:latest"
}

variable "staffshare_loadbalancer_dir" {
  description = "The directory containing the loadbalancer source code"
  default     = "./loadbalancer"
}

variable "staffshare_loadbalancer_port" {
  description = "The port the loadbalancer will listen on"
  default     = 80
}

variable "staffshare_email_address" {
  description = "The email address to send emails from"
  default     = ""
}

variable "staffshare_email_password" {
  description = "The password for the email address"
  default     = ""
}

variable "staffshare_google_client_secret" {
  description = "The Google client secret for OAuth"
  default = ""
}

variable "staffshare_google_client_id" {
  description = "The Google client ID for OAuth"
  default = ""
}