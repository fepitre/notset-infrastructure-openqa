openqa:
  users:
    user1:
      password: hashed_password
      sshkey: ssh-rsa ...
    user2:
      password: hashed_password
      sshkey: ssh-rsa ...
  hosts:
    openqa.notset.fr:
# Here 'ip' is for specifying /etc/host
# entry for openqa.notset.fr
      ip: 10.0.0.1
      key: azerty123456
      secret: azerty123456
    openqa.qubes-os.org:
      key: qsdfgh78910
      secret: qsdfgh78910
  workers:
    myrtille:
      hostname: myrtille.notset.fr
      users:
        - user1
        - user2
      pool: 4
      hosts:
        - openqa.notset.fr
        - openqa.qubes-os.org
    mure:
      hostname: mure.notset.fr
      users:
        - user1
      pool: 4
      hosts:
        - openqa.notset.fr