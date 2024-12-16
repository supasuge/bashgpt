#!/bin/bash
# Author: [supasuge](https://github.com/supasuge) ~ Evan Pardon
# Version: 0.0.1

# In order for this script to work you need to set the OPENAI_API_KEY environment variable
# to your OpenAI API key.
# export OPENAI_API_KEY=your_api_key
#   add this to the bottom of your .bashrc OR .zshrc file depending on your shell.
# source ~/.bashrc OR source ~/.zshrc
# chmod +x bashgpt/gpt.sh
# ln -s bashgpt/gpt.sh /usr/bin/gpt 
MODEL="gpt-4-turbo-2024-04-09"
TEMPERATURE="0.7"
SYSTEM_MSG=""
PROMPT=""
LIST_MODELS=false
# check if OPENAI_API_KEY is set
: "${OPENAI_API_KEY:?Please set OPENAI_API_KEY in your environment}"

# ANSI escape helpers for nicer formatting
function ansi_escape() { printf "\033[%sm" "$1"; }
function ansi_reset_all() { ansi_escape "0"; }

function ansi_bold() { ansi_escape "1"; }
function ansi_no_bold() { ansi_escape "22"; }

function ansi_italic() { ansi_escape "3"; }
function ansi_no_italic() { ansi_escape "23"; }

function ansi_underline() { ansi_escape "4"; }
function ansi_no_underline() { ansi_escape "24"; }

function ansi_strikethrough() { ansi_escape "9"; }  
function ansi_no_strikethrough() { ansi_escape "29"; }

function ansi_inverse() { ansi_escape "7"; }
function ansi_no_inverse() { ansi_escape "27"; }

function ansi_fg_black() { ansi_escape "30"; }
function ansi_fg_red() { ansi_escape "31"; }
function ansi_fg_green() { ansi_escape "32"; }
function ansi_fg_yellow() { ansi_escape "33"; }
function ansi_fg_blue() { ansi_escape "34"; }
function ansi_fg_magenta() { ansi_escape "35"; }
function ansi_fg_cyan() { ansi_escape "36"; }
function ansi_fg_white() { ansi_escape "37"; }
function ansi_fg_default() { ansi_escape "39"; }

FG_GREEN=$(printf "\033[32m")
FG_CYAN=$(printf "\033[36m")
RESET=$(printf "\033[0m")



# Prints usage instructions and exits (./gpt.sh -h)
function usage() {
    echo "Usage: $0 [-m <model>] [-t <temperature>] [-s <system_message>] [-p <prompt>] [-l] [prompt]"
    echo "  -m <model>           Set the model (default: $MODEL)"
    echo "  -t <temperature>     Set the temperature (default: $TEMPERATURE)"
    echo "  -s <system_message>  Set a system message (optional)"
    echo "  -p <prompt>          Set the prompt explicitly"
    echo "  -l                   List available models"
    exit 1
}
# Fetches a list of publicly available models
function get_models() {
    curl -s https://api.openai.com/v1/models \
      -H "Authorization: Bearer $OPENAI_API_KEY" | jq '.data[] | select(.owned_by == "system") | .id'
}

# Parses Markdown-like text to ANSI-styled output.
# - Handles code blocks (```).
# - Removes headings or replaces them with ANSI styling.
# - Removes horizontal rules (---).
# - Transforms bold, italic, underline, strikethrough.
# - Removes single quotes.
function parse_markdown_to_ansi() {
    local input
    input=$(cat)

    # Code blocks: transform lines between ``` into green
    input=$(echo "$input" | awk -v RESET="$RESET" -v FG_GREEN="$FG_GREEN" '
        BEGIN { in_code=0 }
        /^```/ {
            if (in_code == 0) {
                in_code=1
                next
            } else {
                in_code=0
                next
            }
        }
        {
            if (in_code == 1) {
                print FG_GREEN $0 RESET
            } else {
                print $0
            }
        }
    ')

    # Remove lines that are just '---'
    input=$(echo "$input" | sed -E '/^[[:space:]]*---[[:space:]]*$/d')

    # handle headings
    # ###### and up (6 hashes)
    input=$(echo "$input" | sed -E "s/^[[:space:]]*######[[:space:]]+(.*)/$(ansi_bold)$(ansi_fg_cyan)$(ansi_inverse)  \1  $(ansi_no_inverse)$(ansi_fg_default)$(ansi_no_bold)/")
    # ##### (5 hashes)
    input=$(echo "$input" | sed -E "s/^[[:space:]]*#####[[:space:]]+(.*)/$(ansi_bold)$(ansi_fg_cyan)$(ansi_inverse)  \1  $(ansi_no_inverse)$(ansi_fg_default)$(ansi_no_bold)/")
    # #### (4 hashes)
    input=$(echo "$input" | sed -E "s/^[[:space:]]*####[[:space:]]+(.*)/$(ansi_bold)$(ansi_fg_cyan)$(ansi_inverse)  \1  $(ansi_no_inverse)$(ansi_fg_default)$(ansi_no_bold)/")

    # ### (3 hashes)
    input=$(echo "$input" | sed -E "s/^[[:space:]]*###[[:space:]]+(.*)/$(ansi_bold)$(ansi_underline)   \1   $(ansi_no_underline)$(ansi_no_bold)/")
    # ## (2 hashes)
    input=$(echo "$input" | sed -E "s/^[[:space:]]*##[[:space:]]+(.*)/$(ansi_bold)$(ansi_underline)   \1   $(ansi_no_underline)$(ansi_no_bold)/")
    # # (1 hash)
    input=$(echo "$input" | sed -E "s/^[[:space:]]*#[[:space:]]+(.*)/$(ansi_bold)$(ansi_underline)   \1   $(ansi_no_underline)$(ansi_no_bold)/")

    # Inline markdown:
    # Bold **text**
    input=$(echo "$input" | sed -E "s/\*\*([^*]+)\*\*/$(ansi_bold)\\1$(ansi_no_bold)/g")
    # Italic *text*
    input=$(echo "$input" | sed -E "s/\*([^*]+)\*/$(ansi_italic)\\1$(ansi_no_italic)/g")
    # Underline __text__
    input=$(echo "$input" | sed -E "s/__([^_]+)__/$(ansi_underline)\\1$(ansi_no_underline)/g")
    # Strikethrough ~~text~~
    input=$(echo "$input" | sed -E "s/~~([^~]+)~~/$(ansi_strikethrough)\\1$(ansi_no_strikethrough)/g")

    # Remove single quotes entirely
    input=$(echo "$input" | tr -d "'")

    echo "$input"
}



# Gets the best completion result from the OpenAI API and prints it.
# Arguments:
#   $1 - Model
#   $2 - Temperature
#   $3 - System message (optional)
#   $4 - Prompt
function get_best_result() {
    local model="$1"
    local temp="$2"
    local system_msg="$3"
    local user_prompt="$4"
    local messages
    if [ -n "$system_msg" ]; then
        messages=$(jq -n --arg sm "$system_msg" --arg pm "$user_prompt" \
        '{ "messages": [{"role": "system", "content": $sm}, {"role": "user", "content": $pm}] }')
    else
        messages=$(jq -n --arg pm "$user_prompt" \
        '{ "messages": [{"role": "user", "content": $pm}] }')
    fi
    local request
    request=$(echo "$messages" | jq --arg model "$model" --argjson temp "$temp" '. + {model: $model, temperature: $temp}')
    local response
    response=$(echo "$request" | curl -s https://api.openai.com/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d @-)
    local content
    content=$(echo "$response" | jq -r '.choices[0].message.content')
    # Parse the markdown and remove leftover markdown syntax
    echo "$content" | parse_markdown_to_ansi
}

# Main entry point of the script.
# Parses arguments, handles options, and calls the appropriate functions.
function main() {
    while getopts ":m:t:s:p:l" opt; do
        case "$opt" in
            m) MODEL="$OPTARG" ;;
            t) TEMPERATURE="$OPTARG" ;;
            s) SYSTEM_MSG="$OPTARG" ;;
            p) PROMPT="$OPTARG" ;;
            l) LIST_MODELS=true ;;
            \?)
                echo "Invalid option: -$OPTARG" >&2
                usage
                ;;
            :)
                echo "Option -$OPTARG requires an argument." >&2
                usage
                ;;
        esac
    done

    shift $((OPTIND - 1))

    # check if list models flag is set
    if [ "$LIST_MODELS" = true ]; then
        # call the get_models function and exit cleanly
        get_models
        exit 0
    fi
    

    # check if all options were parsed
    for arg in "$@"; do
        if [[ "$arg" == -* ]]; then
            echo "Error: Non-option arguments found before all options were parsed." >&2
            usage
        fi
    done
    # if prompt is not set use all arguments as the prompt. Aka: ./gpt.sh -t 0.5 -s "You are a helpful assistant" "What is the weather in Tokyo?"
    if [ -z "$PROMPT" ] && [ $# -gt 0 ]; then
        PROMPT="$*"
    fi
    # check if prompt is empty
    if [ -z "$PROMPT" ]; then
        echo "No prompt provided."
        usage
    fi

    get_best_result "$MODEL" "$TEMPERATURE" "$SYSTEM_MSG" "$PROMPT"
}

# Call main function
main "$@"
