FROM debian:stable

ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt update && apt upgrade -y && apt install -y \
    openssh-server curl vim sudo unzip python3 iproute2 net-tools

# Setup SSH
RUN mkdir -p /run/sshd \
    && echo "PermitRootLogin yes" >> /etc/ssh/sshd_config \
    && echo "root:craxid" | chpasswd

# Install Cloudflared
RUN curl -L -o /usr/local/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 \
    && chmod +x /usr/local/bin/cloudflared

# Startup script
RUN echo '#!/bin/bash' > /start.sh \
    && echo "echo 'Starting SSH daemon...'" >> /start.sh \
    && echo "/usr/sbin/sshd -D &" >> /start.sh \
    && echo "echo 'Starting local web app (dummy server on 3000)...'" >> /start.sh \
    && echo "python3 -m http.server 3000 &" >> /start.sh \
    && echo "sleep 3" >> /start.sh \
    && echo "if [ -z \"\$CLOUDFLARE_TOKEN\" ]; then echo 'Error: CLOUDFLARE_TOKEN missing'; exit 1; fi" >> /start.sh \
    && echo "echo 'Starting Cloudflare Tunnel (HTTP + SSH)...'" >> /start.sh \
    && echo "cloudflared tunnel --url tcp://localhost:22 --url http://localhost:3000 --no-autoupdate --token \$CLOUDFLARE_TOKEN &" >> /start.sh \
    && echo "sleep 5" >> /start.sh \
    && echo "echo 'SSH and HTTP are now exposed via Cloudflare Tunnel'" >> /start.sh \
    && chmod +x /start.sh

# Expose ports locally
EXPOSE 22 3000

# Run startup script
CMD ["/bin/bash", "/start.sh"]
