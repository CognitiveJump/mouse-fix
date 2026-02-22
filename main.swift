import Foundation
import IOKit
import IOKit.usb

setbuf(stdout, nil)

let logitechVendorID: Int = 1133
let logitechProductID: Int = 50475

// Undocumented CoreGraphics functions that System Preferences uses internally
@_silgen_name("_CGSDefaultConnection")
func _CGSDefaultConnection() -> Int32

@_silgen_name("CGSSetSwipeScrollDirection")
func CGSSetSwipeScrollDirection(_ connection: Int32, _ direction: Bool)

func setNaturalScrolling(enabled: Bool) {
    // Actually change the live scroll direction via private CoreGraphics API
    CGSSetSwipeScrollDirection(_CGSDefaultConnection(), enabled)

    // Persist the preference to disk
    CFPreferencesSetAppValue(
        "com.apple.swipescrolldirection" as CFString,
        enabled as CFBoolean,
        kCFPreferencesAnyApplication
    )
    CFPreferencesAppSynchronize(kCFPreferencesAnyApplication)

    // Notify System Settings UI so it stays in sync
    DistributedNotificationCenter.default().postNotificationName(
        NSNotification.Name("SwipeScrollDirectionDidChangeNotification"),
        object: nil,
        userInfo: nil,
        deliverImmediately: true
    )

    let state = enabled ? "ON (trackpad)" : "OFF (mouse)"
    print("[\(Date())] Natural scrolling set to \(state)")
}

func isLogitechReceiverConnected() -> Bool {
    var iterator: io_iterator_t = 0
    let matchingDict = IOServiceMatching(kIOUSBDeviceClassName) as NSMutableDictionary
    matchingDict[kUSBVendorID] = logitechVendorID
    matchingDict[kUSBProductID] = logitechProductID

    let result = IOServiceGetMatchingServices(kIOMainPortDefault, matchingDict, &iterator)
    guard result == KERN_SUCCESS else { return false }

    let device = IOIteratorNext(iterator)
    IOObjectRelease(iterator)

    if device != 0 {
        IOObjectRelease(device)
        return true
    }
    return false
}

// Drain iterator so IOKit continues to send notifications
func drainIterator(_ iterator: io_iterator_t) {
    while case let device = IOIteratorNext(iterator), device != 0 {
        IOObjectRelease(device)
    }
}

var matchedIterator: io_iterator_t = 0
var terminatedIterator: io_iterator_t = 0
let notificationPort = IONotificationPortCreate(kIOMainPortDefault)
let runLoopSource = IONotificationPortGetRunLoopSource(notificationPort).takeUnretainedValue()
CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .defaultMode)

let matchingForMatched = IOServiceMatching(kIOUSBDeviceClassName) as NSMutableDictionary
matchingForMatched[kUSBVendorID] = logitechVendorID
matchingForMatched[kUSBProductID] = logitechProductID

let matchingForTerminated = IOServiceMatching(kIOUSBDeviceClassName) as NSMutableDictionary
matchingForTerminated[kUSBVendorID] = logitechVendorID
matchingForTerminated[kUSBProductID] = logitechProductID

let matchedCallback: IOServiceMatchingCallback = { (refCon, iterator) in
    drainIterator(iterator)
    print("[\(Date())] Logitech USB Receiver connected")
    setNaturalScrolling(enabled: false)
}

let terminatedCallback: IOServiceMatchingCallback = { (refCon, iterator) in
    drainIterator(iterator)
    print("[\(Date())] Logitech USB Receiver disconnected")
    setNaturalScrolling(enabled: true)
}

IOServiceAddMatchingNotification(
    notificationPort,
    kIOMatchedNotification,
    matchingForMatched,
    matchedCallback,
    nil,
    &matchedIterator
)

IOServiceAddMatchingNotification(
    notificationPort,
    kIOTerminatedNotification,
    matchingForTerminated,
    terminatedCallback,
    nil,
    &terminatedIterator
)

// Drain both iterators to arm the notifications, then set initial state
drainIterator(matchedIterator)
drainIterator(terminatedIterator)

let connected = isLogitechReceiverConnected()
print("[\(Date())] mouse-fixer started. Logitech receiver \(connected ? "connected" : "not connected")")
setNaturalScrolling(enabled: !connected)

// Run forever
CFRunLoopRun()
