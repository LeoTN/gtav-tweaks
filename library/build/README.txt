**********IMPORTANT**********

Thank you for downloading GTAV Tweaks!

You can either execute the setup excutable or run the application directly.
I recommend choosing the first option, in case you have just downloaded the installer archive.

You might encounter a Windows Defender message. This is because I did not buy a digital certificate. Feel free to continue at your own risk...

Just kidding, there's nothing wrong with this software. Or is it?


**********GOOD TO KNOW**********

You can customize the hotkeys in the config file along with many other things. It is always located in a folder called "GTAV_Tweaks" in the
same directory as the main script. To uninstall this script, just delete all files.


**********Recording Macros FAQ**********

1. Why is this script even using "complicated" macros?
-> Originally the actions, such as depositing cash, were going to be hardcoded. This worked well on some systems but failed miserably on others. This was likely due to different resolutions,
other settings and / or different environments. By letting the user create their own macro, we eliminate these issues for the most part.

2. Where are my macro files saved?
-> The macro files are saved in the "GTAV_Tweaks" folder in a subfolder called "macros". The "GTAV_Tweaks" folder is always in the same directory as the GTAV_Tweaks executable.

3. How can I transfer GTAV Tweaks macros?
-> You just have to copy / move the file(s) inside the folder mentioned above into the target macro folder. Make sure to not rename the file(s).

4. My macro doesn't work correctly (inside the GTAV web browser)!
-> There are some limitations to this version of the self-made macro recorder:
1) This recorder can only record one key at a time. This means it is incapable of capturing key combinations, such as [Shift + A] etc.
2) It cannot capture mouse wheel movements (scrolling in the browser, for instance). You can work around this behavior and use the [Page Up] and [Page Down] keys for scrolling.
Alternatively you can click on the GTAV browser's search bar and enter the address directly. For example "www.maze-bank.com".
-> The second reason might be an incorrect delay between the key inputs. You can adjust the delay yourself. Be sure to read the 5th question, if you are planing to do so.

5. Why is my recorded macro slower than my original inputs?
-> GTAV is a bit weird, when it comes to registering key inputs from AutoHotkey. There seems to be a small period, after a key is sent, where further key inputs aren't registered.
To ensure that no inputs get lost, there is at least a 500 millisecond delay after each input, no matter how fast they were originally recorded. If you would like to speed up the macro,
you can achieve this by changing the values inside the Sleep() functions. These values are measured in milliseconds and specify the idle time after each key input.
MAKE SURE TO BACK UP YOUR FILE(S)! This CAN break your macro(s).

6. How do I open macro files?
-> The macro files are written in AutoHotkey. This means they can be opened with any text editor, for example notepad. To run them without GTAV Tweaks, you will need AutoHotkey installed.

7. My macro worked but now it isn't anymore!
-> The macros use the screen coordinates to move the mouse. If you change the resolution, the monitor or a setting which amplifies the screen coordinates,
you might have to record your macro again.


**********Creating Hotkeys FAQ**********

1. Why are there hotkeys already?
-> I thought this would be a good idea to include ready to use hotkeys for very useful actions such as creating a solo lobby for example.

2. Can I customize the built-in hotkeys?
-> Yes of course! I recommend keeping the name, because changing it would cause the script to load in a new instance. This happens because
the script checks the macro config file at every launch if all built-in hotkeys are present. For example: The built-in hotkeys are called
"1" and "2". If you rename "1" to let's say "one", you would end up with "one", "2" and "1" as your hotkeys.

3. Where are my hotkeys saved?
-> The macro configuration file is saved in the "GTAV_Tweaks" folder in a subfolder called "macros". The "GTAV_Tweaks" folder is always in the same directory as the GTAV_Tweaks executable.
You can also open the file under the [File] menu in the main window.

4. How do I create custom hotkeys?
-> When you launch the script, the first thing you should see is the main window. There will be a menu called [Hotkeys & Macros].
Clicking on it will open another window. On the bottom left you can find the button to create your own hotkeys.
From there on you will just have to fill in the values and confirm the creation. If the name and keyboard shortcut
aren't used by any other hotkey yet, you are ready.

5. My hotkey doesn't work!
-> This can be caused by multiple issues.
1. Note, that hotkeys are only enabled when GTA V is the active window (in the foreground). It takes 2 - 3 seconds for the script to realize this
and turn on the hotkeys when switching applications fast.
2. Your recorded macro file is broken. You might have to fix the file manually or record a new one. I will try to improve the macro recorder to avoid those issues from time to time.
3. You have other hotkey or macro programs installed using the same keyboard shortcut already. In this case, the corresponding program sort of "captures" the key
and does not redirect it to this script.


**********END**********

If you have any issues or you would like to submit a feature, you can do this here (https://github.com/LeoTN/gtav-tweaks/issues).