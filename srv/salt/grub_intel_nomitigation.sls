/etc/default/grub:
  file.append:
    - text: |
        GRUB_CMDLINE_LINUX="$GRUB_CMDLINE_LINUX pti=off spectre_v2=off mds=off l1tf=off kvm-intel.vmentry_l1d_flush=never"

grub_update:
  cmd.wait:
  - name: grub2-mkconfig -o /boot/grub2/grub.cfg