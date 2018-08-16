#! /bin/sh

# <codex>
# <abstract>Script to remove everything installed by the sample.</abstract>
# </codex>

# This uninstalls everything installed by the sample.  It's useful when testing to ensure that 
# you start from scratch.

sudo launchctl unload /Library/LaunchDaemons/com.cxy.PPTPVPN.HelpTool.plist
sudo rm /Library/LaunchDaemons/com.cxy.PPTPVPN.HelpTool.plist
sudo rm /Library/PrivilegedHelperTools/com.cxy.PPTPVPN.HelpTool

sudo security -q authorizationdb remove "com.cxy.PPTPVPN.HelpTool"

