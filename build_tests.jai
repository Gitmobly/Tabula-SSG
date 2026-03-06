// 
// Build script.
// Set the icon by running with: +Icon -icon icon.ico
// 
#load "src/tests.jai";
#run {
    make_directory_if_it_does_not_exist("./build/");
    copy_directory("./resources/", "./build/resources");
    set_build_options_dc(.{
                           output_path = "build",
                           output_executable_name = "tabula_tests"});
}
#import "Compiler";
#import "File";
#import "File_Utilities";
