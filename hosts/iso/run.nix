{ iso, pkgs }:

pkgs.writeShellApplication {
  name = "iso-test";
  runtimeInputs = with pkgs; [
    qemu_kvm
    qemu-utils
  ];
  text = ''
    disk=disk.qcow
    if [ ! -f $disk ]; then
        qemu-img create -f qcow2 $disk 8G
    fi
    set -- "${iso}/iso/${iso.name}"
    exec qemu-kvm \
      --nographic \
      -m 2G \
      -smp 2 \
      -boot c \
      -cpu host \
      -boot d -cdrom "$1" \
      -netdev user,id=net0,net=192.168.0.0/24,dhcpstart=192.168.0.9 \
      -device virtio-net-pci,netdev=net0
  '';
}
