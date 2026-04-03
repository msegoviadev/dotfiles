#!/bin/bash

# Register file associations for Neovim.app (Automator version)
# Bundle ID: com.apple.automator.Neovim

BUNDLE_ID="com.apple.automator.Neovim"

# All file extensions to register
EXTENSIONS=(
    "lua"
    "py" "pyw"
    "js" "jsx" "mjs" "cjs"
    "ts" "tsx" "mts" "cts"
    "md" "mdx" "markdown"
    "json" "jsonc" "json5"
    "yaml" "yml"
    "tf" "tfvars" "hcl"
    "java" "kt" "kts"
    "txt" "text"
    "sh" "bash" "zsh" "fish"
    "vim" "vimrc"
    "conf" "config" "cfg" "ini" "toml"
    "html" "htm" "css" "scss" "sass" "less"
    "xml" "xsl" "xslt" "svg"
    "gitignore" "gitattributes" "gitmodules"
    "env" "envrc"
    "rs"
    "go" "gohtml"
    "c" "h" "cpp" "hpp" "cc" "hh" "cxx" "hxx"
    "mind"
)

echo "==================================="
echo "Registering Neovim.app file associations"
echo "==================================="
echo ""
echo "Bundle ID: $BUNDLE_ID"
echo "Extensions: ${#EXTENSIONS[@]} file types"
echo ""

# Check for duti
if ! command -v duti &> /dev/null; then
    echo "❌ Error: duti not installed"
    echo "   Install with: brew install duti"
    exit 1
fi

# Check if app exists
if [ ! -d ~/Applications/Neovim.app ]; then
    echo "❌ Error: ~/Applications/Neovim.app not found"
    echo "   Please create the Neovim.app in Automator first"
    exit 1
fi

# Register each extension
success_count=0
skip_count=0
fail_count=0

for ext in "${EXTENSIONS[@]}"; do
    current=$(duti -x ".$ext" 2>/dev/null | sed -n '3p')
    if [ "$current" = "$BUNDLE_ID" ]; then
        echo "○ .$ext (already set)"
        ((skip_count++))
    elif duti -s "$BUNDLE_ID" ".$ext" all 2>&1; then
        echo "✓ .$ext"
        ((success_count++))
    else
        echo "✗ .$ext"
        ((fail_count++))
    fi
done

echo ""
echo "==================================="
echo "Results"
echo "==================================="
echo "○ Skipped: $skip_count"
echo "✓ Success: $success_count"
echo "✗ Failed: $fail_count"
echo ""

if [ $fail_count -eq 0 ]; then
    echo "✅ All file associations registered successfully!"
else
    echo "⚠️  Some associations failed. This is usually because:"
    echo "   - The file type is protected by macOS (e.g., .html)"
    echo "   - The extension is already associated with a system app"
    echo ""
    echo "You can manually set associations in Finder:"
    echo "   Right-click file → Get Info → Open with: → Neovim.app"
fi

echo ""
echo "Next: Restart Finder to apply changes"
