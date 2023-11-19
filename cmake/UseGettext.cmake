function(_gettext_mkdir_for_file file)
  get_filename_component(dir "${file}" DIRECTORY)
  file(MAKE_DIRECTORY "${dir}")
endfunction()

function(gettext_compile project_name)
    cmake_parse_arguments(ARGS "" "MO_FILES_NAME;TARGET_NAME;SOURCE_DIR;PROJECT_NAME" "" ${ARGN})

    if(NOT ARGS_SOURCE_DIR)
        set(ARGS_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR})
    endif(NOT ARGS_SOURCE_DIR)
    file(STRINGS "${ARGS_SOURCE_DIR}/LINGUAS" LINGUAS)
    set(target_files)
    foreach(lang ${LINGUAS})
        set(source_file ${ARGS_SOURCE_DIR}/${lang}.po)
        set(target_file ${CMAKE_BINARY_DIR}/locale/${lang}/LC_MESSAGES/${project_name}.mo)
        _gettext_mkdir_for_file(${target_file})
        list(APPEND target_files ${target_file})
        add_custom_command(OUTPUT ${target_file} COMMAND ${MSGFMT_EXECUTABLE} --check-format -o ${target_file} ${source_file} DEPENDS ${source_file})
        install(FILES ${target_file} DESTINATION ${LOCALE_INSTALL_DIR}/${lang}/LC_MESSAGES)
    endforeach(lang)
    if(ARGS_MO_FILES_NAME)
        set(${ARGS_MO_FILES_NAME} ${target_files} PARENT_SCOPE)
    endif(ARGS_MO_FILES_NAME)
    if(ARGS_TARGET_NAME)
        add_custom_target(${ARGS_TARGET_NAME} DEPENDS ${target_files})
    endif(ARGS_TARGET_NAME)
endfunction(gettext_compile)
