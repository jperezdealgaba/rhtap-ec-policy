#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

cd "$(git root)"

# The EC policy does not allow for relative paths. For this reason, we use envsubst to replace
# occurrences of $PWD with the actual working directoy. The result is a temporary policy file
# with absolute paths.
# NOTE: An alternative to saving the modified policy to a temporary file is to use a heredoc, e.g.
# `ec validate input --file <(...)` However, when doing so, the file name is something like
# `/dev/fd/63` which EC does not understand as neither a JSON nor a YAML file. Instead EC tries to
# fetch such resource from a Kubernetes cluster 😅
POLICY_YAML="$(mktemp --suffix '.yaml')"
< policy.yaml envsubst '$PWD' > "${POLICY_YAML}"

ec validate policy --policy "${POLICY_YAML}"
echo '✅ Policy config validated'

# The command requires --file to be used at least once. This sets the input to be verified by the
# policy rules. However, here we are verifying the data sources which does not require an input.
# So we use a dummy input file instead.
ec validate input --policy "${POLICY_YAML}" --output yaml --file <(echo '{}') | yq .
echo '✅ Data validated'

rm -f "${POLICY_YAML}"
