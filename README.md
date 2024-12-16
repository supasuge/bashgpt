# BashGPT

**Inspiration:** We've all been in the place at some point in our life sitting at the terminal/command line and suddenly the command we plan to execute suddenly just slips from your conciousness and you can't remember it to save your life all the sudden. This has happened to me many times before, and instead of turning to google, offline cheat sheets, or notes, it can be nice at times to simply ask a brief question straight from the terminal and receive a detailed and accurate response.

`gpt.sh` is a simple bash script that interacts with the OpenAI API to provide quick and easy command-line access to various OpenAI models. It can parse Markdown output and display it with ANSI colors, making the results more readable from the terminal without getting cluttered from the un-rendered markdown text.

## Features

- Query OpenAI's chat completions endpoint directly from your terminal.
- Supports changing models, temperature, system messages, and prompts.
- Able to list available OpenAI models owned by `"system"`.
- Parses Markdown responses and colorizes code blocks, headings, and other Markdown formatting.

## Prerequisites

1. **OpenAI API Key:**  
   You must have a valid OpenAI API key. Sign up at [OpenAI](https://platform.openai.com/) if you don't have one.
   
2. **Dependencies:**  
   - `curl`  
   - `jq`  
   - `bash` (tested on `bash` 4.x and above)
   
   Most Linux distributions come with `bash` and `curl` pre-installed.  
   To install `jq` on Debian/Ubuntu:

```bash
sudo apt-get update -y && sudo apt-get uprade -y && sudo apt-get install -y jq
```

3. **Environment**

```bash
export OPENAI_API_KEY=your_api_key
```

Make it a permanent environment variable by adding the following to the bottom of your `.bashrc` or `.zshrc` file:

```bash
export OPENAI_API_KEY=your_api_key
```

Then, run:

```bash
source ~/.zshrc
# OR
source ~/.bashrc
```

Now it should refresh and you should be good to go!

4. **Install**

```bash
git clone https://github.com/supasuge/bashgpt.git
cd bashgpt
# make it executable
chmod +x gpt.sh
# symlink to a directory from PATH sot he script can be accessed globally. 
ln -s bashgpt/gpt.sh /usr/bin/gpt # Creates a symlink to the gpt.sh script in /usr/bin
# Optionally copy to another common location in PATH.
sudo cp bashgpt/gpt.sh /usr/local/bin/gpt
```

Now, you'll be able to use the `gpt` command in your terminal globally:

```bash
gpt "Hello, how are you today chatgpt4o-latest?"
```

5. **Usage**

```bash
$ gpt -h
Usage: gpt [-m <model>] [-t <temperature>] [-s <system_message>] [-p <prompt>] [-l] [prompt]

Options:
  -m <model>          Set the model (default: gpt-4-turbo-2024-04-09)
  -t <temperature>    Set the temperature (default: 0.7)
  -s <system_message> Set a system message (optional)
  -p <prompt>         Set the prompt explicitly
  -l                  List available models owned by "system"

If -p is not provided, any remaining arguments after the options are considered the prompt.
```

1. Basic Prompt

```bash
gpt "Hello, how are you today chatgpt4o-latest?"
```
2. Specify Model and Temperature

```bash
gpt -m gpt-4o-mini -t 0.5 "Hello, how are you today chatgpt4o-mini?"
```

3. Set a custom System Message
```bash
gpt -s "You are a helpful assistant" "Hello, how are you today chatgpt4o-mini?"
```

4. List Available Models

```bash
$ gpt -l

"o1-mini-2024-09-12"
"dall-e-2"
"gpt-4o"
"gpt-4-1106-preview"
"gpt-3.5-turbo-instruct"
"babbage-002"
"davinci-002"
"dall-e-3"
"gpt-4o-realtime-preview-2024-10-01"
"text-embedding-3-small"
"gpt-4-0125-preview"
"gpt-4o-realtime-preview"
"gpt-4-turbo-preview"
"gpt-4o-2024-08-06"
"omni-moderation-latest"
"gpt-4o-2024-05-13"
"omni-moderation-2024-09-26"
"tts-1-hd-1106"
"chatgpt-4o-latest"
"o1-mini"
"gpt-3.5-turbo-0125"
"o1-preview"
"gpt-4o-2024-11-20"
"o1-preview-2024-09-12"
"gpt-4-turbo"
"tts-1-hd"
"gpt-4-turbo-2024-04-09"
"gpt-3.5-turbo-1106"
"gpt-4o-audio-preview"
"gpt-4o-audio-preview-2024-10-01"
"tts-1-1106"
"gpt-3.5-turbo-instruct-0914"
"text-embedding-3-large"
"gpt-4o-mini-2024-07-18"
"gpt-4o-mini"
```

Feel free to make a pull request and add/change anything! 

---

