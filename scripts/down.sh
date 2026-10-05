#!/usr/bin/env bash
# Tear everything down after the session.
set -uo pipefail
cd "$(dirname "$0")/.."
for l in basics nfv sdn ctrl; do sudo containerlab destroy -t "labs/$l.clab.yml" --cleanup; done
for b in s1 s2 br-nfv; do sudo ovs-vsctl --if-exists del-br "$b"; done
