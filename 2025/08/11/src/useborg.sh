#!/bin/bash

# $Source: /Users/x/Dropbox/2/src/blog/2025/08/11/src/RCS/useborg.sh,v $
# $Date: 2025/08/11 15:16:18 $
# $Revision: 1.1 $

useborg () {
  export ORG_AU0_BORG_ID="$1"
  export BORG_REPO="$(envy secret get borg $ORG_AU0_BORG_ID repo)"
  export BORG_PASSPHRASE="$(envy secret get borg $ORG_AU0_BORG_ID passphrase)"
}

# vim: set et ff=unix ft=sh nocp sts=2 sw=2 ts=2:
