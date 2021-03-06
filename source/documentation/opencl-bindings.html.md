---
title: OpenCL Bindings
description: How to use new OpenCL binding mechanism.
---

As a step towards the extension mechanism I needed a way to easily bind OpenCL to an interface.

Here is what I have come up with. We will use the 'Square' example.

You first define an interface with OpenCL annotations..

```java

interface Squarer extends OpenCL<Squarer>{
@Kernel("{\n"//
     + "  const size_t id = get_global_id(0);\n"//
     + "  out[id] = in[id]*in[id];\n"//
     + "}\n")//
public Squarer square(//
     Range _range,//
     @GlobalReadOnly("in") float[] in,//
     @GlobalWriteOnly("out") float[] out);
}
```

This describes the API we wish to bind to a set of kernel entrypoints (here we only have one, but we could have many). Then you 'realize' the interface by asking a device to create an implementation of the interface. Device is a new Aparapi class which represents a GPU or CPU OpenCL device. So here we are asking for the first (default) GPU device to realize the interface.

```java

Squarer squarer = Device.firstGPU(Squarer.class);
```
  
Now you can call the implementation directly with a Range.

```java

squarer.square(Range.create(in.length), in, out);
```
 
I think that we will have the easiest OpenCL binding out there...

Following some conversations/suggestions online http://a-hackers-craic.blogspot.com/2012/03/aparapi.html we could also offer the ability to provide the OpenCL source from a file/url course using interface level Annotations.

So we could allow.

```java

@OpenCL.Resource("squarer.cl");
interface Squarer extends OpenCL<Squarer>{
     public Squarer square(//
       Range _range,//
       @GlobalReadOnly("in") float[] in,//
       @GlobalWriteOnly("out") float[] out);
}
```
  
Or if the text is on-hand at compile time in a single constant string

```java

@OpenCL.Source("... opencl text here");
interface Squarer extends OpenCL<Squarer>{
     public Squarer square(//
       Range _range,//
       @GlobalReadOnly("in") float[] in,//
       @GlobalWriteOnly("out") float[] out);
}
```
  
Finally to allow for creation of dynamic OpenCL (good for FFT's of various Radii).

```java

String openclSource = ...;
Squarer squarer = Device.firstGPU(Squarer.class, openclSource);
```