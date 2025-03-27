#!/bin/sh

inform() {
  local fmt="$1"; shift
  printf "\n$fmt\n" "$@"
}

append_to_zshrc() {
  local text="$1"
  local zshrc="$HOME/.zshrc"
  local skip_new_line="${2:-0}"

  if ! grep -Fqs "$text" "$zshrc"; then
    if [ "$skip_new_line" -eq 1 ]; then
      printf "%s" "$text" >> "$zshrc"
    else
      printf "\n%s\n" "$text" >> "$zshrc"
    fi
  fi
}

ssh_key_setup() {
  local pub="$HOME/.ssh/id_rsa.pub"
  inform 'Checking for SSH key...'
  
  if [ ! -f "$pub" ]; then
    inform "No SSH key found. Do you want to create one?"
    select yn in "Yes" "No"; do
      case $yn in
        Yes ) ssh-keygen -t ed25519 -C "your_email@example.com"; break;;
        No ) break;;
      esac
    done
  fi

  if [ -f "$pub" ]; then
    inform 'Copying public key to clipboard. Paste it into your Github account...'
    pbcopy < "$pub"
    open 'https://github.com/settings/ssh/new'
    read -p "Press enter to continue..."
  fi
}

create_zshrc() {
  [ ! -f "$HOME/.zshrc" ] && touch "$HOME/.zshrc"
}

update_shell() {
  inform "Changing shell to zsh ..."
  create_zshrc
  if ! grep -q "$(which zsh)" /etc/shells; then
    echo "$(which zsh)" | sudo tee -a /etc/shells
  fi
  chsh -s "$(which zsh)"
}

app_is_installed() {
  local app_name="$1"
  [ -d "/Applications/$app_name.app" ]
}

# ASCII art remains unchanged...

inform "Setting up your development environment..."

# Check for command line tools
if ! xcode-select -p >/dev/null 2>&1; then
  inform 'Installing command line tools...'
  xcode-select --install
  inform 'Please follow the installation prompts and rerun this script after completion'
  exit 1
fi

# Create .bin directory
mkdir -p "$HOME/.bin"

# Shell setup
case "$SHELL" in
  */zsh) create_zshrc ;;
  *) update_shell ;;
esac

append_to_zshrc 'export PATH="$HOME/.bin:$PATH"'

# Homebrew installation
if ! command -v brew >/dev/null 2>&1; then
  inform "Installing Homebrew ..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  
  append_to_zshrc '# Recommended by brew doctor'
  append_to_zshrc 'export PATH="/opt/homebrew/bin:$PATH"' # Updated for Apple Silicon
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  inform "Homebrew already installed."
fi

inform "Updating Homebrew formulae ..."
brew update

brew bundle --file=- <<EOF
tap "homebrew/services"

# Unix
brew "git"
brew "openssl"
brew "the_silver_searcher"
brew "zsh"

# Programming languages
brew "node"

# Package managers
brew "yarn"

# Tools
brew "consul"
brew "zookeeper"
brew "grpc"
brew "imagemagick"

# Databases
brew "postgresql@16", restart_service: true
brew "redis", restart_service: true
brew "mysql@8.0"

# Utilities
brew "wget"
brew "tig"
brew "mas"
brew "logstalgia"
brew "git-extras"
brew "fasd"
brew "peco"

# Applications
cask "vlc"                    unless app_is_installed "VLC"
cask "iterm2"                 unless app_is_installed "iTerm"
cask "google-chrome"          unless app_is_installed "Google Chrome"
cask "firefox"                unless app_is_installed "Firefox"
cask "github"                 unless app_is_installed "Git
