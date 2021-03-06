---
title: Multiple Entry Points
description: How to extend Aparapi to allow multiple entrypoints for kernels. 
---

##The Current Single Entrypoint World

At present Aparapi allows us to dispatch execution to a single 'single entry point' in a Kernel. Essentially for each Kernel only the overridden Kernel.run() method can be used to initiate execution on the GPU.

Our canonical example is the 'Squarer' Kernel which allows us to create squares for each element in an input array in an output array.

```java

Kernel squarer = new Kernel(){
   @Overide public void run(){
      int id = getGlobalId(0);
      out[id] = in[id] * in[id];
   }
};
```

If we wanted a vector addition Kernel we would have to create a whole new Kernel.

```java

Kernel adder = new Kernel(){
   @Overide public void run(){
      int id = getGlobalId(0);
      out[id] = in[id] * in[id];
   }
};
```

For us to square and then add a constant we would have to invoke two kernels. Or of course create single SquarerAdder kernel.

See this page EmulatingMultipleEntrypointsUsingCurrentAPI for ideas on how to emulate having multiple methods, by passing data to a single run() method.

##Why can't Aparapi just allow 'arbitary' methods

Ideally we would just expose a more natural API, one which allows us to provide specific methods for each arithmetic operation.

Essentially

```java

class VectorKernel extends Kernel{
   public void add();
   public void sub();
   public void sqr();
   public void sqrt();
}
```

Unfortunately this is hard to implement using Aparapi. There are two distinct problems, both at runtime.

* How will Aparapi know which of the available methods we want to execute when we call Kernel.execute(range)?
* On first execution how does Aparapi determine which methods might be entrypoints and are therefore need to be converted to OpenCL?

The first problem can be solved by extending Kernel.execute() to accept a method name

```java

kernel.execute(SIZE, "add");
```

This is the obvious solution, but really causes maintenence issues int that it trades compile time reporting for a runtime errors. If a developer mistypes the name of the method, :-

```java

kernel.execute(SIZE, "sadd"); // there is no such method
```

The code will compile perfectly, only at runtime will we detect that there is no such method.

##An aside

Maybe the new Java 8 method reference feature method might help here. In the paper below Brian Goetz talks about a double-colon syntax (Class::Method) for directly referencing a method which is presumably checked at compile time.

So presumably

```java

kernel.execute(SIZE, VectorKernel::add);
```

Would compile just fine, whereby

```java

kernel.execute(SIZE, VectorKernel::sadd);
```

Would yield a compile time error.

See Brian Goetz's excellent Lambda documentation

##back from Aside

The second problem (knowing which methods need to be converted to OpenCL) can probably be solved using an Annotation.

```java

class VectorKernel extends Kernel{
   @EntryPoint public void add();
   @EntryPoint public void sub();
   @EntryPoint public void sqr();
   @EntryPoint public void sqrt();
   public void nonOpenCLMethod();
}
```

Here the @EntryPoint annotation allows the Aparapi runtime to determine which methods need to be exposed.

#My Extension Proposal

Here is my proposal. Not only does it allow us to reference multiple entryoints, but I think it actually improves the single entrypoint API, albeit at the cost of being more verbose.

##The developer must provide an API interface

First I propose that we should ask the developer to provide an interface for all methods that we wish to execute on the GPU (or convert to OpenCL).

```java

interface VectorAPI extends AparapiAPI {
   public void add(Range range);
   public void sub(Range range);
   public void sqrt(Range range);
   public void sqr(Range range);
}
```

Note that each API takes a Range, this will make more sense in a moment.
##The developer provides a bound implementation

Aparapi should provide a mechanism for mapping the proposed implementation of the API to it's implementation.

Note the weasel words here, this is not a conventional implementation of an interface. We will use an annotation (@Implements(Class class)) to provide the binding.

```java

@Implements(VectorAPI.class) class Vector extends Kernel {
   public void add(RangeId rangeId){/*implementation here */}
   public void sub(RangeId rangeId){/*implementation here */}
   public void sqrt(RangeId rangeId){/*implementation here */}
   public void sqr(RangeId rangeId){/*implementation here */}
   public void  public void nonOpenCLMethod();
}
```

##Why we can't the implementation just implement the interface?

This would be ideal. Sadly we need to intercept a call to say VectorAPI.add(Range) and dispatch to the resulting Vector.add(RangeId) instances. If you look at the signatures, the interface accepts a Range as it's arg (the range over which we intend to execute) whereas the implementation (either called by JTP threads or GPU OpenCL dispatch) receives a RangeId (containing the unique globalId, localId, etc fields). At the very end of this page I show a strawman implementation of a sequential loop implementation.

##So how do we get an implementation of VectorAPI

We instantiate our Kernel by creating an instance using new. We then ask this instance to create an API instance. Some presumably java.util.Proxy trickery will create an implementation of the actual instance, backed by the Java implementation.

So execution would look something like.

```java

Vector kernel = new Vector();
VectorAPI kernelApi = kernel.api();
Range range = Range.create(SIZE);
kernalApi.add(range);
```

So the Vector instance is a pure Java implementation. The extracted API is the bridge to the GPU.

Of course then we can also execute using an inline call through api()

```java

Vector kernel = new Vector();
Range range = Range.create(SIZE);
kernel.api().add(range);
kernel.api().sqrt(range);
```

or even expose api as public final fields

```java

Vector kernel = new Vector();
Range range = Range.create(SIZE);
kernel.api.add(range);
kernel.api.sqrt(range);
```

##How would our canonical Squarer example look

```java

interface SquarerAPI extends AparapiAPI{
   square(Range range);
}

@Implement(SquarerAPI) class Squarer extends Kernel{
   int in[];
   int square[];
   public void square(RangeId rangeId){
      square[rangeId.gid] = in[rangeId.gid]*in[rangeId.gid];
   }
}
```

Then we execute using

```java

Squarer squarer = new Squarer();
// fill squarer.in[SIZE]
// create squarer.values[SIZE];


squarer.api().square(Range.create(SIZE));
```

#Extending this proposal to allow argument passing

Note that we have effectively replaced the use of the 'abstract' squarer.execute(range) with the more concrete squarer.api().add(range).

Now I would like to propose that we take one more step by allowing us to pass arguments to our methods.

Normally Aparapi captures buffer and field accesses to create the args that it passes to the generated OpenCL code. In our canonical squarer example the `in[]` and `square[]` buffers are captured from the bytecode and passed (behind the scenes) to the OpenCL.

However, by exposing the actual method we want to execute, we could also allow the API to accept parameters.

So our squarer example would go from

```java

interface SquarerAPI extends AparapiAPI{
   square(Range range);
}

@Implement(SquarerAPI) class Squarer extends Kernel{
   int in[];
   int square[];
   public void square(RangeId rangeId){
      square[rangeId.gid] = in[rangeId.gid]*in[rangeId.gid];
   }
}


Squarer squarer = new Squarer();
// fill squarer.in[SIZE]
// create squarer.values[SIZE];

squarer.api().square(Range.create(SIZE));
```

to

```java

interface SquarerAPI extends AparapiAPI{
   square(Range range, int[] in, int[] square);
}

@Implement(SquarerAPI) class Squarer extends Kernel{
   public void square(RangeId rangeId, int[] in, int[] square){
      square[rangeId.gid] = in[rangeId.gid]*in[rangeId.gid];
   }
}


Squarer squarer = new Squarer();
int[] in = // create and fill squarer.in[SIZE]
int[] square = // create squarer.values[SIZE];

squarer.api().square(Range.create(SIZE), in, result);
```

I think that this makes Aparapi look more conventional. It also allows us to allow overloading for the first time.

```java

interface SquarerAPI extends AparapiAPI{
   square(Range range, int[] in, int[] square);
   square(Range range, float[] in, float[] square);
}

@Implement(SquarerAPI) class Squarer extends Kernel{
   public void square(RangeId rangeId, int[] in, int[] square){
      square[rangeId.gid] = in[rangeId.gid]*in[rangeId.gid];
   }
   public void square(RangeId rangeId, float[] in, float[] square){
      square[rangeId.gid] = in[rangeId.gid]*in[rangeId.gid];
   }
}


Squarer squarer = new Squarer();
int[] in = // create and fill squarer.in[SIZE]
int[] square = // create squarer.values[SIZE];

squarer.api().square(Range.create(SIZE), in, result);
float[] inf = // create and fill squarer.in[SIZE]
float[] squaref = // create squarer.values[SIZE];

squarer.api().square(Range.create(SIZE), inf, resultf);
```

test harness

```java

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;


public class Ideal{

   public static class OpenCLInvocationHandler<T> implements InvocationHandler {
       Object instance;
       OpenCLInvocationHandler(Object _instance){
          instance = _instance;
       }
      @Override public Object invoke(Object interfaceThis, Method interfaceMethod, Object[] interfaceArgs) throws Throwable {
         Class clazz = instance.getClass();

         Class[] argTypes =  interfaceMethod.getParameterTypes();
         argTypes[0]=RangeId.class;
         Method method = clazz.getDeclaredMethod(interfaceMethod.getName(), argTypes);


         if (method == null){
            System.out.println("can't find method");
         }else{
            RangeId rangeId = new RangeId((Range)interfaceArgs[0]);
            interfaceArgs[0]=rangeId;
            for (rangeId.wgid = 0; rangeId.wgid <rangeId.r.width; rangeId.wgid++){
                method.invoke(instance, interfaceArgs);
            }
         }

         return null;
      }
   }

   static class Range{
      int width;
      Range(int _width) {
         width = _width;
      }
   }

   static class Range2D extends Range{
      int height;

      Range2D(int _width, int _height) {
         super(_width);
         height = _height;
      }
   }

   static class Range1DId<T extends Range>{
      Range1DId(T _r){
         r = _r;
      }
      T r;

      int wgid, wlid, wgsize, wlsize, wgroup;
   }

   static class RangeId  extends Range1DId<Range>{
      RangeId(Range r){
         super(r);
      }
   }

   static class Range2DId extends Range1DId<Range2D>{
      Range2DId(Range2D r){
         super(r);
      }

      int hgid, hlid, hgsize, hlsize, hgroup;
   }





   static <T> T create(Object _instance, Class<T> _interface) {
      OpenCLInvocationHandler<T> invocationHandler = new OpenCLInvocationHandler<T>(_instance);
      T instance = (T) Proxy.newProxyInstance(Ideal.class.getClassLoader(), new Class[] {
            _interface,

      }, invocationHandler);
      return (instance);

   }



   public static class Squarer{
      interface API {
         public API foo(Range range, int[] in, int[] out);
         public Squarer dispatch();

      }

      public API foo(RangeId rangeId, int[] in, int[] out) {
         out[rangeId.wgid] = in[rangeId.wgid]*in[rangeId.wgid];
         return(null);
      }
   }

   /**
    * @param args
    */
   public static void main(String[] args) {

      Squarer.API squarer = create(new Squarer(), Squarer.API.class);
      int[] in = new int[] {
            1,
            2,
            3,
            4,
            5,
            6
      };
      int[] out = new int[in.length];
      Range range = new Range(in.length);

      squarer.foo(range, in, out);

      for (int s:out){
         System.out.println(s);
      }

   }

}
```