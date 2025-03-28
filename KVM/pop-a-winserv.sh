#!/bin/bash - 
#===============================================================================
#
#          FILE: pop-a-winserv.sh
# 
#         USAGE: ./pop-a-winserv.sh 
# 
#   DESCRIPTION: Use this to pop a Microsoft Windows Lab.
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: beanbat 
#  ORGANIZATION: 
#       CREATED: 03/28/2025 14:54
#      REVISION:  ---
#===============================================================================


#!/bin/bash
#
# ===============================
# Constants & Defaults
# ===============================
RAM="8192"
VCPUS="4"
DISK_SIZE="60"
ISO_PATH="/var/lib/libvirt/boot/SERVER_EVAL_x64FRE_en-us.iso"
VIRTIO_ISO="/var/lib/libvirt/boot/virtio-win.iso"
VIRTIO_URL="https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso"
LIBVIRT_IMG_PATH="/var/lib/libvirt/images"

# ===============================
# Functions
# ===============================

check_requirements() {
    if [ -z "$1" ]; then
        echo "Usage: $0 <vm-name>"
        exit 1
    fi

    if [ ! -f "$ISO_PATH" ]; then
        echo "[✗] Windows Server ISO not found at: $ISO_PATH"
        exit 1
    fi
}

download_virtio_iso() {
    if [ ! -f "$VIRTIO_ISO" ]; then
        echo "[~] virtio-win.iso not found. Downloading..."
        wget -O "$VIRTIO_ISO" "$VIRTIO_URL"
        if [ $? -ne 0 ]; then
            echo "[✗] Failed to download virtio-win.iso"
            exit 1
        fi
        echo "[✓] virtio-win.iso downloaded successfully."
    else
        echo "[✓] virtio-win.iso found."
    fi
}

create_disk() {
    local vm_name="$1"
    local disk_path="${LIBVIRT_IMG_PATH}/${vm_name}.qcow2"

    echo "[+] Creating QCOW2 disk at ${disk_path}..."
    qemu-img create -f qcow2 "${disk_path}" "${DISK_SIZE}G"
}

launch_vm() {
    local vm_name="$1"
    local disk_path="${LIBVIRT_IMG_PATH}/${vm_name}.qcow2"

    echo "[+] Starting installation for VM: ${vm_name}..."
    virt-install \
        --name "${vm_name}" \
        --ram "${RAM}" \
        --vcpus "${VCPUS}" \
        --cpu host \
        --cdrom "${ISO_PATH}" \
        --disk path="${disk_path}",format=qcow2,bus=virtio \
        --disk path="${VIRTIO_ISO}",device=cdrom \
        --os-variant win2k22 \
        --network network=default,model=virtio \
        --graphics spice \
        --sound ich9 \
        --video qxl \
        --boot cdrom,hd \
        --features kvm_hidden=on \
        --noautoconsole

    echo "[✓] VM ${vm_name} has been launched."
}

# ===============================
# Main
# ===============================

main() {
    VM_NAME="$1"
    check_requirements "$VM_NAME"
    download_virtio_iso
    create_disk "$VM_NAME"
    launch_vm "$VM_NAME"

    echo "[~] Connecting to VM console for ${VM_NAME}..."
    sleep 2
    virt-viewer "${VM_NAME}" & disown
}

main "$@"
