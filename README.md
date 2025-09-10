# Binary Verifier

A security tool for verifying binary signatures and calculating checksums on macOS systems.

## Features

- Verifies code signatures using macOS `codesign` utility
- Calculates SHA-256 checksums for all executable files
- Supports multiple output formats (text and JSON)
- Configurable logging and quiet modes
- Scans multiple directories simultaneously

## Installation

### Using Homebrew (Recommended)

```bash
# Add the tap
brew tap perryjr1444-ux/binary-verifier

# Install the tool
brew install binary-verifier
```

### Manual Installation

```bash
# Clone the repository
git clone https://github.com/perryjr1444-ux/binary-verifier.git
cd binary-verifier

# Make the script executable
chmod +x binary-verifier.sh

# Move to a directory in your PATH
sudo mv binary-verifier.sh /usr/local/bin/binary-verifier
```

## Usage

```bash
# Basic usage (scans /usr/local/bin by default)
sudo binary-verifier

# Scan specific directories
sudo binary-verifier /usr/bin /opt/bin

# Output in JSON format
sudo binary-verifier --json

# Quiet mode (log only)
sudo binary-verifier --quiet

# Custom log file
sudo binary-verifier --log /path/to/custom.log

# Show help
binary-verifier --help
```

## Options

- `-l, --log <file>`: Set custom log file (default: binary_verification.log)
- `-j, --json`: Output results in JSON format
- `-q, --quiet`: Suppress terminal output (log only)
- `-h, --help`: Show help message

## Output

The tool generates detailed reports including:
- File paths
- Code signature status (Signed/Not signed or invalid)
- SHA-256 checksums
- Timestamps and scan metadata

## Requirements

- macOS (uses `codesign` utility)
- Root privileges (required for scanning system directories)
- Bash 4.0 or later

## Security Note

This tool requires elevated privileges to scan system directories and verify code signatures. Always review the source code before running with sudo.

## License

MIT License - see LICENSE file for details.