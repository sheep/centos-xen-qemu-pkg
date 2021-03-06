Name:    qemu-xen
Summary: Device Model for Xen
Version: 4.15.0
Release: 1%{?dist}
License: GPLv2
URL:     https://www.xenproject.org/
Source0: qemu-xen-%{version}.tar.gz

Requires: xen-libs
BuildRequires: xen-devel

BuildRequires: zlib-devel bzip2-devel
BuildRequires: gtk3-devel
BuildRequires: SDL-devel
BuildRequires: ncurses-devel
BuildRequires: libaio-devel
BuildRequires: gnutls-devel
BuildRequires: curl-devel
BuildRequires: python3
# Spice
BuildRequires: spice-server-devel usbredir-devel
# Xen 9pfs
BuildRequires: libcap-ng-devel libattr-devel

ExclusiveArch: x86_64

%if 0%{?centos_ver} >= 8
# Disable debug package due to installing qemu-xen in an non /bin /lib location
%define debug_package %{nil}
%endif

%description
Device Model for the Xen hypervisor. This package provides QEMU that can be
used with Xen.

%prep
%setup -q -c -n qemu-xen

%build
%define qemu_xen_prefix %{_libdir}/xen
%define qemu_datadir %{_prefix}/share/qemu-xen

./configure \
        --enable-virtfs \
        --enable-spice \
        --enable-usb-redir \
        --disable-kvm \
        --disable-docs \
        --disable-guest-agent \
        --disable-fdt \
        --disable-vhost-user \
        --disable-vhost-kernel \
        --extra-cflags="$RPM_OPT_FLAGS" \
        --enable-trace-backend=log \
        --prefix=%{qemu_xen_prefix} \
        --libdir=%{qemu_xen_prefix}/lib \
        --bindir=%{qemu_xen_prefix}/bin \
        --includedir=%{qemu_xen_prefix}/include \
        --datadir=%{qemu_datadir} \
        --localstatedir=%{_localstatedir} \
        --cpu=x86_64 \
        --target-list=i386-softmmu

make %{?_smp_mflags}

%install
make %{?_smp_mflags} DESTDIR=%{buildroot} prefix=%{_prefix} install

%define qemudocdir %{_docdir}/%{pkgname}
mkdir -p licensedir
install -m 644 -t licensedir COPYING LICENSE

# qemu stuff (unused or available from upstream)
rm %{buildroot}%{_prefix}/libexec/qemu-bridge-helper
rm %{buildroot}%{_prefix}/libexec/qemu-pr-helper
rm %{buildroot}%{_prefix}/libexec/virtfs-proxy-helper
rm -r %{buildroot}%{qemu_datadir}/applications
rm -r %{buildroot}%{qemu_datadir}/icons

%files
%defattr(-,root,root)
%dir %{qemu_xen_prefix}
%dir %{qemu_xen_prefix}/bin
%attr(0700,root,root) %{qemu_xen_prefix}/bin/*
%dir %{_datadir}/qemu-xen
%{_datadir}/locale/*/LC_MESSAGES/qemu.mo
%{_datadir}/qemu-xen/qemu
%doc licensedir/*

%changelog
* Fri May 21 2021 Anthony PERARD <anthony.perard@citrix.com> - 4.15.0-1
- Xen 4.15 release

* Tue Feb 09 2021 Anthony PERARD <anthony.perard@citrix.com> - 4.14.1-1
- Xen 4.14 release

* Fri Jul 24 2020 Anthony PERARD <anthony.perard@citrix.com> - 4.13.1-1
- Xen 4.13 release

* Tue Aug 13 2019 Anthony PERARD <anthony.perard@citrix.com> - 4.12.1-1
- Xen 4.12.1 release

* Tue Apr 02 2019 Anthony PERARD <anthony.perard@citrix.com> - 4.12.0-1
- Xen 4.12 release

* Fri Feb 22 2019 Anthony PERARD <anthony.perard@citrix.com> - 4.12.0-0.2.rc1
- Re-add tools as they were present in the xen-runtime package.
- Add COPYING and LICENSE.

* Thu Feb 21 2019 Anthony PERARD <anthony.perard@citrix.com> - 4.12.0-0.1.rc1
- New packages, extracting QEMU from the main Xen package.

