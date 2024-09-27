
# TranscribeCLI - The Seamless Audio-to-Text Whisperer

## Table of Contents

- Introduction
- Features
- Requirements
- Installation
- Usage
- Options
- Configuration
- Examples
- Troubleshooting
- License

## Introduction

TranscribeCLI is a simple and powerful utility for converting audio files into text, allowing you to seamlessly transcribe .m4a audio files into .wav and process them using OpenAI's Whisper ASR model. This tool is designed to be cross-platform and user-friendly, providing flexible options to suit various use cases.

## My Use Case

I prefer to listen attentively in class and take notes myself, rather than just record everything verbatim. But sometimes, things slip through, or I just want to revisit something later to reinforce what I learned. That’s where TranscribeCLI comes in handy.

I record notes or lectures on my phone, Airdrop them to my laptop, and then run this script. The audio is quickly converted to text, so if I’ve forgotten anything or need to go over certain details again, the transcript is ready for me to work with. This way, I can focus on understanding in class and use the transcripts as a backup to ensure I don’t miss any important points.

## **Table of Contents**

- [Introduction](#introduction)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Options](#options)
- [Configuration](#configuration)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)
- [License](#license)

## **Introduction**

TranscribeCLI is a simple and powerful utility for converting audio files into text, allowing you to seamlessly transcribe `.m4a` audio files into `.wav` and process them using OpenAI's Whisper ASR model. This tool is designed to be cross-platform and user-friendly, providing flexible options to suit various use cases.

## **Features**

- **Automatic Audio Conversion**: Converts `.m4a` files to `.wav` format with ease.
- **OpenAI Whisper Integration**: Transcribes audio files to text using Whisper, supporting quick speech-to-text conversion.
- **Cross-Platform Support**: Runs on both Linux and macOS, with smart detection for OS-specific configurations.
- **Easy Setup**: Automatically downloads required binaries (`ffmpeg`, `ffprobe`, and Whisper) as needed.
- **Symbolic Linking**: Provides an option to make the script accessible system-wide without hardcoding paths.
- **Customizable Downloads Folder**: Choose your preferred directory for storing audio files.

## **Requirements**

Before using TranscribeCLI, ensure that the following build dependencies are installed:

- **`git`**: For cloning the Whisper repository.
- **`make`**: For building the Whisper executable.
- **`gcc` and `g++`**: Required C and C++ compilers for building.

### **Installing Dependencies**

#### **Ubuntu/Debian**

```bash
sudo apt update
sudo apt install -y build-essential git
```

#### **macOS**

1. **Install Xcode Command Line Tools**:

```bash
xcode-select --install
```

2. **Install Homebrew (if not installed)**:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

3. **Install Make and GCC**:

```bash
brew install make gcc
```

## **Installation**

### **Step 1: Clone the Repository**

```bash
git clone https://github.com/yourusername/TranscribeCLI.git
cd TranscribeCLI
```

### **Step 2: Make the Script Globally Accessible (Optional)**

To make the `transcribe.sh` script available globally, create a symbolic link in `/usr/local/bin`:

```bash
./transcribe.sh -p
```

## **Usage**

To use TranscribeCLI, simply run the `transcribe.sh` script with the desired option:

```bash
./transcribe.sh [option]
```

## **Options**

- **`-a`**: Convert all `.m4a` files in the Downloads folder to `.wav`.
- **`-c`**: Transcribe all `.wav` files using the Whisper model and output transcriptions as `.txt`.
- **`-w`**: Convert `.m4a` files to `.wav` and then transcribe them.
- **`-p`**: Create a symbolic link to make the script accessible from anywhere in your system.
- **`-h`**: Display the help message and exit.

## **Configuration**

### **Custom Downloads Folder**

The default location for audio files is `~/Downloads`. You can customize this by setting the `DOWNLOADS_FOLDER` environment variable:

```bash
DOWNLOADS_FOLDER="/path/to/your/folder" ./transcribe.sh -w
```

### **Setting Up a Symbolic Link for Global Access**

After running `./transcribe.sh -p`, the script will be accessible from any directory:

```bash
transcribe -a
```

If you encounter a "command not found" error, ensure `/usr/local/bin` is included in your `PATH` by adding the following line to your shell configuration file (e.g., `.bashrc` or `.zshrc`):

```bash
export PATH="/usr/local/bin:$PATH"
```

Restart your terminal or source the configuration file:

```bash
source ~/.bashrc   # For bash users
source ~/.zshrc    # For zsh users
```

## **Examples**

### **Convert `.m4a` Files to `.wav`**

```bash
transcribe -a
```

Converts all `.m4a` files in the `~/Downloads` folder to `.wav` format.

### **Transcribe `.wav` Files**

```bash
transcribe -c
```

Processes all `.wav` files in the `~/Downloads` folder using the Whisper model and generates `.txt` transcriptions.

### **Convert and Transcribe in One Step**

```bash
transcribe -w
```

Converts `.m4a` files to `.wav` and then transcribes them into text.

## **Troubleshooting**

### **Build Issues for Whisper Executable**

If the script prompts you to download and build `whisper.cpp`, but the build fails, try the following:

1. **Check Dependencies**: Ensure `git`, `make`, `gcc`, and `g++` are installed.
2. **Permission Issues**: Ensure write permissions for the directories being used. Use `sudo` if necessary.
3. **Manual Build**: If the automated build fails, manually clone and build the `whisper.cpp` repository:
   ```bash
   git clone https://github.com/ggerganov/whisper.cpp.git
   cd whisper.cpp
   make
   ```
   Move the `main` executable to the project directory:
   ```bash
   mv main ../TranscribeCLI/
   ```

### **ffmpeg Issues**

If `ffmpeg` and `ffprobe` are not found:

- Confirm with `y` when prompted by the script to download these binaries.
- If the download fails, manually download `ffmpeg` from [here](https://johnvansickle.com/ffmpeg/).

## **License**

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
