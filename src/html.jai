insert_html_header :: (output_html: *String_Builder, page_name: string, config: Build_Config) {
    print_to_builder(output_html, #string END
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>%</title>
            <link rel="stylesheet" href="%">
        </head>
        <body>
        <header>
            <nav>
                <span class="site-title">%</span>
                <a href="/index.html">Blog</a>
                %
            </nav>
        </header>
        <main>
        END,

                     page_name,
                     config.stylesheet_path,
                     config.site_title,
                     ifx !config.no_about then "<a href=\"/about.html\">About</a>" else "");
}

insert_html_footer :: (output_html: *String_Builder, total_time: s64 = 0, has_metrics: bool = false) {
    if (has_metrics) {
        print_to_builder(output_html, "%% | %%%%\n", "<footer>", DEFAULT_HTML_FOOTER, "This page was generated in ", total_time, "μs.", "</footer>");
    } else {
        print_to_builder(output_html, "%%%", "<footer>", DEFAULT_HTML_FOOTER, "</footer>");
    }
    print_to_builder(output_html, "%\n%\n%", "</main>", "</body>", "</html>");
}

create_blog_page :: (posts: []Markdown_Metadata, config: Build_Config) -> bool {
    output_html: String_Builder;

    insert_html_header(*output_html, "Tabula-SSG", config);

    print_to_builder(*output_html, "%\n", "<nav>");

    for 0..posts.count - 1 {
        page_name_arr := split(posts[it].file_path, "/");
        page_name := split(page_name_arr[page_name_arr.count - 1], ".")[0];
        print_to_builder(*output_html, "% :: <a href=%%>%</a> :: %<br>\n", posts[it].date_str, page_name, ".html", posts[it].title, posts[it].subtitle); // holy fragile
    }
    print_to_builder(*output_html, "%\n", "</nav>");

    insert_html_footer(*output_html);

    success := write_entire_file("./web/index.html", *output_html);
    if (!success) {
        print("Could not write home content to index.html file.\n");
        return false;
    }

    print("Successfully generated index.html.\n");
    return true;
}

create_about_page :: (config: Build_Config, a: *Allocator) -> bool {
    if config.no_about return true;

    if config.about_src.count == 0 {
        output_html: String_Builder;
        insert_html_header(*output_html, "About", config);
        print_to_builder(*output_html, "<p>Tabula-SSG is a static site generator written in Jai. Find out more <a target=\"_blank\" href=\"https://git.deplet.ing/Jj/Tabula-SSG\">here</a>.</p>\n");
        insert_html_footer(*output_html);
        return write_entire_file("./web/about.html", *output_html);
    }

    data, ok := read_entire_file(config.about_src);
    if !ok {print("Could not read about file: %\n", config.about_src); return false;}
    defer free(data);

    markdown_data := Markdown_Data.{data = data, file_path = config.about_src};
    lexer_ok, lexer_result := run_markdown_lexer(a, *markdown_data, config);
    if !lexer_ok || !markdown_data.should_process return false;

    output_html: String_Builder;
    start_time := current_time_monotonic();
    insert_html_header(*output_html, "About", config);
    if markdown_data.title.count > 0 || markdown_data.date_str.count > 0 || markdown_data.subtitle.count > 0 {
        print_to_builder(*output_html, "%<br>%<br>%<br><br>", markdown_data.date_str, markdown_data.title, markdown_data.subtitle);
    }
    render_tokens_to_builder(*output_html, lexer_result);
    insert_html_footer(*output_html, to_microseconds(current_time_monotonic() - start_time), true);

    success := write_entire_file("./web/about.html", *output_html);
    if !success print("Could not write about.html.\n");
    else print("Successfully generated about.html.\n");
    return success;
}
