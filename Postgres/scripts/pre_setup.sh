#!/bin/bash
#!/bin/bash

USER='vagrant'
GROUP='vagrant'
POSTGRES_GIT='git://git.postgresql.org/git/postgresql.git'
HOME_DIR="/home/${USER?}"
SOURCE_DIR="${HOME_DIR?}/postgres"
BUILD_DIR="${HOME_DIR?}/build"
BIN_PATH="PATH=${PATH}:/home/${USER?}/pg/bin"
BASHRC="${HOME_DIR?}/.bashrc"

# Install Dependencies/Tools
echo "Installing Tools.."
yum -y install vim git

echo "Installing PostgreSQL Dependencies.."
yum -y install zlib-devel readline-devel \
    gzip flex bison openssl-devel \
    perl-Test-Harness gcc

# Clone Postgres
echo "Clone Postgres.."
git clone ${POSTGRES_GIT?} ${SOURCE_DIR?}
chown -R ${USER?}:${GROUP?} ${SOURCE_DIR?}

# Create Build Directory
echo "Create Build Directory.."
mkdir ${BUILD_DIR?}
chown ${USER?}:${GROUP?} ${BUILD_DIR?}
cd ${BUILD_DIR?}

# Configure Postgres
echo "Configure Postgres.."
${SOURCE_DIR?}/configure \
    --prefix="/home/${USER?}/pg" \
    --enable-cassert \
    --enable-tap-tests \
    --with-openssl

cd ${SOURCE_DIR?}

# Apply Patch
echo "Applying Patch.."
git apply ${HOME_DIR?}/*.patch

# Install
echo "Make Install Postgres.."
cd ${BUILD_DIR?}
make -s install

# Add Postgres Binaries To BASHRC
echo "Add Bin Path To Bashrc.."

grep -Fxq "${BIN_PATH?}" ${BASHRC?}
if [[ $? == 1 ]]
then
    printf "${BIN_PATH?}" >> ${BASHRC?}
fi

exit 0
