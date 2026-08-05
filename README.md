# About This Application

The open-source Windows program [Rufus](https://rufus.ie/en/) is useful free tool to write some ISO image to a disk drive, for example, bootable Windows installation disc.  [Check Rufus' screenshot](rufus.01.png). Cannot find similar free tool in Mac OS.  Thus, this application is trying to simulate the basic functions of Rufus.

The framework used is Swift UI within MacRufusSwift subfolder.  Since I have only little knowledge of Swift and desktop app programming, I'm using Claude Sonnet 4.6 to generate the basic structure of the app, and further modifications as I keep test and find issues.  There's also consideration of using Electron framework to enforce cross-OS compatibility.  But the problem found so far really requires a pack of library and executives in large space size, compared to Mac-native version in small space size like less than 1 MB.

==========================================

# Methods to Collect Device Information

## Mac OS Device Information

### Specifically find connected external devices even partitions mounted
```
diskutil list External
```

A sample of the out is logged in MacRufusSwift/mac_diskutil_list_External.log


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