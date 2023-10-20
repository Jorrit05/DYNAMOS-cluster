#!/bin/sh

linkerd install --crds | kubectl apply -f -
linkerd install --set proxyInit.runAsRoot=true | kubectl apply -f -
linkerd check

linkerd jaeger install | kubectl apply -f -
# Possibly: linkerd viz install | kubectl apply -f -

echo "Finished setting up Linkerd"
exit 0
