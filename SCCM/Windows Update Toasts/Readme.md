Instructions:
- Test the scripts & modify with your branding.
- Create a CI with the discovery and remediation scripts. Ensure it runs in the user context.
- Compliance is an integer value and it should return 0 to be compliant since it's looking for visible updates (Triggered by the "Display in Software Center" option in the deployment). If you have visible updates, that means we have something available or required.


What it does:
- Hooks into the CIM Instance of the CCM client and looks for software updates deployed to the client. It sorts these updates by deadline so we get the earliest deadline and can display a toat notification out to the user for exactly what updates are available or required to install. It works with anything that you set as visible to the user in Software Center (including Feature Updates deployed from SCCM).

