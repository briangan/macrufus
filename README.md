# About This Application

## Project Plan
The open-source Windows program [Rufus](https://rufus.ie/en/) is useful free tool to write some ISO image to a disk drive, for example, bootable Windows installation disc.  [Check Rufus' screenshot](rufus.01.png). Cannot find similar free tool in Mac OS.  Thus, this application is trying to simulate the basic functions of Rufus.  It's unusual for me to choose a desktop app, but I feel such disk utility is missing or unknown compared to vast library of utility programs in Windows during this multiple OS installation disks making.  Personally, I get blurry with side projects because not many inspirations and ideas of what to make.  This necessary utility would give me push to develop something.

The framework used is Swift UI within MacRufusSwift subfolder.  Since I have only little knowledge of Swift and desktop app programming, I started using Claude Sonnet 4.6 initially to generate and fix up the basic structure of the app, and amazingly those prompts alone ate up one month's premium request capacity.  So for further modifications, testing and debugging would need assistance.  I did installation of publicly open-source AI code-leaning models and server on my own Macbook Pro: Ollama, its own llama3.1:8b, qwen2.5-coder-7b, gemma4:2b, gemma4:4b, and nomic-embed-text.  I'm tied up with these smaller local models because to be developing and running local AI pretty much use up most of my MBP's memory.  I'm preparing my PC with mid-level video card to run AI better, so beginning of setup has been painful: replace privacy-stealing Windows 11 with fresh installation of Windows 10, a more trust-worthy OS that still works with most software.  Linux is installed on the other drive, but the latter is slower SSD and setup on Linux would take more time for another project.  Overall, it's cumbersome to use a large PC, especially now electricity rates and hardware prices are continuously being raised.

There's also consideration of using Electron framework to enforce cross-OS compatibility.  But the problem found so far really requires a pack of library and executives in large space size, compared to Mac-native version in small space size like less than 1 MB.  Maybe future AI conversion will help with head-start.

## Development So Far

* 2026-08-07: It's been a week of part-time work on a fresh framework.
  * The initial Claud-generated draft of the app was slim but was successful built and capable of showing the windows with title only.
  * Then I started experimenting with the syntax of Swift in comparison of the brief IOS framework I had learned in the past.  Swift is neat in its short and clean syntax.  Its data type restrictions can ensure the application running efficiently as well as giving me trouble to figure out what types to use where and when.
  * Local AI's performance has been acceptable.  Simple language or framework specific questions can be answered within tens of seconds with clarity.  
  * However, when the context of codes, its analysis can take a minute or two.  The UI of Copilot using local models definitely has difference: local AI's answer to prompt returns some JSON output, for example with keys of type, old_code, and new_code.  Thus the answer UI is not clean by requiring the user to click more to reach the answer, compared to GPT or Claude where explanation, returning questions and code suggestions with code comparisons are immediately displayed without need of extra user interactions.
  * The most basic front end components of the form is done: output drive, input image, format options, progress bar, submit button and popup alert.
  * Next is the actual backend: which commands and how options on front end would match with the commands' options.

==========================================

# Methods to Collect Device Information

## Mac OS Device Information

### Specifically find connected external devices even partitions mounted
```
diskutil list External
```

A sample of the output is logged in MacRufusSwift/mac_diskutil_list_External.log


### More detail of mounted storage drives using system_profile command

`system_profile -json` alone provides nested levels of system info with root-level category key values, for examples, "SPThunderboltDataType",  "SPStorageDataType".

To list out what are those root-level category keys, can run:
```
system_profiler -listDataTypes
```

So far, the follow obvious valid category keys representing storage devices:
```
system_profiler SPThunderboltDataType -json

system_profiler SPNVMeDataType -json
```

The samples of output are logged within MacRufusSwift: mac_system_profiler_SPNVMeDataType.json and mac_system_profiler_SPUSBHostDataType.json

=============================================

# TODOs

* Device name is missing in using `diskutil` to collect device info.
* Might have to try using `system_profiler` to collect
* Partition Options: partition scheme, target system
* Format Options section: file system, cluster size
* Status section: progress bar, status text
* Partitioning process
* Write image to drive, and update progress bar