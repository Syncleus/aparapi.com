---
title: FAQ
description: Frequently Asked Questions. 
---

**Frequently Asked Questions**

**Why is this project called Aparapi and how is it pronounced?**

Aparapi is just a contraction of A PAR{allel} API and is pronounced (ap-per-rap-ee).

**Does Aparapi only work with AMD graphics cards?**

No. Aparapi has been tested with AMD's OpenCL enabled drivers and devices as well as a limited set of NVidia devices and drivers on Windows, Linux and Mac OSX platforms. The minimal requirement at runtime is OpenCL 1.1. If you have a compatible OpenCL 1.1 runtime and supported devices Aparapi should work.

Although the build is currently configured for AMD APP SDK, OpenCL is an open standard and we look forward to contributions which will allow Aparapi to be built against other OpenCL SDK's.

Note that dll's built using AMD APP SDK will work on other platforms at runtime. So the binary builds are expected to work on all OpenCL 1.1 platforms.

Witold Bolt has kindly supplied the patches to allow Mac OS support. The Mac OS build will run against OpenCL 1.1 and 1.0 runtimes, but we won't fix any issues reported against the OpenCL 1.0, your code may run, or may not.

Aparapi may be used in JTP (Java Thread Pool) mode on any platform supported by Oracle®’s JDK.

** Does Aparapi only support AMD CPUs?**

No, there is nothing restricting Aparapi to AMD CPUs. The JNI code that we use may run on any x86/x64 machine provided there is a compatible Java Virtual Machine® JVM implementation for your platform.

**Will there be an Aparapi-like translator for .NET?**

This is still an early technology and Aparapi is currently focused on Java® enablement. There are similar projects targeting .NET (See www.tidepowerd.com)

**How can I profile the OpenCL kernels that Aparapi generates? Can I get details on the latency of my kernel request?How do I optimize my kernel?**

AMD offers the ‘AMD APP Profiler’ which can be used to profile the kernels. With Aparapi, we recommend using the command line mode of the profiler, which is described in the release notes. Using the ‘AMD APP Profiler’ you can see how much time is taken by each kernel execution and buffer transfer. Also, in each kernel, you can get more detailed information on things like memory reads and writes, and other useful data.

**Can I have multiple threads all using the GPU compute capabilities?**

Yes. There might be a performance impact if the device becomes a bottleneck. However, OpenCL and your GPU driver are designed to coordinate the various threads of execution.

**Can I make method calls from the run method?**

You can generally only make calls to other methods declared in the same class as the initial run() method. Aparapi will follow this call chain to try to determine whether it can create OpenCL. If, for example, Aparapi encounters System.out.println("Hello World") ( call to a method not in the users Kernel class) it will detect this and refuse to consider the call chain as an OpenCL candidate.

One exception to this rule allows a kernel to access or mutate the state of objects held in simple arrays via their setters/getters. For example a kernel can include :-

```java

out[i].setValue(in[i].getValue()*5);
```

**Does Aparapi support vectorized types?**

Due to Java's lack of vector types (float4 for example) Aparapi can't directly use them. Also, due to Java's lack of operator overloading, simulating these with Java abstracts could lead to very complex and unwieldy code.

**Is there a way I can see the generated OpenCL?**

Yes, by using adding -Dcom.aparapi.enableShowGeneratedOpenCL=true to your command line when you start your JVM.

**Does Aparapi support sharing buffers with JOGL? Can I exploit the features of JOGAMP/glugen?**

Rather than only supporting display-oriented compute, we are pursuing general data parallel compute. Therefore, we have chosen not to bind Aparapi too closely with JOGL.

**What is the performance delta from handcrafted OpenCL?**

This depends heavily on the application. Although we can currently show 20x performance improvement on some compute intensive Java applications compared with the same algorithm using a Java Thread Pool a developer who is prepared to handcraft and hand-tune OpenCL and write custom host code in C/C++ is likely to see better performance than Aparapi may achieve.

We understand that some user may use Aparapi as a gateway technology to test their Java code before porting to hand-crafted/tuned OpenCL.

**Are you working with Project Lambda for offloading/parallelizing suitable work?**

We are following the progress of Project Lambda (currently scheduled for inclusion in Java 8) and would like to be able to leverage Lambda expression format in Aparapi, but none exists now.

**Can I select a specific GPU if I have more than one card?**

Under review. At present, Aparapi just looks for the first AMD GPU (or APU) device. If the community has feedback on its preference, let us know.

**Can I get the demos/samples presented at JavaOne or ADFS?**

The Squares and Mandlebrot sample code is included in the binary download of Aparapi. The NBody source is not included in the binary (because of a dependency on JOGL). We have, however, included the NBody code as an example project in the Open Source tree (code.google.com/p/aparapi) and provide details and we provide details on how to install the appropriate JOGL components.

**Can Mersenne twister be ported as a random number function inside the kernel class?**

You can elect to implement your own Mersenne twister and use it in our own derived Kernel.

**Does Aparapi use JNI?**

Yes, we do ship a small JNI shim to handle the host OpenCL calls.

**How can I confirm that my code is actually executing on the GPU?**

From within the Java code itself you can query the execution mode after Kernel.execute(n) has returned.

```java

Kernel kernel = new Kernel(){
   @Override public void run(){
   }
} ;
kernel.execute(1024);
System.out.priintln(“Execution mode = “+kernel.getExecutionMode());
```

The above code fragment will print either ‘GPU’ if the kernel executed on the GPU or JTP if Aparapi executed the Kernel in a Java Thread Pool.

Alternatively, setting the property –Dcom.aparapi.enableShowExecutionModes=true when you start your JVM will cause Aparapi to automatically report the execution mode of all kernels to stdout.

**Why does Aparapi need me to compile my code with -g?**

Aparapi extracts most of the information required to create OpenCL from the bytecode of your Kernel.run() (and run-reachable) methods. We use the debug information to re-create the original variable name and to determine the local variable scope information.

Of course only the derived Kernel class (or accessed Objects using new Arrays of Objects feature) need to be compiled using -g.

**Why does the Aparapi documentation suggest I use Oracle's JDK/JRE? Why can't I use any JVM/JDK?**

The documentation suggests using Oracle's JDK/JRE for coverage reasons and not as a requirement. AMD focused its testing on Oracle's JVM/JDK.

There are two parts to this.

1. Our bytecode to OpenCL engine is somewhat tuned to the bytecode structures created by javac supplied by Oracle®. Specifically, there are some optimizations that other javac implementation might perform that Aparapi won't recognize. Eclipse (for example) does not presently use Oracle's javac, and so we do have some experience handling Eclipse specific bytecode patterns.
2. At runtime, we piggyback on the (aptly named) sun.misc.Unsafe class, which is included in rt.jar from Oracle®. This class is useful because it helps us avoid some JNI calls by providing low level routines for accessing object field addresses (in real memory) and useful routines for Atomic operations. All accesses to 'sun.misc.Unsafe' are handled by an Aparapi class called UnsafeWrapper with the intent that this could be refactored to avoid this dependency.

**I am using a dynamic language (Clojure, Scala, Groovy, Beanshell, etc) will I be able to use Aparapi?**

No.

To access the bytecode for a method Aparapi needs to parse the original class file. For Java code, Aparapi can use something like the code below to reload the class file bytes and parse the constant pool, attributes, fields, methods and method bytecode.

```java

YourClass.getClassLoader().loadAsResource(YourClass.getName()+".class"))
```

It is unlikely that this process would work with a dynamically created class based on the presumption that dynamic languages employ some form of custom classloader to make dynamically generated bytecode available to the JVM. Therefore, it is unlikely that these classloaders would yield the classfile bytes. However, we encourage contributors to investigate opportunities here. Even if the class bytes were loadable, Aparapi would also expect debug information to be available (see previous FAQ entry). Again, this is not impossible for a dynamic language to do, indeed it would probably even be desirable as it would allow the code to be debugged using JDB compatible debugger.

Finally, Aparapi recognizes bytecode patterns created by the javac supplied by Oracle® and it is possible that the code generated by a particular dynamic language may not be compatible with Aparapi current code analyzer.

Therefore, at present this is unlikely to work. However, these would be excellent contributions to Aparapi. It would be great to see Aparapi being adopted by other JVM based dynamic language.

**Why does Aparapi seems to be copying data unnecessarily back and forth between host and GPU. Can I stop Aparapi from doing this?**

Aparapi ensures that required data is moved to the GPU prior to kernel execution and returned to the appropriate array before Java execution resumes. Generally, this is what the Java user will expect. However, for some code patterns where multiple Kernel.execute() calls are made in succession (or more likely in a tight loop) Aparapi's approach may not be optimal.

In the NewFeatures page we discuss a couple of Aparapi enhancements which will developers to elect intervene to reduce unnecessary copies.

**Do I have to refactor my code to use arrays of primitives? Why can’t Aparapi just work with Java Objects?**

Aparapi creates OpenCL from the bytecode. Generally, OpenCL constrains us to using parallel primitive arrays (OpenCL does indeed allow structs, but Java and OpenCL do not have comparable memory layouts for these structures). Therefore, you will probably need to refactor your code to use primitive arrays. In this initial contribution, we have included some limited support for Arrays of simple Objects and hope contributors extend them. Check the NewFeatures page which shows how you can use this feature.