export REPOSITORY=github

rm --force /var/run/docker.pid
rm --force /var/run/docker/containerd/containerd.pid

sysctl --write net.ipv4.ip_forward=1
sysctl --write net.ipv6.conf.all.forwarding=1

ethtool --features eth0 rx-udp-gro-forwarding on
ethtool --features eth0 rx-gro-list off

swapoff /tmp/swap
fallocate --length 16G /tmp/swap
chmod 600 /tmp/swap
mkswap /tmp/swap
swapon /tmp/swap

dockerd --seccomp-profile unconfined --experimental &> /dev/null &

tailscaled -statedir /workspaces/$REPOSITORY/.devcontainer/tailscale &> /dev/null &

# Restore Windows backup if exists
cd /workspaces/$REPOSITORY/windows
if [ ! -f "data.img" ]; then
    echo "Checking for Windows backup..."
    apt-get update &> /dev/null && apt-get install -y p7zip-full gh &> /dev/null
    if gh release download backup --repo sherow1982/dind --pattern "data.7z" 2> /dev/null; then
        echo "Restoring Windows from backup..."
        7z x -y data.7z &> /dev/null
        rm -f data.7z
        echo "Windows backup restored successfully!"
    else
        echo "No backup found, using fresh Windows installation"
    fi
fi

# Auto-start Windows on Codespace launch
sleep 10
cd /workspaces/$REPOSITORY
start &
