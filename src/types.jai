Lexer :: struct {
    data: string;
    cursor: u32;
    num_tokens: u32;
    token_result: *Token;
}

Allocators :: struct {
    persistent: *Allocator;
}

Markdown_Data :: struct {
    data: string;
    file_path: string;
}
