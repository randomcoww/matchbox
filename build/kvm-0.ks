%include http://127.0.0.1:8080/generic?ks=live-base
%include http://127.0.0.1:8080/generic?ks=kvm-0

%post --erroronfail

## Add firmware for worker HBA passthrough
mkdir -p /var/lib/libvirt/boot

pushd /var/lib/libvirt/boot
curl -LO http://127.0.0.1:8080/assets/firmware/SAS9300_8i_IT.bin
popd

%end