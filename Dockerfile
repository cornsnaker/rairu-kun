FROM debian:stable

ENV DEBIAN_FRONTEND=noninteractive

# Install SSH, Docker, and your required utilities
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    openssh-server wget unzip vim curl python3 python3-pip \
    ca-certificates apt-transport-https gnupg lsb-release \
    docker.io \
    && rm -rf /var/lib/apt/lists/*

# Optionally install docker-compose via pip
# RUN pip3 install docker-compose

# Ensure docker group exists
RUN groupadd -f docker

# Setup SSH directory
RUN mkdir -p /run/sshd

# Configure SSH to allow root login with your password
RUN echo "PermitRootLogin yes" >> /etc/ssh/sshd_config \
    && echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config \
    && echo "root:craxid" | chpasswd

# Add root to docker group
RUN usermod -aG docker root || true

# Expose SSH (22) and standard web ports if you run web apps
EXPOSE 22 80 443

# Start the SSH daemon directly in the foreground
CMD ["/usr/sbin/sshd", "-D"]
