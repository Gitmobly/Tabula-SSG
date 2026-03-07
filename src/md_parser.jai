MAX_TOKENS :: 2048;
PRINT_PARSER_OUTPUT :: false;

DEFAULT_HTML_FOOTER :: "Created by <a target=\"_blank\" rel=\"noopener noreferrer\" href='https://git.deplet.ing/Jj/Tabula-SSG'>Tabula-SSG</a>.";

/* -------------------------------------
* (JJB): API
*/

run_markdown_parser :: (a: *Allocator, markdown_data: *Markdown_Data, lexer_result: *Lexer, start_time: Apollo_Time, config: Build_Config) -> bool {
    if (!markdown_data.should_process) {
        return false;
    }

    print("Beginning parser pass for `%`.\n", markdown_data.file_path);
    output_html_string_builder: String_Builder;
    page_name_arr := split(markdown_data.file_path, "/");
    page_name_val := split(page_name_arr[page_name_arr.count - 1], ".")[0];

    // Header
    insert_html_header(*output_html_string_builder, page_name_val, config);
    print_to_builder(*output_html_string_builder, "%<br>%<br>%<br><br>", markdown_data.date_str, markdown_data.title, markdown_data.subtitle);

    // Tokens
    render_tokens_to_builder(*output_html_string_builder, lexer_result);

    // Footer
    end_time := current_time_monotonic();
    total_time := to_microseconds(end_time - start_time);
    insert_html_footer(*output_html_string_builder, total_time, true);

    // Logistics?
    make_directory_if_it_does_not_exist("./web/");
    make_directory_if_it_does_not_exist("./web/images");
    make_directory_if_it_does_not_exist("./posts/images");
    copy_directory("./posts/images", "./web/images");
    file_to_write := sprint("./web/%.html", page_name_val);
    success := write_entire_file(file_to_write, *output_html_string_builder);
    if (!success) {
        print("Could not write to file.\n");
        return false;
    }

    if (PRINT_PARSER_OUTPUT) {
        for 0..lexer_result.num_tokens - 1 {
            print("%\n", lexer_result.token_result[it]);
        }
    }

    print("Completed parser pass for `%`.\n", markdown_data.file_path);
    return true;
}

render_tokens_to_builder :: (output: *String_Builder, lexer_result: *Lexer) {
    in_paragraph := false;

    for 0..lexer_result.num_tokens - 1 {
        token := lexer_result.token_result[it];
        if token.type == .UNKNOWN continue;

        if token.type == .NEWLINE {
            if token.length >= 2 && in_paragraph {
                print_to_builder(output, "</p>\n");
                in_paragraph = false;
            }
            continue;
        }

        if token.type == .HYPERLINK {
            if !in_paragraph {print_to_builder(output, "<p>"); in_paragraph = true;}
            print_to_builder(output, "<a href=\"%\">%</a>",
                             string.{token.aux_length, token.aux_start},
                             string.{token.length, token.start});
            continue;
        }

        if token.type == .IMAGE {
            if in_paragraph {print_to_builder(output, "</p>\n"); in_paragraph = false;}
            print_to_builder(output, "<img src=\"%\" alt=\"%\">\n",
                             string.{token.aux_length, token.aux_start},
                             string.{token.length, token.start});
            continue;
        }

        is_block := token.type == .H1 || token.type == .H2 || token.type == .H3 ||
                    token.type == .H4 || token.type == .H5 || token.type == .H6 ||
                    token.type == .QUOTE || token.type == .CODEBLOCK;

        if is_block {
            if in_paragraph {print_to_builder(output, "</p>\n"); in_paragraph = false;}
            tags := TOKEN_HTML[cast(int)token.type];
            print_to_builder(output, "%%%\n", tags.open, token_as_string(*token), tags.close);
            continue;
        }

        if !in_paragraph {print_to_builder(output, "<p>"); in_paragraph = true;}
        tags := TOKEN_HTML[cast(int)token.type];
        print_to_builder(output, "%%%", tags.open, token_as_string(*token), tags.close);
    }

    if in_paragraph print_to_builder(output, "</p>\n");
}

run_markdown_lexer :: (a: *Allocator, markdown_data: *Markdown_Data, config: Build_Config) -> bool, *Lexer {
    print("Beginning lexer pass for `%`.\n", markdown_data.file_path);
    lexer := New(Lexer,, a);
    lexer.data = markdown_data.data;
    lexer.cursor = 0;
    lexer.num_tokens = 0;
    lexer.token_result = NewArray(MAX_TOKENS, Token,, a);

    is_about := markdown_data.file_path == config.about_src;

    if !is_about {
        if peek(lexer) != #char "-" {
            print("Missing frontmatter from %. This file will not be processed.\n", markdown_data.file_path);
            markdown_data.should_process = false;
            return true, lexer;
        }
        if !consume_frontmatter(lexer, markdown_data) {
            markdown_data.should_process = false;
            return true, lexer;
        }
    }

    while lexer.cursor < lexer.data.count {
        assert(lexer.num_tokens < MAX_TOKENS);
        current_token := peek(lexer);

        if current_token == {
        case #char "#"; {
                header_token: Token;
                consume_heading(lexer, *header_token);
            }
        case #char "*"; #through;
        case #char "_"; {
                emphasis_token: Token;
                consume_emphasis(lexer, *emphasis_token);
            }
        case #char "`"; {
                code_token: Token;
                consume_code(lexer, *code_token);
            }
        case #char ">"; {
                quote_token: Token;
                consume_quote(lexer, *quote_token);
            }
        case #char "\n"; #through;
        case #char "\r"; {
                newline_token: Token;
                consume_newline(lexer, *newline_token);
            }
        case #char "["; {
                hyperlink_token: Token;
                consume_hyperlink(lexer, *hyperlink_token);
            }
        case #char "!"; {
                if peek(lexer, 1) == #char "[" {
                    image_token: Token;
                    consume_image(lexer, *image_token);
                } else {
                    text_token: Token;
                    text_token.type = .TEXT;
                    text_token.start = *lexer.data[lexer.cursor];
                    text_token.length = 1;
                    consume(lexer);
                    lexer.token_result[lexer.num_tokens] = text_token;
                    lexer.num_tokens += 1;
                }
            }
        case; {
                text_token: Token;
                consume_text(lexer, *text_token);
            }
        }
    }

    print("Completed lexer pass for `%`.\n", markdown_data.file_path);
    return true, lexer;
}

/* -------------------------------------
* (JJB): Markdown Parsing Functions
*/

consume_heading :: (lexer: *Lexer, header_token: *Token) {
    header_count := 0;
    while (consume(lexer) == "#") {
        header_count += 1;
    }

    if header_count == {
    case 1; header_token.type = .H1;
    case 2; header_token.type = .H2;
    case 3; header_token.type = .H3;
    case 4; header_token.type = .H4;
    case 5; header_token.type = .H5;
    case 6; header_token.type = .H6;
    }

    if (peek(lexer) == " ") consume(lexer);
    header_token.start = *lexer.data[lexer.cursor];

    while (!is_eol(consume(lexer))) {
        header_token.length += 1;
    }

    lexer.token_result[lexer.num_tokens] = header_token;
    lexer.num_tokens += 1;
}

consume_emphasis :: (lexer: *Lexer, emphasis_token: *Token) {
    /* TODO(JJB): This isn't exactly robust, but I need to figure out whether I care about that... */
    if (peek(lexer, 2) == "*" || peek(lexer, 2) == "_") {
        emphasis_token.type = .BOLDITALIC;
    } else if (peek(lexer, 1) == "*" || peek(lexer, 1) == "_") {
        emphasis_token.type = .BOLD;
    } else {
        emphasis_token.type = .ITALIC;
    }

    while (peek(lexer) == "*" || peek(lexer) == "_") {
        consume(lexer);
    }

    emphasis_token.start = *lexer.data[lexer.cursor];

    while (peek(lexer) != "*" && peek(lexer) != "_") {
        emphasis_token.length += 1;
        consume(lexer);
    }

    /* TODO(JJB): A bit ugly... */
    if emphasis_token.type == {
    case .BOLDITALIC; consume(lexer, 3);
    case .BOLD; consume(lexer, 2);
    case .ITALIC; consume(lexer);
    }

    lexer.token_result[lexer.num_tokens] = emphasis_token;
    lexer.num_tokens += 1;
}

consume_text :: (lexer: *Lexer, text_token: *Token) {
    text_token.type = .TEXT;
    text_token.start = *lexer.data[lexer.cursor];

    while (!is_special_character(peek(lexer))) {
        text_token.length += 1;
        consume(lexer);
    }

    if (text_token.length > 0) {
        lexer.token_result[lexer.num_tokens] = text_token;
        lexer.num_tokens += 1;
    }
}

consume_newline :: (lexer: *Lexer, newline_token: *Token) {
    newline_token.type = .NEWLINE;
    newline_token.start = *lexer.data[lexer.cursor];

    while (is_eol(peek(lexer))) {
        newline_token.length += 1;
        consume(lexer);
        if (lexer.cursor >= lexer.data.count) break;
    }

    lexer.token_result[lexer.num_tokens] = newline_token;
    lexer.num_tokens += 1;
}

consume_code :: (lexer: *Lexer, code_token: *Token) {
    if (peek(lexer, 1) == "`") {
        code_token.type = .CODEBLOCK;
    } else {
        code_token.type = .INLINECODE;
    }

    while (peek(lexer) == "`" || is_eol(peek(lexer))) {
        consume(lexer);
    }

    code_token.start = *lexer.data[lexer.cursor];

    while (consume(lexer) != "`") {
        code_token.length += 1;
    }

    while (peek(lexer) == "`") {
        consume(lexer);
    }

    consume(lexer);
    lexer.token_result[lexer.num_tokens] = code_token;
    lexer.num_tokens += 1;
}

consume_quote :: (lexer: *Lexer, quote_token: *Token) {
    quote_token.type = .QUOTE;
    consume(lexer); // '>'
    if peek(lexer) == #char " " consume(lexer);

    quote_token.start = *lexer.data[lexer.cursor];
    while lexer.cursor < lexer.data.count && !is_eol(peek(lexer)) {
        quote_token.length += 1;
        consume(lexer);
    }

    lexer.token_result[lexer.num_tokens] = quote_token;
    lexer.num_tokens += 1;
}

consume_hyperlink :: (lexer: *Lexer, hyperlink_token: *Token) {
    hyperlink_token.type = .HYPERLINK;

    consume(lexer); // '['
    hyperlink_token.start = *lexer.data[lexer.cursor];
    while lexer.cursor < lexer.data.count && peek(lexer) != #char "]" && !is_eol(peek(lexer)) {
        hyperlink_token.length += 1;
        consume(lexer);
    }
    consume(lexer); // ']'

    if peek(lexer) != #char "(" {
        hyperlink_token.type = .TEXT;
        lexer.token_result[lexer.num_tokens] = hyperlink_token;
        lexer.num_tokens += 1;
        return;
    }
    consume(lexer); // '('

    // url
    hyperlink_token.aux_start = *lexer.data[lexer.cursor];
    while lexer.cursor < lexer.data.count && peek(lexer) != #char ")" && !is_eol(peek(lexer)) {
        hyperlink_token.aux_length += 1;
        consume(lexer);
    }
    consume(lexer); // ')'

    lexer.token_result[lexer.num_tokens] = hyperlink_token;
    lexer.num_tokens += 1;
}

consume_image :: (lexer: *Lexer, image_token: *Token) {
    image_token.type = .IMAGE;
    consume(lexer); // '!'
    consume(lexer); // '['

    // alt text
    image_token.start = *lexer.data[lexer.cursor];
    while lexer.cursor < lexer.data.count && peek(lexer) != #char "]" && !is_eol(peek(lexer)) {
        image_token.length += 1;
        consume(lexer);
    }
    consume(lexer); // ']'

    if peek(lexer) != #char "(" {
        image_token.type = .UNKNOWN;
        lexer.token_result[lexer.num_tokens] = image_token;
        lexer.num_tokens += 1;
        return;
    }
    consume(lexer); // '('

    // url
    image_token.aux_start = *lexer.data[lexer.cursor];
    while lexer.cursor < lexer.data.count && peek(lexer) != #char ")" && !is_eol(peek(lexer)) {
        image_token.aux_length += 1;
        consume(lexer);
    }
    consume(lexer); // ')'

    lexer.token_result[lexer.num_tokens] = image_token;
    lexer.num_tokens += 1;
}

is_special_character :: (char: u8) -> bool {
    if char == {
    case "#"; #through;
    case "`"; #through;
    case "\n"; #through;
    case "\r"; #through;
    case "\0"; #through;
    case "["; #through;
    case "*"; return true;
    }

    return false;
}

consume_frontmatter :: (lexer: *Lexer, markdown_data: *Markdown_Data) -> bool {
    if !test_range(lexer, "---") {
        print("No frontmatter in %. File will not be processed.\n", markdown_data.file_path);
        return false;
    }
    consume(lexer, 3);
    skip_ws(lexer);

    while lexer.cursor < lexer.data.count {
        if test_range(lexer, "---") {
            consume(lexer, 3);
            skip_ws(lexer);
            break;
        }

        key := read_until(lexer, #char ":");
        consume(lexer); // ':'
        if peek(lexer) == #char " " consume(lexer);

        value := read_until_eol(lexer);
        skip_ws(lexer);

        if key == "title" markdown_data.title = value;
        else if key == "subtitle" markdown_data.subtitle = value;
        else if key == "date" markdown_data.date_str = value;
    }

    if markdown_data.title.count == 0 {
        print("Missing required 'title' in frontmatter: %. File will not be processed.\n", markdown_data.file_path);
        return false;
    }

    if markdown_data.date_str.count == 0 {
        print("Missing required 'date' in frontmatter: %. File will not be processed.\n", markdown_data.file_path);
        return false;
    }

    return true;
}

read_until :: (l: *Lexer, sentinel: u8) -> string {
    start := *l.data[l.cursor];
    length: s64 = 0;
    while l.cursor < l.data.count && peek(l) != sentinel && !is_eol(peek(l)) {
        length += 1;
        consume(l);
    }
    return .{length, start};
}

read_until_eol :: (l: *Lexer) -> string {
    start := *l.data[l.cursor];
    length: s64 = 0;
    while l.cursor < l.data.count && !is_eol(peek(l)) {
        length += 1;
        consume(l);
    }
    return .{length, start};
}

/* -------------------------------------
* (JJB): Generic parsing functions
*/

peek :: (l: *Lexer, ahead: u32 = 0) -> u8 {
    if (l.cursor + ahead >= l.data.count) {
        return 0;
    }

    return l.data[l.cursor + ahead];
}

consume :: (l: *Lexer, ahead: s64) {
    if (l.cursor + ahead >= l.data.count) {
        return;
    }

    l.cursor += ahead;
    return;
}

consume :: (l: *Lexer) -> u8 {
    if (l.cursor >= l.data.count) {
        return 0;
    }

    character: u8 = l.data[l.cursor];
    l.cursor += 1;
    return character;
}

is_eol :: (c: u8) -> bool {
    return c == #char "\n" || c == #char "\r" || c == #char "\0";
}

skip_ws :: (l: *Lexer) {
    while l.cursor < l.data.count {
        c := peek(l);
        if c != #char " " && c != #char "\t" && !is_eol(c) break;
        consume(l);
    }
}

test_range :: (l: *Lexer, expected: string) -> bool {
    if l.cursor + expected.count > l.data.count return false;
    for 0..expected.count - 1 {
        if l.data[l.cursor + it] != expected[it] return false;
    }
    return true;
}

/* -------------------------------------
* (JJB): Misc Helpers
*/

ascii_from_u8 :: (num: u8) -> string #expand {
    return .{1, *num};
}

token_as_string :: (t: *Token) -> string {
    return .{t.length, t.start};
}

#import "File";
#import "String";
