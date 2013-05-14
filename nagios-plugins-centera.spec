Name:		nagios-plugins-centera
Version:	0.1
Release:	1%{?dist}
Summary:	Centera monitoring plugin for Nagios/Icinga

Group:		Applications/System
License:	GPLv2+
URL:		https://github.com/ovido/check_centera
Source0:	check_centera-%{version}.tar.gz
BuildRoot:	%{_tmppath}/check_centera-%{version}-%{release}-root

%description
This plugin for Icinga/Nagios is used to monitor EMC Centera
storage systems.

%prep
%setup -q -n check_centera-%{version}

%build
%configure --prefix=%{_libdir}/nagios/plugins \
	   --with-nagios-user=nagios \
	   --with-nagios-group=nagios \
	   --with-pnp-dir=%{_datadir}/nagios/html/pnp4nagios

make all


%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT INSTALL_OPTS=""
# cleanup directory
rm -rf $RPM_BUILD_ROOT/%{_docdir}/check_centera-%{version}

%clean
rm -rf $RPM_BUILD_ROOT


%files
%defattr(0755,nagios,nagios)
%{_libdir}/nagios/plugins/check_centera
%{_datadir}/nagios/html/pnp4nagios/templates/check_centera.php
%doc README INSTALL NEWS ChangeLog COPYING
%doc example-scripts/centera_*


%changelog
* Tue May 14 2013 Rene Koch <r.koch@ovido.at> 0.1-1
- Initial build.
