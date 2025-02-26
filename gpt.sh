#!/bin/bash
# Author: [supasuge](https://github.com/supasuge) ~ Evan Pardon (Improved Version)
# Version: 0.1.1 (2025-02-26)

set -euo pipefail # exit immediately on a non-zero exit code, treat unset variables as an error, and catch errors piped commands
# Ensure that the OPENAI_API_KEY environment variable is set.
trap 'echo "Error on line ${LINENO}: command \"${BASH_COMMAND}\" exited with status $?" >&2' ERR
: "${OPENAI_API_KEY:?Please set OPENAI_API_KEY in your environment}"

# Default configuration variables
readonly MODEL="gpt-4o-2024-11-20"
readonly TEMPERATURE="0.7"
SYSTEM_MSG=""  # Will be updated in interactive mode if not set
PROMPT=""
LIST_MODELS=false
INTERACTIVE_MODE=false
SEARCH_QUERY=""
SEARCH_MODE=false
SEARCH_ENGINE_DEFAULT="google"
DOC_TOPIC=""
QUERY_MODE=""

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

readonly FG_GREEN=$(printf "\033[32m")
readonly FG_CYAN=$(printf "\033[36m")
readonly RESET=$(printf "\033[0m")

readonly DEFAULT_SYSTEM_PROMPT="You are an expert coding and CLI documentation specialist. Your role is to provide precise, detailed, and well-formatted explanations for code, CLI commands, and documentation queries. Provide complete examples when necessary and give maximum technical detail when possible while staying concise, to the point, yet easily understandable."


function usage() {
    cat <<EOF
Usage: $0 [options] [prompt]
Options:
  -m <model>           Set the model (default: $MODEL)
  -t <temperature>     Set the temperature (default: $TEMPERATURE)
  -s <system_message>  Set a system message (optional)
  -p <prompt>          Set the prompt explicitly
  -l                   List available models
  -i                   Interactive chat mode
  -d <topic>           Retrieve documentation/help
                       For command-line help, prefix topic with "cmd: " or "cli: "
  -q <query>           Search the web for information
  -h                   Display this help message
EOF
    exit 1
}

# Fetches a list of publicly available models
function get_models() {
    curl -s https://api.openai.com/v1/models \
      -H "Authorization: Bearer $OPENAI_API_KEY" | jq '.data[] | select(.owned_by == "system") | .id'
}

function highlight_code() {
    local code="$1"
    # Extract the first word of the code block as a potential language alias.
    local lang
    lang=$(echo "$code" | head -n 1 | awk '{print tolower($1)}')
    
    # Check if pygmentize recognizes this alias; if not, fall back to "text"
    if ! pygmentize -L lexers | grep -i -q "\b${lang}\b"; then
        lang="text"
    fi

    if command -v pygmentize >/dev/null 2>&1; then
        echo "$code" | pygmentize -l "$lang" -f terminal256 -O style=monokai
    else
        echo -e "${FG_GREEN}${code}${RESET}"
    fi
}

function parse_markdown_to_ansi() {
    local input
    input=$(cat)

    local in_code=0
    local code_buffer=""
    local lang=""

    while IFS= read -r line; do
        if [[ "$line" =~ ^\`\`\` ]]; then
            if [ $in_code -eq 0 ]; then
                in_code=1
                lang=$(echo "$line" | sed 's/```//g' | xargs)
                code_buffer=""
            else
                in_code=0
                if [ -n "$lang" ]; then
                    code_buffer="$lang\n$code_buffer"
                fi
                highlight_code "$code_buffer"
            fi
            continue
        fi

        if [ $in_code -eq 1 ]; then
            code_buffer+="$line"$'\n'
        else
            # Remove horizontal rules (---)
            if [[ "$line" =~ ^[[:space:]]*---[[:space:]]*$ ]]; then
                continue
            fi

            # Process headings (from ###### to #)
            if [[ "$line" =~ ^[[:space:]]*######[[:space:]]+(.*) ]]; then
                line="$(ansi_bold)$(ansi_fg_cyan)$(ansi_inverse)  ${BASH_REMATCH[1]}  $(ansi_no_inverse)$(ansi_fg_default)$(ansi_no_bold)"
            elif [[ "$line" =~ ^[[:space:]]*#####[[:space:]]+(.*) ]]; then
                line="$(ansi_bold)$(ansi_fg_cyan)$(ansi_inverse)  ${BASH_REMATCH[1]}  $(ansi_no_inverse)$(ansi_fg_default)$(ansi_no_bold)"
            elif [[ "$line" =~ ^[[:space:]]*####[[:space:]]+(.*) ]]; then
                line="$(ansi_bold)$(ansi_fg_cyan)$(ansi_inverse)  ${BASH_REMATCH[1]}  $(ansi_no_inverse)$(ansi_fg_default)$(ansi_no_bold)"
            elif [[ "$line" =~ ^[[:space:]]*###[[:space:]]+(.*) ]]; then
                line="$(ansi_bold)$(ansi_underline)   ${BASH_REMATCH[1]}   $(ansi_no_underline)$(ansi_no_bold)"
            elif [[ "$line" =~ ^[[:space:]]*##[[:space:]]+(.*) ]]; then
                line="$(ansi_bold)$(ansi_underline)   ${BASH_REMATCH[1]}   $(ansi_no_underline)$(ansi_no_bold)"
            elif [[ "$line" =~ ^[[:space:]]*#[[:space:]]+(.*) ]]; then
                line="$(ansi_bold)$(ansi_underline)   ${BASH_REMATCH[1]}   $(ansi_no_underline)$(ansi_no_bold)"
            fi

            # Inline markdown styling: Bold, Italic, Underline, Strikethrough and mathjax -> latex
            line=$(echo "$line" | sed -E "s/\*\*([^*]+)\*\*/$(ansi_bold)\1$(ansi_no_bold)/g")
            line=$(echo "$line" | sed -E "s/\*([^*]+)\*/$(ansi_italic)\1$(ansi_no_italic)/g")
            line=$(echo "$line" | sed -E "s/__([^_]+)__/$(ansi_underline)\1$(ansi_no_underline)/g")
            line=$(echo "$line" | sed -E "s/~~([^~]+)~~/$(ansi_strikethrough)\1$(ansi_no_strikethrough)/g")
            line=$(echo "$line" | sed -E 's/\\(\(|\))/\$\$/g; s/\\(\[|\])/\$/g')
            # Remove single quotes entirely
            line=$(echo "$line" | tr -d "'")
            echo -e "$line"
        fi
    done <<< "$input"
}

# Arguments:
#   $1 - Model
#   $2 - Temperature
#   $3 - System message (optional)
#   $4 - Prompt
# Usage: get_best_result "$MODEL" "$TEMPERATURE" "$SYSTEM_MSG" "$PROMPT"
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
    echo "$content" | parse_markdown_to_ansi
}

function interactive_chat() {
    # Enters the user into an interactive chat with the specified model and temperature if specified, otherwise uses the default.
    local sys_msg="${SYSTEM_MSG:-$DEFAULT_SYSTEM_PROMPT}"
    echo -e "$(ansi_bold)Interactive GPT Chat (Type 'exit' to quit)$(ansi_no_bold)"
    while true; do
        echo -en "$(ansi_fg_cyan)You > $(ansi_fg_default)"
        read -r user_input
        if [[ "$user_input" == "exit" ]]; then
            echo "Exiting interactive chat."
            break
        elif [[ -z "$user_input" ]]; then
            continue
        fi
        get_best_result "$MODEL" "$TEMPERATURE" "$sys_msg" "$user_input"
        echo ""  # Add spacing between messages
    done
}

# Gets the best result from the OpenAI API with the search tool enabled so the model can effectively search the web for relevant information and provide detailed, up-to-date, and accurate responses. The more specific the query, the better the results.
function get_best_result_with_search() {
    local model="$1" temp="$2" system_msg="$3" user_prompt="$4"
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
    # Append hints=search to prompt the model to use its search tool
    local response
    response=$(echo "$request" | curl -s "https://api.openai.com/v1/chat/completions?hints=search" \
         -H "Content-Type: application/json" \
         -H "Authorization: Bearer $OPENAI_API_KEY" \
         -d @-)
    local content
    content=$(echo "$response" | jq -r '.choices[0].message.content')
    echo "$content" | parse_markdown_to_ansi
}

# query() uses the search tool to fetch live, up-to-date information.
function query() {
    local search_query="$1"
    local prompt="You have access to the Web search tool. Please perform a live search for the following query and summarize the findings with citations and a detailed summary filled with examples, technical details, and any other relevant information; make sure to include any relevant information for code documentation and anything of that nature for maximum user benefit:\n\n\"$search_query\""
    get_best_result_with_search "$MODEL" "$TEMPERATURE" "$DEFAULT_SYSTEM_PROMPT" "$prompt"
}

# doc_help() retrieves documentation/help for a given topic using the web search tool.
function doc_help() {
    local topic="$1"
    local prompt="You have access to the Web search tool. Please search for the official documentation on '$topic' and provide a concise explanation, followed by a detailed summary with examples where possible, include any relevant information for code documentation and anything of that nature for maximum user benefit. Provide any and all relevant API information, syntax, usage, etc. in essence, you are an expert documentation specialist/progammer/developer/tutor and your job is to provide the best possible documentation and information to use on the fly that is relevant to the user's query and intentions."
    get_best_result_with_search "$MODEL" "$TEMPERATURE" "$DEFAULT_SYSTEM_PROMPT" "$prompt"
}

# Main entry point
function main() {
    while getopts ":m:t:s:p:liq:d:" opt; do
        case "$opt" in
            m) MODEL="$OPTARG" ;;  # For custom model (override default)
            t) TEMPERATURE="$OPTARG" ;; # 0.0 - 1.0 (Default: 0.7)
            s) SYSTEM_MSG="$OPTARG" ;; # Custom system message (optional)
            p) PROMPT="$OPTARG" ;; # Explicit prompt (optional)
            l) LIST_MODELS=true ;; # List available models (optional, default is false, can only be ran on it's own before exiting)
            i) INTERACTIVE_MODE=true ;; # Interactive chat mode (optional, default is false, can only be ran on it's own before exiting)
            q) QUERY_MODE="$OPTARG" ;; # Search the web for information (optional, default is false, can only be ran on it's own before exiting)
            d) DOC_TOPIC="$OPTARG" ;; # Retrieve documentation/help (optional, default is false, can only be ran on it's own before exiting)
            h) usage ;; # Display usage instructions
            \?)
                echo "Invalid option: -$OPTARG" >&2 # You done goofed. Think about what you have done.
                usage
                ;;
            :)
                echo "Option -$OPTARG requires an argument." >&2 # You done goofed. Think about what you have done.
                usage
                ;;
        esac
    done
    shift $((OPTIND - 1))

    if [ "$LIST_MODELS" = true ]; then
        get_models
        exit 0
    fi

    if [ "$INTERACTIVE_MODE" = true ]; then
        interactive_chat
        exit 0
    fi

    if [ -n "$QUERY_MODE" ]; then
        query "$QUERY_MODE"
        exit 0
    fi

    if [ -n "$DOC_TOPIC" ]; then
        doc_help "$DOC_TOPIC"
        exit 0
    fi

    # If prompt is not set, use remaining arguments as prompt.
    # this just means it will treat any preceding arguments following the flags provided as the prompt if -p <prompt> isn't explicitly set.
    if [ -z "$PROMPT" ] && [ $# -gt 0 ]; then
        PROMPT="$*"
    fi

    if [ -z "$PROMPT" ]; then
        echo "No prompt provided." >&2 # You done goofed. Think about what you have done.
        usage
    fi

    if [ -z "$SYSTEM_MSG" ]; then
        SYSTEM_MSG="$DEFAULT_SYSTEM_PROMPT"
    fi

    get_best_result "$MODEL" "$TEMPERATURE" "$SYSTEM_MSG" "$PROMPT"
}

main "$@"
