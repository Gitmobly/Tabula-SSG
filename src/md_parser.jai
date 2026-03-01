Parser :: struct {
    data: string;
    cursor: u32;
}

/* -------------------------------------
* (JJB): Node Types
*/

Node_Type :: enum {
    NONE;
    HEADING;
    TEXT;
    PARAGRAPH;
}

Node :: struct {
    parent: *Node;
    node_type: Node_Type;
}

Atx_Heading :: struct {
    using #as node: Node;
    node_type = .HEADING;
    size: u8;
    heading_text: string;
}

/* -------------------------------------
* (JJB): API
*/

parse_md_into_ast :: (a: *Allocator, file_path: string) -> bool {
    data, ok := read_entire_file(file_path);
    if (!ok) return false;

    parser := New(Parser,, a);
    parser.data = data;
    parser.cursor = 0;

    while parser.cursor < parser.data.count {
        current_token := peek(parser);
        is_reserved_token, node_type := is_reserved_token(current_token);

        if (is_reserved_token) {
            ok, _ = parse_node(parser, node_type);
            if (!ok) {
                print("Failed to parse a node beginning with reserved token %.\n", ascii_from_u8(current_token));
            }
        }

        consume(parser);
    }

    return true;
}

/* -------------------------------------
* (JJB): Markdown Parsing Functions
*/

parse_node :: (p: *Parser, node_type: Node_Type) -> bool, *Node {
    if node_type == {
    case .NONE; {
            print("What?\n");
            return false, null;
        }
    case .HEADING; {
            heading := parse_heading(p);
            print("\n");
            return true, heading;
        }

    case; {
            print("Attempting to parse an unexpected token.\n");
            return false, null;
        }
    }
}

parse_heading :: (p: *Parser) -> *Atx_Heading {
    heading := New(Atx_Heading);

    while (consume(p) != #char " ") {
        heading.size += 1;
    }

    while (!is_eol(p)) {
        print("%", ascii_from_u8(p.data[p.cursor]));
        consume(p);
    }

    return heading;
}

is_reserved_token :: (token: u8) -> bool, Node_Type {
    if token == {
    case #char "#"; return true, .HEADING;
    case; return false, .NONE;
    }
}

/* -------------------------------------
* (JJB): Generic parsing functions
*/

peek :: (p: *Parser) -> u8 {
    if (p.cursor >= p.data.count) {
        return 0;
    }

    return p.data[p.cursor];
}

peek :: (p: *Parser, ahead: u32) -> u8 {
    if (p.cursor + ahead >= p.data.count) {
        return 0;
    }

    return p.data[p.cursor + ahead];
}

consume :: (p: *Parser) -> u8 {
    if (p.cursor >= p.data.count) {
        return 0;
    }

    character: u8 = p.data[p.cursor];
    p.cursor += 1;
    return character;
}

skip_ws :: (p: *Parser) {
    while (p.cursor < p.data.count) {
        c: u8 = p.data[p.cursor];
        if c == {
        case #char " "; #through;
        case #char "\n"; #through;
        case #char "\r"; #through;
        case #char "\t"; #through;
        case #char "\0"; {
                p.cursor += 1;
            }
        case; break;
        }
    }
}

// eol == end of line
is_eol :: (p: *Parser) -> bool {
    c: u8 = p.data[p.cursor];
    if c == {
    case #char "\n"; #through;
    case #char "\r"; #through;
    case #char "\t"; #through;
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
