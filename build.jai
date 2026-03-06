// 
// Build script.
// Set the icon by running with: +Icon -icon icon.ico
// 
#load "src/entry_point.jai";
#run {
    make_directory_if_it_does_not_exist("./build/");
    copy_directory("./posts/", "./build/posts"); // TODO: Fix
    set_build_options_dc(.{
                           output_path = "build",
                           output_executable_name = "tabula"});
}
#import "Compiler";
#import "File";
#import "File_Utilities";
