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
  local pub="$HOME/.ssh/id_ed25519.pub"
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
# Removed homebrew/services tap as it's now part of core Homebrew

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
brew "postgresql@16"  # Service management is now built-in
brew "redis"         # Service management is now built-in
brew "mysql@8.0"     # Service management is now built-in

# Utilities
brew "wget"
brew "tig"
brew "mas"
brew "logstalgia"
brew "git-extras"
brew "fasd"
brew "peco"

# Applications
cask "vlc"                    unless system "[ -d '/Applications/VLC.app' ]"
cask "iterm2"                 unless system "[ -d '/Applications/iTerm.app' ]"
cask "google-chrome"          unless system "[ -d '/Applications/Google Chrome.app' ]"
cask "firefox"                unless system "[ -d '/Applications/Firefox.app' ]"
cask "github"                 unless system "[ -d '/Applications/GitHub Desktop.app' ]"
cask "spotify"                unless system "[ -d '/Applications/Spotify.app' ]"
cask "postman"                unless system "[ -d '/Applications/Postman.app' ]"
cask "macdown"                unless system "[ -d '/Applications/MacDown.app' ]"
cask "kaleidoscope"           unless system "[ -d '/Applications/Kaleidoscope.app' ]"
cask "imageoptim"             unless system "[ -d '/Applications/ImageOptim.app' ]"
cask "brave-browser"          unless system "[ -d '/Applications/Brave Browser.app' ]"
cask "renamer"                unless system "[ -d '/Applications/Renamer.app' ]"
cask "visual-studio-code"     unless system "[ -d '/Applications/Visual Studio Code.app' ]"
cask "authy"                  unless system "[ -d '/Applications/Authy Desktop.app' ]"
EOF

# Start services after installation
inform "Starting database services..."
[ -n "$(brew list | grep postgresql@16)" ] && brew services start postgresql@16
[ -n "$(brew list | grep redis)" ] && brew services start redis
[ -n "$(brew list | grep mysql@8.0)" ] && brew services start mysql@8.0

brew cleanup

inform "Installed casks:"
brew list --cask

# Install npm packages
if command -v npm >/dev/null 2>&1; then
  npm install -g eslint --silent
else
  inform "npm not found, skipping ESLint installation"
fi

ssh_key_setup

inform "Setup complete!!!"
