#!/bin/sh

# Create a Docker network named 'jenkins' to ensure communication between Jenkins and Docker containers
docker network create jenkins

# Run the Docker daemon in a container (Docker-in-Docker)
docker run \
  --name jenkins-docker \                        # Name of the container running Docker
  --detach \                                     # Run container in background
  --privileged \                                 # Allow this container to perform Docker actions inside
  --network jenkins \                            # Attach to the 'jenkins' network
  --network-alias docker \                       # Assign an alias to the container in the network
  --env DOCKER_TLS_CERTDIR=/certs \              # Enable TLS for secure Docker client communication
  --volume jenkins-docker-certs:/certs/client \  # Mount volume to store Docker certificates
  --volume jenkins-data:/var/jenkins_home \      # Volume for Jenkins data persistence
  --publish 2376:2376 \                          # Publish Docker daemon's TCP port
  --publish 3000:3000 --publish 5000:5000 \      # Publish any additional ports you may need (optional)
  --restart always \                             # Restart container if it stops
  docker:dind \                                  # Use Docker-in-Docker image
  --storage-driver overlay2                      # Set storage driver to overlay2 for Docker

# Build the Jenkins Blue Ocean Docker image
docker build -t myjenkins-blueocean:2.426.2-1 .  # Build the Jenkins image from your Dockerfile

# Run the Jenkins Blue Ocean container
docker run \
  --name jenkins-blueocean \                     # Name of the Jenkins Blue Ocean container
  --detach \                                     # Run container in background
  --network jenkins \                            # Attach Jenkins to the 'jenkins' network
  --env DOCKER_HOST=tcp://docker:2376 \          # Set Docker host to communicate with Docker daemon
  --env DOCKER_CERT_PATH=/certs/client \         # Set path for Docker certificates
  --env DOCKER_TLS_VERIFY=1 \                    # Enable TLS verification
  --publish 49000:8080 \                         # Expose Jenkins on port 49000 (accessible at http://localhost:49000)
  --publish 50000:50000 \                        # Publish Jenkins agent port
  --volume jenkins-data:/var/jenkins_home \      # Persist Jenkins data
  --volume jenkins-docker-certs:/certs/client:ro \  # Read-only mount for Docker certificates
  --volume "$HOME":/home \                       # Mount your home directory for additional usage
  --restart=on-failure \                         # Restart only if Jenkins fails
  --env JAVA_OPTS="-Dhudson.plugins.git.GitSCM.ALLOW_LOCAL_CHECKOUT=true" \  # Allow local Git checkouts
  myjenkins-blueocean:2.426.2-1                  # Use the custom-built Jenkins Blue Ocean image

# Run the NGINX container as a reverse proxy for Jenkins
docker run -d \
  --name nginx-jenkins-proxy \                   # Name of the NGINX proxy container
  --network jenkins \                            # Attach to the same 'jenkins' network
  -p 9000:9000 \                                 # Expose NGINX on port 9000 (accessible at http://localhost:9000)
  -v $(pwd)/nginx.conf:/etc/nginx/conf.d/default.conf \  # Mount the custom NGINX configuration file
  nginx                                          # Use the official NGINX image

# Modifie the Jenkins configuration file to enable the signup feature.
docker exec jenkins-blueocean sed -i 's#<disableSignup>true</disableSignup>#<disableSignup>false</disableSignup>#' /var/jenkins_home/config.xml

# Restart the Jenkins container to apply the changes made to the configuration.
docker restart jenkins-blueocean
