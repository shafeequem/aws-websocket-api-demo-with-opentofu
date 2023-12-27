# opentofu-with-aws


# open powershell and enter following commands
$TOFU_VERSION="1.6.0-alpha2"
$TARGET=Join-Path $env:LOCALAPPDATA OpenTofu
New-Item -ItemType Directory -Path $TARGET
Push-Location $TARGET
Invoke-WebRequest -Uri "https://github.com/opentofu/opentofu/releases/download/v${TOFU_VERSION}/tofu_${TOFU_VERSION}_windows_amd64.zip" -OutFile "tofu_${TOFU_VERSION}_windows_amd64.zip"
Expand-Archive "tofu_${TOFU_VERSION}_windows_amd64.zip" -DestinationPath $TARGET
Remove-Item "tofu_${TOFU_VERSION}_windows_amd64.zip"
$TOFU_PATH=Join-Path $TARGET tofu.exe
Pop-Location
echo "OpenTofu is now available at ${TOFU_PATH}. Please add it to your path for easier access."


Note down ${TOFU_PATH}.


# Gitbash settings
Open Git Bash.

Check if you already have a .bashrc or .bash_profile file. You can do this by running the following commands:

ls -a ~
# This will list all files in your home directory, including hidden files.
# If you see either .bashrc or .bash_profile, open it with a text editor. If you don't see either file, you can create one. For example:

touch ~/.bashrc
# Open the .bashrc or .bash_profile file with a text editor. For example:

nano ~/.bashrc
# Add the following line to the file, replacing the path with your actual path, Refer that noted ${TOFU_PATH}:

alias tofu='/c/Users/{Username}/AppData/Local/OpenTofu/tofu.exe'
# Save and exit the text editor.

# Restart Git Bash or run source ~/.bashrc to apply the changes to the current session.

Now, when you type tofu init in Git Bash, it should execute /usr/local/bin/opentofu.exe init. Keep in mind that Git Bash uses a Bash shell, so the syntax for defining aliases is different from PowerShell.