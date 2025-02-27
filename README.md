# BashGPT 🤖

![BashGPT Logo](logo.png)

**Inspiration:**  
Ever been at the terminal, only to have the command slip your mind at the last minute? BashGPT is here to help! Instead of rummaging through cheat sheets or notes, simply ask a brief question straight from your terminal and get a detailed, accurate response. BashGPT interacts with OpenAI’s API to deliver real-time answers, formatted in beautifully rendered Markdown with ANSI colors for a clear and engaging reading experience.

---

## Features ✨

- **Direct API Query:** Interact with OpenAI's chat completions endpoint right from your terminal with lot's of room for customization as-per your needs and use cases.
- **Customizable Parameters:** Change models, temperature, system messages, and prompts on the fly.
- **Live Web Search:** Use the `-q` flag to perform a live web search that leverages ChatGPT’s new search tool capabilities; all from the comfort of your command line!
- **Documentation Helper:** Retrieve concise documentation/help using the `-d` flag, with detailed summaries, key insights, usage, and examples.
- **Interactive Chat Mode:** Enjoy a continuous chat session with context-aware conversation.
- **Markdown Parsing & Syntax Highlighting:** Automatically parse Markdown output, highlight code blocks, and transform headings and inline styles for enhanced readability.
- **Robust Error Handling:** Uses modern bash practices (`set -euo pipefail` and traps) to ensure reliability and clear error reporting.

---

## Prerequisites 📦

1. **OpenAI API Key:**  
First things first, sign up at [OpenAI (Playground)](https://platform.openai.com/) and set your API key environment variable as `OPENAI_API_KEY:

```bash
export OPENAI_API_KEY=sk.........
```
To make the environment variable persistent across reboots and different terminals, simply append the line to your default shell config file (`~/.bashrc`, `~/.zshrc`).

**Quick note on API Key security/Best Practices**

- Best practice is to put `export OPENAI_API_KEY=...` in its own file (`~/.openai_key`) with pemissions `600` so it's only accesible to the file owner to prevent it from unauthorized access/disclosure.
- Then, simply append a line that `source`'s the file at the bottom of your `~/.bashrc` OR `~/.zshrc` file. In other words, `source` works similarly to pythons `eval()` expression. So it's reading the file and evaluating `export OPENAI_API_KEY=....` to set the environment variable rather then leaving the API key hardcoded in the shell profile configs. It's not hugely different, however additional file attributes and permissions can help further secure the file from unauthorized access.

**Example:**

```bash
touch ~/.openai_key
echo 'export OPENAI_API_KEY=sk-........' >> ~/.openai_key
chmod 600 ~/.openai_key
echo 'source ~/.openai_key' >> ~/.zshrc # make sure this is the rc file of the default shell you have configured.
```

2. **Dependencies:**  
   - `curl`
   - `jq`
   - `bash` (tested on version 4.x and above)
   - Optionally, `pygmentize` for enhanced syntax highlighting.
   
On Debian/Ubuntu:

```bash
# you only need pip here to install pygmentize, the CLI interface to the Pygments python library used for syntax highlighting
sudo apt-get update -y && sudo apt-get install -y jq curl && sudo apt-get install python3-Pygments || pip install Pygments || sudo apt-get install python3-pip || pip install Pygments --break-system-packages. 
```

> Note: `--break-system-packages` isn't usually a very good idea, though it depends on what version of Linux/Windows your using. The one liner above works fine as intended, though it was more-so meant as a series of fail safe's and is quite overkill. 


---

## Installation & Setup 🔧

Clone the repository and set up the script:
```bash
git clone https://github.com/supasuge/bashgpt.git
cd bashgpt
chmod +x gpt.sh
# Symlink the script for global access:
sudo ln -s "$(pwd)/gpt.sh" /usr/local/bin/gpt
# Optionally: cp/mv the script to a globally accesible location
chmod +x bashgpt/gpt.sh && sudo mv bashgpt/gpt.sh /usr/local/bin/gpt 
```

Next, make sure you have the `OPENAI_API_KEY` environment variable set otherwise the script will throw an error:

Now the script should be good to go!

To use the script with the default values:

```bash
gpt "Hello, how are you today?"
```

---

## Usage 📖

```bash
$ gpt -h
Usage: gpt [options] [prompt]

Options:
  -m <model>           Set the model (default: gpt-4-turbo-2024-04-09)
  -t <temperature>     Set the temperature (default: 0.7) (range: 0 - 1.0)
  -s <system_message>  Set a system message (optional)
  -p <prompt>          Set the prompt explicitly
  -l                   List available models owned by "system"
  -i                   Interactive chat mode
  -q <query>           Search the web for information
  -d <topic>           Retrieve documentation/help. For CLI help, prefix topic with "cmd:" or "cli:"
  -h                   Display this help message

If -p is not provided, any remaining arguments are treated as the prompt.
```

### Examples

1. **Basic Prompt:**

```bash
gpt "What is the weather in Tokyo?"
```

2. **Custom Model & Temperature:**
```bash
gpt -m gpt-4o-mini -t 0.5 "Tell me a joke."
```

3. **Custom System Message:**
```bash
gpt -s "You are a helpful assistant" "How do I set up a Python virtual environment?"
```

4. **List Available Models:**
```bash
gpt -l
"omni-moderation-2024-09-26"
"gpt-4o-mini-audio-preview-2024-12-17"
"dall-e-3"
"dall-e-2"
"gpt-4o-audio-preview-2024-10-01"
"gpt-4o-audio-preview"
"gpt-4o-mini-realtime-preview-2024-12-17"
"gpt-4o-mini-realtime-preview"
"o1-mini-2024-09-12"
"o1-preview-2024-09-12"
"o1-mini"
> ...
[SNIP]
... <
"gpt-40-mini"
```

5. **Interactive Chat Mode:**
```bash
gpt -i
```

6. **Live Web Search:**
```bash
gpt -q "Latest academic news on cybersecurity and/or quantum computing"
```

7. **Documentation Help:**
 
This functionality is meant for quickly retrieving Code documentation from the internet via ChatGPT "Search" functionality in which it uses a preset custom system prompt to first fetch any relevant & recent documentation based on the topic specified, then a concise and detailed API spec is output along with brief explanations, key insights, usage examples, and more!

```bash
gpt -d "Python regex"
# Retrieving CLI documentation/easy interpretation of manpages with direct usage examples
gpt -d "cli: tr" # retrieves a detailed usage explanation  for the `tr` command.
# can also use "bash: "
```

8. General Web Search/Query

Searches the web utilizing ChatGPT's "Search" tool, and returns any relevant information summarized as best as possible. Best used for broad topics, vocab definitions, and other small tasks not requiring large amounts of technical detail. This is best thought of as a more "broad", generic search functionality similar to auto-generated wikipedia pages with accompanying sources.

---

## Changelog 📝

### Version 0.1.1 (2025-02-26)

**Enhanced Error Handling:**  
  - Implemented `set -euo pipefail` and an error trap for clearer debugging.
**Improved Markdown Parsing & Syntax Highlighting:**  
  - Modified `highlight_code()` to check for unrecognized language aliases and/or parsing failures then fall back to `"text"`.
  - Extended inline markdown styling and added handling for math/LaTeX formatting.
**New Web Search & Documentation Functions:**  
  - Added `get_best_result_with_search()` to enable search tool functionality via the `?hints=search` parameter.
  - Introduced `query()` for live web searches and `doc_help()` for specifically fetching official documentation help and providing concise summaries with only necessary information rather than reading through lengthy API documentation to find a single function/parameter definition.
**Interactive Chat Mode:**  
  - Streamlined the interactive chat experience with enhanced prompts and error feedback.
**Command-Line Options:**  
  - Added `-q` for web search queries.
  - Added `-d` for documentation help, alongside existing options.
**General Code Refinements:**  
  - Refactored functions for better readability and maintainability.
  - Updated default system prompt for improved clarity and detail.

## TODO 
- Add Groq API function's similarly to OpenAI's API functions to access a larger range of open-source models.
   - Add functionality to process .wav files, and a live chat mode.
   - Add functionality for various specific models with specialized use cases
- Add functionality to process image files to add to queries via the use of a vision/OCR model.
   - Should process image files dynamically so image's can be added to regular prompts similar to how you can do the same on the ChatGPT web interface.
 

---

## Contributing 🤝

Contributions are welcome! Please fork the repository, make your changes, and submit a pull request. For major changes, open an issue first to discuss what you would like to change.

---
