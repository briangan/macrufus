# About This Application

## Project Plan
The open-source Windows program [Rufus](https://rufus.ie/en/) is useful free tool to write some ISO image to a disk drive, for example, bootable Windows installation disc.  [Check Rufus' screenshot](rufus.01.png). Cannot find similar free tool in Mac OS.  Thus, this application is trying to simulate the basic functions of Rufus.  It's unusual for me to choose a desktop app, but I feel such disk utility is missing or unknown compared to vast library of utility programs in Windows during this multiple OS installation disks making.  Personally, I get blurry with side projects because not many inspirations and ideas of what to make.  This necessary utility would give me push to develop something.

The framework used is Swift UI within MacRufusSwift subfolder.  Since I have only little knowledge of Swift and desktop app programming, I started using Claude Sonnet 4.6 initially to generate and fix up the basic structure of the app, and amazingly those prompts alone ate up one month's premium request capacity.  So for further modifications, testing and debugging would need assistance. 

There's also consideration of using Electron framework to enforce cross-OS compatibility.  But the problem found so far really requires a pack of library and executives in large space size, compared to Mac-native version in small space size like less than 1 MB.  Maybe future AI conversion will help with head-start.

## Development So Far

* __2026-08-13__: 
  * After last week's UI work, this week has been tougher because of backend obstacles when working on this part-time.
  * The main obstacle is running the image writing in background internally while still able to capture its continuous progress stats for conversion into UI's progress bar and stats.
  * AI responses to prompts for the above are just either incomplete or unstable.  Rather, I have to search online for postings and answers to this topic.
  * After a few trials, at least I found the convenient stable Swift library [Subprocess](https://swiftpackageindex.com/swiftlang/swift-subprocess#readme) to run command with clean code and enough call backs for execution status change and output pipes.
  * But because DD or my simulated script re-renders the same line for stat updates, output streaming just does not recognize new lines, which is the trigger for realizing new content and proceeding to capture that.  Need some workaround.

* __2026-08-07__: 
  * It's been a week of part-time work on a fresh framework.
  * The initial Claud-generated draft of the app was slim but was successful built and capable of showing the window with title only.
  * Then I started experimenting with the syntax of Swift in comparison of the brief IOS framework I had learned in the past.  Swift is neat in its short and clean syntax.  Its data type restrictions can ensure the application running efficiently as well as giving me trouble to figure out what types to use where and when.
  * Local AI's performance has been acceptable.  Simple language or framework specific questions can be answered within tens of seconds with clarity.  
  * However, when the context of codes, its analysis can take a minute or two.  The UI of Copilot using local models definitely has difference: local AI's answer to prompt returns some JSON output, for example with keys of type, old_code, and new_code.  Thus the answer UI is not clean by requiring the user to click more to reach the answer, compared to GPT or Claude where explanation, returning questions and code suggestions with code comparisons are immediately displayed without need of extra user interactions.
  * The most basic front end components of the form is done: output drive, input image, format options, progress bar, submit button and popup alert.
  * Next is the actual backend: which commands and how options on front end would match with the commands' options.

## Swift Language and Mac OS Libraries

### Syntax 

* I haven't officialy gone into learning Swift syntax.
* Swift's syntax is quite unique.  The casing of data type, functions, classes and file names are based on camel style.
* The syntax style of classes and functions is similar to other languages like Java.
* While for years have be spoiled by interpreted languages like Ruby and Python, this is back to restrictive, precise specification of data types, which is painful.  The compiler no way would let you make a statement without proper conversion to the correct data type matching the other side.  Luckily the autocomplete feature of Swift in the IDE has been helpful to suggestion of correct data type specifications matching the variables and the library's actual function definitions.  The IDE can underline suspected wrong data type before build.
* The definition of functions is where it gets the most messy.  Because of the camel style squishing words into one, any long name cannot be quickly readable into mind.  Every argument of the function needs data type specified along, and as well as return type.  But arguments can be optional like in a hash of keys and values and values can be given default values.  All together makes a long function definition so crowded.
* The block syntax is the most confusing.  The block's internal variable can end up right after braces in weird way like "addToTotal(){ current_balace in }"
* Another confusing initially but good feature is use of class type's internal methods without putting in lambda or block: "match(options: [.caseIntensitive])"
* Either the AI or autocompletion suggestion would strictively enforce reassignment of immutable variable: "f(s : String); let s2 = s".

### Libraries

* Of course without knowing the Swift and Mac OS libraries, I really rely on outer guides and AI to point to what libraries have what.
* The most dirtiest part of Swift is its intermediate maturity: there are some data types that based on old versions like "NSxxx" while latest Swift versions have cleaner alternatives.
* The most painful library is regular expression.  It's crazy that it cannot fully support simplest definition like "match = /([a-z]+) has \d+/ =~ text; name = $1"; somehow the compiler needs you to set like "Regex(#"\d"#)".  The match result type is set with match class instance in old Swift.  Basically search online would pile onto you a few different styles.
* After importing [Subprocess](https://github.com/swiftlang/swift-subprocess), eventually I figured out how to add external dependencies into package.


## Local API Performance

Last Updated: 2026-08-10

Since my paid CoPilot premium usage for August was already eaten by early prompts to summarize Rufus written in C++ and generate similar one in Swift for Mac OS, I have to reconsidering paying these AI services for big operations.  So the other option is to try running open-source AI models locally.  I did installation of Ollama and selected models on my own Macbook Pro: Ollama, its own llama3.1:8b, qwen2.5-coder-7b, gemma4:2b, gemma4:4b, and nomic-embed-text.  I'm tied up with these smaller local models because to be developing and running local AI pretty much use up most of my MBP's memory.  I'm preparing my PC with mid-level video card to run AI better, so beginning of setup has been painful: replace privacy-stealing Windows 11 with fresh installation of Windows 10, a more trust-worthy OS that still works with most software.  Linux is installed on the other drive, but the latter is slower SSD and setup on Linux would take more time for another project.  Overall, it's cumbersome to use a large PC, especially now electricity rates and hardware prices are continuously being raised.

* __llama3.1:8b__ - More like general technical knowledge assitant.  Only briefly used it to resolve coding problems, so not sure how well it performs.
* __gemma4:2b__ - Actually pretty good in analyzing the context of codes, and suggesting solutions.  After typing the class or function synopsis and functionalities, its autocomplete and correction suggestions have been helpful.  For example, once one variable has data type changed, it can auto-correct the other spots of data type for change.  However, its code block generation is sometimes confusing with wrong syntax, and for newbie like me who does not know much about Swift system would be little painful.
* __gemma4:4b__ - This model requires more than 10GB of memory, so would push the MBP to use swap and heats up the laptop quickly because of intensive GPU usage.  So have not used it much.  One time when a tricky Swift build error could not be resolved by other models, I intentionally switched to this, and it solved it.  I guess this is good choice for little more complexity.  Will try running in PC.
* __qwen2.5-coder-7b__ - Originally by its name, expected coder to be at least capable of helping out on coding.  But the prompts within some context cannot be correct all the time.  Any big task like code generation of a function would be given inaccurate or incomplete suggestions.  Simpler corrections and documentation queries are still good enough.
* __rafw007/qwen35-claude-coder:9b__ - Since qwen2.5-coder-7b often provides incomplete explanations for humans, I tried to upgrade a version to Qwen3.5.  No official smaller quantitized version other than open-source poster on Unsloth/Huggingface.  Had one try with this one from rafw007: provided code suggestion but no wordy explanation.


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


## Installation

A version of [built .app](tree/main/MacRufusSwift/MacRufus.app/Contents) is pushed.  And its size is still under 3 MB because it literally calls native tools and uses Swift library.

For functional disk writing operations, the [**Full Disk Access** security setting](mac_privacy_full_disk_access.png) for MacRufus / MacRufusSwift needs to be enabled.

=============================================

# TODOs

* Device name is missing in using `diskutil` to collect device info.
* Might have to try using `system_profiler` to collect
* Partition Options: partition scheme, target system
* Format Options section: file system, cluster size
* Status section: progress bar, status text
* Authorization to execute dd: request to be authorized on the list of "Allow the applications below to access data like Mail, Messages, Safari, and certain administrative settings for all users on this Mac
* Write image to drive using dd, and update progress bar
* Partitioning process using diskutil

# Difficult Rufus Features

* Upon recognition of the image is a Windows 11 installation, Rufus has extra options to help user to skip out or turn off Windows' privacy or bloat content at initial installation.  Certainly these need more knowledge of tricks to counter Microsoft's doings, and reviewing over Rufus' C++ codes would not be easy.
