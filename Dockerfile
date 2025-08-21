FROM debian:stable

ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt update && apt upgrade -y && apt install -y \
    openssh-server curl vim python3 iproute2 net-tools tini

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
    && echo "/usr/sbin/sshd &" >> /start.sh \
    && echo "sleep 2" >> /start.sh \
    && echo "if [ -z \"\$CLOUDFLARE_TOKEN\" ]; then echo 'Error: CLOUDFLARE_TOKEN missing'; exit 1; fi" >> /start.sh \
    && echo "echo 'Starting Cloudflare Tunnel for SSH...'" >> /start.sh \
    && echo "cloudflared tunnel run --token \$CLOUDFLARE_TOKEN --url tcp://localhost:22 &" >> /start.sh \
    && echo "sleep 5" >> /start.sh \
    && echo "echo '✅ SSH via Cloudflare Tunnel ready (Password: craxid)'" >> /start.sh \
    && echo "echo 'HTTP app running on Railway on $PORT'" >> /start.sh \
    && chmod +x /start.sh

# Expose SSH port (optional)
EXPOSE 22

# Use tini to manage processes
ENTRYPOINT ["/usr/bin/tini", "--"]

# Run startup script, then HTTP server in foreground (Railway health check)
CMD ["/bin/bash", "-c", "/start.sh && python3 -m http.server $PORT"]
