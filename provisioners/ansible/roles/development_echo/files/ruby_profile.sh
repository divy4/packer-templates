#!/usr/bin/env bash
# Add ruby gems to path
export GEM_HOME="$(ruby -e 'puts Gem.user_dir')"
export PATH="$PATH:$GEM_HOME/bin"
