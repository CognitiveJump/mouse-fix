import Foundation
import IOKit.hid

setbuf(stdout, nil)

// Undocumented CoreGraphics functions that System Preferences uses internally
@_silgen_name("_CGSDefaultConnection")
func _CGSDefaultConnection() -> Int32

@_silgen_name("CGSSetSwipeScrollDirection")
func CGSSetSwipeScrollDirection(_ connection: Int32, _ direction: Bool)

func setNaturalScrolling(enabled: Bool) {
    CGSSetSwipeScrollDirection(_CGSDefaultConnection(), enabled)

    CFPreferencesSetAppValue(
        "com.apple.swipescrolldirection" as CFString,
        enabled as CFBoolean,
        kCFPreferencesAnyApplication
    )
    CFPreferencesAppSynchronize(kCFPreferencesAnyApplication)

    DistributedNotificationCenter.default().postNotificationName(
        NSNotification.Name("SwipeScrollDirectionDidChangeNotification"),
        object: nil,
        userInfo: nil,
        deliverImmediately: true
    )

    let state = enabled ? "ON (trackpad)" : "OFF (mouse)"
    print("[\(Date())] Natural scrolling set to \(state)")
}

let hidManager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))

let matchingCriteria: [[String: Any]] = [
    [
        kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop,
        kIOHIDDeviceUsageKey: kHIDUsage_GD_Mouse,
        kIOHIDTransportKey: kIOHIDTransportUSBValue
    ],
    [
        kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop,
        kIOHIDDeviceUsageKey: kHIDUsage_GD_Mouse,
        kIOHIDTransportKey: kIOHIDTransportBluetoothValue
    ],
    [
        kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop,
        kIOHIDDeviceUsageKey: kHIDUsage_GD_Mouse,
        kIOHIDTransportKey: kIOHIDTransportBluetoothLowEnergyValue
    ]
]

IOHIDManagerSetDeviceMatchingMultiple(hidManager, matchingCriteria as CFArray)

func mouseCount() -> Int {
    guard let devices = IOHIDManagerCopyDevices(hidManager) as? Set<IOHIDDevice> else { return 0 }
    return devices.count
}

func deviceName(_ device: IOHIDDevice) -> String {
    IOHIDDeviceGetProperty(device, kIOHIDProductKey as CFString) as? String ?? "Unknown mouse"
}

let matchedCallback: IOHIDDeviceCallback = { context, result, sender, device in
    print("[\(Date())] Mouse connected: \(deviceName(device))")
    setNaturalScrolling(enabled: false)
}

let removalCallback: IOHIDDeviceCallback = { context, result, sender, device in
    let name = deviceName(device)
    // Check remaining mice after this one is removed
    let remaining = mouseCount() - 1
    print("[\(Date())] Mouse disconnected: \(name) (\(remaining) remaining)")
    if remaining <= 0 {
        setNaturalScrolling(enabled: true)
    }
}

IOHIDManagerRegisterDeviceMatchingCallback(hidManager, matchedCallback, nil)
IOHIDManagerRegisterDeviceRemovalCallback(hidManager, removalCallback, nil)
IOHIDManagerScheduleWithRunLoop(hidManager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
IOHIDManagerOpen(hidManager, IOOptionBits(kIOHIDOptionsTypeNone))

let mice = mouseCount()
print("[\(Date())] mouse-fixer started. \(mice) mouse/mice connected")
setNaturalScrolling(enabled: mice == 0)

CFRunLoopRun()
