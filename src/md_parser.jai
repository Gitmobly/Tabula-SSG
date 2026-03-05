MAX_TOKENS :: 512;

Lexer :: struct {
    data: string;
    cursor: u32;
    num_tokens: u32;
    token_result: *Token;
}

/* -------------------------------------
* (JJB): Tokens
*/

Token_Type :: enum {
    UNKNOWN;

    HASH;
    H1;
    H2;
    H3;
    H4;
    H5;
    H6;

    ASTERISK;
    BOLD;
    ITALIC;
    BOLDITALIC;

    TEXT;

    NEWLINE;

    QUOTE;

    INLINECODE;
    CODEBLOCK;
}

Token :: struct {
    type: Token_Type;
    start: *u8;
    length: u32;
}

/* -------------------------------------
* (JJB): API
*/

run_markdown_parser :: (a: *Allocator, lexer_result: *Lexer) -> bool {
    print("Parser layout: \n");
    for 0..lexer_result.num_tokens - 1 {
        print("%\n", lexer_result.token_result[it]);
    }

    return true;
}

run_markdown_lexer :: (a: *Allocator, file_path: string) -> bool, *Lexer {
    data, ok := read_entire_file(file_path);
    if (!ok) {
        print("Could not read file: %\n", file_path);
        return false, null;
    }

    print("Data: %\n", data);

    lexer := New(Lexer,, a);
    lexer.data = data;
    lexer.cursor = 0;
    lexer.num_tokens = 0;
    lexer.token_result = New(Token,, a);

    while lexer.cursor < lexer.data.count {
        assert(lexer.num_tokens < MAX_TOKENS);
        current_token := peek(lexer);

        if current_token == {
        case "#"; {
                header_token: Token;
                consume_heading(lexer, *header_token);
            }
        case "*"; {
                emphasis_token: Token;
                consume_emphasis(lexer, *emphasis_token);
            }
        case "`"; {
                code_token: Token;
                consume_code(lexer, *code_token);
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

    return true, lexer;
}

/* -------------------------------------
* (JJB): Markdown Parsing Functions
*/

consume_heading :: (lexer: *Lexer, header_token: *Token) {
    header_count := 0;
    while (peek(lexer) == "#") {
        header_count += 1;
        consume(lexer);
    }

    if (peek(lexer) == " ") consume(lexer);
    header_token.start = *lexer.data[lexer.cursor];

    if header_count == {
    case 1; header_token.type = .H1;
    case 2; header_token.type = .H2;
    case 3; header_token.type = .H3;
    case 4; header_token.type = .H4;
    case 5; header_token.type = .H5;
    case 6; header_token.type = .H6;
    }

    while (!is_eol(peek(lexer))) {
        header_token.length += 1;
        consume(lexer);
    }

    consume(lexer);
    lexer.token_result[lexer.num_tokens] = header_token;
    lexer.num_tokens += 1;
}

consume_emphasis :: (lexer: *Lexer, emphasis_token: *Token) {
    if (peek(lexer, 2) == "*") {
        emphasis_token.type = .BOLDITALIC;
    } else if (peek(lexer, 1) == "*") {
        emphasis_token.type = .BOLD;
    } else if (peek(lexer, 1) != "*") {
        emphasis_token.type = .ITALIC;
    } else {
        emphasis_token.type = .UNKNOWN;
    }

    while (peek(lexer) == "*") {
        consume(lexer);
    }

    emphasis_token.start = *lexer.data[lexer.cursor];

    while (consume(lexer) != "*") {
        emphasis_token.length += 1;
    }

    consume(lexer);
    lexer.token_result[lexer.num_tokens] = emphasis_token;
    lexer.num_tokens += 1;
}

consume_text :: (lexer: *Lexer, text_token: *Token) {
    text_token.type = .TEXT;
    text_token.start = *lexer.data[lexer.cursor];

    while (!is_special_character(peek(lexer)) && !is_eol(peek(lexer))) {
        text_token.length += 1;
        if (!is_special_character(peek(lexer, 1)) && !is_eol(peek(lexer, 1))) {
            consume(lexer);
        } else {
            break;
        }
    }

    consume(lexer);
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

    while (peek(lexer) == "`") {
        consume(lexer);
    }

    code_token.start = *lexer.data[lexer.cursor];

    while (peek(lexer) != "`") {
        code_token.length += 1;
        consume(lexer);
    }

    while (peek(lexer) == "`") {
        consume(lexer);
    }

    consume(lexer);
    lexer.token_result[lexer.num_tokens] = code_token;
    lexer.num_tokens += 1;
}

is_special_character :: (char: u8) -> bool {
    if char == {
    case "#"; #through;
    case "`"; #through;
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

consume :: (l: *Lexer) -> u8 {
    if (l.cursor >= l.data.count) {
        return 0;
    }

    character: u8 = l.data[l.cursor];
    l.cursor += 1;
    return character;
}

skip_ws :: (l: *Lexer) {
    while (l.cursor < l.data.count) {
        c: u8 = l.data[l.cursor];
        if c == {
        case #char " "; #through;
        case #char "\n"; #through;
        case #char "\r"; #through;
        case #char "\t"; #through;
        case #char "\0"; {
                l.cursor += 1;
            }
        case; break;
        }
    }
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

#import "File";
#import "String";
