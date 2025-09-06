# PostmarketOS Bootc

Experiment to see if Bootc could work on PostmarketOS.


## Building

This requires an already setup postmarketos environment.

Firstly, we need to generate a postmarketos image.

1. Download and install `pmbootstrap` with [these instructions](https://wiki.postmarketos.org/wiki/Pmbootstrap/Installation).
2. Run `pmbootstrap init` and use all the defaults, except when it asks about `systemd` set it to `always`. I recommend either `phosh` or `gnome-mobile` for the DE when asked.
3. Run `pmboostrap install`
4. Go to a repo directory, create a `pm-exports` folder, cd into it, and run `pmbootstrap export . `
   1. You should now have a folder filled with symlinks, but only `initramfs`, `qemu-amd64.img`, and `vmlinuz-stable` are valid.
5. Move up to the parent directory and run the following to create the docker image.
   1. `guestfish --ro -a ./pm-exports/qemu-amd64.img -m /dev/sda2:/ tar-out / - | sudo podman import - postmarketos`

In order to get a running pmos-bootc system you can run the following steps:
```shell
just build-containerfile # This will build the containerfile and all the dependencies you need
just generate-bootable-image # Generates a bootable image for you using bootc!
```

Then you can run the `bootable.img` as your boot disk in your preferred hypervisor.

# Fixes

- `mount /dev/vda2 /sysroot/boot` - You need this to get `bootc status` and other stuff working (`/dev/vda2` is your ESP)
