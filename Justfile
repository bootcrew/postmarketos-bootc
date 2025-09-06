image_name := env("BUILD_IMAGE_NAME", "pmos-bootc")
image_tag := env("BUILD_IMAGE_TAG", "latest")
base_dir := env("BUILD_BASE_DIR", ".")
filesystem := env("BUILD_FILESYSTEM", "ext4")
pm_exports := env("PM_EXPORTS", "./pm-exports")

build-base-pmos:
    sudo podman build -t pmos -f pmos.dockerfile .
    
build-containerfile $image_name=image_name:
    cp {{pm_exports}}/vmlinuz-stable ./ && \
    cp {{pm_exports}}/initramfs ./ && \
    sudo podman build -t "${image_name}:latest" .

bootc *ARGS:
    sudo podman run \
        --rm --privileged --pid=host \
        -it \
        -v /sys/fs/selinux:/sys/fs/selinux \
        -v /etc/containers:/etc/containers:Z \
        -v /var/lib/containers:/var/lib/containers \
        -v /dev:/dev \
        -v "{{base_dir}}:/data" \
        --security-opt label=type:unconfined_t \
        "{{image_name}}:latest" bootc {{ARGS}}

generate-bootable-image $base_dir=base_dir $filesystem=filesystem:
    #!/usr/bin/env bash
    if [ ! -e "${base_dir}/bootable.img" ] ; then
        fallocate -l 20G "${base_dir}/bootable.img"
    fi
    just bootc install to-disk --composefs-native --via-loopback /data/bootable.img --filesystem "${filesystem}" --wipe
