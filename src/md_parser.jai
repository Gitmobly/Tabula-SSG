MAX_TOKENS :: 2048;
PRINT_PARSER_OUTPUT :: false;

DEFAULT_HTML_FOOTER :: "Created by <a target=\"_blank\" rel=\"noopener noreferrer\" href='https://git.deplet.ing/Jj/Tabula-SSG'>Tabula-SSG</a>.";

/* -------------------------------------
* (JJB): API
*/

run_markdown_parser :: (a: *Allocator, markdown_data: *Markdown_Data, lexer_result: *Lexer, start_time: Apollo_Time) -> bool {
    print("Beginning parser pass for `%`.\n", markdown_data.file_path);
    output_html_string_builder: String_Builder;
    page_name_arr := split(markdown_data.file_path, "/");
    page_name_val := split(page_name_arr[page_name_arr.count - 1], ".")[0];

    // Header
    insert_html_header(*output_html_string_builder, page_name_val);

    // Tokens
    for 0..lexer_result.num_tokens - 1 {
        token := lexer_result.token_result[it];
        if token.type == .UNKNOWN {
            print("Warning: Unknown token. Skipping. Be sure to verify the output!\n");
            continue;
        }
        tags := TOKEN_HTML[cast(int)token.type];
        print_to_builder(*output_html_string_builder, "%%%", tags.open, token_as_string(*token), tags.close);
    }

    // Footer
    end_time := current_time_monotonic();
    total_time := to_microseconds(end_time - start_time);
    insert_html_footer(*output_html_string_builder, total_time, true);

    // Logistics?
    make_directory_if_it_does_not_exist("./web/");
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

run_markdown_lexer :: (a: *Allocator, markdown_data: *Markdown_Data) -> bool, *Lexer {
    print("Beginning lexer pass for `%`.\n", markdown_data.file_path);
    lexer := New(Lexer,, a);
    lexer.data = markdown_data.data;
    lexer.cursor = 0;
    lexer.num_tokens = 0;
    lexer.token_result = NewArray(MAX_TOKENS, Token,, a);

    while lexer.cursor < lexer.data.count {
        assert(lexer.num_tokens < MAX_TOKENS);
        current_token := peek(lexer);
        // / print("%\n", ascii_from_u8(current_token));

        if current_token == {
        case "#"; {
                header_token: Token;
                consume_heading(lexer, *header_token);
            }
        case "*"; #through;
        case "_"; {
                emphasis_token: Token;
                consume_emphasis(lexer, *emphasis_token);
            }
        case "`"; {
                code_token: Token;
                consume_code(lexer, *code_token);
            }
        case ">"; {
                quote_token: Token;
                consume_quote(lexer, *quote_token);
            }
        case "\n"; #through;
        case "\r"; {
                newline_token: Token;
                consume_newline(lexer, *newline_token);
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

    consume(lexer, 2); // first '> '

    quote_token.start = *lexer.data[lexer.cursor];

    while (!is_eol(peek(lexer))) {
        quote_token.length += 1;
        consume(lexer);
    }

    lexer.token_result[lexer.num_tokens] = quote_token;
    lexer.num_tokens += 1;
}

is_special_character :: (char: u8) -> bool {
    if char == {
    case "#"; #through;
    case "`"; #through;
    case "\n"; #through;
    case "\r"; #through;
    case "\0"; #through;
    case "*"; return true;
    }

    return false;
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

consume :: (l: *Lexer, ahead: u32 = 1) {
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
