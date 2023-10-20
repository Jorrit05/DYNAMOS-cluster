#!/bin/sh

GO_VERSION="go1.21.3.linux-amd64.tar.gz"

sudo apt update
sudo apt upgrade -y
sudo apt install -y protobuf-compiler protoc-gen-go

mkdir -p local-bin/

# setup Linkerd
export INSTALLROOT="${PWD}/local-bin"
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh

export PATH=${PWD}/local-bin/:${PWD}/local-bin/bin:${PWD}/local-bin/go/bin:$PATH
echo "export PATH=${PWD}/local-bin/:${PWD}/local-bin/bin:${PWD}/local-bin/go/bin:\$PATH" | sudo tee /etc/profile.d/path_for_all.sh
echo 'alias k="kubectl"' | sudo tee /etc/profile.d/aliases_for_all.sh
echo 'export PATH=/local/repository/local-bin/:/local/repository/local-bin/bin:/local/repository/local-bin/go/bin:$PATH' | sudo tee -a /root/.bashrc

# Install Go
curl -LO "https://go.dev/dl/${GO_VERSION}"  && sudo tar -C local-bin/ -xzf ${GO_VERSION}
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

(
cd DYNAMOS/go
make all
echo $?
echo "Finished making Go"
)


(
cd DYNAMOS/python
make all
echo $?
echo "Finished making Python"
)

exit 0