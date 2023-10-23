#!/bin/sh

GO_VERSION="go1.21.3.linux-amd64.tar.gz"

sudo apt update
sudo apt upgrade -y
sudo apt install -y protobuf-compiler protoc-gen-go

mkdir -p local-bin/

# setup Linkerd CLI
export INSTALLROOT="${PWD}/local-bin"
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh

export PATH=${PWD}/local-bin/:${PWD}/local-bin/bin:/usr/local/go/bin:$(go env GOPATH)/bin:$PATH

# Install Go
curl -LO "https://go.dev/dl/${GO_VERSION}"  && sudo tar -C /usr/local/ -xzf ${GO_VERSION}
export PATH=${PWD}/local-bin/:${PWD}/local-bin/bin:/usr/local/go/bin:$(go env GOPATH)/bin:$PATH

go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.28
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.2

export PATH=${PWD}/local-bin/:${PWD}/local-bin/bin:/usr/local/go/bin:$(go env GOPATH)/bin:$PATH
echo "export PATH=${PWD}/local-bin/:${PWD}/local-bin/bin:/usr/local/go/bin:$(go env GOPATH)/bin:\$PATH" | sudo tee /etc/profile.d/path_for_all.sh
echo 'export PATH=/local/repository/local-bin/:/local/repository/local-bin/bin:/usr/local/go/bin:$(go env GOPATH)/bin:$PATH' | sudo tee -a /root/.bashrc
echo 'alias k="kubectl"' | sudo tee /etc/profile.d/aliases_for_all.sh

echo "ECHO buildDynamos"
echo $BUILDDYNAMOS

# To be refactored and made dynamic
REPO=jorrit05
TAG="0.1"
IMAGES=("policy_enforcer" "agent" "anonymize" "orchestrator" "sidecar" "query")

for image in "${IMAGES[@]}"; do
    # If the local image name is different from the remote one, use a mapping
    # Otherwise, assume they are the same

    remote_image=$(echo "dynamos-$image" | sed 's/_/-/g')

    docker pull $REPO/${remote_image}:$TAG
done

# (
# cd DYNAMOS/go
# make all
# echo $?
# echo "Finished making Go"
# )


# (
# cd DYNAMOS/python
# make all
# echo $?
# echo "Finished making Python"
# )

exit 0