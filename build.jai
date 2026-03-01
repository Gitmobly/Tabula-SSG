// 
// Build script.
// Set the icon by running with: +Icon -icon icon.ico
// @TODO(JJB): load correct platform layer depending on platform 
// 

#load "src/entry_point.jai";

#run {
    make_directory_if_it_does_not_exist("./build/");

    set_build_options_dc(.{
                           output_path = "build",
                           output_executable_name = "tabula"});
}

#import "Compiler";
#import "File";
