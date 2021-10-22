# fepitre-copr-qemu:
#   cmd.wait:
#     - name: dnf copr enable -y fepitre/qemu

update_pkg:
  pkg.uptodate:
    # - require:
    #     - cmd: fepitre-copr-qemu
    - refresh : True
