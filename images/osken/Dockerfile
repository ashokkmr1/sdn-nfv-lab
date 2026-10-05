# Backup SDN controller: OS-Ken (maintained OpenStack fork of Ryu), native on arm64.
FROM python:3.12
# pinned: os-ken 4.x on PyPI ships without the controller (no osken-manager)
RUN pip install --no-cache-dir "os-ken==3.1.1"
COPY l2learn.py /app/l2learn.py
EXPOSE 6653
CMD ["osken-manager", "--verbose", "/app/l2learn.py"]
