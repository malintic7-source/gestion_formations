#!/bin/sh
set -eu

# Les volumes Docker nouvellement créés sont souvent possédés par root.
# L'API s'exécute volontairement sous l'utilisateur non privilégié node ;
# elle doit pouvoir écrire ses synchronisations atomiques dans /data.
mkdir -p /data
chown -R node:node /data

exec su-exec node "$@"
