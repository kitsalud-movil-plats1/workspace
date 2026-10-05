#cloud-config
# Equivale a una instalación limpia: usuario individual, SSH solo con llave, sin root.
hostname: ${HOSTNAME}
timezone: America/Bogota
users:
  - name: ${LAB_USUARIO}
    groups: [sudo]
    shell: /bin/bash
    sudo: "ALL=(ALL) NOPASSWD:ALL"
    lock_passwd: true
    ssh_authorized_keys:
      - ${LLAVE}
ssh_pwauth: false
disable_root: true
