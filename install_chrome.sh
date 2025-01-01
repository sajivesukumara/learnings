# Instructions to install Chrome Browser on Ubuntu
# Follow the instruction for installation with apt-key add:

# Add Key:

wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -

# Set repository:
echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' | sudo tee /etc/apt/sources.list.d/google-chrome.list

# Install package:

sudo apt-get update 
sudo apt-get install google-chrome-stable

# Open the chrome browser
google-chrome &
