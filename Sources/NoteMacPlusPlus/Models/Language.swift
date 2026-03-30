import Foundation

enum LineEnding: String, CaseIterable {
    case lf = "Unix (LF)"
    case crlf = "Windows (CRLF)"
    case cr = "Classic Mac (CR)"

    var characters: String {
        switch self {
        case .lf:   return "\n"
        case .crlf: return "\r\n"
        case .cr:   return "\r"
        }
    }

    static func detect(in text: String) -> LineEnding {
        if text.contains("\r\n") { return .crlf }
        if text.contains("\r")   { return .cr }
        return .lf
    }
}

enum Language: String, CaseIterable, Identifiable {
    case plainText   = "Plain Text"
    case swift       = "Swift"
    case python      = "Python"
    case javascript  = "JavaScript"
    case typescript  = "TypeScript"
    case cLang       = "C"
    case cpp         = "C++"
    case java        = "Java"
    case kotlin      = "Kotlin"
    case rust        = "Rust"
    case go          = "Go"
    case ruby        = "Ruby"
    case php         = "PHP"
    case html        = "HTML"
    case css         = "CSS"
    case xml         = "XML"
    case json        = "JSON"
    case yaml        = "YAML"
    case sql         = "SQL"
    case shell       = "Shell Script"
    case markdown    = "Markdown"

    var id: String { rawValue }

    static func detect(from url: URL) -> Language {
        switch url.pathExtension.lowercased() {
        case "swift":                return .swift
        case "py", "pyw":            return .python
        case "js", "mjs", "cjs":     return .javascript
        case "ts", "tsx":            return .typescript
        case "c", "h":               return .cLang
        case "cpp", "cxx", "cc",
             "hpp", "hxx":           return .cpp
        case "java":                 return .java
        case "kt", "kts":            return .kotlin
        case "rs":                   return .rust
        case "go":                   return .go
        case "rb", "rake":           return .ruby
        case "php":                  return .php
        case "html", "htm":          return .html
        case "css", "scss", "sass":  return .css
        case "xml", "plist", "xib",
             "storyboard":           return .xml
        case "json":                 return .json
        case "yaml", "yml":          return .yaml
        case "sql":                  return .sql
        case "sh", "bash", "zsh",
             "fish":                 return .shell
        case "md", "markdown":       return .markdown
        default:                     return .plainText
        }
    }

    var lineCommentPrefix: String? {
        switch self {
        case .swift, .javascript, .typescript,
             .cLang, .cpp, .java, .kotlin, .rust,
             .go, .php:                              return "//"
        case .python, .ruby, .shell, .yaml:          return "#"
        case .sql:                                   return "--"
        case .html, .xml:                            return nil
        case .css, .markdown, .json, .plainText:     return nil
        }
    }

    var blockCommentDelimiters: (open: String, close: String)? {
        switch self {
        case .swift, .javascript, .typescript,
             .cLang, .cpp, .java, .kotlin, .go, .php:
            return ("/*", "*/")
        case .html, .xml:
            return ("<!--", "-->")
        case .css:
            return ("/*", "*/")
        default:
            return nil
        }
    }

    // MARK: - Keyword Lists

    var keywords: Set<String> {
        switch self {
        case .swift:
            return [
                "associatedtype", "class", "deinit", "enum", "extension",
                "func", "import", "init", "inout", "let", "operator",
                "precedencegroup", "protocol", "struct", "subscript",
                "typealias", "var", "break", "case", "catch", "continue",
                "default", "defer", "do", "else", "fallthrough", "for",
                "guard", "if", "in", "repeat", "return", "throw", "switch",
                "where", "while", "Any", "as", "false", "is", "nil",
                "rethrows", "self", "Self", "super", "throws", "true", "try",
                "associativity", "convenience", "dynamic", "didSet", "final",
                "get", "indirect", "lazy", "left", "mutating", "none",
                "nonmutating", "open", "optional", "override", "postfix",
                "precedence", "prefix", "Protocol", "required", "right",
                "set", "some", "static", "Type", "unowned", "weak", "willSet",
                "public", "private", "internal", "fileprivate", "async", "await",
                "actor", "isolated", "nonisolated", "distributed", "macro"
            ]
        case .python:
            return [
                "False", "None", "True", "and", "as", "assert", "async",
                "await", "break", "class", "continue", "def", "del", "elif",
                "else", "except", "finally", "for", "from", "global", "if",
                "import", "in", "is", "lambda", "nonlocal", "not", "or",
                "pass", "raise", "return", "try", "while", "with", "yield",
                "print", "len", "range", "type", "int", "str", "float",
                "list", "dict", "set", "tuple", "bool", "super", "self"
            ]
        case .javascript, .typescript:
            return [
                "break", "case", "catch", "class", "const", "continue",
                "debugger", "default", "delete", "do", "else", "export",
                "extends", "false", "finally", "for", "function", "if",
                "import", "in", "instanceof", "let", "new", "null",
                "return", "static", "super", "switch", "this", "throw",
                "true", "try", "typeof", "undefined", "var", "void",
                "while", "with", "yield", "async", "await", "of",
                "from", "interface", "type", "enum", "implements",
                "namespace", "declare", "abstract", "readonly", "as"
            ]
        case .cLang, .cpp:
            var kw: Set<String> = [
                "auto", "break", "case", "char", "const", "continue",
                "default", "do", "double", "else", "enum", "extern",
                "float", "for", "goto", "if", "inline", "int", "long",
                "register", "restrict", "return", "short", "signed",
                "sizeof", "static", "struct", "switch", "typedef",
                "union", "unsigned", "void", "volatile", "while",
                "NULL", "true", "false"
            ]
            if self == .cpp {
                kw.formUnion([
                    "alignas", "alignof", "and", "and_eq", "asm",
                    "bitand", "bitor", "bool", "catch", "char8_t",
                    "char16_t", "char32_t", "class", "compl",
                    "concept", "consteval", "constexpr", "constinit",
                    "co_await", "co_return", "co_yield", "decltype",
                    "delete", "explicit", "export", "false", "friend",
                    "mutable", "namespace", "new", "noexcept", "not",
                    "not_eq", "nullptr", "operator", "or", "or_eq",
                    "private", "protected", "public", "requires",
                    "static_assert", "static_cast", "template",
                    "this", "thread_local", "throw", "true", "try",
                    "typeid", "typename", "using", "virtual",
                    "wchar_t", "xor", "xor_eq", "override", "final"
                ])
            }
            return kw
        case .java:
            return [
                "abstract", "assert", "boolean", "break", "byte",
                "case", "catch", "char", "class", "const", "continue",
                "default", "do", "double", "else", "enum", "extends",
                "final", "finally", "float", "for", "goto", "if",
                "implements", "import", "instanceof", "int", "interface",
                "long", "native", "new", "null", "package", "private",
                "protected", "public", "return", "short", "static",
                "strictfp", "super", "switch", "synchronized", "this",
                "throw", "throws", "transient", "try", "void",
                "volatile", "while", "true", "false", "record", "sealed",
                "permits", "var", "yield"
            ]
        case .kotlin:
            return [
                "as", "break", "class", "continue", "do", "else",
                "false", "for", "fun", "if", "in", "interface", "is",
                "null", "object", "package", "return", "super", "this",
                "throw", "true", "try", "typealias", "typeof", "val",
                "var", "when", "while", "by", "catch", "constructor",
                "delegate", "dynamic", "field", "file", "finally",
                "get", "import", "init", "param", "property",
                "receiver", "set", "setparam", "value", "where",
                "actual", "abstract", "annotation", "companion",
                "const", "crossinline", "data", "enum", "expect",
                "external", "final", "infix", "inline", "inner",
                "internal", "lateinit", "noinline", "open", "operator",
                "out", "override", "private", "protected", "public",
                "reified", "sealed", "suspend", "tailrec", "vararg"
            ]
        case .rust:
            return [
                "as", "async", "await", "break", "const", "continue",
                "crate", "dyn", "else", "enum", "extern", "false",
                "fn", "for", "if", "impl", "in", "let", "loop",
                "match", "mod", "move", "mut", "pub", "ref", "return",
                "self", "Self", "static", "struct", "super", "trait",
                "true", "type", "union", "unsafe", "use", "where",
                "while", "abstract", "become", "box", "do", "final",
                "macro", "override", "priv", "try", "typeof", "unsized",
                "virtual", "yield", "i8", "i16", "i32", "i64", "i128",
                "u8", "u16", "u32", "u64", "u128", "f32", "f64",
                "isize", "usize", "bool", "char", "str", "String",
                "Vec", "Option", "Result", "Box", "Rc", "Arc"
            ]
        case .go:
            return [
                "break", "case", "chan", "const", "continue", "default",
                "defer", "else", "fallthrough", "for", "func", "go",
                "goto", "if", "import", "interface", "map", "package",
                "range", "return", "select", "struct", "switch", "type",
                "var", "bool", "byte", "complex64", "complex128",
                "error", "float32", "float64", "int", "int8", "int16",
                "int32", "int64", "rune", "string", "uint", "uint8",
                "uint16", "uint32", "uint64", "uintptr", "true",
                "false", "nil", "iota", "append", "cap", "close",
                "complex", "copy", "delete", "imag", "len", "make",
                "new", "panic", "print", "println", "real", "recover"
            ]
        case .sql:
            return [
                "SELECT", "FROM", "WHERE", "AND", "OR", "NOT", "IN",
                "IS", "NULL", "LIKE", "BETWEEN", "EXISTS", "CASE",
                "WHEN", "THEN", "ELSE", "END", "AS", "JOIN", "INNER",
                "LEFT", "RIGHT", "FULL", "OUTER", "CROSS", "ON",
                "GROUP", "BY", "HAVING", "ORDER", "ASC", "DESC",
                "LIMIT", "OFFSET", "INSERT", "INTO", "VALUES",
                "UPDATE", "SET", "DELETE", "CREATE", "TABLE",
                "ALTER", "DROP", "INDEX", "VIEW", "DATABASE",
                "SCHEMA", "PRIMARY", "KEY", "FOREIGN", "REFERENCES",
                "UNIQUE", "CHECK", "DEFAULT", "NOT", "NULL",
                "CONSTRAINT", "DISTINCT", "ALL", "UNION", "INTERSECT",
                "EXCEPT", "WITH", "RECURSIVE", "TRANSACTION", "COMMIT",
                "ROLLBACK", "BEGIN", "INT", "VARCHAR", "TEXT",
                "BOOLEAN", "DATE", "TIMESTAMP", "FLOAT", "DOUBLE"
            ]
        case .ruby:
            return [
                "BEGIN", "END", "__ENCODING__", "__FILE__", "__LINE__",
                "alias", "and", "begin", "break", "case", "class",
                "def", "defined?", "do", "else", "elsif", "end",
                "ensure", "false", "for", "if", "in", "module",
                "next", "nil", "not", "or", "redo", "rescue",
                "retry", "return", "self", "super", "then", "true",
                "undef", "unless", "until", "when", "while", "yield",
                "puts", "print", "p", "require", "require_relative",
                "attr_accessor", "attr_reader", "attr_writer",
                "include", "extend", "prepend", "raise"
            ]
        case .php:
            return [
                "abstract", "and", "array", "as", "break", "callable",
                "case", "catch", "class", "clone", "const", "continue",
                "declare", "default", "die", "do", "echo", "else",
                "elseif", "empty", "enddeclare", "endfor", "endforeach",
                "endif", "endswitch", "endwhile", "eval", "exit",
                "extends", "final", "finally", "fn", "for", "foreach",
                "function", "global", "goto", "if", "implements",
                "include", "include_once", "instanceof", "insteadof",
                "interface", "isset", "list", "match", "namespace",
                "new", "or", "print", "private", "protected", "public",
                "readonly", "require", "require_once", "return",
                "static", "switch", "throw", "trait", "try",
                "unset", "use", "var", "while", "xor", "yield",
                "true", "false", "null", "TRUE", "FALSE", "NULL"
            ]
        case .shell:
            return [
                "if", "then", "else", "elif", "fi", "case", "esac",
                "for", "while", "until", "do", "done", "in",
                "function", "return", "exit", "export", "local",
                "readonly", "declare", "typeset", "unset", "shift",
                "source", "break", "continue", "select", "time",
                "echo", "printf", "read", "cd", "ls", "mkdir",
                "rm", "cp", "mv", "cat", "grep", "sed", "awk",
                "chmod", "chown", "sudo", "su", "kill", "ps",
                "pwd", "test", "true", "false", "set", "unset"
            ]
        default:
            return []
        }
    }
}
