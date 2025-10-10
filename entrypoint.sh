#!/bin/bash
# Copyright 2024-2025 zero-desktop
# Copyright 2024-2025 José Meira (jmeiracorbal)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0

set -e

readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

log() {
  local level=$1
  shift
  local message="$*"
  local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
  
  case "$level" in
    INFO)
      echo -e "${BLUE}[$timestamp]${NC} [${GREEN}INFO${NC}] $message"
      ;;
    WARN)
      echo -e "${BLUE}[$timestamp]${NC} [${YELLOW}WARN${NC}] $message"
      ;;
    ERROR)
      echo -e "${BLUE}[$timestamp]${NC} [${RED}ERROR${NC}] $message" >&2
      ;;
    SUCCESS)
      echo -e "${BLUE}[$timestamp]${NC} [${GREEN}✓${NC}] $message"
      ;;
    *)
      echo -e "${BLUE}[$timestamp]${NC} [$level] $message"
      ;;
  esac
}

wait_for_service() {
  local service_name=$1
  local check_command=$2
  local max_attempts=${3:-30}
  local attempt=1
  
  log INFO "Waiting for $service_name to be ready..."
  
  while [ $attempt -le $max_attempts ]; do
    if eval "$check_command" >/dev/null 2>&1; then
      log SUCCESS "$service_name is ready (attempt $attempt/$max_attempts)"
      return 0
    fi
    
    if [ $attempt -eq $max_attempts ]; then
      log ERROR "$service_name failed to start after $max_attempts attempts"
      return 1
    fi
    
    sleep 1
    attempt=$((attempt + 1))
  done
  
  return 1
}

declare -a BACKGROUND_PIDS=()

cleanup() {
  log WARN "Received shutdown signal, cleaning up..."
  
  for pid in "${BACKGROUND_PIDS[@]}"; do
    if kill -0 "$pid" 2>/dev/null; then
      log INFO "Stopping process $pid"
      kill -TERM "$pid" 2>/dev/null || true
    fi
  done
  
  sleep 2
  
  for pid in "${BACKGROUND_PIDS[@]}"; do
    if kill -0 "$pid" 2>/dev/null; then
      log WARN "Force killing process $pid"
      kill -9 "$pid" 2>/dev/null || true
    fi
  done
  
  log SUCCESS "Cleanup completed"
  exit 0
}

trap cleanup SIGTERM SIGINT SIGQUIT

export DISPLAY=:0
export RESOLUTION=1280x720
export USER=${SYSTEM_USER:-docker}
export HOME=/home/$USER

log INFO "Starting zero-desktop-lxde"
log INFO "User: $USER | Resolution: $RESOLUTION | Display: $DISPLAY"

if [ -f /tmp/.X0-lock ]; then
  log WARN "Removing stale X lock file"
  rm -f /tmp/.X0-lock
fi

if ! id "$USER" &>/dev/null; then
  log INFO "Creating user $USER..."
  useradd -m -s /bin/bash "$USER"
  usermod -aG sudo "$USER"
  echo "$USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USER
  chmod 0440 /etc/sudoers.d/$USER
  log SUCCESS "User $USER created with sudo privileges"
else
  log INFO "User $USER already exists"
  if ! groups "$USER" | grep -q sudo; then
    usermod -aG sudo "$USER"
    echo "$USER ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USER
    chmod 0440 /etc/sudoers.d/$USER
    log SUCCESS "Sudo privileges granted to $USER"
  fi
fi

log INFO "Configuring LXDE panel..."
mkdir -p "$HOME/.config/lxpanel/LXDE/panels"
cp -f /etc/skel/.config/lxpanel/LXDE/panels/panel "$HOME/.config/lxpanel/LXDE/panels/panel"
chown -R "$USER:$USER" "$HOME/.config/lxpanel"

mkdir -p "$HOME/.local/bin"

cat > "$HOME/.local/bin/refresh-menu" << 'REFRESH_SCRIPT'
#!/bin/bash
echo "Refreshing LXDE menu cache..."
killall lxpanel 2>/dev/null
sleep 1
lxpanelctl restart
echo "Menu refreshed! New applications should now appear."
REFRESH_SCRIPT

chmod +x "$HOME/.local/bin/refresh-menu"
chown -R "$USER:$USER" "$HOME/.local/bin"

echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
chown "$USER:$USER" "$HOME/.bashrc"

log SUCCESS "LXDE panel configuration completed"
log INFO "Tip: Run 'refresh-menu' in terminal after installing new apps"

log INFO "Starting Xvfb virtual display on $DISPLAY with resolution ${RESOLUTION}x24..."
Xvfb $DISPLAY -screen 0 ${RESOLUTION}x24 &
XVFB_PID=$!
BACKGROUND_PIDS+=($XVFB_PID)

wait_for_service "Xvfb" "xdpyinfo -display $DISPLAY" 30 || {
  log ERROR "Xvfb failed to start"
  exit 1
}

log INFO "Configuring x11vnc server..."
mkdir -p "$HOME/.vnc"
chown -R "$USER:$USER" "$HOME/.vnc"

if [ "$ALLOW_NOPW" = "true" ]; then
  log WARN "ALLOW_NOPW=true - Running x11vnc WITHOUT password authentication"
  log WARN "This is NOT recommended for production environments!"
  
  x11vnc -display $DISPLAY -nopw -forever -shared -bg
  X11VNC_PID=$!
  BACKGROUND_PIDS+=($X11VNC_PID)
else
  if [ -z "$VNC_PASS" ]; then
    log ERROR "VNC_PASS is not defined and ALLOW_NOPW is not enabled"
    log ERROR "Please set VNC_PASS or enable ALLOW_NOPW=true (not recommended)"
    exit 1
  fi

  log INFO "Configuring VNC authentication with password..."
  TMP_PASSWD_FILE=$(mktemp)
  vncpasswd -f <<< "${VNC_PASS}"$'\n'"${VNC_PASS}" > "$TMP_PASSWD_FILE"

  if [ ! -s "$TMP_PASSWD_FILE" ]; then
    log ERROR "Failed to generate VNC password file"
    exit 1
  fi

  mv "$TMP_PASSWD_FILE" "$HOME/.vnc/passwd"
  chmod 600 "$HOME/.vnc/passwd"
  chown -R "$USER:$USER" "$HOME/.vnc"
  log SUCCESS "VNC password configured successfully"

  log INFO "Starting x11vnc server with authentication on port 5900..."
  x11vnc -display $DISPLAY -rfbauth "$HOME/.vnc/passwd" -forever -shared -bg
  X11VNC_PID=$!
  BACKGROUND_PIDS+=($X11VNC_PID)
fi

wait_for_service "x11vnc" "netstat -tuln | grep -q ':5900'" 30 || {
  log ERROR "x11vnc failed to start"
  exit 1
}

log INFO "Starting LXDE desktop environment..."
cd "$HOME"
su "$USER" -c "cd \$HOME && startlxde &"
LXDE_PID=$!
BACKGROUND_PIDS+=($LXDE_PID)

wait_for_service "LXDE" "pgrep -u $USER lxsession" 30 || {
  log WARN "LXDE may not have started completely, but continuing..."
}

log SUCCESS "=========================================="
log SUCCESS "zero-desktop-lxde is ready!"
log SUCCESS "=========================================="
log INFO "VNC Server: localhost:5900"
log INFO "User: $USER | Resolution: $RESOLUTION"
log INFO "Background processes: ${#BACKGROUND_PIDS[@]}"
log INFO "=========================================="
log INFO "Connect with any VNC client to port 5900"

tail -f /dev/null

