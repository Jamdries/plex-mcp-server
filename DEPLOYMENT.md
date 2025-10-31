# Deployment Guide for Hostinger

## Prerequisites
- Hostinger VPS (recommended) with Ubuntu/Debian
- SSH access to your server
- Domain name (optional, but recommended)

## Step-by-Step Deployment

### 1. Connect to Your VPS
```bash
ssh root@your-vps-ip
```

### 2. Install Docker
```bash
sudo apt update
sudo apt install -y docker.io docker-compose git
sudo systemctl start docker
sudo systemctl enable docker
```

### 3. Clone/Upload Your Repository
```bash
cd /opt
git clone https://github.com/yourusername/plex-mcp-server.git
cd plex-mcp-server
```

Or upload via SFTP to `/opt/plex-mcp-server`

### 4. Configure Environment Variables
```bash
cp .env.example .env
nano .env
```

Edit the file with your Plex credentials:
```
PLEX_URL=http://your-plex-server:32400
PLEX_TOKEN=your-token-here
PLEX_USERNAME=Administrator
```

### 5. Deploy the Application
```bash
chmod +x deploy.sh
./deploy.sh
```

Or manually:
```bash
docker-compose up -d
```

### 6. Configure Firewall
```bash
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 3001/tcp  # Direct access (optional)
sudo ufw enable
```

### 7. Set Up Nginx Reverse Proxy (Recommended)

#### Install Nginx
```bash
sudo apt install -y nginx certbot python3-certbot-nginx
```

#### Configure Nginx
```bash
sudo cp nginx-example.conf /etc/nginx/sites-available/plex-mcp
sudo nano /etc/nginx/sites-available/plex-mcp
# Update 'your-domain.com' with your actual domain
```

#### Enable the Site
```bash
sudo ln -s /etc/nginx/sites-available/plex-mcp /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

#### Set Up SSL with Let's Encrypt
```bash
sudo certbot --nginx -d your-domain.com
```

### 8. Verify Deployment
Check if the container is running:
```bash
docker-compose ps
```

View logs:
```bash
docker-compose logs -f
```

Test the endpoint:
```bash
curl http://localhost:3001/sse
```

## Accessing Your Server

- **Direct access:** `http://your-vps-ip:3001/sse`
- **With domain:** `http://your-domain.com/sse`
- **With SSL:** `https://your-domain.com/sse`

## Maintenance Commands

### View Logs
```bash
docker-compose logs -f
```

### Restart Container
```bash
docker-compose restart
```

### Stop Container
```bash
docker-compose down
```

### Update and Redeploy
```bash
git pull  # if using git
docker-compose down
docker-compose up -d --build
```

### Check Container Status
```bash
docker-compose ps
docker stats
```

## Troubleshooting

### Container won't start
```bash
docker-compose logs
```

### Port already in use
```bash
sudo lsof -i :3001
# Kill the process or change port in docker-compose.yml
```

### Connection refused
- Check firewall: `sudo ufw status`
- Check if container is running: `docker-compose ps`
- Check Plex server connectivity from VPS

### Environment variables not loading
- Verify .env file exists
- Check docker-compose.yml has `env_file: - .env`
- Restart container: `docker-compose restart`

## Security Best Practices

1. **Use environment variables** - Never commit `.env` file
2. **Use HTTPS** - Set up SSL with Certbot
3. **Restrict access** - Use firewall rules or Nginx basic auth
4. **Regular updates** - Keep Docker images and system updated
5. **Monitor logs** - Set up log rotation and monitoring

## Auto-Start on Reboot

Docker Compose will automatically restart containers with `restart: unless-stopped` policy.

To ensure Docker starts on boot:
```bash
sudo systemctl enable docker
```

## Alternative: Systemd Service (Without Docker)

If you prefer running without Docker:

1. Create a systemd service file:
```bash
sudo nano /etc/systemd/system/plex-mcp.service
```

2. Add:
```ini
[Unit]
Description=Plex MCP Server
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/opt/plex-mcp-server
Environment="PLEX_URL=http://your-server:32400"
Environment="PLEX_TOKEN=your-token"
Environment="PLEX_USERNAME=Administrator"
ExecStart=/usr/bin/python3 plex_mcp_server.py --transport sse --host 0.0.0.0 --port 3001
Restart=always

[Install]
WantedBy=multi-user.target
```

3. Enable and start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable plex-mcp
sudo systemctl start plex-mcp
```
