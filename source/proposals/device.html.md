---
title: Device
description: How we might use the extension mechanism devices for general Kernel execution.  
---

At present the first GPU or CPU device (depending on Kernel.ExecutionMode value) is chosen at execution time. This make it easy to execute simple Kernels, but is problematic when using some advanced feature (barriers, local memory) or for sizing buffers appropriate for the target device. I propose that we add API's to allow the developer to specify exactly which device we intend to target.

In the extension proposal branch we needed to expose a Device class for binding arbitrary OpenCL to a Java interface. I suggest we also be use this to query device information useful for allocating suitable size global buffers/local buffers, and for dispatching Kernel's to specific devices.

The general pattern would be that we ask Aparapi to give us a Device, probably via a Device factory method.

Something like:-

```java

Device device = Device.best();
```
    
We would also offer other useful factory methods `getBestGPU()`, `getFirstCPU()`, `getJavaMultiThread()`, `getJavaSequential()` as well as a method to get all device so that the developer can filter themselves.

Note that as well as real OpenCL devices we also expose 'pseudo' devices such as JavaMultiThread and Sequential. We might also allow pseudo devices to group multiple devices. So `getAllGPUDevices()` might return a pseudo device for executing across devices.

    Device chosen=null;
    for (Device device: devices.getAll()){
       if (device.getVendor().contains("AMD") && device.isGPU()){
          chosen = device;
          break;
       }
    }

A Device can be queried (`isGPU()`, `isOpenCL()`, `isGroup()`, `isJava()`, `getOpenCLPlatform()`, `getMaxMemory()`, `getLocalSizes()`) and may need to be cast to specific types.

This would allow us to configure buffers.

```java

Device device = Device.best();
if (device instanceof OpenCLDevice){
   OpenCLDevice openCLDevice  = (OpenCLDevice)device;
   char input[] = new char[openCLDevice.getMaxMemory()/4);
}
```
    
We can also use the Device as a factory for creating Ranges.

```java

Range range = device.createRange2D(width, height);
```
    
This allows the Range to be created with knowledge of the underlying device. So for example `device.createRange3D(1024, 1024, 1024, 16, 16, 16)` will fail if the device does not allow a local size of (16x16x16).

A range created using `device.createRangeXX()` would also capture the device that created it. As if we had

```java

Range range = device.createRange2D(width, height);
// implied range.setDevice(device);
This basically means that the Range locks the device that it can be used with.

So when we have a Kernel.

Kernel kernel = new Kernel(){
    @Override public void run(){
      ...
    }
}
```
    
And we then use

```java

Device device = Device.firstGPU();
final char input[] = new char[((OpenCLDevice)device).getMaxMemory()/4);
Kernel kernel = new Kernel(){
    @Override public void run(){
      // uses input[];
    }
};
range = device.createRange2D(1024, 1024);
kernel.execute(range);
```
    
We have forced execution on the first GPU. Java fallback would still be possible (should we forbid this?).

```java

kernel.execute( Device.firstGPU().getRange2D(width, height));
```
