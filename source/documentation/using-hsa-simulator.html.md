---
title: Using HSA Simulator
description: Using Aparapi lambda branch with HSA Simulator.
---

##Introduction
Although HSA compatible devices are available, we understand that Aparapi developers may not have access to these devices.

The HSA foundation has open sourced an LLVM based HSAIL emulator which we can use to test HSAIL generated code.

The project is based here ([https://github.com/HSAFoundation/Okra-Interface-to-HSAIL-Simulator](https://github.com/HSAFoundation/Okra-Interface-to-HSAIL-Simulator)) but we have extracted detailed download and build instructions for Ubuntu below.

Aparapi users/developers can use this simulator to test correctness.

##Building the HSA Simulator on Ubuntu
We assume you have ant, svn and g++ available because you can build other aparapi artifacts.

You will also need git, libelf-dev, libdwarf-dev, flex and cmake

```java

$ sudo apt-get install git libelf-dev libdwarf-dev flex cmake
```

login...

```java

$ git clone https://github.com/HSAFoundation/Okra-Interface-to-HSAIL-Simulator.git okra
$ cd okra
$ ant -f build-okra-sim.xml
```

##The build should take approximately 15 mins.

How to setup and test an initial lambda/HSA enabled Aparapi build
Assuming you have built okra in /home/gfrost/okra

Assuming your Java8 JDK is in /home/gfrost/jdk1.8.0

Assuming your aparapi svn trunk is /home/gfrost/aparapi

```java

$ export JAVA_HOME=/home/gfrost/jdk1.8.0
$ export OKRA=/home/gfrost/okra
$ export PATH=${PATH}:${JAVA_HOME}/bin:${OKRA}/dist/bin
$ java -version
java version "1.8.0-ea"
Java(TM) SE Runtime Environment (build 1.8.0-ea-b94)
Java HotSpot(TM) 64-Bit Server VM (build 25.0-b36, mixed mode)
$ cd /home/gfrost/aparapi/branches/lambda
$ ant
$ export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${OKRA}/dist/bin
$ java -agentpath:com.aparapi.jni/dist/libaparapi_x86_64.so -cp com.aparapi/dist/aparapi.jar:${OKRA}/dist/okra.jar hsailtest.Squares
```