---
title: Emulating Multiple Entrypoints
description: How to emulate multiple entrypoints using existing Aparapi APIs 
---

##Emulating Multiple Entrypoints Using Existing Aparapi APIs

Until we have support for multiple entrypoints in Aparapi, there are some tricks for emulating this feature.

Suppose we wanted to create a general VectorMath kernel which might expose unary square, squareroot methods and binary addition and subtraction functionality. With our current API limitations we can't easily do this, we can approximate having separate methods by passing a separate arg to dictate the 'function' that we wish to perform.

```java

class VectorKernel extends Kernel{
    float[] lhsOperand;
    float[] rhsOperand;
    float[] unaryOperand;
    float[] result;
    final static int FUNC_ADD =0;
    final static int FUNC_SUB =1;
    final static int FUNC_SQR =2;
    final static int FUNC_SQRT =3;
    // other functions
    int function;
    @Override public void run(){
        int gid = getGlobalId(0){
        if (function==FUNC_ADD){
           result[gid]=lhsOperand[gid]+rhsOperand[gid];
        }else if (function==FUNC_SUB){
           result[gid]=lhsOperand[gid]-rhsOperand[gid];
        }else if (function==FUNC_SQR){
           result[gid]=unaryOperand[gid]*unaryOperand[gid];
        }else if (function==FUNC_ADD){
           result[gid]=sqrt(unaryOperand[gid]);
        }else if ....
    }
}
```

To use this for adding two vectors and then take the sqrt of the result we would use something like....

```java

int SIZE=1024;
Range range = Range.create(SIZE);
VectorKernel vk = new VectorKernel();
vk.lhsOperand = new float[SIZE];
vk.rhsOperand = new float[SIZE];
vk.unaryOperand = new float[SIZE];
vk.result = new float[SIZE];

// fill lhsOperand ommitted
// fill rhsOperand ommitted
vk.function = VectorKernel.FUNC_ADD;
vk.execute(range);
System.arrayCopy(vk.result, 0, vk.unaryOperand, 0, SIZE);
vk.function = VectorKernel.FUNC_SQRT;
vk.execute(range);
```

This approach is fairly common and I have used it successfully to perform various pipeline stages for calculating FFT's for example. Whilst this is functional it is not a great solution. First the API is clumsy. We have to mutate the state of the kernel instance and then re-arrange the arrays manually to chain math operations. We could of course hide all of this behind helper methods. One could imagine for example an implementation which exposes helper add(lhs, rhs)}}, or {{{sqrt() which hid all the nasty stuff.

```java

class VectorKernel extends Kernel{
    float[] lhsOperand;
    float[] rhsOperand;
    float[] unaryOperand;
    float[] result;
    final static int FUNC_ADD =0;
    final static int FUNC_SUB =1;
    final static int FUNC_SQR =2;
    final static int FUNC_SQRT =3;
    // other functions
    int function;
    @Override public void run(){
        int gid = getGlobalId(0){
        if (function==FUNC_ADD){
           result[gid]=lhsOperand[gid]+rhsOperand[gid];
        }else if (function==FUNC_SUB){
           result[gid]=lhsOperand[gid]-rhsOperand[gid];
        }else if (function==FUNC_SQR){
           result[gid]=unaryOperand[gid]*unaryOperand[gid];
        }else if (function==FUNC_ADD){
           result[gid]=sqrt(unaryOperand[gid]);
        }else if ....
    }
    private void binary(int operator, float[] lhs, float[] rhs){
       lhsOperand = lhs;
       rhsOperand = rhs;
       function=operator;
       execute(lhs.length());
    }
    public void add(float[] lhs, float[] rhs){
       binary(FUNC_ADD, lhs, rhs);
    }

    public void sub(float[] lhs, float[] rhs){
       binary(FUNC_SUB, lhs, rhs);
    }

    private void binary(int operator, float[] rhs){
       System.arrayCopy(result, 0, lhsOperand, result.length);
       rhsOperand = rhs;
       function=operator;
       execute(lhsOperand.legth());
    }

    public void add(float[] rhs){
       binary(FUNC_ADD,  rhs);
    }

    public void sub( float[] rhs){
       binary(FUNC_SUB,  rhs);
    }

    private void unary(int operator, float[] unary){
       unaryOperand = unary;
       function=operator;
       execute(unaryOperand.length());
    }

    public void sqrt(float[] unary){
       unary(FUNC_SQRT, unary);
    }

    private void unary(int operator){
       System.array.copy(result, 0, unaryOperand, 0, result.length);
       function=operator;
       execute(unaryOperand.length());
    }

    public void sqrt(){
       unary(FUNC_SQRT);
    }

}

VectorKernel vk = new VectorKernel(SIZE);
vk.add(copyLhs, copyRhs);  // copies args to lhs and rhs operands
                           // sets function type
                           // and executes kernel
vk.sqrt();                 // because we have no arg
                           // copies result to unary operand
                           // sets function type
                           // execute kernel
```

However there is one more objection to this approach, namely that it by default will force unnecessarily buffer copies.

When the bytecode for the above `Kernel.run()` method is analyzed Aparapi finds bytecode reading from lhsOperand, rhsOperand and unaryOperand arrays/buffers. Obviously at this bytecode analysis stage we can't predict which 'function type' will be used, so on every executions (Kernel.run()) Aparapi must copy all three buffers to the GPU. For binary operations this is one buffer copy wasted (the unaryOperand), for the unary operations we copy two buffers unnecessarily (lhsOperand and rhsOperand). We can of course use explicit buffer management to help us reduce these costs. Ideally we add this to our helper methods.

```java

class VectorKernel extends Kernel{
    float[] lhsOperand;
    float[] rhsOperand;
    float[] unaryOperand;
    float[] result;
    final static int FUNC_ADD =0;
    final static int FUNC_SUB =1;
    final static int FUNC_SQR =2;
    final static int FUNC_SQRT =3;
    // other functions
    int function;
    @Override public void run(){
        int gid = getGlobalId(0){
        if (function==FUNC_ADD){
           result[gid]=lhsOperand[gid]+rhsOperand[gid];
        }else if (function==FUNC_SUB){
           result[gid]=lhsOperand[gid]-rhsOperand[gid];
        }else if (function==FUNC_SQR){
           result[gid]=unaryOperand[gid]*unaryOperand[gid];
        }else if (function==FUNC_ADD){
           result[gid]=sqrt(unaryOperand[gid]);
        }else if ....
    }
    private void binary(int operator, float[] lhs, float[] rhs){
       lhsOperand = lhs;
       rhsOperand = rhs;
       function=operator;
       put(lhsOperand).put(rhsOperand);
       execute(lhs.length());
       get(result);
    }
    public void add(float[] lhs, float[] rhs){
       binary(FUNC_ADD, lhs, rhs);
    }

    public void sub(float[] lhs, float[] rhs){
       binary(FUNC_SUB, lhs, rhs);
    }

    private void binary(int operator, float[] rhs){
       System.arrayCopy(result, 0, lhsOperand, result.length);
       rhsOperand = rhs;
       function=operator;
       put(lhsOperand).put(rhsOperand);
       execute(lhsOperand.legth());
       get(result);
    }

    public void add(float[] rhs){
       binary(FUNC_ADD,  rhs);
    }

    public void sub( float[] rhs){
       binary(FUNC_SUB,  rhs);
    }

    private void unary(int operator, float[] unary){
       unaryOperand = unary;
       function=operator;
       put(unaryOperand);
       execute(unaryOperand.length());
       get(result);
    }

    public void sqrt(float[] unary){
       unary(FUNC_SQRT, unary);
    }

    private void unary(int operator){
       System.array.copy(result, 0, unaryOperand, 0, result.length);
       function=operator;
       put(unaryOperand);
       execute(unaryOperand.length());
       get(result);

    }

    public void sqrt(){
       unary(FUNC_SQRT);
    }

}
```

