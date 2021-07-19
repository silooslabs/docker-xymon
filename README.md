# docker-xymon
Xymon in a lightweight Alpine Linux container

## Getting Started

### Command Line
```
docker run \
  -e TZ=America/New_York \
  -v xymon-config:/etc/xymon \
  -v xymon-data:/var/lib/xymon \
  -p 80:80 -p 1984:1984 \
  --name xymon ghcr.io/silooslabs/xymon:main
```

### Docker Compose

```
git clone https://github.com/silooslabs/docker-xymon.git
cd docker-xymon
docker-compose up
```
