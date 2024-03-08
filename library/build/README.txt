**********IMPORTANT**********

Thank you for downloading GTAV Tweaks!

You might encounter a Windows Defender message. This is because I did not buy a digital certificate. Feel free to continue at your own risk...

Just kidding, there's nothing wrong with this software. Or is it?


**********GOOD TO KNOW**********

You can customize the hotkeys in the config file along with many other things. It is always located in a folder called "GTAV_Tweaks" in the
same directory as the main script.


**********Recording Macros FAQ**********

1. Where are my macro files saved?
-> The macro files are saved in the "GTAV_Tweaks" folder in a subfolder called "macros". The "GTAV_Tweaks" folder is always in the same directory as the GTAV_Tweaks executable.

2. How can I transfer GTAV Tweaks macros?
-> You just have to copy / move the file(s) inside the folder mentioned above into the target macro folder. Make sure to not rename the file(s).

3. My macro doesn't work correctly (inside the GTAV web browser)!
-> There are some limitations to this version of the self-made macro recorder:
1) This recorder can only record one key at a time. This means it is incapable of capturing key combinations, such as [Shift + A] etc.
2) It cannot capture mouse wheel movements (scrolling in the browser, for instance). You can work around this behavior and use the [Page Up] and [Page Down] keys for scrolling.
Alternatively you can click on the GTAV browser's search bar and enter the address directly. For example "www.maze-bank.com".
-> The second reason might be an incorrect delay between the key inputs. You can adjust the delay yourself. Be sure to read the 4th question, if you are planing to do so.

4. Why is my recorded macro slower than my original inputs?
-> GTAV is a bit weird, when it comes to registering key inputs from AutoHotkey. There seems to be a small period, after a key is sent, where further key inputs aren't registered.
To ensure that no inputs get lost, there is at least a 800 millisecond delay after each input, no matter how fast they were originally recorded. If you would like to speed up the macro,
you can achieve this by changing the values inside the Sleep() functions. These values are measured in milliseconds and specify the idle time after each key input.
MAKE SURE TO BACK UP YOUR FILE(S)! This CAN break your macro(s).

5. How do I open macro files?
-> The macro files are written in AutoHotkey. This means they can be opened with any text editor, for example notepad. To run them without GTAV Tweaks, you will need AutoHotkey installed.

6. My macro worked but now it isn't anymore!
-> The macros use the screen coordinates to move the mouse. If you change the resolution, the monitor or a setting which amplifies the screen coordinates,
you might have to record your macro again.


**********END**********

If you have any issues or you would like to submit a feature, you can do this here (https://github.com/LeoTN/gtav-tweaks/issues).