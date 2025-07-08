FROM almalinux:10-minimal

ENV HOME="/root"

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
RUN <<DNF
  # dnf -y config-manager --set-enabled crb
  dnf -y install epel-release
  echo "-------------------------------------------"
  dnf -y --allowerasing install sudo tar bash-completion findutils grep gzip tar xz which curl git unzip procps-ng
DNF
RUN <<DNF  
  dnf -y update
  mkdir -p /etc/sudoers.d/
  echo '%wheel ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/wheel
  dnf -y install dos2unix vim-minimal vim-enhanced gpg which
DNF

RUN <<PIPXUV
  python3 -m ensurepip --upgrade && python3 -m pip install --user pipx
  . ${HOME}/.bashrc
  curl -LsSf https://astral.sh/uv/install.sh | sh -s -- 
  echo 'eval "$(uv generate-shell-completion bash)"' >> ~/.bashrc
PIPXUV

RUN <<EOF
  curl -sfL https://direnv.net/install.sh | bash
  dnf -y install python3-devel gcc-c++ make
  gpg --version
  echo "eval \"\$(direnv hook bash)\"" >> ${HOME}/.bashrc
  curl https://sh.rustup.rs -sSf | sh -s -- -y
  . "${HOME}/.cargo/env"
  cargo install petname
  curl -sS https://starship.rs/install.sh | sh -s -- --yes
  echo 'eval "$(starship init bash)"' >> ${HOME}/.bashrc
EOF
# RUN <<POETRY  
#   python3 -m ensurepip --upgrade && python3 -m pip install --user pipx
#   . ${HOME}/.bashrc
#   pipx install poetry
#   curl -LsSf https://astral.sh/uv/install.sh | sh -s -- -y
#   echo 'eval "$(uv generate-shell-completion bash)"' >> ~/.bashrc
# POETRY

COPY direnv.toml ${HOME}/.config/direnv/direnv.toml
COPY tool-versions ${HOME}/.tool-versions
COPY awsconfig ${HOME}/.aws/config
COPY Dockerfile ${HOME}/Dockerfile.almabase
COPY AWS.pub ${HOME}/.gnupg/AWS.pub
COPY starship_config.toml ${HOME}/.config/starship.toml

RUN dos2unix \
  ${HOME}/.aws/config \
  ${HOME}/.bashrc \
  ${HOME}/.tool-versions \
  ${HOME}/.gnupg/AWS.pub \
  ${HOME}/Dockerfile.almabase \
  ${HOME}/.config/starship.toml \
  ${HOME}/.config/direnv/direnv.toml

RUN <<ASDF
    git clone https://github.com/asdf-vm/asdf.git ${HOME}/.asdf --branch v0.14.0
    echo ". $HOME/.asdf/asdf.sh" >> ${HOME}/.bashrc
    echo ". $HOME/.asdf/completions/asdf.bash" >> ${HOME}/.bashrc
    . ${HOME}/.asdf/asdf.sh
    asdf plugin add awscli
    asdf install awscli latest
    asdf local awscli latest
    asdf plugin-add packer https://github.com/asdf-community/asdf-hashicorp.git
    asdf install packer latest
    asdf local packer latest

    asdf plugin add opentofu
    asdf install opentofu latest
    asdf local opentofu latest
    
    # asdf plugin-add aws-vault https://github.com/karancode/asdf-aws-vault.git    
    # asdf install aws-vault
    # export AWS_VAULT_FILE_PASSPHRASE=somepassword needs to be set
ASDF

COPY README.md ${HOME}/README.md

# pipx install --include-deps ansible==9.* to work with RHEL8