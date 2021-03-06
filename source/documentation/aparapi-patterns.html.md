---
title: Aparapi Patterns
description: Examples and code fragments to demonstrate Aparapi features.
---

##Aparapi Patterns

The following suggestions help solve some common problems found in using Aparapi.

Additional suggestions and solutions to extend this list would be welcome.

##How do I return data from a kernel if I can’t write to kernel fields?

Use a small array buffer (possibly containing a single element) and assign it from the kernel.

For example, the following kernel code detects whether the `buffer[]` contains the value `1234`. The flag (true or false) is returned in `found[0]`.

```java

final int buffer[] = new int[HUGE];
final boolean found[] = new boolean[]{false};
// fill buffer somehow
 kernel kernel = new kernel(){
    @Override public void run(){
          if (buffer[getGlobald()]==1234){
                found[0]=true;
          }
    }
};
kernel.execute(buffer.length);
```

This code does include a race condition, whereby more than one value of `Kernel.getGlobalId()` might contain 1234 and try to set `found[0]`. This is not a problem here, because we don't care if multiple kernel executions match, provided one flips the value of `found[0]`.

##How can I use Aparapi and still maintain an object-oriented view of my data?

See the NewFeatures page. Aparapi can now handle simple arrays of objects, which minimizes the amount of refactoring required to experiment with Aparapi. However, performance is still likely to be better if your algorithm operates on data held in parallel primitive arrays. To get higher performance from Aparapi with minimal exposure to data in this parallel primitive array form, we can (with a little work) allow both forms of data to co-exist. Let’s reconsider [the NBody problem](http://en.wikipedia.org/wiki/N-body_problem).

A Java developer writing an NBody solution would most likely create a Body class:

```java

class Body{
  float x,y,z;
  float getX(){return x;}
  void setX(float _x){ x = _x;}
  float getY(){return y;}
  void setY(float _y){ y = _y;}
  float getZ(){return z;}
  void setZ(float _z){ z = _z;}


  // other data related to Body unused by positioning calculations
}
```

The developer would also likely create a container class (such as NBodyUniverse), that manages the positions of multiple Body instances.

```java

class NBodyUniverse{
     final Body[] bodies = null;
     NBodyUniverse(final Bodies _bodies[]){
        bodies = _bodies;
        for (int i=0; i<bodies.length; i++){
           bodies[i].setX(Math.random()*100);
           bodies[i].setY(Math.random()*100);
           bodies[i].setZ(Math.random()*100);
        }
     }
     void adjustPositions(){
       // can use new array of object Aparapi features, but is not performant
     }
}
Body bodies = new Body[BODIES];
for (int i=0; i<bodies; i++){
    bodies[i] = new Body();
}
NBodyUniverse universe = new NBodyUniverse(bodies);
while (true){
   universe.adjustPositions();
   // display NBodyUniverse
}
```

The `NBodyUniverse.adjustPostions()` method contains the nested loops (adjusting each body position based on forces impinging on it from all of the other bodies), making it an ideal Aparapi candidate.

Even though this code can now be written by accessing the x, y and z ordinates of `Body[]` via getters/setters, the most performant Aparapi implementation is the one that operates on parallel arrays of floats containing x, y and z ordinates, with `Body[10]`’s state conceptually stored across `x[10]`, `y[10]` and `z[10]`.

So for performance reasons, you can do something like this:

```java

class Body{
    int idx;
    NBodyUniverse universe;
    void setUniverseAndIndex(NBodyUniverse _universe, int _idx){
        universe = _universe;
        idx = _idx;
    }

    // other fields not used by layout

    void setX(float _x){ layout.x[idx]=_x;}
    void setY(float _y){ layout.y[idx]=_y;}
    void setZ(float _z){ layout.z[idx]=_z;}
    float getX(){ return layout.x[idx];}
    float getY(){ return layout.y[idx];}
    float getZ(){ return layout.z[idx];}
}
class NBodyUniverse {
     final Body[] bodies;
     final int[] x, y, z;
     NBodyUniverse(Body[] _bodies){
        bodies = _bodies;
        for (int i=0; i<bodies.length; i++){
           bodies[i].setUniverseAndIndex(this, i);
           bodies[i].setX(Math.random()*100);
           bodies[i].setY(Math.random()*100);
           bodies[i].setZ(Math.random()*100);
        }
     }
     void adjustPositions(){
         // can now more efficiently use Aparapi
     }
}



Body bodies = new Body[BODIES];
for (int i=0; i<bodies; i++){
    bodies[i] = new Body();
}
NBodyUniverse universe = new NBodyUniverse(bodies);
while (true){
   universe.adjustPositions();
   // display NBodyUniverse
}
```

This example allows Java™ code to treat each Body in a traditional object-oriented fashion and also allows Aparapi kernels to act on the parallel primitive array form, in order to access/mutate the position of the bodies.