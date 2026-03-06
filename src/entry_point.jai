main :: () {
    perm_pool: Flat_Pool;

    persistent: Allocator;
    persistent.proc = flat_pool_allocator_proc;
    persistent.data = *perm_pool;

    allocators: Allocators;
    allocators.persistent = *persistent;

    files := file_list("./resources");
    print("%", files);

    for 0..files.count - 1 {
        file_path := files[it];

        start_time := current_time_monotonic();
        markdown_raw_data, read_ok := read_entire_file(file_path);
        if (!read_ok) {
            print("Could not read file: %\n", file_path);
            return;
        }
        defer free(markdown_raw_data);

        markdown_data := Markdown_Data.{data = markdown_raw_data, file_path = file_path};
        lexer_ok, lexer_result := run_markdown_lexer(allocators.persistent, *markdown_data);
        if (!lexer_ok) print("Failed to complete lexer stage for file: %\n", file_path);
        run_markdown_parser(allocators.persistent, *markdown_data, lexer_result, start_time);
    }

    if (!create_css_stylesheet()) {
        print("Could not create CSS stylesheet...\n");
    }

    if (!create_blog_page(files)) {
        print("Could not create home page...\n");
    }

    if (!create_about_page()) {
        print("Could not create about page...\n");
    }
}

#import "Basic";
#import "Flat_Pool";
#import "File_Utilities";
#load "md_parser.jai";
#load "types.jai";
#load "css.jai";
#load "html.jai";
