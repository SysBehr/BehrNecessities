Update 7/20/2019: Changed AppID on the toast to "Software Center" instead of "Windows Powershell" for a better User Experience

Problem to solve:
- You deploy updates as available for a period of time to give users some leeway for installation before they're required... but users don't install updates until the deadline has passed. Complaints ensue as reboot timers kick in and force the reboot at an inopportune time for the user.
Disclaimer: this depends a fair bit on how you have your update deployments and maintenance windows configured.

Here's the default Software Center Notification for required deployments:

![logo](https://raw.githubusercontent.com/SysBehr/BehrNecessities/master/Images/DefaultNotifications.png "Software Center Notification")

Here's the toast notification that this script generates with branding for MMSMOA (with deadline):

![logo](https://raw.githubusercontent.com/SysBehr/BehrNecessities/master/Images/Toast_With_Logo.png "Branded Toast Notification")

Here's the toast notification that this script generates for required deployments (title switches to reboot notification):

![logo](https://raw.githubusercontent.com/SysBehr/BehrNecessities/master/Images/Toast_No_Logo.png "Default Toast Notification (no branding)")

Instructions:
- Test the scripts & modify with your branding.
- Create a CI with the discovery and remediation scripts. Ensure it runs in the user context.
- Compliance is an integer value and it should return 0 to be compliant since it's looking for visible updates (Triggered by the "Display in Software Center" option in the deployment). If you have visible updates, that means we have something available or required.
- I deploy the notification on a schedule of every 8 hours to a computer collection that excludes certain machines (conference rooms/labs/classroom scenarios). Deploy it how it makes sense to in your own environment

What it does:
- Hooks into the CIM Instance of the CCM client and looks for software updates deployed to the client. It sorts these updates by deadline so we get the earliest deadline and can display a toast notification out to the user for exactly what updates are available or required to install. It works with anything that you set as visible to the user in Software Center (including Feature Updates deployed from SCCM).
- The toast displays all updates to the user, as well as reminds them for restarts after they've taken action to install updates. Clicking "Install Updates" takes them to the Software Center, dismiss dismisses the toast.

Limitations:
- Toast doesn't go away unless the user clicks on it - In presentation mode, Focus Assist hides these notifications.
- User context GPO deployment flashes a powershell window briefly when launching the toast. Theoretically you can get around this with the runsilent.exe developed by onevinn: https://gallery.technet.microsoft.com/Web-Service-for-OS-93b6ecb8.

I don't have hard data, but my patch compliance numbers before patch deadlines have improved greatly, and I don't get any more user compliants :)
