#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
set -o errtrace

get_join_command ()
{
sudo /vagrant/join_command.sh
}

get_join_command