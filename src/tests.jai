#load "md_parser.jai";
#import "Basic";

pass_count: int;
fail_count: int;

token_string :: (t: *Token) -> string {
    return .{t.length, t.start};
}

check :: (condition: bool, label: string) {
    if condition {
        print("  [PASS] %\n", label);
        pass_count += 1;
    } else {
        print("  [FAIL] %\n", label);
        fail_count += 1;
    }
}

expect_token :: (lexer: *Lexer, index: u32, expected_type: Token_Type, expected_content: string) {
    if index >= lexer.num_tokens {
        print("  [FAIL] Token[%]: out of bounds (num_tokens = %)\n", index, lexer.num_tokens);
        fail_count += 1;
        return;
    }

    t := *lexer.token_result[index];
    content := token_string(t);

    label := tprint("Token[%] type=% content=\"%\"", index, expected_type, expected_content);

    type_ok := t.type == expected_type;
    content_ok := content == expected_content;

    if type_ok && content_ok {
        print("  [PASS] %\n", label);
        pass_count += 1;
    } else {
        print("  [FAIL] %\n", label);
        if !type_ok print("         type:    expected %, got %\n", expected_type, t.type);
        if !content_ok print("         content: expected \"%\", got \"%\"\n", expected_content, content);
        fail_count += 1;
    }
}

main :: () {
    a := context.allocator;

    print("Lexer Tests\n\n");

    print("[ Lexer bootstrap ]\n");
    ok, lexer := run_markdown_lexer(*a, "../resources/test.md");
    check(ok, "run_markdown_lexer returns true");
    if !ok {
        print("\nLexer failed to initialise. Aborting.\n");
        return;
    }
    check(lexer != null, "Lexer pointer non-null");

    print("\n[ Token count ]\n");
    check(lexer.num_tokens == 21, "total token count == 21");

    print("\n[ Heading tokens ]\n");
    expect_token(lexer, 0, .H1, "Test MD");
    expect_token(lexer, 8, .H3, "Now for some more MD features I'd use");

    print("\n[ Newline tokens ]\n");
    expect_token(lexer, 1, .NEWLINE, "\n\r");
    expect_token(lexer, 7, .NEWLINE, "\n");
    expect_token(lexer, 9, .NEWLINE, "\n");
    expect_token(lexer, 11, .NEWLINE, "\n");
    expect_token(lexer, 13, .NEWLINE, "\n");
    expect_token(lexer, 15, .NEWLINE, "\n");
    expect_token(lexer, 17, .NEWLINE, "\n");

    print("\n[ Plain text tokens ]\n");
    expect_token(lexer, 2, .TEXT, "This is a ");
    expect_token(lexer, 4, .TEXT, " markdown file. Made for ");
    expect_token(lexer, 6, .TEXT, " a markdown parser. More stuff should be added to this. ");
    expect_token(lexer, 10, .TEXT, "> This is a quote");
    expect_token(lexer, 12, .TEXT, "> A multi-line quote, in fact!");
    expect_token(lexer, 14, .TEXT, "onto code:");
    expect_token(lexer, 18, .TEXT, "of course, we'd expect this to return ");
    expect_token(lexer, 20, .TEXT, ".");

    print("\n[ Emphasis tokens ]\n");
    expect_token(lexer, 3, .ITALIC, "test");
    expect_token(lexer, 5, .BOLD, "testing");

    print("\n[ Code tokens ]\n");
    expect_token(lexer, 16, .CODEBLOCK, "\nif(is_code_block()) return true;\n");
    expect_token(lexer, 19, .INLINECODE, "true");

    print("\nResults: % passed, % failed\n", pass_count, fail_count);
}
