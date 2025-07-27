FROM almalinux:10-minimal

ENV HOME="/root"

ENV YQ_VERSION="v4.46.1"
ENV THISARCH=amd64
RUN <<MKDIRSENVVARS
  mkdir -p ${HOME}/.config/direnv
  mkdir -p ${HOME}/.aws
  mkdir -p ${HOME}/.local/bin
  mkdir -p ${HOME}/.gnupg
  mkdir -p ${HOME}/.asdf
  echo "export PATH=${HOME}/.local/bin:${PATH}" >> ${HOME}/.bashrc
  echo "export DIRENV_LOG_FORMAT=shell" >> ${HOME}/.bashrc
  echo "export AWS_VAULT_BACKEND=file" >> ${HOME}/.bashrc
  echo "alias ll='ls -al'" >> ${HOME}/.bashrc
  echo "alias python=python3" >> ${HOME}/.bashrc
  echo "alias pip=pip3" >> ${HOME}/.bashrc
  echo 'export GPG_TTY=$(tty)' >> ${HOME}/.bashrc
  echo "export EDITOR=vim" >> ${HOME}/.bashrc
  
  microdnf -y install dnf
  dnf -y update dnf
  dnf -y --allowerasing install util-linux coreutils
  dnf -y update
MKDIRSENVVARS
RUN <<DNF1
  # dnf -y config-manager --set-enabled crb
  dnf -y install epel-release
  echo "-------------------------------------------"
  dnf -y --allowerasing install sudo tar bash-completion findutils grep gzip tar xz which curl git unzip procps-ng
  
DNF1
RUN <<DNF2
  dnf -y update
  mkdir -p /etc/sudoers.d/
  echo '%wheel ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/wheel
  dnf -y install dos2unix vim-minimal vim-enhanced gpg which wget jq
  wget https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${THISARCH} -O ${HOME}/.local/bin/yq && \
  chmod +x ${HOME}/.local/bin/yq
DNF2

RUN <<PIPXUV
  python3 -m ensurepip --upgrade
  # python3 -m ensurepip --upgrade && python3 -m pip install --user pipx
  # . ${HOME}/.bashrc
  # curl -LsSf https://astral.sh/uv/install.sh | sh -s -- 
  # echo 'eval "$(uv generate-shell-completion bash)"' >> ~/.bashrc
PIPXUV

RUN <<EOF
  curl -sfL https://direnv.net/install.sh | bash
  dnf -y install python3-devel gcc-c++ make
  gpg --version
  echo "eval \"\$(direnv hook bash)\"" >> ${HOME}/.bashrc
  # curl https://sh.rustup.rs -sSf | sh -s -- -y
  # . "${HOME}/.cargo/env"
  # cargo install petname
  # curl -sS https://starship.rs/install.sh | sh -s -- --yes
  # echo 'eval "$(starship init bash)"' >> ${HOME}/.bashrc
EOF
# RUN <<POETRY  
#   python3 -m ensurepip --upgrade && python3 -m pip install --user pipx
#   . ${HOME}/.bashrc
#   pipx install poetry
#   curl -LsSf https://astral.sh/uv/install.sh | sh -s -- -y
#   echo 'eval "$(uv generate-shell-completion bash)"' >> ~/.bashrc
# POETRY


COPY README.md ${HOME}/README.md
COPY direnv.toml ${HOME}/.config/direnv/direnv.toml
COPY awsconfig ${HOME}/.aws/config
COPY Dockerfile ${HOME}/Dockerfile.almabase
COPY AWS.pub ${HOME}/.gnupg/AWS.pub
COPY starship_config.toml ${HOME}/.config/starship.toml
COPY asdfrc ${HOME}/.asdfrc
COPY tool-versions.yaml ${HOME}/.tool-versions.yaml

RUN dos2unix \
  ${HOME}/README.md \
  ${HOME}/.config/direnv/direnv.toml \
  ${HOME}/.aws/config \
  ${HOME}/.bashrc \
  ${HOME}/.gnupg/AWS.pub \
  ${HOME}/Dockerfile.almabase \
  ${HOME}/.config/starship.toml \
  ${HOME}/.config/direnv/direnv.toml \
  ${HOME}/.asdfrc \
  ${HOME}/.config/direnv/direnv.toml \
  ${HOME}/.tool-versions.yaml

RUN <<GITFLOW
  . ${HOME}/.bashrc
  export PREFIX=${HOME}/.local
  wget -q  https://raw.githubusercontent.com/CJ-Systems/gitflow-cjs/develop/contrib/gitflow-installer.sh 
  sudo bash gitflow-installer.sh install stable
  sudo rm -f gitflow-installer.sh
GITFLOW

RUN <<ASDF
    . ${HOME}/.bashrc
    export ASDF_VERSION="v0.18.0"
    pushd ${HOME}/.local/bin
    wget -O - https://github.com/asdf-vm/asdf/releases/download/${ASDF_VERSION}/asdf-${ASDF_VERSION}-linux-${THISARCH}.tar.gz | tar -xzvf -
    popd
    echo "export PATH=\"${ASDF_DATA_DIR:-${HOME}/.asdf}/shims:$PATH\"" >> ${HOME}/.bashrc
    echo ". <(asdf completion bash)" >> ${HOME}/.bashrc
ASDF
RUN <<ASDFINSTALLS

    . ${HOME}/.bashrc
    ASDF_TOOLS_CONFIG=${HOME}/.tool-versions.yaml
    # Install plugins from ${ASDF_TOOLS_CONFIG} if it exists
    echo "Checking for ${ASDF_TOOLS_CONFIG}"
    if [ -f ${ASDF_TOOLS_CONFIG} ]; then
      echo "Installing plugins and tools from ${ASDF_TOOLS_CONFIG}"
      # Get all plugins and their URLs from the yaml file
      plugin_entries=$(yq '.plugins | to_entries | .[]' ${ASDF_TOOLS_CONFIG})
      
      # For each plugin entry, extract the name and URL
      for plugin in $(yq '.plugins | keys | .[]' ${ASDF_TOOLS_CONFIG}); do
        plugin_url=$(yq ".plugins.$plugin" ${ASDF_TOOLS_CONFIG})
        echo "Adding plugin $plugin from $plugin_url"
        
        # If URL is not empty, add plugin with URL
        if [ -n "$plugin_url" ] && [ "$plugin_url" != "null" ]; then
          asdf plugin add "$plugin" "$plugin_url" || true
        else
          # Otherwise add plugin without URL
          asdf plugin add "$plugin" || true
        fi
      done

      # Get all tools listed in the yaml file under the "tools" key
      for tool in $(yq '.tools | keys | .[]' ${ASDF_TOOLS_CONFIG} 2>/dev/null); do
      tool_version=$(yq ".tools.$tool" ${ASDF_TOOLS_CONFIG})
      
      # Install the tool with asdf if version is specified
      if [ -n "$tool_version" ] && [ "$tool_version" != "null" ]; then
        if [ "$tool_version" = "latest" ]; then
          echo "Fetching latest version of $tool"
          tool_version=$(asdf latest "$tool")
        fi
      else
        # Install latest version if no version specified
        tool_version=$(asdf latest "$tool")
      fi
      echo "Installing $tool version $tool_version"
      asdf install "$tool" "$tool_version" || true
      asdf set -u "$tool" "$tool_version" || true
      done
    fi

    # asdf plugin-add aws-vault https://github.com/karancode/asdf-aws-vault.git    
    # asdf install aws-vault
    # export AWS_VAULT_FILE_PASSPHRASE=somepassword needs to be set
ASDFINSTALLS

RUN <<SOMEOTHER
echo 'eval "$(uv generate-shell-completion bash)"' >> ~/.bashrc
echo 'eval "$(starship init bash)"' >> ${HOME}/.bashrc
. ${HOME}/.bashrc
uv tool install bdtemplater
uv tool install bump-my-version
SOMEOTHER

# pipx install --include-deps ansible==9.* to work with RHEL8

