The problem I'm trying to solve is one where users complain about not having enough time or notice to install updates or reboot (or their computer auto reboots). I deploy updates as available for a few days before they're required, but I found that users wouldn't actually install updates until the deadline hit (and that's when I'd get complaints).

Instructions:
- Test the scripts & modify with your branding.
- Create a CI with the discovery and remediation scripts. Ensure it runs in the user context.
- Compliance is an integer value and it should return 0 to be compliant since it's looking for visible updates (Triggered by the "Display in Software Center" option in the deployment). If you have visible updates, that means we have something available or required.
- I deploy the notification on a schedule of every 8 hours to a computer collection that excludes certain machines (conference rooms/labs/classroom scenarios). Deploy it how it makes sense to in your own environment

What it does:
- Hooks into the CIM Instance of the CCM client and looks for software updates deployed to the client. It sorts these updates by deadline so we get the earliest deadline and can display a toast notification out to the user for exactly what updates are available or required to install. It works with anything that you set as visible to the user in Software Center (including Feature Updates deployed from SCCM).
- The toast displays all updates to the user, as well as reminds them for restarts after they've taken action to install updates. Clicking "Install Updates" takes them to the Software Center, dismiss dismisses the toast.

Limitations:
- Can't get rid of the "Windows Powershell" App ID displaying in the toast since we're using an existing registered app. I wanted to keep it easier for the average admin to modify and deploy without having to learn .NET/C#
- Toast doesn't go off screen unless the user clicks on it - In presentation mode this might be a concern, but PowerPoint typically presents on the secondary display unless you're in mirrored display mode so it would display to the presenter but not the audience.

I don't have hard data, but my patch compliance numbers before patch deadlines have improved greatly, and I don't get any more user compliants :)
