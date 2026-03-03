MAX_TOKENS :: 1024;

Lexer :: struct {
    data: string;
    cursor: u32;
    token_result: [MAX_TOKENS]Token;
    num_tokens: u32;
}

/* -------------------------------------
* (JJB): Tokens
*/

Token_Type :: enum {
    NONE;
    H1;
    H2;
    H3;
    H4;
    H5;
    H6;
}

Token :: struct {
    type: Token_Type;
    start: *u8;
    length: u32;
}

/* -------------------------------------
* (JJB): API
*/

run_markdown_lexer :: (a: *Allocator, file_path: string) -> bool {
    data, ok := read_entire_file(file_path);
    if (!ok) return false;
    print("\n\nThe data: \n\n%\n\n", data);

    lexer := New(Lexer,, a);
    lexer.data = data;
    lexer.cursor = 0;
    lexer.num_tokens = 0;

    while lexer.cursor < lexer.data.count {
        assert(lexer.num_tokens < MAX_TOKENS);
        current_token := peek(lexer);

        if (is_heading(current_token)) {
            header_token: Token;
            consume_heading(lexer, *header_token);
        }

        consume(lexer);
    }

    print("%", lexer.token_result);

    return true;
}

/* -------------------------------------
* (JJB): Markdown Parsing Functions
*/

is_heading :: (token: u8) -> bool {
    if (token == "#") return true;
    else return false;
}

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

    while (!is_eol(lexer)) {
        header_token.length += 1;
        consume(lexer);
    }

    lexer.token_result[lexer.num_tokens] = header_token;
    lexer.num_tokens += 1;
}

/* -------------------------------------
* (JJB): Generic parsing functions
*/

peek :: (l: *Lexer) -> u8 {
    if (l.cursor >= l.data.count) {
        return 0;
    }

    return l.data[l.cursor];
}

peek :: (l: *Lexer, ahead: u32) -> u8 {
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

// eol == end of line
is_eol :: (l: *Lexer) -> bool {
    c: u8 = l.data[l.cursor];
    if c == {
    case #char "\n"; #through;
    case #char "\r"; #through;
    case #char "\0"; {
            return true;
        }
    case; return false;
    }
}

/* -------------------------------------
* (JJB): Misc Helpers
*/

ascii_from_u8 :: (num: u8) -> string #expand {
    return .{1, *num};
}

#import "File";
