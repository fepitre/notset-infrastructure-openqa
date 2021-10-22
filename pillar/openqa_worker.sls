openqa:
  users:
    user1:
      # password: hashed_password
      sshkey: ssh-rsa AAAA...
    user2:
      # password: hashed_password
      sshkey: ssh-rsa AAAA...
  hosts:
    openqa.qubes-os.org:
      key: ABCDEF
      secret: GHIJKL
  workers:
    myrtille:
      hostname: myrtille.notset.fr
      users:
        - user1
        - user2
      pool: 4
      hosts:
        - openqa.qubes-os.org
    groseille:
      hostname: groseille.notset.fr
      users:
        - user1
        - user2
      pool: 8
      hosts:
        - openqa.qubes-os.org
