#!/bin/bash

################################################################################
# Process template files with environment variables from a specified .env file
# Only processes files with '_template' suffix
#
# Arguments:
#   $1 - Path to the .env file containing environment variables
#   $2 - Directory containing template files to process
#   $3 - Output directory for processed files
#
# Returns:
#   0 - Success
#   1 - Invalid arguments or directory not found
#   2 - No template files found (warning only)
#
# Example:
#   func_utils_process_templates "/path/to/.env" "/path/to/templates" "/path/to/output"
################################################################################
func_utils_process_templates() {
    # Validate input parameters
    if [ $# -ne 3 ]; then
        echo "Error: Invalid number of arguments"
        echo "Usage: ${FUNCNAME[0]} <env_file> <template_dir> <output_dir>"
        return 1
    fi

    local env_file="$1"
    local template_dir="$2"
    local output_dir="$3"
    local env_vars=()
    local sed_commands=()

    # Check if env file exists
    if [ ! -f "$env_file" ]; then
        echo "Warning: Environment file not found: $env_file"
        echo "Proceeding without variable substitution..."
    fi

    # Verify template directory exists
    if [ ! -d "$template_dir" ]; then
        echo "Error: Template directory not found: $template_dir"
        return 1
    fi

    # Create output directory if it doesn't exist
    if ! mkdir -p "$output_dir" 2>/dev/null; then
        echo "Error: Failed to create output directory: $output_dir"
        return 1
    fi

    echo "Starting template processing..."
    echo "Environment file: $env_file"
    echo "Template directory: $template_dir"
    echo "Output directory: $output_dir"

    # Extract variables from env file if it exists
    if [ -f "$env_file" ]; then
        echo "Collecting environment variables..."
        while IFS='=' read -r key value; do
            # Skip comments and empty lines
            [[ $key =~ ^[[:space:]]*# ]] && continue
            [[ -z $key ]] && continue

            # Clean up key (remove whitespace and quotes)
            key=$(echo "$key" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

            # Skip invalid keys
            [[ -z $key ]] && continue

            # Add to replacement commands list
            sed_commands+=(-e "s|[@\$]{${key}}|${!key}|g")
            echo "Added variable: ${key}=${value}"
        done < "$env_file"
    fi

    # Process all template files
    echo "Processing template files..."
    local template_count=0

    # List all files in template directory for debugging
    echo "Files in template directory:"
    ls -la "${template_dir}"

    # Find all template files
    for template in "${template_dir}"/*_template; do
        # Skip if no files found
        [ ! -f "$template" ] && {
            echo "Warning: No template files found in $template_dir"
            return 2
        }

        echo "-------------------------------------------"
        echo "Processing: $template"

        # Get output filename (remove _template suffix)
        local base_filename=$(basename "$template")
        local output_filename=${base_filename%_template}
        echo "Creating: $output_filename"

        # Apply all variable replacements
        if [ ${#sed_commands[@]} -eq 0 ]; then
            echo "No variables to replace, copying file directly"
            cp "$template" "${output_dir}/${output_filename}"
        else
            echo "Applying ${#sed_commands[@]} variable replacements"
            if ! sed "${sed_commands[@]}" "$template" > "${output_dir}/${output_filename}"; then
                echo "Error: sed command failed for $template"
                continue
            fi
        fi

        # Make shell scripts executable
        if [[ $output_filename == *.sh ]]; then
            echo "Making executable: ${output_filename}"
            chmod +x "${output_dir}/${output_filename}"
        fi

        echo "Successfully processed: ${output_filename}"
        # ((template_count++))
        template_count=$((template_count + 1))
        echo "Files processed so far: $template_count"
        echo "-------------------------------------------"
    done

    echo "===== Template processing completed ====="
    echo "Total files processed: $template_count"
    return 0
}
