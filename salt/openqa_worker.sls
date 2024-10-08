{% set worker = grains['id'] %}

{% set hostname =  salt['pillar.get']('openqa:worker:hostname', {}) %}
{% set users = salt['pillar.get']('openqa:worker:users', {}) %}
{% set pool_end = salt['pillar.get']('openqa:worker:pool-end', 1) %}
{% set pool_start = salt['pillar.get']('openqa:worker:pool-start', 1) %}
{% set hosts = salt['pillar.get']('openqa:worker:hosts', {}) %}

openqa-worker:
  pkg.installed:
    - refresh: True
    - pkgs:
{%- if grains['os'] == 'SUSE' %}
        - openQA-worker
{%- else %}
        - openqa-worker
{%- endif %}

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
        WORKER_CLASS = hdd_download,qemu_x86_64{{ ",smep" if "smep" in grains['cpu_flags'] else "" }}

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

{% if grains['os'] == 'Fedora' %}
# Compatibility with openSuse OpenQA appliance
/usr/share/qemu/ovmf-x86_64-code.bin:
  file.symlink:
    - target: /usr/share/OVMF/OVMF_CODE.fd

/usr/share/qemu/ovmf-x86_64-vars.bin:
  file.symlink:
    - target: /usr/share/OVMF/OVMF_VARS.fd
{% endif %}

# Use provided OVMF for MAC in tests repository
/var/lib/openqa/share/tests/qubesos:
  file.directory:
    - user: _openqa-worker
    - group: root
    - mode: 755
    - makedirs: True

# Use at least one OpenQA instance as source for the OVMF MAC files
/var/lib/openqa/share/tests/qubesos/utils:
  file.symlink:
    - target: /var/lib/openqa/cache/openqa.qubes-os.org/tests/qubesos/utils

firewalld:
  service.running:
    - enable: True

{% for n in range(pool_start, pool_end ) %}
firewalld-{{n}}:
  cmd.run:
    - name: firewall-cmd --permanent --add-port={{ 20003 + n * 10}}/tcp

openqa-worker@{{n}}:
  service.running:
    - enable: True
{% endfor %}

{% if pool_start > 1 %}
openqa-worker@1:
  service.masked: []
{% endif %}

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
