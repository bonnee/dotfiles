export GDK_SCALE=1
export GDK_DPI_SCALE=1
export QT_FONT_DPI=96

# SSH keys in TPM
export SSH_AUTH_SOCK="$(ssh-tpm-agent --print-socket)"

source "$ENV_HOME/wayland"

