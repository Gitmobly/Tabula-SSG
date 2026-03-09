main :: () {
    perm_pool: Flat_Pool;
    persistent: Allocator;
    persistent.proc = flat_pool_allocator_proc;
    persistent.data = *perm_pool;
    allocators: Allocators;
    allocators.persistent = *persistent;

    config: Build_Config;
    args := get_command_line_arguments();
    i := 1;
    while i < args.count {
        if args[i] == {
        case "--help"; {
                print("Usage: tabula [options]\n\n");
                print("Options:\n");
                print("  --title <text>        Site title displayed in the header\n");
                print("  --stylesheet <path>   Path to a custom CSS file\n");
                print("  --about <path>        Path to a markdown file to use as the about page. This page does not need frontmatter.\n");
                print("  --no-about            Disable the about page entirely\n");
                print("  --help                Show this message\n");
                return;
            }
        case "--stylesheet"; {
                if i + 1 >= args.count {print("--stylesheet requires a path argument.\n"); return;}
                config.stylesheet_src = args[i + 1];
                config.stylesheet_path = path_filename(args[i + 1]);
                i += 2;
                continue;
            }
        case "--title"; {
                if i + 1 >= args.count {print("--title requires a title argument.\n"); return;}
                i += 1;
                builder: String_Builder;
                first := true;
                while i < args.count && !begins_with(args[i], "--") {
                    if !first append(*builder, " ");
                    append(*builder, args[i]);
                    first = false;
                    i += 1;
                }
                config.site_title = builder_to_string(*builder);
                continue;
            }
        case "--about"; {
                if i + 1 >= args.count {print("--about requires a path argument.\n"); return;}
                src := args[i + 1];
                for 0..src.count - 1 if src[it] == #char "\\" then src[it] = #char "/";
                config.about_src = src;
                i += 2;
                continue;
            }
        case "--no-about"; {
                config.no_about = true;
                i += 1;
                continue;
            }
        }
        print("Unknown argument: % (run with --help for usage)\n", args[i]);
        i += 1;
    }

    make_directory_if_it_does_not_exist("./posts");
    files := file_list("./posts");
    print("Found % items in posts folder.\n", files.count);
    processed_items: [..]Markdown_Metadata;

    for 0..files.count - 1 {
        file_path := files[it];
        if config.about_src.count > 0 && file_path == config.about_src continue;

        start_time := current_time_monotonic();
        page_name_arr := split(files[it], "/");
        file_extension := split(page_name_arr[page_name_arr.count - 1], ".")[1];
        if file_extension != "md" {
            print("Found a non-markdown file. Skipping it...\n");
            continue;
        }

        markdown_raw_data, read_ok := read_entire_file(file_path);
        if !read_ok {print("Could not read file: %\n", file_path); return;}
        defer free(markdown_raw_data);

        markdown_data := Markdown_Data.{data = markdown_raw_data, file_path = file_path};
        lexer_ok, lexer_result := run_markdown_lexer(allocators.persistent, *markdown_data, config);
        if !lexer_ok print("Failed to complete lexer stage for file: %\n", file_path);
        if run_markdown_parser(allocators.persistent, *markdown_data, lexer_result, start_time, config) {
            array_add(*processed_items, Markdown_Metadata.{
                file_path = copy_string(markdown_data.file_path,, allocators.persistent),
                title     = copy_string(markdown_data.title,,     allocators.persistent),
                subtitle  = copy_string(markdown_data.subtitle,,  allocators.persistent),
                date_str  = copy_string(markdown_data.date_str,,  allocators.persistent),
            });
        }
    }

    print("Successfully processed % posts.\n", processed_items.count);
    quick_sort(processed_items, (a, b) => date_to_ordinal(b.date_str) - date_to_ordinal(a.date_str));

    if !create_css_stylesheet(config) print("Could not create CSS stylesheet...\n");
    if !create_blog_page(processed_items, config) print("Could not create home page...\n");
    if !create_about_page(config, allocators.persistent) print("Could not create about page...\n");
}

date_to_ordinal :: (date_str: string) -> s64 {
    if date_str.count < 10 return 0;

    parse_digits :: (s: string, offset: int, count: int) -> s64 {
        result: s64 = 0;
        for 0..count - 1 {
            c := s[offset + it];
            if c < #char "0" || c > #char "9" return -1;
            result = result * 10 + (c - #char "0");
        }
        return result;
    }

    year := parse_digits(date_str, 0, 4);
    month := parse_digits(date_str, 5, 2);
    day := parse_digits(date_str, 8, 2);

    if year < 0 || month < 0 || day < 0 return 0;
    return year * 10000 + month * 100 + day;
}

#import "Basic";
#import "Flat_Pool";
#import "File_Utilities";
#import "Sort";
#load "md_parser.jai";
#load "types.jai";
#load "css.jai";
#load "html.jai";
