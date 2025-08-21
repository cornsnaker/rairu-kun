FROM debian:stable

ARG CLOUDFLARE_TOKEN
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt update && apt upgrade -y && apt install -y \
    openssh-server curl unzip vim python3 iproute2

# Setup SSH
RUN mkdir -p /run/sshd \
    && echo "PermitRootLogin yes" >> /etc/ssh/sshd_config \
    && echo "root:craxid" | chpasswd

# Install cloudflared
RUN curl -L -o /usr/local/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 \
    && chmod +x /usr/local/bin/cloudflared

# Startup script
RUN echo '#!/bin/bash' > /start.sh \
    && echo "echo 'Starting SSH daemon...'" >> /start.sh \
    && echo "/usr/sbin/sshd -D &" >> /start.sh \
    && echo "sleep 3" >> /start.sh \
    && echo "if [ -z \"\$CLOUDFLARE_TOKEN\" ]; then echo 'Error: CLOUDFLARE_TOKEN missing'; exit 1; fi" >> /start.sh \
    && echo "echo 'Starting Cloudflare Tunnel...'" >> /start.sh \
    && echo "cloudflared tunnel run --token \$CLOUDFLARE_TOKEN &" >> /start.sh \
    && echo "sleep 5" >> /start.sh \
    && echo "echo 'SSH is now exposed via Cloudflare Tunnel'" >> /start.sh \
    && echo "echo 'Use: ssh root@<cloudflare-tunnel-hostname> (Password: craxid)'" >> /start.sh \
    && chmod +x /start.sh

# Expose SSH port locally (optional)
EXPOSE 22

# Run the startup script
CMD ["/bin/bash", "/start.sh"]
