---
title: About
---
# What is Aparapi?

Aparapi allows Java developers to take advantage of the compute power of GPU and APU devices by executing data parallel code fragments on the GPU rather than being confined to the local CPU. It does this by converting Java bytecode to OpenCL at runtime and executing on the GPU, if for any reason Aparapi can't execute on the GPU it will execute in a Java thread pool.

We like to think that for the appropriate workload this extends Java's 'Write Once Run Anywhere' to include GPU devices.

With Aparapi we can take a sequential loop such as this (which adds each element from inA and inB arrays and puts the result in result).

```java

final float inA[] = .... // get a float array of data from somewhere
final float inB[] = .... // get a float array of data from somewhere
assert (inA.length == inB.length);
final float result = new float[inA.length];

for (int i = 0; i < array.length; i++) {
    result[i] = intA[i] + inB[i];
}
```

And refactor the sequential loop to the following form:

```java

Kernel kernel = new Kernel() {
    @Override
    public void run() {
        int i = getGlobalId();
        result[i] = intA[i] + inB[i];
    }
};

Range range = Range.create(result.length);
kernel.execute(range);
```

In the above code we extend com.amd.aparapi.Kernel base class and override the Kernel.run() method to express our data parallel algorithm. We initiate the execution of the Kernel(over a specific range 0..results.length) using Kernel.execute(range).

# About the Name

Aparapi is just a contraction of "A PARallel API"

However... "Apa rapi" in Indonesian (the language spoken on the island of Java) translates to "What a neat...". So "Apa rapi Java Project" translates to "What a neat Java Project" How cool is that?

# In the News

* "GPU Acceleration of Interactive Large Scale Data Analytics Utilizing The Aparapi Framework" - Ryan LaMothe - AFDS
* "Aparapi: OpenCL GPU and Multi-Core CPU Heterogeneous Computing for Java" - Ryan LaMothe and Gary Frost - AFDS
* "Performance Evaluation of AMD-APARAPI Using Real World Applications" - Prakash Raghavendra - AFDS
* "Aparapi: An Open Source tool for extending the Java promise of ‘Write Once Run Anywhere’ to include the GPU" - Gary Frost - OSCON 7/18/2012
* Aparapi talk at DOSUG (Denver Open Source User Group) Sept 4th 2012
* Meetup meeting in Paris Sept 25th 2012

# Similar Work

* Peter Calvert's java-GPU has similar goals and offers a mechanism for converting Java code for use on the GPU
* Check out Peter's dissertation "Parallelisation of Java for Graphics Processors" which can be found here
* Marco Hutter's Java bindings for CUDA
* Marco Hutter's Java bindings for OpenCL
* Ian Wetherbee's Java acceleration project - creates accelerated code from Java (currently C code and native Android - but CUDA creation planned)
* "Rootbeer: Seamlessly using GPUs from Java" by Philip C. Pratt-Szeliga