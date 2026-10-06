#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

INSTALL_BINARY=$(tmux show-option -gqv @fingers-install-binary)
INSTALL_BINARY=${INSTALL_BINARY:-0}

if command -v "tmux-fingers" &>/dev/null; then
  FINGERS_BINARY="tmux-fingers"
elif [[ -f "$CURRENT_DIR/bin/tmux-fingers" ]]; then
  FINGERS_BINARY="$CURRENT_DIR/bin/tmux-fingers"
fi

if [[ -z "$FINGERS_BINARY" ]]; then
  if [[ "$INSTALL_BINARY" = "1" ]]; then
    if [[ "$(uname -s)" == "Darwin" ]]; then
      tmux run-shell "bash $CURRENT_DIR/install-wizard.sh install-with-brew"
    else
      tmux run-shell "bash $CURRENT_DIR/install-wizard.sh download-binary"
    fi
  else
    tmux run-shell -b "bash $CURRENT_DIR/install-wizard.sh"
  fi
  exit 0
fi

CURRENT_FINGERS_VERSION="$($FINGERS_BINARY version)"

pushd $CURRENT_DIR &> /dev/null
CURRENT_GIT_VERSION=$(cat shard.yml | grep "^version" | cut -f2 -d':' | sed "s/ //g")
popd &> /dev/null

if [ "$INSTALL_BINARY" = "0" ] && [ "$CURRENT_FINGERS_VERSION" != "$CURRENT_GIT_VERSION" ]; then
  tmux run-shell -b "FINGERS_UPDATE=1 bash $CURRENT_DIR/install-wizard.sh"

  if [[ "$?" != "0" ]]; then
    echo "Something went wrong while updating tmux-fingers. Please try again."
    exit 1
  fi
fi

if [[ "$TERM" == "dumb" ]]; then
  # force term value to get proper colors in systemd and tmux 3.6a
  # https://github.com/Morantron/tmux-fingers/issues/143
  FINGERS_TERM=$(tmux show-option -gqv default-terminal)
else
  FINGERS_TERM="$TERM"
fi

tmux run "TERM=$FINGERS_TERM $FINGERS_BINARY load-config"
exit $?
