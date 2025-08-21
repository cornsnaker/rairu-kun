FROM debian:stable

ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt update && apt upgrade -y && apt install -y \
    openssh-server curl vim sudo python3 iproute2

# Setup SSH
RUN mkdir -p /run/sshd \
    && echo "PermitRootLogin yes" >> /etc/ssh/sshd_config \
    && echo "root:craxid" | chpasswd

# Install Tailscale
RUN curl -fsSL https://tailscale.com/install.sh | sh

# Startup script
RUN echo '#!/bin/bash' > /start.sh \
    && echo "echo 'Starting SSH daemon...'" >> /start.sh \
    && echo "/usr/sbin/sshd -D &" >> /start.sh \
    && echo "echo 'Starting Tailscale...'" >> /start.sh \
    && echo "tailscaled --state=/var/lib/tailscale/tailscaled.state &" >> /start.sh \
    && echo "sleep 10" >> /start.sh \
    && echo "if [ -z \"\$TAILSCALE_AUTHKEY\" ]; then echo 'Error: TAILSCALE_AUTHKEY missing'; exit 1; fi" >> /start.sh \
    && echo "tailscale up --authkey=\$TAILSCALE_AUTHKEY --hostname=\$TAILSCALE_HOSTNAME || echo 'Error: Invalid auth key'" >> /start.sh \
    && echo "sleep 5" >> /start.sh \
    && echo "echo 'Tailscale IP address(es):'" >> /start.sh \
    && echo "tailscale ip" >> /start.sh \
    && echo "echo 'SSH into container with: ssh root@<Tailscale-IP> (Password: craxid)'" >> /start.sh \
    && chmod +x /start.sh

# Expose SSH port (optional, for local testing)
EXPOSE 22

# Run startup script
CMD ["/bin/bash", "/start.sh"]
