# Boot

## Boot Files

The image uses the boot files in `profiles/`:

- `profiles/config.txt` becomes `/boot/config.txt`
- `profiles/cmdline.txt` becomes `/boot/cmdline.txt`

`profiles/config.txt` contains separate `[cm4]` and `[cm5]` sections. Raspberry Pi firmware selects the matching section at boot.

## Kernels

The CM4 section boots:

```ini
kernel=vmlinuz-linux-uconsole-cm4-git
initramfs initramfs-linux-uconsole-cm4-git.img followkernel
```

The CM5 section boots:

```ini
kernel=vmlinuz-linux-uconsole-cm5-git
initramfs initramfs-linux-uconsole-cm5-git.img followkernel
```

`linux-uconsole-cm5-4k-git` intentionally installs into the same CM5 boot slot as `linux-uconsole-cm5-git`, so switching between the CM5 16K and 4K kernels does not require editing `config.txt`.

## Root Filesystem Label

`profiles/cmdline.txt` boots the root filesystem by label:

```text
root=LABEL=alarm-root rw rootwait console=tty1 loglevel=3 fsck.repair=yes
```

The root filesystem partition must therefore be labeled `alarm-root`.

When creating a new ext4 filesystem:

```bash
mkfs.ext4 -L alarm-root /dev/ROOT_PARTITION
```

When relabeling an existing ext4 filesystem:

```bash
e2label /dev/ROOT_PARTITION alarm-root
```
