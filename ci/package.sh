#!/bin/bash

set -euo pipefail

cd /src

. ./ci/install-build-deps.sh


mkdir -p packages


case "$OS" in
    'centos:7')
        case "$ARCH" in
            'arm32v7'|'aarch64')
                echo 'Cross-compilation on CentOS 7 is not supported' >&2
                exit 1
                ;;
        esac

        yum -y install rpm-build

        rm -rf ~/rpmbuild

        make ARCH="$ARCH" PACKAGE_VERSION="$PACKAGE_VERSION" PACKAGE_RELEASE="$PACKAGE_RELEASE" V=1 rpm

        rm -rf "packages/centos7/$ARCH"
        mkdir -p "packages/centos7/$ARCH"
        cp \
            ~/"rpmbuild/RPMS/x86_64/aziot-identity-service-$PACKAGE_VERSION-$PACKAGE_RELEASE.x86_64.rpm" \
            ~/"rpmbuild/RPMS/x86_64/aziot-identity-service-devel-$PACKAGE_VERSION-$PACKAGE_RELEASE.x86_64.rpm" \
            ~/"rpmbuild/SRPMS/aziot-identity-service-$PACKAGE_VERSION-$PACKAGE_RELEASE.src.rpm" \
            "packages/centos7/$ARCH/"
        ;;

    'mariner')
        case "$ARCH" in
            'arm32v7'|'aarch64')
                echo 'Cross-compilation not implemnted for mariner' >&2
                exit 1
                ;;
        esac

        git clone https://github.com/microsoft/CBL-Mariner.git
        pushd CBL-Mariner
        git checkout "1.0-dev"
        pushd toolkit
        sudo make package-toolkit REBUILD_TOOLS=y
        popd
        sudo mv out/toolkit-*.tar.gz "~/CBL-Mariner/toolkit.tar.gz"
        popd

        make ARCH="$ARCH" PACKAGE_VERSION="$PACKAGE_VERSION" PACKAGE_RELEASE="$PACKAGE_RELEASE" V=1 mrpm

        rm -rf "packages/mariner/$ARCH"
        mkdir -p "packages/mariner/$ARCH"
        cp \
            ~/"CBL-Mariner/out/RPMS/x86_64/aziot-identity-service-$PACKAGE_VERSION-$PACKAGE_RELEASE.x86_64.rpm" \
            ~/"CBL-Mariner/out/RPMS/x86_64/aziot-identity-service-devel-$PACKAGE_VERSION-$PACKAGE_RELEASE.x86_64.rpm" \
            ~/"CBL-Mariner/out/SRPMS/aziot-identity-service-$PACKAGE_VERSION-$PACKAGE_RELEASE.src.rpm" \
            "packages/mariner/$ARCH/"
        ;;

    'debian:9'|'debian:10'|'ubuntu:18.04'|'ubuntu:20.04')
        DEBIAN_FRONTEND=noninteractive TZ=UTC apt-get install -y dh-make dh-systemd

        make ARCH="$ARCH" PACKAGE_VERSION="$PACKAGE_VERSION" PACKAGE_RELEASE="$PACKAGE_RELEASE" V=1 deb

        case "$OS" in
            'debian:9')
                TARGET_DIR="debian9/$ARCH"
                DBGSYM_EXT='deb'
                ;;

            'debian:10')
                TARGET_DIR="debian10/$ARCH"
                DBGSYM_EXT='deb'
                ;;

            'ubuntu:18.04')
                TARGET_DIR="ubuntu1804/$ARCH"
                DBGSYM_EXT='ddeb'
                ;;

            'ubuntu:20.04')
                TARGET_DIR="ubuntu2004/$ARCH"
                DBGSYM_EXT='ddeb'
                ;;

            *)
                echo 'unreachable' >&2
                exit 1
                ;;
        esac

        case "$ARCH" in
            'amd64')
                BIN_PACKAGE_SUFFIX=amd64
                ;;

            'arm32v7')
                BIN_PACKAGE_SUFFIX=armhf
                ;;

            'aarch64')
                BIN_PACKAGE_SUFFIX=arm64
                ;;
        esac

        rm -rf "packages/$TARGET_DIR"
        mkdir -p "packages/$TARGET_DIR"
        cp \
            "/tmp/aziot-identity-service_$PACKAGE_VERSION-${PACKAGE_RELEASE}_$BIN_PACKAGE_SUFFIX.deb" \
            "/tmp/aziot-identity-service-dbgsym_$PACKAGE_VERSION-${PACKAGE_RELEASE}_$BIN_PACKAGE_SUFFIX.$DBGSYM_EXT" \
            "/tmp/aziot-identity-service_$PACKAGE_VERSION.orig.tar.gz" \
            "/tmp/aziot-identity-service_$PACKAGE_VERSION-$PACKAGE_RELEASE.debian.tar.xz" \
            "/tmp/aziot-identity-service_$PACKAGE_VERSION-$PACKAGE_RELEASE.dsc" \
            "packages/$TARGET_DIR/"
        ;;

    *)
        echo "Unsupported OS:ARCH $OS:$ARCH" >&2
        exit 1
        ;;
esac
