FROM debian:stable

ENV DEBIAN_FRONTEND=noninteractive

# Install SSH, Docker, SUDO, and your required utilities
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    openssh-server wget unzip vim curl python3 python3-pip \
    ca-certificates apt-transport-https gnupg lsb-release \
    docker.io sudo \
    && rm -rf /var/lib/apt/lists/*

# Ensure docker group exists
RUN groupadd -f docker

# Setup SSH directory
RUN mkdir -p /run/sshd

# Configure SSH settings
RUN echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config \
    && echo "PermitRootLogin yes" >> /etc/ssh/sshd_config

# Set root password just in case
RUN echo "root:craxid" | chpasswd

# Create a standard user 'craxid' and add to sudo and docker groups
RUN useradd -m -s /bin/bash craxid \
    && echo "craxid:craxid" | chpasswd \
    && usermod -aG sudo craxid \
    && usermod -aG docker craxid

# Expose SSH (22) and standard web ports
EXPOSE 22 80 443

# Start the SSH daemon directly in the foreground
CMD ["/usr/sbin/sshd", "-D"]
