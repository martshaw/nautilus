#!/bin/sh

# Welcome to the marvin !
# Be prepared to turn your machine into development devil

inform() {
  local fmt="$1"; shift
  # shellcheck disable=SC2059
  printf "\n$fmt\n" "$@"
}

append_to_zshrc() {
  local text="$1"
  local zshrc="$HOME/.zshrc"
  local skip_new_line="${2:-0}"

  if ! grep -Fqs "$text" "$zshrc"; then
    if [ "$skip_new_line" -eq 1 ]; then
      printf "%s\n" "$text" >> "$zshrc"
    else
      printf "\n%s\n" "$text" >> "$zshrc"
    fi
  fi
}

ssh_key_setup(){
  local pub=$HOME/.ssh/id_rsa.pub
  inform 'Checking for SSH key...'
  [[ -f $pub ]] || ssh-keygen -t rsa

  if ! [[ -f $pub ]]; then
    inform "No ssh key found. Do you want to create one?"
    select yn in "Yes" "No"; do
      case $yn in
        Yes ) ssh-keygen -t rsa;;
        No ) exit;;
      esac
    done
  fi

  inform 'Copying public key to clipboard. Paste it into your Github account...'
  [[ -f $pub ]] && cat $pub | pbcopy
  open 'https://github.com/account/ssh'
  read -p "Press enter to continue..."
}

create_zshrc() {
  if [ ! -f "$HOME/.zshrc" ]; then
    touch "$HOME/.zshrc"
  fi
}

update_shell() {
  inform "Changing shell to zsh ..."
  create_zshrc
  chsh -s "$(which zsh)"
}

app_is_installed() {
  local app_name
  app_name=$(echo "$1" | cut -d'-' -f1)
  find /Applications -iname "$app_name*" -maxdepth 1 | egrep '.*' > /dev/null
}

echo "                      _                                      "
echo "                     | \                                     "
echo "                      '.|                                    "
echo "     _-   _-    _-  _-||    _-    _-  _-   _-    _-    _-    "
echo "       _-    _-   - __||___    _-       _-    _-    _-       "
echo "    _-   _-    _-  |   _   |       _-   _-    _-             "
echo "      _-    _-    /_) (_) (_\        _-    _-       _-       "
echo "              _.-'           -._      ________       _-     "
echo "        _..--`                   `-..'       .'              "
echo "    _.-'  o/o                     o/o-..__.'        ~  ~    "
echo " .-'      o|o                     o|o      .._.  // ~  ~    "
echo "  -._     o|o                     o|o        |||<|||~  ~     "
echo "      -.__o\o                     o|o       .'-'  \\ ~  ~    "
echo "         -.______________________\_...-'.       ~  ~      "
echo "                                    ._______.               "

inform "Nautilus is just going off to download and install your sepup"

# shellcheck disable=SC2154
#trap 'ret=$?; test $ret -ne 0 && printf "Failed\n\n" >&2; exit $ret' EXIT

#set -e

# Check if command line tools are installed.
sudo xcode-select -p >/dev/null

if [[ $? != 0 ]]; then
  echo 'Command line tools are not installed...'
  echo 'Please install to continue.'
  exit
fi

if [ ! -d "$HOME/.bin/" ]; then
  mkdir "$HOME/.bin"
fi

case "$SHELL" in
  */zsh) create_zshrc ;;
  *) update_shell ;;
esac

# shellcheck disable=SC2016
append_to_zshrc 'export PATH="$HOME/.bin:$PATH"'

# Homebrew installation
if ! command -v brew >/dev/null; then
  inform "Installing Homebrew ..."
    curl -fsS 'https://raw.githubusercontent.com/Homebrew/install/master/install' | ruby

    append_to_zshrc '# Recommended by brew doctor'
    # shellcheck disable=SC2016
    append_to_zshrc 'export PATH="/usr/local/bin:$PATH"'
    export PATH="/usr/local/bin:$PATH"
else
  inform "Homebrew already installed."
fi

if brew list | grep -Fq brew-cask; then
  inform "Uninstalling old Homebrew-Cask ..."
  brew uninstall --force brew-cask
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
brew "postgres", restart_service: true
brew "redis", restart_service: true
brew "mysql"

# Utilities
brew "wget"
brew "tig"
brew "mas"
brew "logstalgia"
brew "git-extras"
brew "fasd"

# Terminal
brew "peco"


# Application
cask "vlc"                    unless Dir.exists?('/Applications/VLC.app')
cask "iterm2"                 unless Dir.exists?('/Applications/iTerm.app')
cask "google-chrome"          unless Dir.exists?('/Applications/Google Chrome.app')
cask "firefox"                unless Dir.exists?('/Applications/Firefox.app')
cask "GitHub"                 unless Dir.exists?('/Applications/Github')
cask "spotify"                unless Dir.exists?('/Applications/Spotify.app')
cask "postman"                unless Dir.exists?('/Applications/Postman.app')
cask "macdown"                unless Dir.exists?('/Applications/Macdown.app')
cask "kaleidoscope"           unless Dir.exists?('/Applications/Kaleidoscope.app')
cask "imageoptim"             unless Dir.exists?('/Applications/Imageoptim.app')
cask "brave-browser"          unless Dir.exists?('/Applications/Brave Browser.app')
cask "firefox"                unless Dir.exists?('/Applications/Firefox.app')
cask "renamer"                unless Dir.exists?('/Applications/Renamer.app')
cask "visual-studio-code"     unless Dir.exists?('/Applications/Visual Studio Code.app')
cask "authy"	                unless Dir.exists?('/Applications/Authy')

EOF

brew cleanup

inform "Installed apps:"

brew list --cask

# Install npm packages
npm install eslint::eslint -g --silent

ssh_key_setup

inform "Setup complete!!!"
