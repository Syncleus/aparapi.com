---
title: Choosing Specific Devices
description: Using the new Device API's to choose Kernel execution on a specific device.
---

Previously Aparapi chose the first GPU device when `Kernel.execute()` was called. This make it easy to execute simple Kernels, but was problematic when users wished finer control over which device should be chosen. Especially when the first device may be unsuitable. We recently added new classes and API's to allow the developer to specify exactly which device we intend to target.

A new Device class has been added. This allows the user to select a specific device; either by calling a helper method `Device.firstGPU()` or `Device.best()`. Or by allowing the user to iterate through all devices and choose one based on some other criteria (capabilities? vendor name?).

So selecting the 'best' (most performant) device could be achieved using.

```java

Device device = Device.best();
```

Alternatively if I wanted the first AMD GPU device I might use:-

```java

Device chosen=null;
for (Device device: devices.getAll()){
   if (device.getVendor().contains("AMD") && device.isGPU()){
      chosen = device;
      break;
   }
}
```

A Device can be queried (`isGPU()`, `isOpenCL()`, `isGroup()`, `isJava()`, `getOpenCLPlatform()`, `getMaxMemory()`, `getLocalSizes()`) to yield it's characteristics.

To execute on a specific device we must use the device to create our range.

```java

Range range = device.createRange2D(width, height);
```

This allows the Range to be created with knowledge of the underlying device. So for example `device.createRange3D(1024, 1024, 1024, 16, 16, 16)` will fail if the device does not allow a local size of (16x16x16).

A range created using a device method captures the device which created it. The range instance has a device field which is set by the device which creates it.

It's as if we had this code

```java

Range range = Range.create(width, height);
range.setDevice(device);
```

So the Range locks the device that it can be used with.

Now when we have a Kernel.

```java

Kernel kernel = new Kernel(){
    @Override public void run(){
      ...
    }
}
```

And we then use a device created range.

```java

Device device = Device.firstGPU();
Kernel kernel = new Kernel(){
    @Override public void run(){
      // uses input[];
    }
};
range = device.createRange2D(1024, 1024);
kernel.execute(range);
```

We have forced execution on the first GPU.
