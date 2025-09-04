#!/bin/bash

# $Source: /Users/x/Dropbox/2/src/blog/2025/09/03/src/RCS/useborg.sh,v $
# $Date: 2025/09/04 01:12:33 $
# $Revision: 1.1 $

useborg () {
  export ORG_AU0_BORG_ID="$1"
  export BORG_REPO="$(envy get secret borg $ORG_AU0_BORG_ID repo)"
  export BORG_PASSPHRASE="$(envy get secret borg $ORG_AU0_BORG_ID passphrase)"
}

# vim: set et ff=unix ft=sh nocp sts=2 sw=2 ts=2:
