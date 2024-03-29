{% set worker = grains['id'] %}

{% set hostname =  salt['pillar.get']('openqa:workers:' + worker + ':hostname', {}) %}
{% set users = salt['pillar.get']('openqa:workers:' + worker + ':users', {}) %}
{% set pool = salt['pillar.get']('openqa:workers:' + worker + ':pool', 0) %}
{% set hosts = salt['pillar.get']('openqa:workers:' + worker + ':hosts', {}) %}

openqa-worker:
  pkg.installed:
    - refresh: True
    - pkgs:
        - openQA-worker
      # - openqa-worker

workers-global:
  file.managed:
    - name: /etc/openqa/workers.ini
    - require:
      - pkg: openqa-worker
    - contents: |
        [global]
        HOST = {% for host in hosts %}https://{{host}} {% endfor %}
        CACHEDIRECTORY = /var/lib/openqa/cache
        CACHELIMIT = 100
        CACHEWORKERS = 5
        UPLOAD_CHUNK_SIZE = 10000000
        WORKER_HOSTNAME = {{hostname}}

{% for host in hosts %}
{% set ip = salt['pillar.get']('openqa:hosts:' + host + ':ip', '') %}
{% set key = salt['pillar.get']('openqa:hosts:' + host + ':key', '') %}
{% set secret = salt['pillar.get']('openqa:hosts:' + host + ':secret', '') %}

{% if ip %}
{{host}}:
  host.present:
    - ip: {{ip}}
{% endif %}

workers-{{host}}:
  file.append:
    - name: /etc/openqa/workers.ini
    - require:
      - file: workers-global
    - text: |
        [https://{{host}}]
        TESTPOOLSERVER = rsync://{{host}}/openqa-tests

client-{{host}}:
  file.append:
    - name: /etc/openqa/client.conf
    - require:
      - pkg: openqa-worker
    - text: |
        [{{host}}]
        key = {{key}}
        secret = {{secret}}
{% endfor %}

/var/lib/openqa/share/factory:
  file.directory:
    - user: _openqa-worker
    - group: root
    - mode: 755
    - makedirs: True

/var/lib/openqa/share/tests:
  file.directory:
    - user: _openqa-worker
    - group: root
    - mode: 755
    - makedirs: True

openqa-worker-cacheservice:
  service.running:
    - enable: True

openqa-worker-cacheservice-minion:
  service.running:
    - enable: True
    - require:
      - service: openqa-worker-cacheservice

# # Compatibility with openSuse OpenQA appliance
# /usr/share/qemu/ovmf-x86_64-code.bin:
#   file.symlink:
#     - target: /usr/share/OVMF/OVMF_CODE.fd

# /usr/share/qemu/ovmf-x86_64-vars.bin:
#   file.symlink:
#     - target: /usr/share/OVMF/OVMF_VARS.fd

# # Use provided OVMF for MAC in tests repository
# /var/lib/openqa/share/tests/qubesos/utils/:
#   file.directory:
#     - user: _openqa-worker
#     - group: root
#     - mode: 755
#     - makedirs: True

# Use at least one OpenQA instance as source for the OVMF MAC files
/var/lib/openqa/share/tests/qubesos/utils/OVMF-mac_CODE.fd:
  file.symlink:
    - target: /var/lib/openqa/cache/openqa.qubes-os.org/tests/qubesos/utils/OVMF-mac_CODE.fd

/var/lib/openqa/share/tests/qubesos/utils/OVMF-mac_VARS.fd:
  file.symlink:
    - target: /var/lib/openqa/cache/openqa.qubes-os.org/tests/qubesos/utils/OVMF-mac_VARS.fd

firewalld:
  service.running:
    - enable: True

{% for n in range(1, pool + 1) %}
firewalld-{{n}}:
  cmd.run:
    - name: firewall-cmd --permanent --add-port=200{{n}}3/tcp

openqa-worker@{{n}}:
  service.running:
    - enable: True
{% endfor %}

{% for user in users %}
# {% set password = salt['pillar.get']('openqa:users:' + user + ':password', {}) %}
{% set sshkey = salt['pillar.get']('openqa:users:' + user + ':sshkey', {}) %}
{{user}}:
  user.present:
    - shell: /bin/bash
    - home: /home/{{user}}
    # - password: {{password}}
    - groups:
      - wheel

sshkey-{{user}}:
  ssh_auth.present:
    - user: {{user}}
    - enc: ssh-rsa
    - names:
      - {{sshkey}}
{% endfor %}
