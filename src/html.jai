insert_html_header :: (output_html: *String_Builder, page_name: string) {
    print_to_builder(output_html, #string END
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>%</title>
            <link rel="stylesheet" href="styles.css">
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

                     page_name);
}

insert_html_footer :: (output_html: *String_Builder, total_time: s64 = 0, has_metrics: bool = false) {
    if (has_metrics) {
        print_to_builder(output_html, "%% | %%%%\n", "<footer>", DEFAULT_HTML_FOOTER, "This page was generated in ", total_time, "μs.", "</footer>");
    } else {
        print_to_builder(output_html, "%%%", "<footer>", DEFAULT_HTML_FOOTER, "</footer>");
    }
    print_to_builder(output_html, "%\n%\n%", "</main>", "</body>", "</html>");
}

create_blog_page :: (files: []string) -> bool {
    output_html: String_Builder;

    insert_html_header(*output_html, "Unresearch.ing");
    print_to_builder(*output_html, "%\n", "<h6>todo fix ugly ass names</h6>");

    print_to_builder(*output_html, "%\n", "<nav>");

    /* TODO(JJB): Change to consuming metadata from a thing? like title, subtitle, date, any other relevant info...*/
    for 0..files.count - 1 {
        page_name_arr := split(files[it], "/");
        page_name := split(page_name_arr[page_name_arr.count - 1], ".")[0];
        print_to_builder(*output_html, "<a href=%%>%</a><br>\n", page_name, ".html", page_name); // holy fragile
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

create_about_page :: () -> bool {
    output_html: String_Builder;

    insert_html_header(*output_html, "About");
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
