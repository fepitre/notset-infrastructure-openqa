/etc/default/grub:
  file.append:
    - text: |
        GRUB_CMDLINE_LINUX="$GRUB_CMDLINE_LINUX mitigations=off"

grub_update:
  cmd.wait:
  - name: grub2-mkconfig -o /boot/grub2/grub.cfg
