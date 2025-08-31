#!/bin/bash
# Update existing templates to use enhanced styling

echo "🔄 Updating NanoTrace templates with enhanced styling..."

# Function to add CSS and JS to template if not already present
update_template() {
    local file="$1"
    if [ -f "$file" ]; then
        # Check if already has enhanced styling
        if ! grep -q "style.css" "$file"; then
            # Backup original
            cp "$file" "$file.backup"
            
            # Add CSS and JS links
            sed -i 's|</head>|<link rel="stylesheet" href="{{ url_for('"'"'static'"'"', filename='"'"'css/style.css'"'"') }}">\n<script defer src="{{ url_for('"'"'static'"'"', filename='"'"'js/nanotrace.js'"'"') }}"></script>\n</head>|' "$file"
            
            echo "✅ Updated $file"
        else
            echo "ℹ️  $file already updated"
        fi
    fi
}

# Find and update all HTML templates
find backend -name "*.html" -type f | while read template; do
    update_template "$template"
done

echo "📱 Template updates completed!"
