/* -------------------------------------
* (JJB): General
*/

Lexer :: struct {
    data: string;
    cursor: s64;
    num_tokens: s64;
    token_result: []Token;
    at_line_start: bool = true;
}

Allocators :: struct {
    persistent: *Allocator;
}

Markdown_Data :: struct {
    should_process: bool = true;
    data: string;
    file_path: string;
    title: string;
    subtitle: string;
    date_str: string;
}

Markdown_Metadata :: struct {
    file_path: string;
    title: string;
    subtitle: string;
    date_str: string;
}

Build_Config :: struct {
    no_about: bool = false;
    site_title: string = "Blog";
    about_src: string = "";
    stylesheet_path: string = "styles.css";
    stylesheet_src: string = "";
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

    BOLD;
    ITALIC;
    BOLDITALIC;

    TEXT;

    NEWLINE;

    QUOTE;

    INLINECODE;
    CODEBLOCK;

    HYPERLINK;

    IMAGE;

    LIST_ITEM_UL;
    LIST_ITEM_OL;

    FOOTNOTE_REF;
    FOOTNOTE_DEF;
}

Token :: struct {
    type: Token_Type;
    start: *u8;
    length: s64;
    aux_start: *u8;
    aux_length: s64;
}

/* -------------------------------------
* (JJB): HTML
*/

Html_Tags :: struct {open: string; close: string;}

TOKEN_HTML :: Html_Tags.[
                         .{"", ""}, // UNKNOWN
                         .{"", ""}, // HASH
                         .{"<h1>", "</h1>"}, // H1
                         .{"<h2>", "</h2>"}, // H2
                         .{"<h3>", "</h3>"}, // H3
                         .{"<h4>", "</h4>"}, // H4
                         .{"<h5>", "</h5>"}, // H5
                         .{"<h6>", "</h6>"}, // H6
                         .{"<strong>", "</strong>"}, // BOLD
                         .{"<em>", "</em>"}, // ITALIC
                         .{"<strong><em>", "</em></strong>"}, // BOLDITALIC
                         .{"", ""}, // TEXT
                         .{"", ""}, // NEWLINE
                         .{"<blockquote>", "</blockquote>"}, // QUOTE
                         .{"<code>", "</code>"}, // INLINECODE
                         .{"<pre><code>", "</code></pre>"}, // CODEBLOCK
                         .{"", ""}, // HYPERLINK 
                         .{"", ""}, // IMAGE 
                         .{"<li>", "</li>"}, // LIST_ITEM_UL
                         .{"<li>", "</li>"}, // LIST_ITEM_OL
                         .{"", ""}, // FOOTNOTE_REF  
                         .{"", ""}]; // FOOTNOTE_DEF  

Footnote_Entry :: struct {id: string; text: string;}
