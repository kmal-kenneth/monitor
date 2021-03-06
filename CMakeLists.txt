    # project name
    project (com.github.kmal-kenneth.monitor)

    # the oldest stable cmake version we support
    cmake_minimum_required (VERSION 2.6)

    # tell cmake where its modules can be found in our project directory
    list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
    list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake/src)

    # where we install data directory (if we have any)
    set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")

    # what to call that directory where we install data too
    set (PKGDATADIR "${DATADIR}/com.github.kmal-kenneth.monitor")

    set (EXEC_NAME "com.github.kmal-kenneth.monitor")
    set (RELEASE_NAME "A hello world.")
    set (VERSION "0.1")
    set (VERSION_INFO "whats up world")

    # we're about to use pkgconfig to make sure dependencies are installed so let's find pkgconfig first
    find_package(PkgConfig)
    
    set (MONITOR_DEPS
        gtk+-3.0
        gee-0.8
        libbamf3
        libwnck-3.0
        gobject-2.0
        glib-2.0
        gio-2.0
        granite
    )

    # now let's actually check for the required dependencies
    pkg_check_modules(DEPS REQUIRED ${MONITOR_DEPS})
    
    add_definitions(${DEPS_CFLAGS})
    link_libraries(${DEPS_LIBRARIES})
    link_directories(${DEPS_LIBRARY_DIRS})
    
    # Comment this out to enable C compiler warnings
    add_definitions (-w)
    add_definitions ("-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\"" -DWNCK_I_KNOW_THIS_IS_UNSTABLE)

    # add the directory of gtop for bindigs
    link_libraries(${WNCK_LIBRARIES} gtop-2.0 -lm)
    include_directories(/usr/include/libgtop-2.0)
    
    # Translation files
    set (GETTEXT_PACKAGE "${CMAKE_PROJECT_NAME}")
    add_definitions (-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")
    add_subdirectory (po)

    # make sure we have vala
    find_package(Vala REQUIRED)
    # make sure we use vala
    include(ValaVersion)
    # make sure it's the desired version of vala
    ensure_vala_version("0.16" MINIMUM)

    # files we want to compile
    include(ValaPrecompile)
    vala_precompile(VALA_C ${EXEC_NAME}
        src/Application.vala
        src/MainWindow.vala        
        src/Widgets/Sidebar.vala
        src/Widgets/ProcessView.vala
        src/Widgets/Search.vala        
        src/Models/ApplicationProcessModel.vala        
        src/Services/Resources.vala        
        src/Managers/AppManager.vala
        src/Managers/ProcessManager.vala
        src/Managers/Process.vala

        # tell what libraries to use when compiling
        PACKAGES
            ${MONITOR_DEPS}
            posix
        # tell what libraries to use when compiling
        CUSTOM_VAPIS
            vapi/libgtop-2.0.vapi
        OPTIONS
            # --vapidir=${CMAKE_SOURCE_DIR}/vapi/
            --thread
            --enable-checking
            --enable-experimental
            -v
            -g
    )
    
    # tell cmake what to call the executable we just made
    add_executable(${EXEC_NAME} ${VALA_C})

    # install the binaries we just made
    install (TARGETS ${EXEC_NAME} RUNTIME DESTINATION bin)

    # install our .desktop file so the Applications menu will see it
    install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/com.github.kmal-kenneth.monitor.desktop DESTINATION ${DATADIR}/applications/)

    # install our .appdata.xml file so AppCenter will see it
    install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/com.github.kmal-kenneth.monitor.appdata.xml DESTINATION ${DATADIR}/metainfo/)
    
