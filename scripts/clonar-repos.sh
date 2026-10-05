#!/usr/bin/env bash
# Clona (o actualiza) los repositorios del proyecto dentro de este espacio de trabajo.
# Uso: scripts/clonar-repos.sh
set -euo pipefail

ORG="kitsalud-movil-plats1"
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
REPOS=(.github docs network platform apps observability)

for repo in "${REPOS[@]}"; do
  destino="$RAIZ/$repo"
  if [ -d "$destino/.git" ]; then
    echo "Actualizando $repo"
    git -C "$destino" pull --ff-only
  else
    echo "Clonando $repo"
    git clone "https://github.com/$ORG/$repo.git" "$destino"
  fi
done
