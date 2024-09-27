#!/bin/bash
# TranscribeCLI - The Seamless Audio-to-Text Whisperer
# A user-friendly CLI tool to convert .m4a audio files to .wav and transcribe them to text using OpenAI's Whisper ASR model.

# Get the real directory of the script to use as a base for relative paths
if [[ "$(uname)" == "Darwin" ]]; then
  # macOS doesn't support readlink -f, so use alternative
  script_dir="$(cd "$(dirname "$(readlink "${BASH_SOURCE[0]}")")" && pwd)"
else
  # Linux and other systems
  script_dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
fi

# Default path to Downloads folder (users can customize this)
downloads_folder="$HOME/Downloads"

# Paths to the Whisper model and executable (relative to the script's directory)
whisper_model="$script_dir/models/ggml-small.bin"
whisper_executable="$script_dir/main"
whisper_repo_url="https://github.com/ggerganov/whisper.cpp.git"

# Directory to store downloaded binaries (relative to the script's directory)
bin_folder="$script_dir/whisper-tools"
ffmpeg="$bin_folder/ffmpeg"
ffprobe="$bin_folder/ffprobe"

# URLs for precompiled binaries (example for Linux x86_64)
ffmpeg_url="https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz"
whisper_model_url="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/models/ggml-small.bin"

# Function to detect operating system
detect_os() {
  os_type="$(uname)"
  echo "$os_type"
}

# Function to check for build dependencies
check_build_dependencies() {
  missing_deps=()
  for cmd in git make gcc g++; do
    if ! command -v "$cmd" &> /dev/null; then
      missing_deps+=("$cmd")
    fi
  done

  if [[ ${#missing_deps[@]} -gt 0 ]]; then
    echo "The following build dependencies are missing: ${missing_deps[*]}"
    echo "Please install them before proceeding."
    exit 1
  fi
}

# Function to download and build Whisper executable
download_whisper_executable() {
  echo "Whisper executable not found. Do you wish to download and build whisper.cpp? (y/n)"
  read -r response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    check_build_dependencies

    echo "Cloning whisper.cpp repository..."
    git clone --depth 1 "$whisper_repo_url" "$script_dir/whisper.cpp"

    echo "Building Whisper executable..."
    cd "$script_dir/whisper.cpp" || { echo "Failed to enter directory $script_dir/whisper.cpp"; exit 1; }
    if make; then
      echo "Whisper executable built successfully."
    else
      echo "Failed to build whisper.cpp. Please check for errors above and ensure all dependencies are installed."
      exit 1
    fi

    # Move the main executable to the script directory
    mv "$script_dir/whisper.cpp/main" "$script_dir/" || { echo "Failed to move the executable to $script_dir"; exit 1; }

    # Ensure the executable has the correct permissions
    chmod +x "$whisper_executable"

    echo "Whisper executable built and moved to $script_dir."
  else
    echo "Whisper executable is required to proceed. Please build it manually or ensure it's in the specified location."
    exit 1
  fi
}

# Function to download ffmpeg and ffprobe
download_binaries() {
  mkdir -p "$bin_folder"

  echo "ffmpeg and/or ffprobe not found. Do you wish to download them? (y/n)"
  read -r response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "Downloading ffmpeg and ffprobe..."
    curl -L "$ffmpeg_url" -o "$bin_folder/ffmpeg.tar.xz"
    tar -xf "$bin_folder/ffmpeg.tar.xz" -C "$bin_folder" --strip-components=1
    rm "$bin_folder/ffmpeg.tar.xz"
    chmod +x "$ffmpeg" "$ffprobe"
    echo "ffmpeg and ffprobe have been downloaded to $bin_folder."
  else
    echo "Dependencies are not met. Please install ffmpeg and ffprobe manually."
    exit 1
  fi
}

# Function to download the Whisper model
prompt_model_download() {
  if [[ ! -f "$whisper_model" ]]; then
    echo "Whisper model not found. Do you wish to download the 'small' model? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
      mkdir -p "$script_dir/models"
      echo "Downloading Whisper 'small' model..."
      curl -L "$whisper_model_url" -o "$whisper_model"
      echo "Whisper 'small' model downloaded to $whisper_model."
    else
      echo "Model is required to proceed. Please provide a model in '$whisper_model'."
      exit 1
    fi
  fi
}

# Check if ffmpeg and ffprobe are installed globally or locally
check_dependencies() {
  if ! command -v ffmpeg &> /dev/null || ! command -v ffprobe &> /dev/null; then
    echo "ffmpeg and/or ffprobe not found globally, checking locally..."
    if [[ ! -f "$ffmpeg" || ! -f "$ffprobe" ]]; then
      echo "ffmpeg and/or ffprobe not found locally."
      download_binaries
    fi
  fi

  # Check and prompt for Whisper executable if not found
  if [[ ! -f "$whisper_executable" ]]; then
    download_whisper_executable
  fi

  # Prompt to download the Whisper model if not present
  prompt_model_download
}

# Function to add the script to the PATH
add_to_path() {
  target_dir="/usr/local/bin"
  script_name="transcribe"
  symlink_path="$target_dir/$script_name"

  echo "This will create a symbolic link to the script in your PATH at $symlink_path."
  echo "You may need to enter your password to grant permission."
  read -r -p "Proceed with creating the symbolic link? (y/n): " confirm

  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    # Remove any existing symlink to avoid conflicts
    if [[ -L "$symlink_path" ]]; then
      sudo rm "$symlink_path"
    fi

    # Create the symbolic link
    sudo ln -s "$script_dir/transcribe.sh" "$symlink_path"
    echo "The symbolic link has been created at $symlink_path."
    echo "You can now run the script with the command: $script_name"

    # Notify the user about PATH configuration
    echo "If the command is not found, ensure that /usr/local/bin is included in your PATH."
    echo "You can add the following line to your shell configuration file (e.g., .bashrc, .zshrc):"
    echo "export PATH=\"$target_dir:\$PATH\""
  else
    echo "Operation cancelled."
    exit 1
  fi
}

# Use local ffmpeg and ffprobe if installed
export PATH="$bin_folder:$PATH"

# Function to convert .m4a audio files to WAV
convert_audio() {
  for file in "$downloads_folder"/*.m4a; do
    if [[ -f "$file" ]]; then
      # Determine modification time and format date based on the OS
      if [[ "$(detect_os)" == "Darwin" ]]; then
        # macOS
        modification_time=$(stat -f %m "$file")
        modification_date=$(date -r "$modification_time" +"%Y-%m-%d_%H-%M-%S")
      else
        # Linux
        modification_time=$(stat -c %Y "$file")
        modification_date=$(date -d @"$modification_time" +"%Y-%m-%d_%H-%M-%S")
      fi

      duration=$("$ffprobe" -v error -show_entries format=duration -of default=nk=1:nw=1 "$file")
      duration_seconds=$(printf "%.0f" "$duration")
      duration_minutes=$((duration_seconds / 60))
      duration_seconds=$((duration_seconds % 60))
      duration_formatted=$(printf "%dm%ds" "$duration_minutes" "$duration_seconds")
      output_file_name="${modification_date}-${duration_formatted}.wav"
      output_path="$downloads_folder/$output_file_name"
      "$ffmpeg" -i "$file" -ar 16000 -ac 1 -c:a pcm_s16le "$output_path"
      echo "Converted '$file' to '$output_file_name'"
    fi
  done
}

# Function to process audio files with Whisper and output TXT files
process_with_whisper() {
  for file in "$downloads_folder"/*.wav; do
    if [[ -f "$file" ]]; then
      # Derive the TXT file name from the WAV file name
      base_name=$(basename "$file" .wav)
      txt_output_path="$downloads_folder/$base_name.txt"

      # Run Whisper and capture the output, saving it to a TXT file
      "$whisper_executable" -m "$whisper_model" -f "$file" > "$txt_output_path"

      # Print a message indicating the file has been processed
      echo "Processed '$file' with Whisper, output saved to '$txt_output_path'"
    fi
  done
}

# Function to display help menu
show_help() {
  echo "Usage: transcribe.sh [OPTION]"
  echo ""
  echo "A simple CLI for converting audio files to WAV format and processing them using Whisper."
  echo ""
  echo "Options:"
  echo "  -a      Convert .m4a files to .wav files."
  echo "  -c      Process .wav files with Whisper and output a .txt transcription."
  echo "  -w      Convert .m4a files to .wav, then process them with Whisper."
  echo "  -p      Add the script to the system's PATH."
  echo "  -h      Display this help and exit."
  echo ""
  echo "Examples:"
  echo "  transcribe.sh -a       Converts all .m4a files in the Downloads folder to .wav."
  echo "  transcribe.sh -c       Processes all .wav files with Whisper."
  echo "  transcribe.sh -w       Converts .m4a files to .wav, then runs Whisper."
  echo "  transcribe.sh -p       Adds the script to PATH for easier access."
  echo ""
  exit 0
}

# Parse command-line options
while getopts "acwhp" opt; do
  case $opt in
    a) action="convert";;
    c) action="whisper";;
    w) action="both";;
    p) action="add_path";;
    h) show_help;;
    \?) echo "Invalid option: -$OPTARG" >&2; exit 1;;
  esac
done

# If no options are provided, show help by default
if [[ -z "$action" ]]; then
  show_help
fi

# Check dependencies before proceeding
check_dependencies

# Perform the requested action
case $action in
  "convert") convert_audio;;
  "whisper") process_with_whisper;;
  "both")
    convert_audio
    process_with_whisper
    ;;
  "add_path") add_to_path;;
esac
