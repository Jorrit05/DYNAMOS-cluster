#!/bin/bash

GO_VERSION="go1.21.3.linux-amd64.tar.gz"

# Grab our libs
. "`dirname $0`/setup-lib.sh"


sudo apt update
sudo apt upgrade -y
sudo apt install -y protobuf-compiler protoc-gen-go
sudo usermod -aG docker $USER
echo "USER: ${USER}"
echo "home: ${HOME}"

# setup Linkerd CLI
export INSTALLROOT="/usr/local"
sudo curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sudo sh

# Install Go
curl -LO "https://go.dev/dl/${GO_VERSION}"  && sudo tar -C /usr/local/ -xzf ${GO_VERSION}
export PATH=/usr/local/go/bin:$(go env GOPATH)/bin:/usr/local/bin:$PATH

go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.28
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.2

echo "export PATH=/usr/local/go/bin:$(go env GOPATH)/bin:/usr/local/bin:\$PATH" | sudo tee /etc/profile.d/path_for_all.sh
echo 'export PATH=/usr/local/go/bin:$(go env GOPATH)/bin:/usr/local/bin:$PATH' | sudo tee -a /root/.bashrc
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

    $SUDO docker pull $REPO/${remote_image}:$TAG
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
#!/bin/bash

# Check if the line already exists to avoid duplicates
if ! grep -q "source <(kubectl completion bash)" ${HOME}/.bashrc; then
    echo 'if type kubectl &>/dev/null; then' >> ${HOME}/.bashrc
    echo '    source <(kubectl completion bash)' >> ${HOME}/.bashrc
    echo 'fi' >> ${HOME}/.bashrc
    echo "Added kubectl completion to ${HOME}/.bashrc"
else
    echo "kubectl completion already exists in ${HOME}/.bashrc"
fi

exit 0