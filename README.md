# opentofu-with-aws


### Install OpenTofu using Windows Powershell
```
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
```

Note down ${TOFU_PATH}.


### Gitbash Settings for OpenTofu
Install and Open Git Bash.

Check if you already have a .bashrc or .bash_profile file. You can do this by running the following commands:
```
ls -a ~
```
This will list all files in your home directory, including hidden files.
If you see either .bashrc or .bash_profile, open it with a text editor. If you don't see either file, you can create one by following command.
```
touch ~/.bashrc
```
Open the .bashrc or .bash_profile file with a text editor.
```
nano ~/.bashrc
```
Add the following line to the file, replacing the path with your actual path, Refer that noted ${TOFU_PATH}:
```
alias tofu='/c/Users/{Username}/AppData/Local/OpenTofu/tofu.exe'
```
Save and exit the text editor.
Restart Git Bash or run source ~/.bashrc to apply the changes to the current session.
```
source ~/.bashrc
```

Now, when you type tofu init in Git Bash, it should execute /usr/local/bin/opentofu.exe init. Keep in mind that Git Bash uses a Bash shell, so the syntax for defining aliases is different from PowerShell.

### Deploy Resources
Clone the Repository into your system. Open the Gitbash terminal from the directory 'aws-websocket-api-demo-with-opentofu'.
Enter the following commands in GitBash to deploy the resources using OpenTofu.

```
tofu init
tofu plan
tofu apply
```
### Test the Solution
Once resources are deployed and tested the solution is successful, delete the resources using the following command.
Open the newly created website by OpenTofu. URL for the website will be displayed as an output once the OpenTofu apply execution is completed successfully.
Enter your name in the ‘Name’ field and Submit.
Open the ‘Messenger Lambda’ in the AWS console and invoke the function with a message along with the name given on the website.
The provided message in the backend now will be displayed on the front-end website.

### Delete Resources
Once resources are deployed and tested the solution is successful, delete the resources using the following command.
```
tofu destroy
```
