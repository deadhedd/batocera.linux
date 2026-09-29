################################################################################
#
# soh
#
################################################################################

SOH_VERSION = cb71e22a79bc5d1f688fa881795bbd93094895fc
SOH_PROJECT_VERSION = 9.2.3
SOH_SITE = https://github.com/HarbourMasters/Shipwright.git
SOH_SITE_METHOD = git
SOH_GIT_SUBMODULES = YES
SOH_SUPPORTS_IN_SOURCE_BUILD = NO
SOH_EMULATOR_INFO = soh.emulator.yml

SOH_IMGUI_ARCHIVE = v1.91.9b-docking.tar.gz
SOH_STORMLIB_ARCHIVE = v9.25.tar.gz
SOH_LIBGFXD_ARCHIVE = 008f73dca8ebc9151b205959b17773a19c5bd0da.tar.gz
SOH_THREADPOOL_ARCHIVE = v4.1.0.tar.gz
SOH_PRISM_ARCHIVE = bbcbc7e3f890a5806b579361e7aa0336acd547e7.tar.gz
SOH_DR_LIBS_ARCHIVE = da35f9d6c7374a95353fd1df1d394d44ab66cf01.tar.gz

SOH_EXTRA_DOWNLOADS = \
	https://github.com/ocornut/imgui/archive/refs/tags/$(SOH_IMGUI_ARCHIVE) \
	https://github.com/ladislav-zezula/StormLib/archive/refs/tags/$(SOH_STORMLIB_ARCHIVE) \
	https://github.com/glankk/libgfxd/archive/$(SOH_LIBGFXD_ARCHIVE) \
	https://github.com/bshoshany/thread-pool/archive/refs/tags/$(SOH_THREADPOOL_ARCHIVE) \
	https://github.com/KiritoDv/prism-processor/archive/$(SOH_PRISM_ARCHIVE) \
	https://github.com/mackron/dr_libs/archive/$(SOH_DR_LIBS_ARCHIVE) \
	https://raw.githubusercontent.com/nothings/stb/0bc88af4de5fb022db643c2d8e549a0927749354/stb_image.h \
	https://raw.githubusercontent.com/mdqinc/SDL_GameControllerDB/e6f9f10b2616badca4849e2d8ac1fa175114d854/gamecontrollerdb.txt

SOH_FETCHCONTENT_DIR = $(SOH_DIR)/buildroot-fetchcontent
HOST_SOH_FETCHCONTENT_DIR = $(HOST_SOH_DIR)/buildroot-fetchcontent

define SOH_STAGE_FETCHCONTENT
	mkdir -p $(SOH_FETCHCONTENT_DIR)/imgui $(SOH_FETCHCONTENT_DIR)/stormlib \
		$(SOH_FETCHCONTENT_DIR)/libgfxd $(SOH_FETCHCONTENT_DIR)/threadpool \
		$(SOH_FETCHCONTENT_DIR)/prism $(SOH_FETCHCONTENT_DIR)/dr_libs
	$(TAR) -xzf $(SOH_DL_DIR)/$(SOH_IMGUI_ARCHIVE) -C $(SOH_FETCHCONTENT_DIR)/imgui --strip-components=1
	cd $(SOH_FETCHCONTENT_DIR)/imgui && git apply $(SOH_DIR)/libultraship/cmake/dependencies/patches/imgui-fixes-and-config.patch
	$(TAR) -xzf $(SOH_DL_DIR)/$(SOH_STORMLIB_ARCHIVE) -C $(SOH_FETCHCONTENT_DIR)/stormlib --strip-components=1
	$(TAR) -xzf $(SOH_DL_DIR)/$(SOH_LIBGFXD_ARCHIVE) -C $(SOH_FETCHCONTENT_DIR)/libgfxd --strip-components=1
	$(TAR) -xzf $(SOH_DL_DIR)/$(SOH_THREADPOOL_ARCHIVE) -C $(SOH_FETCHCONTENT_DIR)/threadpool --strip-components=1
	$(TAR) -xzf $(SOH_DL_DIR)/$(SOH_PRISM_ARCHIVE) -C $(SOH_FETCHCONTENT_DIR)/prism --strip-components=1
	$(TAR) -xzf $(SOH_DL_DIR)/$(SOH_DR_LIBS_ARCHIVE) -C $(SOH_FETCHCONTENT_DIR)/dr_libs --strip-components=1
	$(SED) \
		's|set(CMAKE_CXX_FLAGS_DEBUG "-g")|set(CMAKE_CXX_FLAGS_DEBUG "$${CMAKE_CXX_FLAGS_DEBUG} -g")|' \
		-e 's|set(CMAKE_CXX_FLAGS_RELEASE "-O3")|set(CMAKE_CXX_FLAGS_RELEASE "$${CMAKE_CXX_FLAGS_RELEASE} -O3")|' \
		-e 's|set(CMAKE_CXX_FLAGS "-Wno-narrowing")|set(CMAKE_CXX_FLAGS "$${CMAKE_CXX_FLAGS} -Wno-narrowing")|' \
		$(SOH_FETCHCONTENT_DIR)/prism/CMakeLists.txt
endef
SOH_POST_EXTRACT_HOOKS += SOH_STAGE_FETCHCONTENT

define HOST_SOH_STAGE_FETCHCONTENT
	mkdir -p $(HOST_SOH_FETCHCONTENT_DIR)/imgui $(HOST_SOH_FETCHCONTENT_DIR)/stormlib \
		$(HOST_SOH_FETCHCONTENT_DIR)/libgfxd $(HOST_SOH_FETCHCONTENT_DIR)/threadpool \
		$(HOST_SOH_FETCHCONTENT_DIR)/prism $(HOST_SOH_FETCHCONTENT_DIR)/dr_libs
	$(TAR) -xzf $(HOST_SOH_DL_DIR)/$(SOH_IMGUI_ARCHIVE) -C $(HOST_SOH_FETCHCONTENT_DIR)/imgui --strip-components=1
	cd $(HOST_SOH_FETCHCONTENT_DIR)/imgui && git apply $(HOST_SOH_DIR)/libultraship/cmake/dependencies/patches/imgui-fixes-and-config.patch
	$(TAR) -xzf $(HOST_SOH_DL_DIR)/$(SOH_STORMLIB_ARCHIVE) -C $(HOST_SOH_FETCHCONTENT_DIR)/stormlib --strip-components=1
	$(TAR) -xzf $(HOST_SOH_DL_DIR)/$(SOH_LIBGFXD_ARCHIVE) -C $(HOST_SOH_FETCHCONTENT_DIR)/libgfxd --strip-components=1
	$(TAR) -xzf $(HOST_SOH_DL_DIR)/$(SOH_THREADPOOL_ARCHIVE) -C $(HOST_SOH_FETCHCONTENT_DIR)/threadpool --strip-components=1
	$(TAR) -xzf $(HOST_SOH_DL_DIR)/$(SOH_PRISM_ARCHIVE) -C $(HOST_SOH_FETCHCONTENT_DIR)/prism --strip-components=1
	$(TAR) -xzf $(HOST_SOH_DL_DIR)/$(SOH_DR_LIBS_ARCHIVE) -C $(HOST_SOH_FETCHCONTENT_DIR)/dr_libs --strip-components=1
	$(SED) \
		's|set(CMAKE_CXX_FLAGS_DEBUG "-g")|set(CMAKE_CXX_FLAGS_DEBUG "$${CMAKE_CXX_FLAGS_DEBUG} -g")|' \
		-e 's|set(CMAKE_CXX_FLAGS_RELEASE "-O3")|set(CMAKE_CXX_FLAGS_RELEASE "$${CMAKE_CXX_FLAGS_RELEASE} -O3")|' \
		-e 's|set(CMAKE_CXX_FLAGS "-Wno-narrowing")|set(CMAKE_CXX_FLAGS "$${CMAKE_CXX_FLAGS} -Wno-narrowing")|' \
		$(HOST_SOH_FETCHCONTENT_DIR)/prism/CMakeLists.txt
endef
HOST_SOH_POST_EXTRACT_HOOKS += HOST_SOH_STAGE_FETCHCONTENT
HOST_SOH_EXTRA_DOWNLOADS = $(SOH_EXTRA_DOWNLOADS)

SOH_FETCHCONTENT_OPTS = \
	-DFETCHCONTENT_FULLY_DISCONNECTED=ON \
	-DSOH_SOURCE_COMMIT=$(SOH_VERSION) \
	-DBUILD_REMOTE_CONTROL=OFF \
	-DUSE_OPENGLES=OFF

SOH_CONF_OPTS += \
	$(SOH_FETCHCONTENT_OPTS) \
	'-DCMAKE_CXX_LINK_LIBRARY_USING_WHOLE_ARCHIVE=LINKER:--whole-archive;<LINK_ITEM>;LINKER:--no-whole-archive' \
	-DCMAKE_CXX_LINK_LIBRARY_USING_WHOLE_ARCHIVE_SUPPORTED=TRUE \
	-DSOH_STB_IMAGE_FILE=$(SOH_DL_DIR)/stb_image.h \
	-DSOH_GAMECONTROLLERDB_FILE=$(SOH_DL_DIR)/gamecontrollerdb.txt \
	-DFETCHCONTENT_SOURCE_DIR_IMGUI=$(SOH_FETCHCONTENT_DIR)/imgui \
	-DFETCHCONTENT_SOURCE_DIR_STORMLIB=$(SOH_FETCHCONTENT_DIR)/stormlib \
	-DFETCHCONTENT_SOURCE_DIR_LIBGFXD=$(SOH_FETCHCONTENT_DIR)/libgfxd \
	-DFETCHCONTENT_SOURCE_DIR_THREADPOOL=$(SOH_FETCHCONTENT_DIR)/threadpool \
	-DFETCHCONTENT_SOURCE_DIR_PRISM=$(SOH_FETCHCONTENT_DIR)/prism \
	-DFETCHCONTENT_SOURCE_DIR_DR_LIBS=$(SOH_FETCHCONTENT_DIR)/dr_libs \
	-DCMAKE_DISABLE_FIND_PACKAGE_ImageMagick=TRUE \
	-DCMAKE_BUILD_TYPE=Release

HOST_SOH_CONF_OPTS += \
	$(SOH_FETCHCONTENT_OPTS) \
	-DSOH_ASSET_GENERATOR_ONLY=ON \
	-DSOH_STB_IMAGE_FILE=$(HOST_SOH_DL_DIR)/stb_image.h \
	-DSOH_GAMECONTROLLERDB_FILE=$(HOST_SOH_DL_DIR)/gamecontrollerdb.txt \
	-DFETCHCONTENT_SOURCE_DIR_IMGUI=$(HOST_SOH_FETCHCONTENT_DIR)/imgui \
	-DFETCHCONTENT_SOURCE_DIR_STORMLIB=$(HOST_SOH_FETCHCONTENT_DIR)/stormlib \
	-DFETCHCONTENT_SOURCE_DIR_LIBGFXD=$(HOST_SOH_FETCHCONTENT_DIR)/libgfxd \
	-DFETCHCONTENT_SOURCE_DIR_THREADPOOL=$(HOST_SOH_FETCHCONTENT_DIR)/threadpool \
	-DFETCHCONTENT_SOURCE_DIR_PRISM=$(HOST_SOH_FETCHCONTENT_DIR)/prism \
	-DFETCHCONTENT_SOURCE_DIR_DR_LIBS=$(HOST_SOH_FETCHCONTENT_DIR)/dr_libs \
	-DCMAKE_DISABLE_FIND_PACKAGE_ImageMagick=TRUE \
	-DCMAKE_BUILD_TYPE=Release

SOH_DEPENDENCIES = \
	host-soh \
	sdl2 libgl libpng libogg libvorbis opus opusfile libzip \
	json-for-modern-cpp tinyxml2 spdlog

HOST_SOH_DEPENDENCIES = \
	host-python3 host-sdl2 host-libpng host-libogg host-libvorbis \
	host-opus host-opusfile host-libzip host-json-for-modern-cpp \
	host-tinyxml2 host-spdlog

SOH_BUILD_OPTS = --target soh
HOST_SOH_BUILD_OPTS = --target GenerateSohOtr

define HOST_SOH_INSTALL_CMDS
	test -s $(HOST_SOH_BUILDDIR)/soh/soh.o2r
	$(INSTALL) -D -m 0644 $(HOST_SOH_BUILDDIR)/soh/soh.o2r \
		$(HOST_DIR)/share/soh/$(SOH_PROJECT_VERSION)/soh.o2r
endef

define SOH_INSTALL_TARGET_CMDS
	if [ -d $(TARGET_DIR)/usr/lib/soh ]; then \
		chmod -R u+w $(TARGET_DIR)/usr/lib/soh; \
		rm -rf $(TARGET_DIR)/usr/lib/soh; \
	fi
	test -s $(HOST_DIR)/share/soh/$(SOH_PROJECT_VERSION)/soh.o2r
	$(INSTALL) -D -m 0755 $(SOH_BUILDDIR)/soh/soh.elf $(TARGET_DIR)/usr/lib/soh/soh.elf
	$(INSTALL) -m 0644 $(HOST_DIR)/share/soh/$(SOH_PROJECT_VERSION)/soh.o2r \
		$(TARGET_DIR)/usr/lib/soh/soh.o2r
	$(INSTALL) -m 0644 $(SOH_DL_DIR)/gamecontrollerdb.txt \
		$(TARGET_DIR)/usr/lib/soh/gamecontrollerdb.txt
	mkdir -p $(TARGET_DIR)/usr/lib/soh/assets
	cp -a $(SOH_DIR)/soh/assets/extractor $(TARGET_DIR)/usr/lib/soh/assets
	cp -a $(SOH_DIR)/soh/assets/extractor/. $(TARGET_DIR)/usr/lib/soh/assets
	cp -a $(SOH_DIR)/soh/assets/xml $(TARGET_DIR)/usr/lib/soh/assets/xml
	chmod -R a-w $(TARGET_DIR)/usr/lib/soh
endef

$(eval $(cmake-package))
$(eval $(host-cmake-package))
$(eval $(emulator-info-package))
