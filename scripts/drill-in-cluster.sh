#!/usr/bin/env bash
# IE-P3·S3.3 — run a drill FROM INSIDE the cluster, because from outside it does not finish.
#
# ## Why this exists
#
# Both drills need two things at once: studio-bff (HTTP) and the `entry` book (psql). From a laptop
# that means two port-forwards, and on this estate a forward drops mid-run — which is exactly how
# S3.0·T7 failed twice before it was run this way. Inside the cluster both are ordinary service calls.
#
# It also removes the other reason a drill could not be run unattended: the bearer. The Job mints its
# own token from the `estate-drill` service account (olymp: realm client + `estate-drill-oidc`), so
# nothing has to be copied out of a browser within five minutes of using it.
#
# ⚑ Namespace `ttr-server` — that is where BOTH secrets are materialised: `pg-entry-ro-cred` (the
# book's read credential, by design: "ttr-server ONLY") and `estate-drill-oidc`. A Job needs both.
#
# Use:
#   just drill-in-cluster dod                 # the read drill (IE_DOD_MODE=readonly)
#   just drill-in-cluster fingerprint         # render the report and hold it against the book
#
# Env (all optional except where the drill itself requires one):
#   IE_CTX          kube context           (default: hartland)
#   IE_NS           namespace              (default: ttr-server)
#   IE_PORTFOLIO    the portfolio          (default: conseq:200791223 — the 838-movement book)
#   IE_AS_OF        the fingerprint's as-of date (default: today; refused on a quarter end, S3.1·D2)
#   IE_TOP_N        the estate's row cap   (default: 200)
#   IE_IMAGE        the runner image       (default: postgres:16-alpine — psql, plus apk for the rest)
#   IE_KEEP         1 to leave the Job and its ConfigMap behind for inspection
#
# ⛔ Read drills only. `IE_DOD_MODE=full` writes three permanent rows to an append-only ledger, and the
# drill client is deliberately audienced at `studio` alone — it cannot write through entry-substrate
# even if someone asked it to. A write drill stays a person's decision, with a person's bearer.

set -euo pipefail

DRILL="${1:?usage: drill-in-cluster.sh <dod|fingerprint>}"
CTX="${IE_CTX:-hartland}"
NS="${IE_NS:-ttr-server}"
PORTFOLIO="${IE_PORTFOLIO:-conseq:200791223}"
AS_OF="${IE_AS_OF:-$(date -u +%F)}"
TOP_N="${IE_TOP_N:-200}"
IMAGE="${IE_IMAGE:-postgres:16-alpine}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

fail() { printf '\n\033[31m✗ %s\033[0m\n' "$*" >&2; exit 1; }

case "$DRILL" in
    dod)         COMMAND="bash /drill/investment-dod.sh" ;;
    fingerprint) COMMAND="bash /drill/report-fingerprint.sh" ;;
    *) fail "the drill is 'dod' or 'fingerprint', not '$DRILL'" ;;
esac

JOB="estate-drill-$DRILL"
kubectl --context "$CTX" -n "$NS" delete job "$JOB" --ignore-not-found >/dev/null

# The scripts themselves, from THIS checkout — so a drill runs the code in front of you rather than
# whatever was baked into an image.
kubectl --context "$CTX" -n "$NS" create configmap estate-drill-scripts \
    --from-file="$HERE/investment-dod.sh" \
    --from-file="$HERE/report-fingerprint.sh" \
    --from-file=estate-token.sh="$HERE/lib/estate-token.sh" \
    --from-file=fingerprint.py="$HERE/lib/fingerprint.py" \
    --dry-run=client -o yaml | kubectl --context "$CTX" -n "$NS" apply -f - >/dev/null

# The model file the fingerprint lifts the reference query out of (the SYNCED one, which is what the
# estate serves) — mounted rather than fetched, so the comparison uses this checkout's model too.
kubectl --context "$CTX" -n "$NS" create configmap estate-drill-model \
    --from-file="$HERE/../model/investment/queries/q_investment.ttrm" \
    --dry-run=client -o yaml | kubectl --context "$CTX" -n "$NS" apply -f - >/dev/null

cat <<YAML | kubectl --context "$CTX" apply -f - >/dev/null
apiVersion: batch/v1
kind: Job
metadata: { name: $JOB, namespace: $NS }
spec:
  backoffLimit: 0
  ttlSecondsAfterFinished: 3600
  template:
    spec:
      restartPolicy: Never
      containers:
        - name: drill
          image: $IMAGE
          command: ["sh", "-c", "apk add -q --no-cache bash curl jq python3 && mkdir -p /drill/lib && cp /scripts/estate-token.sh /scripts/fingerprint.py /drill/lib/ && cp /scripts/*.sh /drill/ && $COMMAND"]
          env:
            - { name: IE_DOD_MODE, value: readonly }
            - { name: IE_DOD_PORTFOLIO, value: "$PORTFOLIO" }
            - { name: IE_DOD_TOP_N, value: "$TOP_N" }
            - { name: IE_DOD_BFF, value: "http://studio-bff.kantheon.svc.cluster.local:7330" }
            - { name: IE_DOD_DSN, value: "host=postgres-rw.data.svc.cluster.local port=5432 dbname=entry user=entry_readonly" }
            - { name: IE_DOD_OIDC_TOKEN_URL, value: "https://keycloak.hartland.collite.cz/realms/kantheon/protocol/openid-connect/token" }
            - { name: IE_DOD_OIDC_CLIENT_ID, value: estate-drill }
            - name: IE_DOD_OIDC_CLIENT_SECRET
              valueFrom: { secretKeyRef: { name: estate-drill-oidc, key: ESTATE_DRILL_CLIENT_SECRET } }
            - { name: IE_FP_PORTFOLIO, value: "$PORTFOLIO" }
            - { name: IE_FP_AS_OF, value: "$AS_OF" }
            - { name: IE_FP_BFF, value: "http://studio-bff.kantheon.svc.cluster.local:7330" }
            - { name: IE_FP_DSN, value: "host=postgres-rw.data.svc.cluster.local port=5432 dbname=entry user=entry_readonly" }
            - { name: IE_FP_MODEL, value: /model/q_investment.ttrm }
            - { name: IE_FP_OIDC_TOKEN_URL, value: "https://keycloak.hartland.collite.cz/realms/kantheon/protocol/openid-connect/token" }
            - { name: IE_FP_OIDC_CLIENT_ID, value: estate-drill }
            - name: IE_FP_OIDC_CLIENT_SECRET
              valueFrom: { secretKeyRef: { name: estate-drill-oidc, key: ESTATE_DRILL_CLIENT_SECRET } }
            # The book's read credential — psql takes the password from the environment, so the DSN
            # above carries no secret and neither does this file.
            - name: PGPASSWORD
              valueFrom: { secretKeyRef: { name: pg-entry-ro-cred, key: password } }
          volumeMounts:
            - { name: scripts, mountPath: /scripts }
            - { name: model, mountPath: /model }
      volumes:
        - { name: scripts, configMap: { name: estate-drill-scripts } }
        - { name: model, configMap: { name: estate-drill-model } }
YAML

printf 'running %s in %s/%s …\n' "$JOB" "$CTX" "$NS"
kubectl --context "$CTX" -n "$NS" wait --for=condition=complete "job/$JOB" --timeout=600s >/dev/null 2>&1 \
    || kubectl --context "$CTX" -n "$NS" wait --for=condition=failed "job/$JOB" --timeout=5s >/dev/null 2>&1 || true
kubectl --context "$CTX" -n "$NS" logs "job/$JOB" --tail=400 || true

state="$(kubectl --context "$CTX" -n "$NS" get job "$JOB" -o jsonpath='{.status.succeeded}' 2>/dev/null || true)"
if [ -z "${IE_KEEP:-}" ]; then
    kubectl --context "$CTX" -n "$NS" delete job "$JOB" --ignore-not-found >/dev/null
    kubectl --context "$CTX" -n "$NS" delete configmap estate-drill-scripts estate-drill-model --ignore-not-found >/dev/null
fi
[ "$state" = "1" ] || fail "$JOB did not succeed (its log is above)"
printf '\n\033[32m%s succeeded\033[0m\n' "$JOB"
