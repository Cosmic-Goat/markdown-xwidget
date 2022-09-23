#!/bin/bash

tempdir=$(mktemp -d)

# Get a cookie for highlightjs.org
token=$(curl -s \
             --cookie-jar "$tempdir/jar" \
             https://highlightjs.org/download/  \
            | grep csrf \
            | cut -d '"' -f6)

# The languages we want highlight.js to support
langs=("1c"
       "abnf"
       "accesslog"
       "actionscript"
       "ada"
       "angelscript"
       "apache"
       "applescript"
       "arcade"
       "arduino"
       "armasm"
       "asciidoc"
       "aspectj"
       "autohotkey"
       "autoit"
       "avrasm"
       "awk"
       "axapta"
       "bash"
       "basic"
       "bnf"
       "brainfuck"
       "c"
       "cal"
       "capnproto"
       "ceylon"
       "clean"
       "clojure"
       "clojure-repl"
       "cmake"
       "coffeescript"
       "coq"
       "cos"
       "cpp"
       "crmsh"
       "crystal"
       "csharp"
       "csp"
       "css"
       "d"
       "dart"
       "delphi"
       "diff"
       "django"
       "dns"
       "dockerfile"
       "dos"
       "dsconfig.js"
       "dts"
       "dust"
       "ebnf"
       "elixir"
       "elm"
       "erb"
       "erlang"
       "erlang-repl"
       "excel"
       "fix"
       "flix"
       "fortran"
       "fsharp"
       "gams"
       "gauss"
       "gcode"
       "gherkin"
       "glsl"
       "gml"
       "go"
       "golo"
       "gradle"
       "graphql"
       "groovy"
       "haml"
       "handlebars"
       "haskell"
       "haxe"
       "hsp"
       "http"
       "hy"
       "inform7"
       "ini"
       "irpf90"
       "isbl"
       "java"
       "javascript"
       "jboss-cli"
       "json"
       "julia"
       "julia-repl"
       "kotlin"
       "lasso"
       "latex"
       "ldif"
       "leaf"
       "less"
       "lisp"
       "livecodeserver"
       "livescript"
       "llvm"
       "lsl"
       "lua"
       "makefile"
       "markdown"
       "mathematica"
       "matlab"
       "maxima"
       "mel"
       "mercury"
       "mipsasm"
       "mizar"
       "mojolicious"
       "monkey"
       "moonscript"
       "n1ql"
       "nestedtext"
       "nginx"
       "nim"
       "nix"
       "node-repl"
       "nsis"
       "objectivec"
       "ocaml"
       "openscad"
       "oxygene"
       "parser3"
       "perl"
       "pf"
       "pgsql"
       "php"
       "php-template"
       "plaintext"
       "pony"
       "powershell"
       "processing"
       "profile"
       "prolog"
       "properties"
       "protobuf"
       "puppet"
       "purebasic"
       "python"
       "python-repl"
       "q"
       "qml"
       "r"
       "reasonml"
       "rib"
       "roboconf"
       "routeros"
       "rsl"
       "ruby"
       "ruleslanguage"
       "rust"
       "sas"
       "scala"
       "scheme"
       "scilab"
       "scss"
       "shell"
       "smali"
       "smalltalk"
       "sml"
       "sqf"
       "sql"
       "stan"
       "stata"
       "step21"
       "stylus"
       "subunit"
       "swift"
       "taggerscript"
       "tap"
       "tcl"
       "thrift"
       "tp"
       "twig"
       "typescript"
       "vala"
       "vbnet"
       "vbscript"
       "vbscript-html"
       "verilog"
       "vhdl"
       "vim"
       "wasm"
       "wren"
       "x86asm"
       "xl"
       "xml"
       "xquery"
       "yaml"
       "zephir")
lang_params=$(printf "&%s.js=on" "${langs[@]}")

# Download a bundle of resources from highlightjs.org
echo "Downloading resource bundle from highlightjs.org..."
curl -s \
     -H "Referer: https://highlightjs.org/download/" \
     -b $tempdir/jar \
     -d "csrfmiddlewaretoken=$token$lang_params" \
     https://highlightjs.org/download/ \
     > "$tempdir/out.zip"

echo "Extracting highlight.js resources to: $tempdir"
unzip -q -d "$tempdir" \
      "$tempdir/out.zip"

# Copy the highlightjs resources we need

# CSS
d=resources/highlight_css
css_files=($tempdir/styles/*.css)
echo "Copying ${#css_files[@]} highlight.js CSS files to $d"
for f in "${css_files[@]}"; do
    # Parameter expansion to remove prefix pattern
    file_name="${f##*/}"
    cp "$f" "$d/$file_name"
done

# JS
echo "Copying highlight.min.js to resources"
cp $tempdir/highlight.min.js resources/highlight.min.js

echo "Fetching mermaid js"
curl -s https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js \
     > resources/mermaid.min.js

echo "Fetching MathJax js"
curl -s https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js \
     > resources/tex-mml-chtml.js
