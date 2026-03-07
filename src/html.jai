insert_html_header :: (output_html: *String_Builder, page_name: string, stylesheet_path: string) {
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
                <span class="site-title">Unrefactor.ing</span>
                <a href="/index.html">Blog</a>
                <a href="/about.html">About</a>
            </nav>
        </header>
        <main>
        END,

                     page_name,
                     stylesheet_path);
}

insert_html_footer :: (output_html: *String_Builder, total_time: s64 = 0, has_metrics: bool = false) {
    if (has_metrics) {
        print_to_builder(output_html, "%% | %%%%\n", "<footer>", DEFAULT_HTML_FOOTER, "This page was generated in ", total_time, "μs.", "</footer>");
    } else {
        print_to_builder(output_html, "%%%", "<footer>", DEFAULT_HTML_FOOTER, "</footer>");
    }
    print_to_builder(output_html, "%\n%\n%", "</main>", "</body>", "</html>");
}

create_blog_page :: (posts: []Markdown_Metadata, stylesheet_path: string) -> bool {
    output_html: String_Builder;

    insert_html_header(*output_html, "Unresearch.ing", stylesheet_path);
    print_to_builder(*output_html, "%\n", "<h6>todo fix ugly ass names</h6>");

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

create_about_page :: (stylesheet_path: string) -> bool {
    output_html: String_Builder;

    insert_html_header(*output_html, "About", stylesheet_path);
    print_to_builder(*output_html, "%\n", "<h6>o shid waddup</h6>");
    insert_html_footer(*output_html);

    success := write_entire_file("./web/about.html", *output_html);
    if (!success) {
        print("Could not write home content to about.html file.\n");
        return false;
    }

    print("Successfully generated about.html.\n");
    return true;
}
