# Maintainer: Your Name <youremail@domain.com>
pkgname=artix-install
pkgver=2.3.0
pkgrel=1
epoch=
pkgdesc="Artix Installer"
arch=(x86_64)
url="https://github.com/krzyczak/artix-install.git"
license=("GPL")
groups=()
depends=(gum)
makedepends=(git)
checkdepends=()
optdepends=()
provides=(artix-install)
source=("git+$url#tag=$pkgver")
options=("!debug" "strip")
sha256sums=("SKIP")
validpgpkeys=()

# prepare() {
# 	cd "$pkgname-$pkgver"
# 	patch -p1 -i "$srcdir/$pkgname-$pkgver.patch"
# }

# build() {
# 	cd "$pkgname-$pkgver"
# 	./configure --prefix=/usr
# 	make
# }

# check() {
# 	cd "$pkgname-$pkgver"
# 	make -k check
# }

package() {
  install -dm755 "$pkgdir/opt/artix-install"
  cp -r "$srcdir/$pkgname/artix-install.sh" "$srcdir/$pkgname/modules" "$pkgdir/opt/artix-install/"

  install -dm755 "$pkgdir/usr/local/bin"
  ln -s /opt/artix-install/artix-install.sh "$pkgdir/usr/local/bin/artix-install"
}
