# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit cmake-utils git-r3 systemd user

DESCRIPTION="An optimized HTTP server with support for HTTP/1.x and HTTP/2"
HOMEPAGE="https://h2o.examp1e.net"
EGIT_REPO_URI=( {https,git}://github.com/h2o/h2o.git )

LICENSE="MIT"
SLOT="0"
KEYWORDS=""
IUSE="libressl +mruby"

RDEPEND="
	!libressl? ( dev-libs/openssl:0= )
	libressl? ( dev-libs/libressl:0= )"
DEPEND="${RDEPEND}
	mruby? (
		sys-devel/bison
		|| (
			dev-lang/ruby:2.4
			dev-lang/ruby:2.3
			dev-lang/ruby:2.2
			dev-lang/ruby:2.1
		)
	)"

pkg_setup() {
	enewgroup h2o
	enewuser h2o -1 -1 -1 h2o
}

src_prepare() {
	# Leave optimization level to user CFLAGS
	sed -i 's/-O2 -g ${CC_WARNING_FLAGS} //g' ./CMakeLists.txt \
		|| die "sed fix failed!"

	default
}

src_configure() {
	local mycmakeargs=(
		-DCMAKE_INSTALL_SYSCONFDIR="${EPREFIX}"/etc/h2o
		-DWITH_MRUBY="$(usex mruby)"
		-DWITHOUT_LIBS=ON
	)
	cmake-utils_src_configure
}

src_install() {
	cmake-utils_src_install

	newinitd "${FILESDIR}"/h2o.initd h2o
	systemd_dounit "${FILESDIR}"/h2o.service

	insinto /etc/h2o
	doins "${FILESDIR}"/h2o.conf

	keepdir /var/log/h2o
	fperms 0700 /var/log/h2o

	keepdir /var/www/localhost/htdocs

	insinto /etc/logrotate.d
	newins "${FILESDIR}"/h2o.logrotate h2o
}
