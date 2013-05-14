# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# compiler settings
prefix=@doc_dir@
INSTALL=@INSTALL@
INSTALL_OPTS=@INSTALL_OPTS@
PKG_NAME=@PKG_NAME@
PKG_VERSION=@PKG_VERSION@

# compile
all:

# install
install:
	$(INSTALL) -m 755 $(INSTALL_OPTS) -d $(DESTDIR)$(prefix)/$(PKG_NAME)-$(PKG_VERSION)
	$(INSTALL) -m 644 $(INSTALL_OPTS) -t $(DESTDIR)$(prefix)/$(PKG_NAME)-$(PKG_VERSION) centera_*
