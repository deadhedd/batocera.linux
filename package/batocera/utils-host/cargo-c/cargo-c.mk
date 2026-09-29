################################################################################
#
# cargo-c
#
################################################################################

CARGO_C_VERSION = v0.10.19
CARGO_C_SITE = $(call github,lu-zero,cargo-c,$(CARGO_C_VERSION))
CARGO_C_LICENSE = MIT License
CARGO_C_LICENSE_FILES = LICENSE

HOST_CARGO_C_DEPENDENCIES = host-pkgconf host-rustc host-openssl

# The pinned sources compile with Buildroot's Rust 1.95 despite newer declared MSRVs.
HOST_CARGO_C_CARGO_BUILD_OPTS += --ignore-rust-version
HOST_CARGO_C_CARGO_INSTALL_OPTS += --ignore-rust-version

$(eval $(host-cargo-package))
