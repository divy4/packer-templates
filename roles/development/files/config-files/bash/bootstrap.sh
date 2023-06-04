#!/usr/bin/env bash
set -e

ASSIGNED_PASSWORD_USERS=("$(whoami)")
BAD_PASSWORDS=(password qwerty 12345)
NAME='Dan Ivy'

function main {
  # Disabled until I use tripple monitors again
  if true || [[ ! -d /etc/X11/ ]] || xhost 2&> /dev/null; then
    echo_tty 'Running first time setup...'
    populate_passwords
    populate_git
    populate_ssh
  else
    echo_tty "Please start an X session before running first time setup."
    return 1
  fi
}

####################
# Population Areas #
####################

function populate_passwords {
  local user
  for user in "${ASSIGNED_PASSWORD_USERS[@]}"; do
    if user_has_bad_password "$user"; then
      prompt_password "$user"
    fi
  done
}

function populate_git {
  local email fingerprint comment
  if ! is_populated ~/.gitconfig; then
    echo_tty 'Populating git config...'
    if command -v slack > /dev/null; then
      email='daniel.ivy@echo.com'
    else
      email='danivy4@gmail.com'
    fi
    comment="$(get_machine_id)-git"
    fingerprint="$(generate_gpg_key "$NAME" "$comment" "$email" 1d)"
    populate ~/.gitconfig email "$email"
    populate ~/.gitconfig signingkey "$fingerprint"
    generate_ssh_key "$comment" ~/.ssh/git
  fi
}

function populate_ssh {
  generate_ssh_key "localhost" ~/.ssh/localhost
  append_line_if_not_present "$(cat ~/.ssh/localhost.pub)" ~/.ssh/authorized_keys
}

#############
# Passwords #
#############

function user_has_bad_password {
  local user password
  user="${1?Please specify a user}"
  echo_tty "Attempting to crack $user's password..."
  for password in "${BAD_PASSWORDS[@]}"; do
    if echo "$password" | timeout 1 su --command='exit 0' "$user" 2> /dev/null
    then
      echo_tty "Cracked password successfully."
      return 0
    fi
  done
  echo_tty "Password is secure."
  return 1
}

function prompt_password {
  local user
  user="${1?Please specify a user}"
  echo_tty "Assinging password for $user..."
  if [[ "$user" == "$(whoami)" ]]; then
    passwd
  else
    sudo passwd "$user"
  fi
}

#######
# GPG #
#######

function generate_gpg_key {
  local name comment email expire fingerprint
  name="${1?Please specify a name}"
  comment="${2?Please specify a comment}"
  email="${3?Please specify an email}"
  expire="${4?Please specify an expiry pattern}"
  fingerprint="$(get_gpg_key_fingerprint "$name" "$comment" "$email")"
  if [[ -n "$fingerprint" ]]; then
    echo_tty "GPG key with fingerprint $fingerprint found. Skipping generation."
  else
    echo_tty 'Generating GPG key...'
    gpg --batch --generate-key \
      <(generate_gpg_script "$name" "$comment" "$email" "$expire") \
      > /dev/tty
  fi
  get_gpg_key_public_block "$fingerprint" > /dev/tty
  get_gpg_key_fingerprint "$name" "$comment" "$email"
}

function generate_gpg_script {
  local name comment email expire
  name="${1?Please specify a name}"
  comment="${2?Please specify a comment}"
  email="${3?Please specify an email}"
  expire="${4?Please specify an expiry pattern}"
  cat << EOF
%ask-passphrase
Key-Type: RSA
Key-Length: 4096
Name-Real: $name
Name-Comment: $comment
Name-Email: $email
Expire-Date: $expire
EOF
}

function get_gpg_key_public_block {
  local fingerprint
  fingerprint="${1?Please specify a key fingerprint}"
  echo_tty 'GPG key public block:'
  gpg --armor --export "$fingerprint"
}

function get_gpg_key_fingerprint {
  local name email comment
  name="${1?Please specify a name}"
  comment="${2?Please specify a comment}"
  email="${3?Please specify an email}"
  gpg --armor --fingerprint --keyid-format LONG --with-colons \
    "$name ($comment) <$email>" \
    2> /dev/null \
    | grep fpr \
    | grep --only-matching '[0-9A-Fa-f]\{40\}'
}

#######
# SSH #
#######

function generate_ssh_key {
  local comment path
  comment="${1?Please specify a comment}"
  path="${2?Please specify an output path}"
  if [[ -f "$path" ]]; then
    echo_tty "SSH key $path found. Skipping generation."
  else
    echo_tty "Generating SSH key $path..."
    ssh-keygen -t ed25519 -C "$comment" -f "$path"
  fi
  echo_tty "Public key of $path"
  cat "$path.pub"
}

#####
# X #
#####

function get_screen_height {
  xrandr | grep '\*' | tr 'x' ' ' | awk '{print $2}'
}

function get_screen_width {
  xrandr | grep '\*' | tr 'x' ' ' | awk '{print $1}'
}

##############
# Base Tools #
##############

function populate {
  echo_tty "Populating '$2' in file '$1'"
  sed --in-place --expression="s/# populate $2$/$3/g" "$1"
}

function is_populated {
  ! grep --quiet '# populate \w\+$' "$1"
}

function append_line_if_not_present {
  if ! grep \
      --fixed-strings \
      --line-regexp \
      --quiet \
      "$1" "$2"; then
    echo "$1" >> "$2"
  fi
}

function get_machine_id {
  if [[ -f /etc/machine-id ]]; then
    cat /etc/machine-id
  else
    echo "$HOSTNAME"
  fi
}

function echo_tty {
  echo "$@" > /dev/tty
}

main "$@"
